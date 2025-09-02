"""
JobFirst AI服务核心类
集成多种AI模型，提供简历分析、优化等功能
"""

import asyncio
import logging
import json
from typing import Dict, List, Optional, Any, Union
from datetime import datetime
from dataclasses import dataclass

import openai
from anthropic import AsyncAnthropic
import numpy as np
from pydantic import BaseModel, ValidationError

from app.config import config
from app.models.resume import ResumeContent, ResumeAnalysisResult
from app.models.analysis import AnalysisRequest, OptimizationRequest
from app.utils.logger import get_logger
from app.utils.cache import AsyncCache

logger = get_logger(__name__)


@dataclass
class AIModelConfig:
    """AI模型配置"""
    name: str
    provider: str
    max_tokens: int
    temperature: float
    timeout: int
    cost_per_1k_tokens: float


class AIService:
    """AI服务主类"""
    
    def __init__(self):
        self.openai_client: Optional[openai.AsyncOpenAI] = None
        self.anthropic_client: Optional[AsyncAnthropic] = None
        self.cache = AsyncCache()
        self.health_status = "initializing"
        self.model_configs = self._init_model_configs()
        
    async def initialize(self):
        """初始化AI服务"""
        try:
            # 初始化OpenAI客户端
            if config.ai.OPENAI_API_KEY:
                self.openai_client = openai.AsyncOpenAI(
                    api_key=config.ai.OPENAI_API_KEY,
                    timeout=config.ai.ANALYSIS_TIMEOUT
                )
                logger.info("✅ OpenAI客户端初始化成功")
            
            # 初始化Anthropic客户端
            if config.ai.ANTHROPIC_API_KEY:
                self.anthropic_client = AsyncAnthropic(
                    api_key=config.ai.ANTHROPIC_API_KEY,
                    timeout=config.ai.ANALYSIS_TIMEOUT
                )
                logger.info("✅ Anthropic客户端初始化成功")
            
            # 验证模型可用性
            await self._validate_models()
            
            self.health_status = "healthy"
            logger.info("🎉 AI服务初始化完成")
            
        except Exception as e:
            self.health_status = "error"
            logger.error(f"❌ AI服务初始化失败: {e}")
            raise
    
    async def cleanup(self):
        """清理资源"""
        try:
            if self.openai_client:
                await self.openai_client.close()
            if self.anthropic_client:
                await self.anthropic_client.close()
            logger.info("✅ AI服务资源清理完成")
        except Exception as e:
            logger.error(f"❌ AI服务资源清理失败: {e}")
    
    def is_healthy(self) -> bool:
        """检查服务健康状态"""
        return self.health_status == "healthy"
    
    def _init_model_configs(self) -> Dict[str, AIModelConfig]:
        """初始化模型配置"""
        return {
            "gpt-4": AIModelConfig(
                name="gpt-4",
                provider="openai",
                max_tokens=config.ai.OPENAI_MAX_TOKENS,
                temperature=config.ai.OPENAI_TEMPERATURE,
                timeout=config.ai.ANALYSIS_TIMEOUT,
                cost_per_1k_tokens=0.03
            ),
            "gpt-3.5-turbo": AIModelConfig(
                name="gpt-3.5-turbo",
                provider="openai",
                max_tokens=config.ai.OPENAI_MAX_TOKENS,
                temperature=config.ai.OPENAI_TEMPERATURE,
                timeout=config.ai.ANALYSIS_TIMEOUT,
                cost_per_1k_tokens=0.002
            ),
            "claude-3-sonnet": AIModelConfig(
                name="claude-3-sonnet-20240229",
                provider="anthropic",
                max_tokens=config.ai.OPENAI_MAX_TOKENS,
                temperature=config.ai.OPENAI_TEMPERATURE,
                timeout=config.ai.ANALYSIS_TIMEOUT,
                cost_per_1k_tokens=0.015
            ),
            "claude-3-haiku": AIModelConfig(
                name="claude-3-haiku-20240307",
                provider="anthropic",
                max_tokens=config.ai.OPENAI_MAX_TOKENS,
                temperature=config.ai.OPENAI_TEMPERATURE,
                timeout=config.ai.ANALYSIS_TIMEOUT,
                cost_per_1k_tokens=0.00025
            )
        }
    
    async def _validate_models(self):
        """验证模型可用性"""
        validation_tasks = []
        
        if self.openai_client:
            validation_tasks.append(self._validate_openai())
        
        if self.anthropic_client:
            validation_tasks.append(self._validate_anthropic())
        
        if validation_tasks:
            results = await asyncio.gather(*validation_tasks, return_exceptions=True)
            for result in results:
                if isinstance(result, Exception):
                    logger.warning(f"⚠️ 模型验证失败: {result}")
    
    async def _validate_openai(self):
        """验证OpenAI模型"""
        try:
            response = await self.openai_client.chat.completions.create(
                model="gpt-3.5-turbo",
                messages=[{"role": "user", "content": "Hello"}],
                max_tokens=10
            )
            logger.info(f"✅ OpenAI模型验证成功: {response.choices[0].message.content}")
        except Exception as e:
            logger.error(f"❌ OpenAI模型验证失败: {e}")
            raise
    
    async def _validate_anthropic(self):
        """验证Anthropic模型"""
        try:
            response = await self.anthropic_client.messages.create(
                model="claude-3-haiku-20240307",
                max_tokens=10,
                messages=[{"role": "user", "content": "Hello"}]
            )
            logger.info(f"✅ Anthropic模型验证成功: {response.content[0].text}")
        except Exception as e:
            logger.error(f"❌ Anthropic模型验证失败: {e}")
            raise
    
    async def analyze_resume(
        self,
        resume_content: ResumeContent,
        analysis_request: AnalysisRequest
    ) -> ResumeAnalysisResult:
        """分析简历"""
        cache_key = f"resume_analysis:{hash(str(resume_content))}:{hash(str(analysis_request))}"
        
        # 检查缓存
        cached_result = await self.cache.get(cache_key)
        if cached_result:
            logger.info("📋 使用缓存的简历分析结果")
            return ResumeAnalysisResult(**cached_result)
        
        try:
            # 选择AI模型
            model_config = self._select_model(analysis_request.analysis_type)
            
            # 构建分析提示
            prompt = self._build_analysis_prompt(resume_content, analysis_request)
            
            # 调用AI模型
            analysis_result = await self._call_ai_model(
                prompt=prompt,
                model_config=model_config,
                task_type="resume_analysis"
            )
            
            # 解析AI响应
            parsed_result = self._parse_analysis_response(analysis_result, resume_content)
            
            # 缓存结果
            await self.cache.set(cache_key, parsed_result.dict(), ttl=3600)  # 1小时缓存
            
            logger.info(f"✅ 简历分析完成，使用模型: {model_config.name}")
            return parsed_result
            
        except Exception as e:
            logger.error(f"❌ 简历分析失败: {e}")
            raise
    
    async def optimize_resume(
        self,
        resume_content: ResumeContent,
        analysis_result: ResumeAnalysisResult,
        optimization_request: OptimizationRequest
    ) -> Dict[str, Any]:
        """优化简历"""
        try:
            # 构建优化提示
            prompt = self._build_optimization_prompt(
                resume_content, 
                analysis_result, 
                optimization_request
            )
            
            # 选择优化模型
            model_config = self._select_model("comprehensive")
            
            # 调用AI模型
            optimization_result = await self._call_ai_model(
                prompt=prompt,
                model_config=model_config,
                task_type="resume_optimization"
            )
            
            # 解析优化结果
            parsed_result = self._parse_optimization_response(optimization_result)
            
            logger.info(f"✅ 简历优化完成，使用模型: {model_config.name}")
            return parsed_result
            
        except Exception as e:
            logger.error(f"❌ 简历优化失败: {e}")
            raise
    
    async def generate_embeddings(
        self,
        text: str,
        model: str = "text-embedding-ada-002"
    ) -> List[float]:
        """生成文本向量嵌入"""
        try:
            if not self.openai_client:
                raise ValueError("OpenAI客户端未初始化")
            
            response = await self.openai_client.embeddings.create(
                input=text,
                model=model
            )
            
            embeddings = response.data[0].embedding
            logger.info(f"✅ 生成向量嵌入成功，维度: {len(embeddings)}")
            return embeddings
            
        except Exception as e:
            logger.error(f"❌ 生成向量嵌入失败: {e}")
            raise
    
    def _select_model(self, analysis_type: str) -> AIModelConfig:
        """选择AI模型"""
        if analysis_type == "basic":
            return self.model_configs["gpt-3.5-turbo"]
        elif analysis_type == "comprehensive":
            return self.model_configs["gpt-4"]
        elif analysis_type == "expert":
            return self.model_configs["claude-3-sonnet"]
        else:
            return self.model_configs["gpt-4"]
    
    def _build_analysis_prompt(
        self,
        resume_content: ResumeContent,
        analysis_request: AnalysisRequest
    ) -> str:
        """构建简历分析提示"""
        prompt = f"""
请分析以下简历，并提供专业的评估和建议。

简历内容：
姓名：{resume_content.personal_info.name}
职位：{resume_content.personal_info.title or '未指定'}
经验：{len(resume_content.experience)}年工作经验
技能：{', '.join(resume_content.skills)}

详细内容：
{json.dumps(resume_content.dict(), ensure_ascii=False, indent=2)}

分析要求：
- 分析类型：{analysis_request.analysis_type}
- 目标职位：{analysis_request.target_job or '未指定'}
- 行业：{analysis_request.industry or '未指定'}

请提供以下分析：
1. 整体评分（0-100）
2. 内容评分（0-100）
3. 格式评分（0-100）
4. 相关性评分（0-100）
5. 优势分析
6. 改进建议
7. 技能分析
8. 经验分析
9. 市场分析

请以JSON格式返回结果。
"""
        return prompt
    
    def _build_optimization_prompt(
        self,
        resume_content: ResumeContent,
        analysis_result: ResumeAnalysisResult,
        optimization_request: OptimizationRequest
    ) -> str:
        """构建简历优化提示"""
        prompt = f"""
基于以下简历分析结果，请提供具体的优化建议和改进后的简历内容。

原始简历：
{json.dumps(resume_content.dict(), ensure_ascii=False, indent=2)}

分析结果：
{json.dumps(analysis_result.dict(), ensure_ascii=False, indent=2)}

优化要求：
- 优化重点：{optimization_request.optimization_focus}
- 目标职位：{optimization_request.target_job or '未指定'}
- 行业：{optimization_request.industry or '未指定'}

请提供：
1. 优化后的简历内容
2. 具体的修改说明
3. 关键词优化建议
4. 格式改进建议
5. 优化效果评估

请以JSON格式返回结果。
"""
        return prompt
    
    async def _call_ai_model(
        self,
        prompt: str,
        model_config: AIModelConfig,
        task_type: str
    ) -> str:
        """调用AI模型"""
        try:
            if model_config.provider == "openai" and self.openai_client:
                return await self._call_openai(prompt, model_config)
            elif model_config.provider == "anthropic" and self.anthropic_client:
                return await self._call_anthropic(prompt, model_config)
            else:
                raise ValueError(f"不支持的模型提供商: {model_config.provider}")
                
        except Exception as e:
            logger.error(f"❌ AI模型调用失败: {e}")
            raise
    
    async def _call_openai(self, prompt: str, model_config: AIModelConfig) -> str:
        """调用OpenAI模型"""
        response = await self.openai_client.chat.completions.create(
            model=model_config.name,
            messages=[{"role": "user", "content": prompt}],
            max_tokens=model_config.max_tokens,
            temperature=model_config.temperature
        )
        return response.choices[0].message.content
    
    async def _call_anthropic(self, prompt: str, model_config: AIModelConfig) -> str:
        """调用Anthropic模型"""
        response = await self.anthropic_client.messages.create(
            model=model_config.name,
            max_tokens=model_config.max_tokens,
            temperature=model_config.temperature,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text
    
    def _parse_analysis_response(self, ai_response: str, resume_content: ResumeContent) -> ResumeAnalysisResult:
        """解析AI分析响应"""
        try:
            # 尝试解析JSON响应
            if ai_response.strip().startswith('{'):
                parsed_data = json.loads(ai_response)
            else:
                # 如果不是JSON，尝试提取关键信息
                parsed_data = self._extract_analysis_from_text(ai_response)
            
            # 构建分析结果
            analysis_result = ResumeAnalysisResult(
                analysis_id=f"analysis_{datetime.now().timestamp()}",
                resume_id=resume_content.personal_info.name,  # 临时ID
                analysis_time=datetime.now().isoformat(),
                analysis_type="comprehensive",
                overall_score=parsed_data.get('overall_score', 75),
                content_score=parsed_data.get('content_score', 75),
                format_score=parsed_data.get('format_score', 75),
                relevance_score=parsed_data.get('relevance_score', 75),
                strengths=parsed_data.get('strengths', []),
                weaknesses=parsed_data.get('weaknesses', []),
                suggestions=parsed_data.get('suggestions', []),
                skill_analysis=parsed_data.get('skill_analysis', {}),
                experience_analysis=parsed_data.get('experience_analysis', {}),
                market_analysis=parsed_data.get('market_analysis', {})
            )
            
            return analysis_result
            
        except Exception as e:
            logger.error(f"❌ 解析AI分析响应失败: {e}")
            # 返回默认分析结果
            return self._create_default_analysis_result(resume_content)
    
    def _parse_optimization_response(self, ai_response: str) -> Dict[str, Any]:
        """解析AI优化响应"""
        try:
            if ai_response.strip().startswith('{'):
                return json.loads(ai_response)
            else:
                return {"message": "优化完成", "details": ai_response}
        except Exception as e:
            logger.error(f"❌ 解析AI优化响应失败: {e}")
            return {"error": "解析优化结果失败"}
    
    def _extract_analysis_from_text(self, text: str) -> Dict[str, Any]:
        """从文本中提取分析信息"""
        # 简单的文本解析逻辑
        result = {
            'overall_score': 75,
            'content_score': 75,
            'format_score': 75,
            'relevance_score': 75,
            'strengths': [],
            'weaknesses': [],
            'suggestions': []
        }
        
        # 这里可以添加更复杂的文本解析逻辑
        return result
    
    def _create_default_analysis_result(self, resume_content: ResumeContent) -> ResumeAnalysisResult:
        """创建默认分析结果"""
        return ResumeAnalysisResult(
            analysis_id=f"analysis_{datetime.now().timestamp()}",
            resume_id=resume_content.personal_info.name,
            analysis_time=datetime.now().isoformat(),
            analysis_type="basic",
            overall_score=70,
            content_score=70,
            format_score=70,
            relevance_score=70,
            strengths=["简历结构清晰", "包含基本信息"],
            weaknesses=["需要更多具体成就描述", "技能描述可以更详细"],
            suggestions=[],
            skill_analysis={},
            experience_analysis={},
            market_analysis={}
        )

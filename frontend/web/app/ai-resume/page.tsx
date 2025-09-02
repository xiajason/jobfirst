'use client';

import { useState, useRef } from 'react';
import { useMode } from '@/components/common/ModeProvider';
import { FeatureGate, AdvancedFeatureGate } from '@/components/common/FeatureGate';
import Resume from '@/components/dashboard/resume-component';
import ResumeAnalysis from '@/components/dashboard/resume-analysis';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Upload, FileText, Brain, Target, TrendingUp, Download, Share2 } from 'lucide-react';

export default function AIResumePage() {
  const { currentMode, modeConfig, hasFeature } = useMode();
  const [resumeText, setResumeText] = useState('');
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const [isOptimizing, setIsOptimizing] = useState(false);
  const [analysisResult, setAnalysisResult] = useState<any>(null);
  const [resumeData, setResumeData] = useState<any>(null);
  const [analysisStep, setAnalysisStep] = useState<'input' | 'analyzing' | 'result'>('input');
  const fileInputRef = useRef<HTMLInputElement>(null);

  // 处理文件上传
  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      // 检查文件类型
      if (!file.type.includes('pdf') && !file.type.includes('doc') && !file.type.includes('docx')) {
        alert('请上传PDF、DOC或DOCX格式的文件');
        return;
      }
      
      // 检查文件大小 (50MB for Plus, 100MB for Pro)
      const maxSize = currentMode === 'pro' ? 100 * 1024 * 1024 : 50 * 1024 * 1024;
      if (file.size > maxSize) {
        alert(`文件大小不能超过${currentMode === 'pro' ? '100MB' : '50MB'}`);
        return;
      }
      
      setUploadedFile(file);
      setResumeText(''); // 清空文本输入
    }
  };

  // 处理文本输入
  const handleTextChange = (text: string) => {
    setResumeText(text);
    setUploadedFile(null); // 清空文件上传
  };

  // 开始AI优化分析
  const handleStartAnalysis = async () => {
    if (!resumeText.trim() && !uploadedFile) {
      alert('请上传简历文件或输入简历内容');
      return;
    }

    setAnalysisStep('analyzing');
    setIsOptimizing(true);
    
    try {
      // 模拟AI分析过程
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // 生成模拟的AI分析结果
      const mockAnalysis = generateMockAnalysis();
      setAnalysisResult(mockAnalysis);
      
      // 生成简历数据
      const generatedResumeData = generateResumeData(resumeText || '上传的简历内容');
      setResumeData(generatedResumeData);
      
      setAnalysisStep('result');
    } catch (error) {
      console.error('分析失败:', error);
      alert('分析失败，请重试');
    } finally {
      setIsOptimizing(false);
    }
  };

  // 生成模拟的AI分析结果
  const generateMockAnalysis = () => {
    const baseScore = Math.floor(Math.random() * 20) + 75; // 75-95分
    
    return {
      score: baseScore,
      details: '简历结构清晰，技能描述详细，但可以进一步优化关键词匹配和量化指标。',
      commentary: '整体表现良好，建议在项目经验描述中添加更多量化指标，提升技能关键词的匹配度。',
      improvements: [
        { suggestion: '在技能描述中添加具体的技术栈版本和熟练程度', lineNumber: '技能部分' },
        { suggestion: '工作经验描述可以更加量化，如"提升了30%的系统性能"', lineNumber: '经验部分' },
        { suggestion: '项目经历可以突出你的核心贡献和具体成果', lineNumber: '项目部分' },
        { suggestion: '教育背景可以添加相关课程、证书和获奖情况', lineNumber: '教育部分' },
        { suggestion: '建议添加行业关键词，提升简历的搜索匹配度', lineNumber: '整体优化' }
      ],
      // 专业版额外功能
      ...(currentMode === 'pro' && {
        industryMatch: '互联网/软件开发 - 匹配度: 92%',
        jobFit: '高级开发工程师 - 匹配度: 88%',
        competitorAnalysis: '在同行业求职者中排名前15%',
        skillGap: ['微服务架构', '云原生技术', 'DevOps实践'],
        marketTrends: '当前市场对全栈开发工程师需求旺盛',
        salaryRange: '25K-45K (根据经验和技能)'
      })
    };
  };

  // 生成简历数据
  const generateResumeData = (text: string) => {
    const lines = text.split('\n').filter(line => line.trim());
    
    return {
      personalInfo: {
        name: lines.find(line => line.includes('姓名') || line.includes('Name'))?.split(':')[1]?.trim() || '张三',
        title: lines.find(line => line.includes('职位') || line.includes('Title'))?.split(':')[1]?.trim() || '软件工程师',
        email: lines.find(line => line.includes('邮箱') || line.includes('Email'))?.split(':')[1]?.trim() || 'zhangsan@example.com',
        phone: lines.find(line => line.includes('电话') || line.includes('Phone'))?.split(':')[1]?.trim() || '13800138000',
        location: lines.find(line => line.includes('地址') || line.includes('Location'))?.split(':')[1]?.trim() || '北京',
      },
      summary: lines.find(line => line.includes('简介') || line.includes('Summary'))?.split(':')[1]?.trim() || 
               '经验丰富的软件工程师，专注于Web开发和系统架构设计，具备5年以上的开发经验。',
      experience: [
        {
          id: 1,
          title: '高级软件工程师',
          company: '科技公司',
          location: '北京',
          years: '2020-2023',
          description: ['负责核心系统开发，提升系统性能30%', '带领5人开发团队，完成3个重要项目', '优化数据库查询，减少响应时间50%']
        },
        {
          id: 2,
          title: '软件工程师',
          company: '互联网公司',
          location: '上海',
          years: '2018-2020',
          description: ['参与电商平台开发', '实现用户增长200%', '负责前端性能优化']
        }
      ],
      education: [
        {
          id: 1,
          institution: '计算机大学',
          degree: '计算机科学学士',
          years: '2014-2018',
          description: '主修软件工程，获得优秀毕业生称号，参与多个开源项目'
        }
      ],
      skills: ['JavaScript', 'React', 'Node.js', 'Python', 'Docker', 'Kubernetes', 'MySQL', 'Redis', '微服务架构']
    };
  };

  // 导出优化后的简历
  const handleExport = () => {
    // 模拟导出功能
    alert('简历导出功能开发中...');
  };

  // 分享简历
  const handleShare = () => {
    // 模拟分享功能
    alert('简历分享功能开发中...');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-blue-50 py-8">
      <div className="max-w-7xl mx-auto px-4">
        {/* 页面标题 */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            🤖 AI简历优化
          </h1>
          <p className="text-lg text-gray-600">
            当前版本: {modeConfig.name} - {modeConfig.description}
          </p>
          <div className="mt-4">
            <Badge variant="secondary" className="text-lg px-4 py-2">
              {currentMode === 'basic' ? '🔒 功能锁定' : 
               currentMode === 'plus' ? '⚡ 增强版功能' : 
               '👑 专业版功能'}
            </Badge>
          </div>
        </div>

        {/* 功能特性展示 */}
        <FeatureGate feature="ai_resume_optimization" fallback={
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6 text-center">
            <h3 className="text-lg font-semibold text-yellow-800 mb-2">
              🔒 功能锁定
            </h3>
            <p className="text-yellow-700 mb-4">
              当前版本不支持AI简历优化功能，请升级到增强版或专业版
            </p>
            <Button className="bg-yellow-600 hover:bg-yellow-700">
              升级版本
            </Button>
          </div>
        }>
          {/* 输入阶段 */}
          {analysisStep === 'input' && (
            <div className="grid grid-cols-1 xl:grid-cols-2 gap-8">
              {/* 左侧：简历输入 */}
              <div className="space-y-6">
                {/* 文件上传 */}
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <Upload className="w-5 h-5" />
                      上传简历文件
                    </CardTitle>
                    <CardDescription>
                      支持PDF、DOC、DOCX格式，{currentMode === 'pro' ? '无大小限制' : '最大50MB'}
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-blue-400 transition-colors">
                      <input
                        ref={fileInputRef}
                        type="file"
                        accept=".pdf,.doc,.docx"
                        onChange={handleFileUpload}
                        className="hidden"
                      />
                      <Upload className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                      <p className="text-gray-600 mb-2">
                        {uploadedFile ? uploadedFile.name : '点击上传或拖拽文件到此处'}
                      </p>
                      <Button
                        variant="outline"
                        onClick={() => fileInputRef.current?.click()}
                        className="mt-2"
                      >
                        选择文件
                      </Button>
                      {uploadedFile && (
                        <div className="mt-4 p-3 bg-green-50 rounded-lg">
                          <p className="text-sm text-green-700">
                            ✓ 文件已上传: {uploadedFile.name}
                          </p>
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>

                {/* 文本输入 */}
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <FileText className="w-5 h-5" />
                      手动输入简历
                    </CardTitle>
                    <CardDescription>
                      或者直接输入简历内容，AI将为您提供优化建议
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Textarea
                      value={resumeText}
                      onChange={(e) => handleTextChange(e.target.value)}
                      placeholder="请粘贴您的简历内容，AI将为您提供优化建议..."
                      className="w-full h-48 resize-none"
                    />
                    
                    {/* 示例简历 */}
                    {!resumeText && !uploadedFile && (
                      <div className="mt-4 p-3 bg-gray-50 rounded-lg">
                        <p className="text-sm text-gray-600 mb-2">💡 示例简历格式：</p>
                        <div className="text-xs text-gray-500 space-y-1">
                          <p>姓名: 张三</p>
                          <p>职位: 软件工程师</p>
                          <p>邮箱: zhangsan@example.com</p>
                          <p>电话: 13800138000</p>
                          <p>地址: 北京</p>
                          <p>简介: 经验丰富的软件工程师...</p>
                        </div>
                      </div>
                    )}
                  </CardContent>
                </Card>

                {/* 开始分析按钮 */}
                <Button
                  onClick={handleStartAnalysis}
                  disabled={!resumeText.trim() && !uploadedFile}
                  size="lg"
                  className="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white py-4 text-lg"
                >
                  <Brain className="w-5 h-5 mr-2" />
                  开始AI智能分析
                </Button>
              </div>

              {/* 右侧：功能介绍 */}
              <div className="space-y-6">
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <Target className="w-5 h-5" />
                      AI分析功能
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      <div className="flex items-start gap-3">
                        <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center flex-shrink-0">
                          <span className="text-blue-600 text-sm font-semibold">1</span>
                        </div>
                        <div>
                          <h4 className="font-medium text-gray-800">智能解析</h4>
                          <p className="text-sm text-gray-600">AI自动解析简历结构，提取关键信息</p>
                        </div>
                      </div>
                      
                      <div className="flex items-start gap-3">
                        <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center flex-shrink-0">
                          <span className="text-green-600 text-sm font-semibold">2</span>
                        </div>
                        <div>
                          <h4 className="font-medium text-gray-800">深度分析</h4>
                          <p className="text-sm text-gray-600">分析简历质量，提供专业优化建议</p>
                        </div>
                      </div>
                      
                      <div className="flex items-start gap-3">
                        <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center flex-shrink-0">
                          <span className="text-purple-600 text-sm font-semibold">3</span>
                        </div>
                        <div>
                          <h4 className="font-medium text-gray-800">智能匹配</h4>
                          <p className="text-sm text-gray-600">匹配职位要求，提升求职成功率</p>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                {/* 版本特性 */}
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <TrendingUp className="w-5 h-5" />
                      版本特性
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">基础版</span>
                        <Badge variant="outline" className="text-xs">功能锁定</Badge>
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">增强版</span>
                        <Badge className="bg-green-500 text-xs">AI简历优化</Badge>
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-600">专业版</span>
                        <Badge className="bg-purple-500 text-xs">高级分析</Badge>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </div>
          )}

          {/* 分析中阶段 */}
          {analysisStep === 'analyzing' && (
            <div className="text-center py-16">
              <div className="animate-spin rounded-full h-20 w-20 border-b-2 border-blue-600 mx-auto mb-6"></div>
              <h3 className="text-2xl font-semibold text-gray-800 mb-4">AI正在深度分析您的简历...</h3>
              <div className="max-w-2xl mx-auto">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-gray-600">
                  <div className="p-3 bg-white rounded-lg">
                    <Brain className="w-6 h-6 mx-auto mb-2 text-blue-500" />
                    <p>智能解析中</p>
                  </div>
                  <div className="p-3 bg-white rounded-lg">
                    <Target className="w-6 h-6 mx-auto mb-2 text-green-500" />
                    <p>质量分析中</p>
                  </div>
                  <div className="p-3 bg-white rounded-lg">
                    <TrendingUp className="w-6 h-6 mx-auto mb-2 text-purple-500" />
                    <p>优化建议生成中</p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* 结果展示阶段 */}
          {analysisStep === 'result' && analysisResult && resumeData && (
            <div className="space-y-8">
              {/* 分析结果概览 */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Brain className="w-5 h-5" />
                    AI分析结果
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <ResumeAnalysis
                    score={analysisResult.score}
                    details={analysisResult.details}
                    commentary={analysisResult.commentary}
                    improvements={analysisResult.improvements}
                  />
                </CardContent>
              </Card>

              {/* 专业版额外功能 */}
              {currentMode === 'pro' && (
                <AdvancedFeatureGate feature="advanced_ai_analysis">
                  <Card>
                    <CardHeader>
                      <CardTitle className="flex items-center gap-2">
                        <TrendingUp className="w-5 h-5" />
                        高级AI分析结果
                      </CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div className="space-y-4">
                          <div className="p-4 bg-gradient-to-r from-blue-50 to-purple-50 rounded-lg">
                            <h4 className="font-semibold text-gray-800 mb-2">行业匹配度</h4>
                            <p className="text-blue-600 font-medium">{analysisResult.industryMatch}</p>
                          </div>
                          <div className="p-4 bg-gradient-to-r from-green-50 to-emerald-50 rounded-lg">
                            <h4 className="font-semibold text-gray-800 mb-2">职位匹配度</h4>
                            <p className="text-green-600 font-medium">{analysisResult.jobFit}</p>
                          </div>
                        </div>
                        <div className="space-y-4">
                          <div className="p-4 bg-gradient-to-r from-purple-50 to-pink-50 rounded-lg">
                            <h4 className="font-semibold text-gray-800 mb-2">竞争力分析</h4>
                            <p className="text-purple-600 font-medium">{analysisResult.competitorAnalysis}</p>
                          </div>
                          <div className="p-4 bg-gradient-to-r from-orange-50 to-red-50 rounded-lg">
                            <h4 className="font-semibold text-gray-800 mb-2">薪资范围</h4>
                            <p className="text-orange-600 font-medium">{analysisResult.salaryRange}</p>
                          </div>
                        </div>
                      </div>
                      
                      {analysisResult.skillGap && (
                        <div className="mt-6 p-4 bg-yellow-50 rounded-lg">
                          <h4 className="font-semibold text-gray-800 mb-2">技能提升建议</h4>
                          <div className="flex flex-wrap gap-2">
                            {analysisResult.skillGap.map((skill: string, index: number) => (
                              <Badge key={index} variant="outline" className="bg-yellow-100">
                                {skill}
                              </Badge>
                            ))}
                          </div>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                </AdvancedFeatureGate>
              )}

              {/* 优化后的简历预览 */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <FileText className="w-5 h-5" />
                    优化后的简历预览
                  </CardTitle>
                  <CardDescription>
                    基于AI分析结果优化后的简历内容
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Resume resumeData={resumeData} />
                </CardContent>
              </Card>

              {/* 操作按钮 */}
              <div className="flex justify-center gap-4">
                <Button
                  onClick={() => setAnalysisStep('input')}
                  variant="outline"
                  size="lg"
                  className="px-8 py-3"
                >
                  重新分析
                </Button>
                <Button
                  onClick={handleExport}
                  size="lg"
                  className="px-8 py-3 bg-green-600 hover:bg-green-700"
                >
                  <Download className="w-5 h-5 mr-2" />
                  导出简历
                </Button>
                <Button
                  onClick={handleShare}
                  size="lg"
                  className="px-8 py-3 bg-blue-600 hover:bg-blue-700"
                >
                  <Share2 className="w-5 h-5 mr-2" />
                  分享简历
                </Button>
              </div>
            </div>
          )}
        </FeatureGate>
      </div>
    </div>
  );
}

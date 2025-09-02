#!/usr/bin/env python3
"""
JobFirst AI Service - 基于Sanic的高性能异步AI服务
"""

import asyncio
import logging
from contextlib import asynccontextmanager
from typing import Optional

from sanic import Sanic, Request, response
from sanic.response import json, text
from sanic_cors import CORS
from sanic_ext import Extend

from app.routes import setup_routes
from app.middleware import setup_middleware
from app.config import Config
from app.database import init_database, close_database
from app.services.ai_service import AIService
from app.services.vector_service import VectorService
from app.utils.logger import setup_logging

# 配置日志
setup_logging()
logger = logging.getLogger(__name__)

# 创建Sanic应用
app = Sanic("jobfirst-ai-service")
app.config.update(Config.to_dict())

# 扩展功能
Extend(app)

# 配置CORS
CORS(app, resources={r"/api/*": {"origins": "*"}})

# 全局服务实例
ai_service: Optional[AIService] = None
vector_service: Optional[VectorService] = None


@app.listener('before_server_start')
async def setup_services(app, loop):
    """服务器启动前初始化服务"""
    global ai_service, vector_service
    
    logger.info("🚀 启动JobFirst AI服务...")
    
    # 初始化数据库连接
    await init_database()
    logger.info("✅ 数据库连接初始化完成")
    
    # 初始化AI服务
    ai_service = AIService()
    await ai_service.initialize()
    logger.info("✅ AI服务初始化完成")
    
    # 初始化向量服务
    vector_service = VectorService()
    await vector_service.initialize()
    logger.info("✅ 向量服务初始化完成")
    
    logger.info("🎉 所有服务初始化完成！")


@app.listener('after_server_stop')
async def cleanup_services(app, loop):
    """服务器停止后清理资源"""
    logger.info("🔄 清理服务资源...")
    
    # 关闭数据库连接
    await close_database()
    logger.info("✅ 数据库连接已关闭")
    
    # 清理AI服务
    if ai_service:
        await ai_service.cleanup()
        logger.info("✅ AI服务已清理")
    
    # 清理向量服务
    if vector_service:
        await vector_service.cleanup()
        logger.info("✅ 向量服务已清理")
    
    logger.info("👋 服务资源清理完成")


@app.middleware('request')
async def request_middleware(request: Request):
    """请求中间件"""
    request.ctx.start_time = asyncio.get_event_loop().time()
    
    # 记录请求日志
    logger.info(f"📥 {request.method} {request.path} - {request.ip}")
    
    # 添加请求ID
    request.ctx.request_id = request.headers.get('X-Request-ID', f"req_{id(request)}")


@app.middleware('response')
async def response_middleware(request: Request, response):
    """响应中间件"""
    # 计算响应时间
    if hasattr(request.ctx, 'start_time'):
        response_time = asyncio.get_event_loop().time() - request.ctx.start_time
        response.headers['X-Response-Time'] = f"{response_time:.4f}s"
    
    # 记录响应日志
    logger.info(f"📤 {request.method} {request.path} - {response.status} - {response.headers.get('X-Response-Time', 'N/A')}")


@app.exception(Exception)
async def handle_exception(request: Request, exception: Exception):
    """全局异常处理"""
    logger.error(f"❌ 未处理的异常: {exception}", exc_info=True)
    
    return json({
        "success": False,
        "error": "Internal Server Error",
        "message": str(exception),
        "request_id": getattr(request.ctx, 'request_id', 'unknown'),
        "timestamp": asyncio.get_event_loop().time()
    }, status=500)


@app.route("/")
async def health_check(request: Request):
    """健康检查端点"""
    return json({
        "service": "JobFirst AI Service",
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": asyncio.get_event_loop().time()
    })


@app.route("/health")
async def detailed_health_check(request: Request):
    """详细健康检查"""
    health_status = {
        "service": "JobFirst AI Service",
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": asyncio.get_event_loop().time(),
        "components": {}
    }
    
    # 检查数据库连接
    try:
        from app.database import get_database
        db = await get_database()
        if db:
            health_status["components"]["database"] = "healthy"
        else:
            health_status["components"]["database"] = "unhealthy"
            health_status["status"] = "degraded"
    except Exception as e:
        health_status["components"]["database"] = f"error: {str(e)}"
        health_status["status"] = "unhealthy"
    
    # 检查AI服务
    if ai_service and ai_service.is_healthy():
        health_status["components"]["ai_service"] = "healthy"
    else:
        health_status["components"]["ai_service"] = "unhealthy"
        health_status["status"] = "degraded"
    
    # 检查向量服务
    if vector_service and vector_service.is_healthy():
        health_status["components"]["vector_service"] = "healthy"
    else:
        health_status["components"]["vector_service"] = "unhealthy"
        health_status["status"] = "degraded"
    
    status_code = 200 if health_status["status"] == "healthy" else 503
    return json(health_status, status=status_code)


@app.route("/metrics")
async def metrics(request: Request):
    """Prometheus指标端点"""
    from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
    
    return response.raw(
        generate_latest(),
        content_type=CONTENT_TYPE_LATEST
    )


def main():
    """主函数"""
    # 设置路由
    setup_routes(app)
    
    # 设置中间件
    setup_middleware(app)
    
    # 启动服务器
    app.run(
        host=Config.HOST,
        port=Config.PORT,
        debug=Config.DEBUG,
        access_log=Config.ACCESS_LOG,
        workers=Config.WORKERS,
        loop=asyncio.new_event_loop()
    )


if __name__ == "__main__":
    main()

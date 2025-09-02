'use client';

import { useState, useEffect } from 'react';
import { useMode } from '@/components/common/ModeProvider';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Check, Star, Zap, Crown } from 'lucide-react';
import React from 'react';
import { Mode } from '@/config/modes';

export default function Home() {
  const [mounted, setMounted] = useState(false);
  const { currentMode, modeConfig, switchMode } = useMode();
  
  // 解决水合问题
  useEffect(() => {
    setMounted(true);
  }, []);

  // 如果还没有挂载，返回一个加载状态
  if (!mounted) {
    return <div>加载中...</div>;
  }

  // 所有可用模式
  const allModes: Mode[] = ['basic', 'plus', 'pro'];
  
  const modeFeatures = {
    basic: {
      icon: <Star className="w-6 h-6" />,
      color: 'bg-blue-500',
      features: [
        '用户注册登录',
        '基础简历管理',
        '职位搜索',
        '基础聊天功能',
        '文件上传(10MB)',
        '基础数据统计'
      ]
    },
    plus: {
      icon: <Zap className="w-6 h-6" />,
      color: 'bg-green-500',
      features: [
        '基础版所有功能',
        '高级数据分析',
        'AI简历优化',
        '智能职位推荐',
        '积分系统',
        '高级聊天功能',
        '文件上传(50MB)',
        '详细数据统计',
        '个性化推荐'
      ]
    },
    pro: {
      icon: <Crown className="w-6 h-6" />,
      color: 'bg-purple-500',
      features: [
        '增强版所有功能',
        '企业级管理',
        '团队协作',
        '高级AI服务',
        '自定义工作流',
        'API集成',
        '高级安全功能',
        '无限文件上传',
        '实时数据分析',
        '企业级支持',
        '自定义品牌',
        '多语言支持'
      ]
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-blue-50">
      <div className="max-w-7xl mx-auto px-4 py-12">
        {/* 主标题 */}
        <div className="text-center mb-16">
          <h1 className="text-5xl font-bold text-gray-900 mb-6">
            JobFirst - 智能求职平台
          </h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            基于AI技术的智能简历优化和职位匹配平台，帮助求职者提升求职成功率
          </p>
        </div>

        {/* 当前版本状态 */}
        <div className="text-center mb-12">
          <div className="inline-flex items-center gap-3 bg-white rounded-full px-6 py-3 shadow-lg">
            <span className="text-gray-600">当前版本:</span>
            <Badge variant="secondary" className="text-lg px-4 py-2">
              {modeConfig.name}
            </Badge>
            <span className="text-gray-500 text-sm">({modeConfig.description})</span>
          </div>
        </div>

        {/* 版本选择卡片 */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-16">
          {allModes.map((mode) => {
            const modeInfo = modeFeatures[mode as keyof typeof modeFeatures];
            const isCurrentMode = currentMode === mode;
            
            return (
              <Card 
                key={mode} 
                className={`relative transition-all duration-300 hover:shadow-xl ${
                  isCurrentMode ? 'ring-2 ring-blue-500 scale-105' : 'hover:scale-105'
                }`}
              >
                {isCurrentMode && (
                  <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                    <Badge className="bg-blue-500 text-white px-4 py-1">
                      当前版本
                    </Badge>
                  </div>
                )}
                
                <CardHeader className="text-center pb-4">
                  <div className={`inline-flex items-center justify-center w-16 h-16 rounded-full ${modeInfo.color} text-white mb-4`}>
                    {modeInfo.icon}
                  </div>
                  <CardTitle className="text-2xl">
                    {mode === 'basic' ? '基础版' : mode === 'plus' ? '增强版' : '专业版'}
                  </CardTitle>
                  <CardDescription className="text-base">
                    {mode === 'basic' ? '核心功能，轻量级部署' : 
                     mode === 'plus' ? '增加数据分析能力' : 
                     '全功能企业级方案'}
                  </CardDescription>
                </CardHeader>
                
                <CardContent>
                  <div className="space-y-3 mb-6">
                    {modeInfo.features.map((feature, index) => (
                      <div key={index} className="flex items-center gap-2">
                        <Check className="w-4 h-4 text-green-500 flex-shrink-0" />
                        <span className="text-sm text-gray-600">{feature}</span>
                      </div>
                    ))}
                  </div>
                  
                  <div className="text-center">
                    <Button
                      onClick={() => switchMode(mode)}
                      variant={isCurrentMode ? "outline" : "default"}
                      className="w-full"
                      disabled={isCurrentMode}
                    >
                      {isCurrentMode ? '当前版本' : '选择此版本'}
                    </Button>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>

        {/* 功能导航 */}
        <div className="text-center">
          <h2 className="text-3xl font-bold text-gray-800 mb-8">
            开始使用
          </h2>
          <div className="flex flex-wrap justify-center gap-6">
            <Button
              asChild
              size="lg"
              className="bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white px-8 py-4 text-lg"
            >
              <a href="/ai-resume">
                🤖 AI简历优化
              </a>
            </Button>
            
            <Button
              asChild
              variant="outline"
              size="lg"
              className="px-8 py-4 text-lg"
            >
              <a href="/dashboard">
                📊 数据看板
              </a>
            </Button>
            
            <Button
              asChild
              variant="outline"
              size="lg"
              className="px-8 py-4 text-lg"
            >
              <a href="/upload">
                📁 简历上传
              </a>
            </Button>
          </div>
        </div>

        {/* 版本特性对比 */}
        <div className="mt-20">
          <h2 className="text-3xl font-bold text-gray-800 text-center mb-12">
            版本特性对比
          </h2>
          <div className="bg-white rounded-2xl shadow-xl overflow-hidden">
            <div className="grid grid-cols-4 gap-0">
              {/* 表头 */}
              <div className="bg-gray-50 p-6 border-r border-gray-200">
                <h3 className="font-semibold text-gray-800">功能特性</h3>
              </div>
              {allModes.map((mode) => (
                <div key={mode} className="bg-gray-50 p-6 text-center border-r border-gray-200 last:border-r-0">
                  <h3 className="font-semibold text-gray-800">
                    {mode === 'basic' ? '基础版' : mode === 'plus' ? '增强版' : '专业版'}
                  </h3>
                </div>
              ))}
              
              {/* 功能行 */}
              {[
                'AI简历优化',
                '智能职位推荐',
                '高级数据分析',
                '企业级管理',
                'API集成',
                '无限文件上传'
              ].map((feature) => (
                <React.Fragment key={feature}>
                  <div className="p-4 border-r border-gray-200 bg-white">
                    <span className="text-gray-700">{feature}</span>
                  </div>
                  {allModes.map((mode) => (
                    <div key={mode} className="p-4 text-center border-r border-gray-200 last:border-r-0 bg-white">
                      {mode === 'basic' ? (
                        <span className="text-red-500">✗</span>
                      ) : mode === 'plus' ? (
                        feature === 'AI简历优化' || feature === '智能职位推荐' || feature === '高级数据分析' ? 
                        <span className="text-green-500">✓</span> : <span className="text-red-500">✗</span>
                      ) : (
                        <span className="text-green-500">✓</span>
                      )}
                    </div>
                  ))}
                </React.Fragment>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
'use client';

import { useState, useRef } from 'react';
import { useMode } from '@/components/common/ModeProvider';
import { FeatureGate } from '@/components/common/FeatureGate';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Upload, FileText, CheckCircle, AlertCircle, FileUp } from 'lucide-react';

export default function UploadPage() {
  const { currentMode, modeConfig } = useMode();
  const [resumeText, setResumeText] = useState('');
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadResult, setUploadResult] = useState<any>(null);
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
      
      // 检查文件大小
      const maxSize = currentMode === 'pro' ? 100 * 1024 * 1024 : 
                     currentMode === 'plus' ? 50 * 1024 * 1024 : 
                     10 * 1024 * 1024;
      
      if (file.size > maxSize) {
        alert(`文件大小不能超过${currentMode === 'pro' ? '100MB' : currentMode === 'plus' ? '50MB' : '10MB'}`);
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

  // 开始上传
  const handleUpload = async () => {
    if (!resumeText.trim() && !uploadedFile) {
      alert('请上传简历文件或输入简历内容');
      return;
    }

    setIsUploading(true);
    
    try {
      // 模拟上传过程
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // 生成上传结果
      const result = {
        success: true,
        resumeId: `resume_${Date.now()}`,
        message: '简历上传成功！',
        filename: uploadedFile?.name || '手动输入的简历',
        size: uploadedFile?.size || resumeText.length,
        uploadTime: new Date().toLocaleString()
      };
      
      setUploadResult(result);
    } catch (error) {
      console.error('上传失败:', error);
      setUploadResult({
        success: false,
        message: '上传失败，请重试',
        error: error instanceof Error ? error.message : '未知错误'
      });
    } finally {
      setIsUploading(false);
    }
  };

  // 继续到AI优化
  const handleContinueToAI = () => {
    if (uploadResult?.success) {
      window.location.href = `/ai-resume?resume_id=${uploadResult.resumeId}`;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-blue-50 py-8">
      <div className="max-w-6xl mx-auto px-4">
        {/* 页面标题 */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            📁 简历上传
          </h1>
          <p className="text-lg text-gray-600">
            当前版本: {modeConfig.name} - {modeConfig.description}
          </p>
          <div className="mt-4">
            <Badge variant="secondary" className="text-lg px-4 py-2">
              {currentMode === 'basic' ? '🔒 基础功能' : 
               currentMode === 'plus' ? '⚡ 增强功能' : 
               '👑 专业功能'}
            </Badge>
          </div>
        </div>

        {/* 功能特性展示 */}
        <FeatureGate feature="resume_upload" fallback={
          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6 text-center">
            <h3 className="text-lg font-semibold text-yellow-800 mb-2">
              🔒 功能受限
            </h3>
            <p className="text-yellow-700 mb-4">
              当前版本文件上传大小限制为10MB，升级版本获得更大容量
            </p>
            <Button className="bg-yellow-600 hover:bg-yellow-700">
              升级版本
            </Button>
          </div>
        }>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* 左侧：上传区域 */}
            <div className="space-y-6">
              {/* 文件上传 */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <FileUp className="w-5 h-5" />
                    上传简历文件
                  </CardTitle>
                  <CardDescription>
                    支持PDF、DOC、DOCX格式
                    {currentMode === 'basic' && '，最大10MB'}
                    {currentMode === 'plus' && '，最大50MB'}
                    {currentMode === 'pro' && '，无大小限制'}
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
                        <div className="flex items-center gap-2 text-green-700">
                          <CheckCircle className="w-4 h-4" />
                          <span className="text-sm">文件已选择: {uploadedFile.name}</span>
                        </div>
                        <p className="text-xs text-green-600 mt-1">
                          大小: {(uploadedFile.size / 1024 / 1024).toFixed(2)} MB
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
                    或者直接输入简历内容
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Textarea
                    value={resumeText}
                    onChange={(e) => handleTextChange(e.target.value)}
                    placeholder="请粘贴您的简历内容..."
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

              {/* 上传按钮 */}
              <Button
                onClick={handleUpload}
                disabled={isUploading || (!resumeText.trim() && !uploadedFile)}
                size="lg"
                className="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white py-4 text-lg"
              >
                {isUploading ? (
                  <>
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
                    上传中...
                  </>
                ) : (
                  <>
                    <Upload className="w-5 h-5 mr-2" />
                    开始上传
                  </>
                )}
              </Button>
            </div>

            {/* 右侧：状态和结果 */}
            <div className="space-y-6">
              {/* 上传状态 */}
              {isUploading && (
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-blue-600"></div>
                      正在上传...
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                          <span className="text-blue-600 text-sm font-semibold">1</span>
                        </div>
                        <div>
                          <h4 className="font-medium text-gray-800">文件验证</h4>
                          <p className="text-sm text-gray-600">检查文件格式和大小</p>
                        </div>
                      </div>
                      
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center">
                          <span className="text-green-600 text-sm font-semibold">2</span>
                        </div>
                        <div>
                          <h4 className="font-medium text-gray-800">内容解析</h4>
                          <p className="text-sm text-gray-600">AI解析简历内容结构</p>
                        </div>
                      </div>
                      
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
                          <span className="text-purple-600 text-sm font-semibold">3</span>
                        </div>
                        <div>
                          <h4 className="font-medium text-gray-800">数据存储</h4>
                          <p className="text-sm text-gray-600">保存到系统数据库</p>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              )}

              {/* 上传结果 */}
              {uploadResult && !isUploading && (
                <Card>
                  <CardHeader>
                    <CardTitle className={`flex items-center gap-2 ${
                      uploadResult.success ? 'text-green-600' : 'text-red-600'
                    }`}>
                      {uploadResult.success ? (
                        <CheckCircle className="w-5 h-5" />
                      ) : (
                        <AlertCircle className="w-5 h-5" />
                      )}
                      {uploadResult.success ? '上传成功' : '上传失败'}
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    {uploadResult.success ? (
                      <div className="space-y-4">
                        <div className="p-4 bg-green-50 rounded-lg">
                          <p className="text-green-700">{uploadResult.message}</p>
                        </div>
                        
                        <div className="space-y-2 text-sm">
                          <div className="flex justify-between">
                            <span className="text-gray-600">简历ID:</span>
                            <span className="font-mono text-gray-800">{uploadResult.resumeId}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">文件名:</span>
                            <span className="text-gray-800">{uploadResult.filename}</span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">大小:</span>
                            <span className="text-gray-800">
                              {uploadResult.size > 1024 * 1024 
                                ? `${(uploadResult.size / 1024 / 1024).toFixed(2)} MB`
                                : `${(uploadResult.size / 1024).toFixed(2)} KB`
                              }
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-600">上传时间:</span>
                            <span className="text-gray-800">{uploadResult.uploadTime}</span>
                          </div>
                        </div>

                        <Button
                          onClick={handleContinueToAI}
                          className="w-full bg-gradient-to-r from-green-600 to-blue-600 hover:from-green-700 hover:to-blue-700 text-white"
                        >
                          🤖 继续AI简历优化
                        </Button>
                      </div>
                    ) : (
                      <div className="p-4 bg-red-50 rounded-lg">
                        <p className="text-red-700">{uploadResult.message}</p>
                        {uploadResult.error && (
                          <p className="text-red-600 text-sm mt-2">错误详情: {uploadResult.error}</p>
                        )}
                      </div>
                    )}
                  </CardContent>
                </Card>
              )}

              {/* 功能介绍 */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <FileText className="w-5 h-5" />
                    功能介绍
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    <div className="flex items-center gap-2">
                      <CheckCircle className="w-4 h-4 text-green-500" />
                      <span className="text-sm text-gray-600">支持多种文件格式</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <CheckCircle className="w-4 h-4 text-green-500" />
                      <span className="text-sm text-gray-600">AI智能内容解析</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <CheckCircle className="w-4 h-4 text-green-500" />
                      <span className="text-sm text-gray-600">安全数据存储</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <CheckCircle className="w-4 h-4 text-green-500" />
                      <span className="text-sm text-gray-600">无缝对接AI优化</span>
                    </div>
                  </div>
                </CardContent>
              </Card>

              {/* 版本对比 */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Badge className="w-5 h-5" />
                    版本对比
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-600">基础版</span>
                      <Badge variant="outline" className="text-xs">10MB</Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-600">增强版</span>
                      <Badge className="bg-green-500 text-xs">50MB</Badge>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-600">专业版</span>
                      <Badge className="bg-purple-500 text-xs">无限制</Badge>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          </div>
        </FeatureGate>
      </div>
    </div>
  );
}

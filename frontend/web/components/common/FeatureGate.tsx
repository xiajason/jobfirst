'use client';

import React from 'react';
import { useMode } from './ModeProvider';

interface FeatureGateProps {
  feature: string;
  children: React.ReactNode;
  fallback?: React.ReactNode;
  showUpgradePrompt?: boolean;
}

export const FeatureGate: React.FC<FeatureGateProps> = ({
  feature,
  children,
  fallback,
  showUpgradePrompt = false,
}) => {
  const { hasFeature, modeConfig } = useMode();

  if (hasFeature(feature)) {
    return <>{children}</>;
  }

  if (fallback) {
    return <>{fallback}</>;
  }

  if (showUpgradePrompt) {
    return (
      <div className="p-4 border border-gray-200 rounded-lg bg-gray-50">
        <div className="text-center">
          <h3 className="text-lg font-semibold text-gray-900 mb-2">
            功能不可用
          </h3>
          <p className="text-gray-600 mb-4">
            当前模式 ({modeConfig.name}) 不支持此功能。
          </p>
          <div className="space-y-2">
            <button
              className="block w-full px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 transition-colors"
              onClick={() => {
                // 这里可以添加升级逻辑
                console.log('升级到更高版本');
              }}
            >
              升级版本
            </button>
          </div>
        </div>
      </div>
    );
  }

  return null;
};

// 高级特性门控组件
interface AdvancedFeatureGateProps {
  feature: string;
  children: React.ReactNode;
  fallback?: React.ReactNode;
  showUpgradePrompt?: boolean;
  className?: string;
}

export const AdvancedFeatureGate: React.FC<AdvancedFeatureGateProps> = ({
  feature,
  children,
  fallback,
  showUpgradePrompt = false,
  className = '',
}) => {
  const { hasFeature, modeConfig } = useMode();

  if (hasFeature(feature)) {
    return <div className={className}>{children}</div>;
  }

  if (fallback) {
    return <div className={className}>{fallback}</div>;
  }

  if (showUpgradePrompt) {
    return (
      <div className={`p-6 border-2 border-dashed border-gray-300 rounded-xl bg-gradient-to-br from-gray-50 to-gray-100 ${className}`}>
        <div className="text-center">
          <div className="w-16 h-16 mx-auto mb-4 bg-gray-200 rounded-full flex items-center justify-center">
            <svg
              className="w-8 h-8 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8h8z"
              />
            </svg>
          </div>
          <h3 className="text-xl font-bold text-gray-900 mb-2">
            高级功能
          </h3>
          <p className="text-gray-600 mb-6 max-w-md mx-auto">
            此功能仅在更高版本中可用。升级以获得更多强大功能。
          </p>
          <div className="space-y-3">
            <button
              className="w-full px-6 py-3 text-sm font-semibold text-white bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg hover:from-blue-700 hover:to-purple-700 transition-all duration-200 transform hover:scale-105"
              onClick={() => {
                // 这里可以添加升级逻辑
                console.log('升级到更高版本');
              }}
            >
              升级到更高版本
            </button>
          </div>
          <p className="text-xs text-gray-500 mt-4">
            升级后可立即使用所有高级功能
          </p>
        </div>
      </div>
    );
  }

  return null;
};

// 模式特定组件
interface ModeSpecificProps {
  modes: string[];
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

export const ModeSpecific: React.FC<ModeSpecificProps> = ({
  modes,
  children,
  fallback,
}) => {
  const { currentMode } = useMode();

  if (modes.includes(currentMode)) {
    return <>{children}</>;
  }

  return fallback ? <>{fallback}</> : null;
};

// 条件渲染工具
export const ConditionalRender: React.FC<{
  condition: boolean;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}> = ({ condition, children, fallback }) => {
  if (condition) {
    return <>{children}</>;
  }
  return fallback ? <>{fallback}</> : null;
};

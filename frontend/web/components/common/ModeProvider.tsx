'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { Mode, MODES, CURRENT_MODE } from '@/config/modes';

interface ModeContextType {
  currentMode: Mode;
  modeConfig: typeof MODES[Mode];
  hasFeature: (feature: string) => boolean;
  hasApiAccess: (endpoint: string) => boolean;
  switchMode: (mode: Mode) => void;
}

const ModeContext = createContext<ModeContextType | undefined>(undefined);

export const useMode = () => {
  const context = useContext(ModeContext);
  if (!context) {
    throw new Error('useMode must be used within a ModeProvider');
  }
  return context;
};

interface ModeProviderProps {
  children: React.ReactNode;
  initialMode?: Mode;
}

export const ModeProvider: React.FC<ModeProviderProps> = ({
  children,
  initialMode,
}) => {
  // 使用环境变量中的模式或默认为basic
  const defaultMode = (process.env.NEXT_PUBLIC_MODE as Mode) || 'basic';
  const [currentMode, setCurrentMode] = useState<Mode>(initialMode || defaultMode);

  const modeConfig = MODES[currentMode];

  // 切换模式
  const switchMode = (mode: Mode) => {
    if (mode in MODES) {
      setCurrentMode(mode);
      // 保存到localStorage
      if (typeof window !== 'undefined') {
        localStorage.setItem('app_mode', mode);
      }
    }
  };

  // 从localStorage恢复模式设置
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const savedMode = localStorage.getItem('app_mode') as Mode;
      if (savedMode && savedMode in MODES) {
        setCurrentMode(savedMode);
      }
    }
  }, []);

  // 特性检查函数
  const checkFeature = (feature: string): boolean => {
    return modeConfig.features.includes(feature);
  };

  // API权限检查函数
  const checkApiAccess = (endpoint: string): boolean => {
    return modeConfig.apiEndpoints.some((pattern) => {
      if (pattern.endsWith('/*')) {
        return endpoint.startsWith(pattern.slice(0, -2));
      }
      return endpoint === pattern;
    });
  };

  const value: ModeContextType = {
    currentMode,
    modeConfig,
    hasFeature: checkFeature,
    hasApiAccess: checkApiAccess,
    switchMode,
  };

  return (
    <ModeContext.Provider value={value}>
      {children}
    </ModeContext.Provider>
  );
};

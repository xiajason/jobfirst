'use client';

import { useMode } from './ModeProvider';

export const ModeIndicator = () => {
  const { currentMode, modeConfig } = useMode();

  return (
    <div 
      style={{
        position: 'fixed',
        top: '10px',
        right: '10px',
        padding: '5px 10px',
        borderRadius: '4px',
        fontSize: '12px',
        fontWeight: 'bold',
        zIndex: 1000,
        backgroundColor: currentMode === 'basic' ? '#e5e7eb' : 
                         currentMode === 'plus' ? '#93c5fd' : '#c4b5fd',
        color: currentMode === 'basic' ? '#374151' : 
               currentMode === 'plus' ? '#1e40af' : '#5b21b6'
      }}
    >
      当前版本: {modeConfig.name}
    </div>
  );
};
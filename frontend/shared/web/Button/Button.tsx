import React from 'react';
import './Button.module.css';

export interface ButtonProps {
  text: string;
  type?: 'primary' | 'secondary' | 'success' | 'warning' | 'danger';
  size?: 'small' | 'medium' | 'large';
  disabled?: boolean;
  loading?: boolean;
  block?: boolean;
  onClick?: () => void;
}

export const Button: React.FC<ButtonProps> = ({
  text,
  type = "primary",
  size = "medium",
  disabled = false,
  loading = false,
  block = false,
  onClick,
}) => {
  const handleClick = () => {
    if (!disabled && !loading && onClick) {
      onClick();
    }
  };

  return (
    <button
      className={`btn btn-${type} btn-${size} ${block ? 'btn-block' : ''} ${disabled ? 'btn-disabled' : ''}`}
      disabled={disabled || loading}
      onClick={handleClick}
    >
      {loading && <div className="loading-spinner" />}
      <span>{text}</span>
    </button>
  );
};

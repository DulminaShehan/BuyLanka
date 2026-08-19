import React from 'react'

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  helperText?: string
  icon?: React.ReactNode
}

export const Input: React.FC<InputProps> = ({
  label,
  error,
  helperText,
  icon,
  className = '',
  id,
  ...props
}) => {
  const inputId = id || (label ? label.toLowerCase().replace(/\s+/g, '-') : undefined)

  return (
    <div className="form-group">
      {label && (
        <label htmlFor={inputId} className="form-label">
          {label}
        </label>
      )}
      <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
        {icon && (
          <span style={{ position: 'absolute', left: '0.875rem', color: 'var(--text-muted)', display: 'flex', alignItems: 'center', pointerEvents: 'none' }}>
            {icon}
          </span>
        )}
        <input
          id={inputId}
          className={`form-input ${error ? 'border-danger' : ''} ${className}`}
          style={icon ? { paddingLeft: '2.5rem' } : undefined}
          {...props}
        />
      </div>
      {error && <p className="form-helper" style={{ color: 'var(--danger-text)' }}>{error}</p>}
      {!error && helperText && <p className="form-helper">{helperText}</p>}
    </div>
  )
}

import React from 'react'

interface SpinnerProps {
  size?: 'sm' | 'md' | 'lg'
  color?: string
  className?: string
  fullPage?: boolean
}

export const Spinner: React.FC<SpinnerProps> = ({
  size = 'md',
  color = 'var(--primary)',
  className = '',
  fullPage = false,
}) => {
  const dimension = size === 'sm' ? 18 : size === 'lg' ? 44 : 28

  const spinnerElement = (
    <div
      className={className}
      style={{
        width: dimension,
        height: dimension,
        border: `3px solid rgba(0,0,0,0.08)`,
        borderTopColor: color,
        borderRadius: '50%',
        animation: 'spin 0.7s cubic-bezier(0.4, 0, 0.2, 1) infinite',
        display: 'inline-block',
      }}
    />
  )

  if (fullPage) {
    return (
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '60vh',
          gap: '1rem',
        }}
      >
        {spinnerElement}
        <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem', fontWeight: 500 }}>
          Loading BuyLanka Admin...
        </p>
      </div>
    )
  }

  return spinnerElement
}

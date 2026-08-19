import React from 'react'

interface StatCardProps {
  title: string
  value: string | number
  icon: React.ReactNode
  trend?: {
    value: string
    isPositive: boolean
    label?: string
  }
  colorScheme?: 'primary' | 'accent' | 'info' | 'success' | 'danger'
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  icon,
  trend,
  colorScheme = 'primary',
}) => {
  const getIconBackground = () => {
    switch (colorScheme) {
      case 'accent':
        return { bg: 'var(--accent-light)', color: 'var(--accent)' }
      case 'info':
        return { bg: 'var(--info-bg)', color: 'var(--info)' }
      case 'success':
        return { bg: 'var(--success-bg)', color: 'var(--success)' }
      case 'danger':
        return { bg: 'var(--danger-bg)', color: 'var(--danger)' }
      case 'primary':
      default:
        return { bg: 'var(--primary-light)', color: 'var(--primary)' }
    }
  }

  const { bg, color } = getIconBackground()

  return (
    <div className="card card-hover" style={{ position: 'relative', overflow: 'hidden' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.8125rem', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.05em' }}>
            {title}
          </p>
          <h2 style={{ fontSize: '1.75rem', fontWeight: 800, color: 'var(--text-main)', marginTop: '0.375rem', letterSpacing: '-0.02em' }}>
            {value}
          </h2>
        </div>
        <div
          style={{
            width: 48,
            height: 48,
            borderRadius: 'var(--radius-md)',
            backgroundColor: bg,
            color: color,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          {icon}
        </div>
      </div>

      {trend && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '1rem', fontSize: '0.8125rem' }}>
          <span
            style={{
              fontWeight: 700,
              color: trend.isPositive ? 'var(--success)' : 'var(--danger)',
              display: 'flex',
              alignItems: 'center',
              gap: '0.2rem',
            }}
          >
            {trend.isPositive ? '↑' : '↓'} {trend.value}
          </span>
          <span style={{ color: 'var(--text-subtle)' }}>{trend.label || 'vs last month'}</span>
        </div>
      )}
    </div>
  )
}

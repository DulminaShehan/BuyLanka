import React from 'react'
import { getStatusBadgeVariant } from '../../utils/formatters'

interface BadgeProps {
  children: React.ReactNode
  variant?: 'success' | 'warning' | 'danger' | 'info' | 'neutral'
  status?: string
  dot?: boolean
  className?: string
}

export const Badge: React.FC<BadgeProps> = ({
  children,
  variant,
  status,
  dot = true,
  className = '',
}) => {
  const resolvedVariant = variant || (status ? getStatusBadgeVariant(status) : 'neutral')

  return (
    <span className={`badge badge-${resolvedVariant} ${className}`}>
      {dot && <span className="badge-dot" />}
      {children}
    </span>
  )
}

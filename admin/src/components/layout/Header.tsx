import React from 'react'
import { Bell, Database, CheckCircle, AlertCircle, Menu, User } from 'lucide-react'
import { isSupabaseConfigured } from '../../lib/supabaseClient'
import { useAuth } from '../../context/AuthContext'

interface HeaderProps {
  onToggleSidebar?: () => void
}

export const Header: React.FC<HeaderProps> = ({ onToggleSidebar }) => {
  const { user } = useAuth()

  return (
    <header
      style={{
        height: 64,
        backgroundColor: 'var(--bg-surface)',
        borderBottom: '1px solid var(--border-color)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 2rem',
        position: 'sticky',
        top: 0,
        zIndex: 30,
        boxShadow: 'var(--shadow-sm)',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
        <button
          onClick={onToggleSidebar}
          className="btn-icon"
          style={{
            display: 'none',
            background: 'none',
            border: 'none',
            cursor: 'pointer',
            padding: '6px',
            color: 'var(--text-main)',
          }}
          id="mobile-sidebar-toggle"
          aria-label="Toggle navigation menu"
        >
          <Menu size={22} />
        </button>

        {/* Database Connection Status Badge */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.4rem',
            padding: '0.25rem 0.625rem',
            borderRadius: 'var(--radius-full)',
            backgroundColor: isSupabaseConfigured ? 'var(--success-bg)' : 'var(--warning-bg)',
            border: `1px solid ${isSupabaseConfigured ? 'var(--success-border)' : 'var(--warning-border)'}`,
            fontSize: '0.75rem',
            fontWeight: 600,
            color: isSupabaseConfigured ? 'var(--success-text)' : 'var(--warning-text)',
          }}
        >
          <Database size={13} />
          <span className="header-badge-label">
            {isSupabaseConfigured ? 'Connected' : 'Not Configured'}
          </span>
          {isSupabaseConfigured ? <CheckCircle size={12} /> : <AlertCircle size={12} />}
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
        {/* Notification Bell */}
        <button
          className="btn-icon"
          style={{
            background: 'none',
            border: 'none',
            position: 'relative',
            cursor: 'pointer',
            color: 'var(--text-muted)',
            padding: '0.4rem',
            borderRadius: '50%',
          }}
          title="Notifications"
        >
          <Bell size={18} />
        </button>

        <div style={{ width: 1, height: 20, backgroundColor: 'var(--border-color)' }} />

        {/* Admin User Chip */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.625rem' }}>
          {user?.avatar_url ? (
            <img
              src={user.avatar_url}
              alt={user.full_name}
              style={{ width: 34, height: 34, borderRadius: '50%', objectFit: 'cover', border: '2px solid var(--primary-border)' }}
            />
          ) : (
            <div
              style={{
                width: 34,
                height: 34,
                borderRadius: '50%',
                backgroundColor: 'var(--primary-light)',
                color: 'var(--primary)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                border: '2px solid var(--primary-border)',
                flexShrink: 0,
              }}
            >
              <User size={16} />
            </div>
          )}
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <p style={{ fontSize: '0.8125rem', fontWeight: 700, color: 'var(--text-main)', lineHeight: 1.2, maxWidth: 120, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {user?.full_name || user?.email || 'Admin'}
            </p>
            <p style={{ fontSize: '0.6875rem', color: 'var(--text-muted)' }}>
              Super Admin
            </p>
          </div>
        </div>
      </div>
    </header>
  )
}

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
      <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
        <button
          onClick={onToggleSidebar}
          className="btn-icon"
          style={{ display: 'none', background: 'none', border: 'none', cursor: 'pointer' }}
          id="mobile-sidebar-toggle"
        >
          <Menu size={20} />
        </button>

        {/* Database Connection Status Badge */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.5rem',
            padding: '0.3rem 0.75rem',
            borderRadius: 'var(--radius-full)',
            backgroundColor: isSupabaseConfigured ? 'var(--success-bg)' : 'var(--warning-bg)',
            border: `1px solid ${isSupabaseConfigured ? 'var(--success-border)' : 'var(--warning-border)'}`,
            fontSize: '0.75rem',
            fontWeight: 600,
            color: isSupabaseConfigured ? 'var(--success-text)' : 'var(--warning-text)',
          }}
        >
          <Database size={14} />
          <span>{isSupabaseConfigured ? 'Supabase Connected' : 'Supabase Not Configured'}</span>
          {isSupabaseConfigured ? <CheckCircle size={12} /> : <AlertCircle size={12} />}
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '1.25rem' }}>
        {/* Notification Bell */}
        <button
          className="btn-icon"
          style={{
            background: 'none',
            border: 'none',
            position: 'relative',
            cursor: 'pointer',
            color: 'var(--text-muted)',
            padding: '0.5rem',
            borderRadius: '50%',
          }}
          title="Notifications"
        >
          <Bell size={20} />
        </button>

        <div style={{ width: 1, height: 24, backgroundColor: 'var(--border-color)' }} />

        {/* Admin User Chip */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          {user?.avatar_url ? (
            <img
              src={user.avatar_url}
              alt={user.full_name}
              style={{ width: 36, height: 36, borderRadius: '50%', objectFit: 'cover', border: '2px solid var(--primary-border)' }}
            />
          ) : (
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: '50%',
                backgroundColor: 'var(--primary-light)',
                color: 'var(--primary)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                border: '2px solid var(--primary-border)',
              }}
            >
              <User size={18} />
            </div>
          )}
          <div>
            <p style={{ fontSize: '0.875rem', fontWeight: 700, color: 'var(--text-main)', lineHeight: 1.2 }}>
              {user?.full_name || user?.email || 'Administrator'}
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

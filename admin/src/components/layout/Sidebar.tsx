import React from 'react'
import { NavLink } from 'react-router-dom'
import {
  LayoutDashboard,
  ShoppingBag,
  Layers,
  Package,
  Store,
  Users,
  Bike,
  Navigation,
  UserCheck,
  BarChart3,
  LogOut,
  ShieldCheck,
  Sparkles,
} from 'lucide-react'
import { useAuth } from '../../context/AuthContext'

interface SidebarProps {
  isOpen: boolean
  onClose?: () => void
}

export const Sidebar: React.FC<SidebarProps> = ({ isOpen: _isOpen }) => {
  const { user, signOut } = useAuth()

  const navItems = [
    { label: 'Overview', path: '/', icon: <LayoutDashboard size={20} /> },
    { label: 'Orders', path: '/orders', icon: <ShoppingBag size={20} /> },
    { label: 'Categories', path: '/categories', icon: <Layers size={20} /> },
    { label: 'Products', path: '/products', icon: <Package size={20} /> },
    { label: 'Shops', path: '/shops', icon: <Store size={20} /> },
    { label: 'Sellers', path: '/sellers', icon: <Users size={20} /> },
    { label: 'Delivery Riders', path: '/riders', icon: <Bike size={20} /> },
    { label: 'Deliveries', path: '/deliveries', icon: <Navigation size={20} /> },
    { label: 'Customers', path: '/customers', icon: <UserCheck size={20} /> },
    { label: 'Reports & Analytics', path: '/reports', icon: <BarChart3 size={20} /> },
  ]

  return (
    <aside
      style={{
        width: 260,
        backgroundColor: 'var(--sidebar-bg)',
        color: 'var(--sidebar-text)',
        display: 'flex',
        flexDirection: 'column',
        borderRight: '1px solid var(--sidebar-border)',
        height: '100vh',
        position: 'sticky',
        top: 0,
        zIndex: 40,
        transition: 'transform var(--transition-normal)',
      }}
    >
      {/* Brand Header */}
      <div
        style={{
          padding: '1.5rem 1.25rem',
          display: 'flex',
          alignItems: 'center',
          gap: '0.75rem',
          borderBottom: '1px solid var(--sidebar-border)',
        }}
      >
        <div
          style={{
            width: 40,
            height: 40,
            borderRadius: 'var(--radius-md)',
            background: 'linear-gradient(135deg, #059669 0%, #10b981 100%)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'white',
            boxShadow: '0 4px 12px rgba(5, 150, 105, 0.4)',
          }}
        >
          <Sparkles size={22} />
        </div>
        <div>
          <h2
            style={{
              fontSize: '1.25rem',
              fontWeight: 800,
              letterSpacing: '-0.02em',
              color: '#ffffff',
              display: 'flex',
              alignItems: 'center',
              gap: '0.35rem',
            }}
          >
            BuyLanka
            <span
              style={{
                fontSize: '0.625rem',
                backgroundColor: 'rgba(5, 150, 105, 0.3)',
                color: '#34d399',
                padding: '0.15rem 0.4rem',
                borderRadius: 'var(--radius-sm)',
                textTransform: 'uppercase',
                fontWeight: 700,
              }}
            >
              ADMIN
            </span>
          </h2>
          <p style={{ fontSize: '0.75rem', color: 'var(--sidebar-text-muted)' }}>
            Sri Lanka Marketplace
          </p>
        </div>
      </div>

      {/* Navigation List */}
      <nav
        style={{
          flex: 1,
          padding: '1rem 0.75rem',
          overflowY: 'auto',
          display: 'flex',
          flexDirection: 'column',
          gap: '0.25rem',
        }}
      >
        <p
          style={{
            fontSize: '0.6875rem',
            textTransform: 'uppercase',
            letterSpacing: '0.08em',
            color: 'var(--sidebar-text-muted)',
            padding: '0.5rem 0.75rem',
            fontWeight: 700,
          }}
        >
          Platform Management
        </p>

        {navItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            end={item.path === '/'}
            style={({ isActive }) => ({
              display: 'flex',
              alignItems: 'center',
              gap: '0.75rem',
              padding: '0.625rem 0.875rem',
              borderRadius: 'var(--radius-md)',
              fontSize: '0.875rem',
              fontWeight: isActive ? 700 : 500,
              color: isActive ? '#ffffff' : 'var(--sidebar-text-muted)',
              backgroundColor: isActive ? 'var(--sidebar-surface)' : 'transparent',
              borderLeft: isActive ? '3px solid var(--primary)' : '3px solid transparent',
              transition: 'all var(--transition-fast)',
            })}
          >
            {item.icon}
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      {/* Footer / User Profile */}
      <div
        style={{
          padding: '1rem',
          borderTop: '1px solid var(--sidebar-border)',
          backgroundColor: 'rgba(11, 19, 43, 0.5)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.75rem' }}>
          <div
            style={{
              width: 36,
              height: 36,
              borderRadius: '50%',
              backgroundColor: 'var(--sidebar-surface)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#34d399',
            }}
          >
            <ShieldCheck size={20} />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <p
              style={{
                fontSize: '0.8125rem',
                fontWeight: 700,
                color: '#ffffff',
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
              }}
            >
              {user?.full_name || 'Administrator'}
            </p>
            <p
              style={{
                fontSize: '0.6875rem',
                color: 'var(--sidebar-text-muted)',
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
              }}
            >
              {user?.email || 'admin@buylanka.lk'}
            </p>
          </div>
        </div>

        <button
          onClick={() => signOut()}
          className="btn btn-secondary btn-sm"
          style={{
            width: '100%',
            backgroundColor: 'transparent',
            borderColor: 'var(--sidebar-border)',
            color: 'var(--sidebar-text-muted)',
            justifyContent: 'center',
          }}
        >
          <LogOut size={16} /> Sign Out
        </button>
      </div>
    </aside>
  )
}

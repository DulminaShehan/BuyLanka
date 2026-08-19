import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Sparkles, Lock, Mail, User, ArrowRight, UserPlus } from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import { useToast } from '../../context/ToastContext'
import { Input } from '../../components/ui/Input'
import { Button } from '../../components/ui/Button'

export const LoginPage: React.FC = () => {
  const [mode, setMode] = useState<'signin' | 'signup'>('signin')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [fullName, setFullName] = useState('')
  const [loading, setLoading] = useState(false)
  const { signIn, signUp } = useAuth()
  const { success, error: toastError } = useToast()
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!email || !password) {
      toastError('Please fill in all required fields.')
      return
    }

    setLoading(true)

    if (mode === 'signin') {
      const result = await signIn(email, password)
      setLoading(false)

      if (result.success) {
        success('Welcome back to BuyLanka Admin Portal!')
        navigate('/')
      } else {
        toastError(result.error || 'Authentication failed.')
      }
    } else {
      if (!fullName) {
        setLoading(false)
        toastError('Please enter your full name.')
        return
      }

      const result = await signUp(email, password, fullName)
      setLoading(false)

      if (result.success) {
        success('Admin account created successfully!')
        navigate('/')
      } else {
        toastError(result.error || 'Failed to create admin account.')
      }
    }
  }

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#0b132b',
        backgroundImage: 'radial-gradient(circle at 10% 20%, rgba(5, 150, 105, 0.15) 0%, transparent 40%), radial-gradient(circle at 90% 80%, rgba(217, 119, 6, 0.1) 0%, transparent 40%)',
        padding: '1.5rem',
      }}
    >
      <div
        className="card glass-panel"
        style={{
          width: '100%',
          maxWidth: 440,
          padding: '2.5rem 2rem',
          borderRadius: 'var(--radius-xl)',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.4)',
          border: '1px solid rgba(255, 255, 255, 0.1)',
          background: 'rgba(255, 255, 255, 0.98)',
        }}
      >
        {/* Header */}
        <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
          <div
            style={{
              width: 52,
              height: 52,
              borderRadius: 'var(--radius-lg)',
              background: 'linear-gradient(135deg, #059669 0%, #10b981 100%)',
              display: 'inline-flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              marginBottom: '1rem',
              boxShadow: '0 8px 16px rgba(5, 150, 105, 0.3)',
            }}
          >
            <Sparkles size={28} />
          </div>
          <h1 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-main)', letterSpacing: '-0.02em' }}>
            BuyLanka Admin
          </h1>
          <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginTop: '0.25rem' }}>
            {mode === 'signin' ? 'Sign in to access the administrator portal' : 'Register a new administrator account'}
          </p>
        </div>

        {/* Tab Selector */}
        <div
          style={{
            display: 'flex',
            backgroundColor: 'var(--bg-main)',
            borderRadius: 'var(--radius-md)',
            padding: '4px',
            marginBottom: '1.5rem',
            border: '1px solid var(--border-color)',
          }}
        >
          <button
            type="button"
            onClick={() => setMode('signin')}
            style={{
              flex: 1,
              padding: '8px 12px',
              fontSize: '0.875rem',
              fontWeight: 600,
              borderRadius: 'var(--radius-sm)',
              border: 'none',
              cursor: 'pointer',
              transition: 'all var(--transition-fast)',
              backgroundColor: mode === 'signin' ? '#ffffff' : 'transparent',
              color: mode === 'signin' ? 'var(--primary)' : 'var(--text-muted)',
              boxShadow: mode === 'signin' ? '0 2px 4px rgba(0,0,0,0.06)' : 'none',
            }}
          >
            Sign In
          </button>
          <button
            type="button"
            onClick={() => setMode('signup')}
            style={{
              flex: 1,
              padding: '8px 12px',
              fontSize: '0.875rem',
              fontWeight: 600,
              borderRadius: 'var(--radius-sm)',
              border: 'none',
              cursor: 'pointer',
              transition: 'all var(--transition-fast)',
              backgroundColor: mode === 'signup' ? '#ffffff' : 'transparent',
              color: mode === 'signup' ? 'var(--primary)' : 'var(--text-muted)',
              boxShadow: mode === 'signup' ? '0 2px 4px rgba(0,0,0,0.06)' : 'none',
            }}
          >
            Register Admin
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit}>
          {mode === 'signup' && (
            <Input
              label="Full Name"
              type="text"
              placeholder="e.g. Shehan Perera"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              icon={<User size={18} />}
              required
            />
          )}

          <Input
            label="Admin Email"
            type="email"
            placeholder="admin@buylanka.lk"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            icon={<Mail size={18} />}
            required
          />

          <Input
            label="Password"
            type="password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            icon={<Lock size={18} />}
            required
          />

          <Button
            type="submit"
            variant="primary"
            isLoading={loading}
            style={{ width: '100%', marginTop: '0.5rem', padding: '0.75rem' }}
          >
            {mode === 'signin' ? (
              <>
                Sign In to Dashboard <ArrowRight size={16} />
              </>
            ) : (
              <>
                Create Admin Account <UserPlus size={16} />
              </>
            )}
          </Button>
        </form>
      </div>
    </div>
  )
}

import React, { createContext, useContext, useState, useEffect } from 'react'
import { Profile } from '../types'
import { authService } from '../services/auth.service'
import { supabase, isSupabaseConfigured } from '../lib/supabaseClient'

interface AuthContextType {
  user: Profile | null
  isAuthenticated: boolean
  isAdmin: boolean
  isLoading: boolean
  signIn: (email: string, password: string) => Promise<{ success: boolean; error?: string }>
  signUp: (email: string, password: string, fullName?: string) => Promise<{ success: boolean; error?: string }>
  signOut: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<Profile | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const initAuth = async () => {
      setIsLoading(true)
      const { profile } = await authService.getInitialSession()
      setUser(profile)
      setIsLoading(false)
    }

    initAuth()

    if (isSupabaseConfigured) {
      const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
        if (event === 'SIGNED_OUT' || !session?.user) {
          setUser(null)
        } else if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
          const profile = await authService.getCurrentProfile(session.user.id)
          if (profile?.role === 'admin' && profile.status === 'active') {
            setUser(profile)
          } else {
            setUser(profile)
          }
        }
      })

      return () => {
        subscription.unsubscribe()
      }
    }
  }, [])

  const signIn = async (email: string, password: string) => {
    const { profile, error } = await authService.signIn(email, password)
    if (profile) {
      setUser(profile)
      return { success: true }
    }
    return { success: false, error: error || 'Sign in failed' }
  }

  const signUp = async (email: string, password: string, fullName?: string) => {
    const { profile, error } = await authService.signUp(email, password, fullName)
    if (profile) {
      setUser(profile)
      return { success: true }
    }
    return { success: false, error: error || 'Sign up failed' }
  }

  const signOut = async () => {
    await authService.signOut()
    setUser(null)
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: Boolean(user),
        isAdmin: user?.role === 'admin',
        isLoading,
        signIn,
        signUp,
        signOut,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

import React from 'react'
import { Navigate, Outlet } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { Spinner } from '../components/ui/Spinner'

export const ProtectedRoute: React.FC = () => {
  const { isAuthenticated, isAdmin, isLoading } = useAuth()

  if (isLoading) {
    return <Spinner fullPage />
  }

  if (!isAuthenticated || !isAdmin) {
    return <Navigate to="/login" replace />
  }

  return <Outlet />
}

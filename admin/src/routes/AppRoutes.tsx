import React from 'react'
import { Routes, Route, Navigate } from 'react-router-dom'
import { ProtectedRoute } from './ProtectedRoute'
import { DashboardLayout } from '../components/layout/DashboardLayout'
import { LoginPage } from '../features/auth/LoginPage'
import { OverviewPage } from '../features/overview/OverviewPage'
import { OrdersPage } from '../features/orders/OrdersPage'
import { CategoriesPage } from '../features/categories/CategoriesPage'
import { ProductsPage } from '../features/products/ProductsPage'
import { ShopsPage } from '../features/shops/ShopsPage'
import { SellersPage } from '../features/sellers/SellersPage'
import { RidersPage } from '../features/riders/RidersPage'
import { DeliveriesPage } from '../features/deliveries/DeliveriesPage'
import { CustomersPage } from '../features/customers/CustomersPage'
import { AdminsPage } from '../features/admins/AdminsPage'
import { ReportsPage } from '../features/reports/ReportsPage'

export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      {/* Public Authentication Route */}
      <Route path="/login" element={<LoginPage />} />

      {/* Protected Admin Routes */}
      <Route element={<ProtectedRoute />}>
        <Route element={<DashboardLayout />}>
          <Route path="/" element={<OverviewPage />} />
          <Route path="/orders" element={<OrdersPage />} />
          <Route path="/categories" element={<CategoriesPage />} />
          <Route path="/products" element={<ProductsPage />} />
          <Route path="/shops" element={<ShopsPage />} />
          <Route path="/sellers" element={<SellersPage />} />
          <Route path="/riders" element={<RidersPage />} />
          <Route path="/deliveries" element={<DeliveriesPage />} />
          <Route path="/customers" element={<CustomersPage />} />
          <Route path="/admins" element={<AdminsPage />} />
          <Route path="/reports" element={<ReportsPage />} />
        </Route>
      </Route>

      {/* Fallback Redirect */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

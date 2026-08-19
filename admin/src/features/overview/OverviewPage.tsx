import React, { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import {
  DollarSign,
  ShoppingBag,
  Store,
  Bike,
  Users,
  AlertCircle,
  ArrowRight,
  TrendingUp,
  RefreshCw,
} from 'lucide-react'
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'
import { PageHeader } from '../../components/common/PageHeader'
import { StatCard } from '../../components/common/StatCard'
import { Badge } from '../../components/ui/Badge'
import { Button } from '../../components/ui/Button'
import { Spinner } from '../../components/ui/Spinner'
import { overviewService } from '../../services/overview.service'
import { DashboardMetrics } from '../../types'
import { formatLKR, formatDate } from '../../utils/formatters'

export const OverviewPage: React.FC = () => {
  const [metrics, setMetrics] = useState<DashboardMetrics | null>(null)
  const [loading, setLoading] = useState(true)

  const loadData = async () => {
    setLoading(true)
    try {
      const data = await overviewService.getDashboardMetrics()
      setMetrics(data)
    } catch (err) {
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [])

  if (loading || !metrics) {
    return <Spinner fullPage />
  }

  const totalPending =
    metrics.pendingApprovals.shops +
    metrics.pendingApprovals.products +
    metrics.pendingApprovals.sellers +
    metrics.pendingApprovals.riders

  return (
    <div>
      <PageHeader
        title="Marketplace Overview"
        subtitle="Real-time performance metrics and operations control across Sri Lanka"
        actions={
          <Button variant="secondary" onClick={loadData} icon={<RefreshCw size={16} />}>
            Refresh
          </Button>
        }
      />

      {/* Pending Approvals Action Bar */}
      {totalPending > 0 && (
        <div
          style={{
            backgroundColor: 'var(--accent-light)',
            border: '1px solid var(--accent-border)',
            borderRadius: 'var(--radius-lg)',
            padding: '1rem 1.5rem',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: 'wrap',
            gap: '1rem',
            marginBottom: '2rem',
            boxShadow: 'var(--shadow-sm)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: '50%',
                backgroundColor: 'var(--accent)',
                color: 'white',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <AlertCircle size={20} />
            </div>
            <div>
              <p style={{ fontWeight: 700, color: 'var(--accent)', fontSize: '0.9375rem' }}>
                {totalPending} Items Awaiting Admin Moderation
              </p>
              <p style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                {metrics.pendingApprovals.shops} new shops, {metrics.pendingApprovals.products} products,{' '}
                {metrics.pendingApprovals.sellers} sellers, and {metrics.pendingApprovals.riders} riders
                require your verification.
              </p>
            </div>
          </div>

          <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
            {metrics.pendingApprovals.shops > 0 && (
              <Link to="/shops" className="btn btn-sm btn-secondary" style={{ backgroundColor: 'white' }}>
                Verify Shops ({metrics.pendingApprovals.shops})
              </Link>
            )}
            {metrics.pendingApprovals.products > 0 && (
              <Link to="/products" className="btn btn-sm btn-secondary" style={{ backgroundColor: 'white' }}>
                Moderate Products ({metrics.pendingApprovals.products})
              </Link>
            )}
            {metrics.pendingApprovals.riders > 0 && (
              <Link to="/riders" className="btn btn-sm btn-secondary" style={{ backgroundColor: 'white' }}>
                Review Riders ({metrics.pendingApprovals.riders})
              </Link>
            )}
          </div>
        </div>
      )}

      {/* KPI Metric Cards */}
      <div className="grid-metrics">
        <StatCard
          title="Total Gross Revenue"
          value={formatLKR(metrics.totalRevenue)}
          icon={<DollarSign size={24} />}
          trend={{ value: '18.4%', isPositive: true, label: 'vs last week' }}
          colorScheme="primary"
        />

        <StatCard
          title="Total Orders"
          value={metrics.totalOrders.toLocaleString()}
          icon={<ShoppingBag size={24} />}
          trend={{ value: '12.1%', isPositive: true, label: 'vs last week' }}
          colorScheme="info"
        />

        <StatCard
          title="Registered Sellers"
          value={metrics.totalSellers.toLocaleString()}
          icon={<Store size={24} />}
          colorScheme="accent"
        />

        <StatCard
          title="Active Delivery Riders"
          value={metrics.totalRiders.toLocaleString()}
          icon={<Bike size={24} />}
          colorScheme="success"
        />
      </div>

      {/* Sales Trend Chart & Summary */}
      <div className="grid-two-cols" style={{ marginBottom: '2rem' }}>
        <div className="card">
          <div className="card-header">
            <div>
              <h3 className="card-title">Weekly Revenue Trend (LKR)</h3>
              <p className="card-subtitle">Gross marketplace sales over the past 7 days</p>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', color: 'var(--primary)', fontWeight: 700, fontSize: '0.875rem' }}>
              <TrendingUp size={18} /> +24% Growth
            </div>
          </div>
          <div style={{ width: '100%', height: 280, marginTop: '1rem' }}>
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={metrics.salesTrend}>
                <defs>
                  <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="var(--primary)" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="var(--primary)" stopOpacity={0.0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--border-color)" />
                <XAxis dataKey="date" stroke="var(--text-muted)" fontSize={12} />
                <YAxis
                  stroke="var(--text-muted)"
                  fontSize={12}
                  tickFormatter={(val) => `Rs. ${(val / 1000).toFixed(0)}k`}
                />
                <Tooltip
                  formatter={(value: any) => [formatLKR(Number(value)), 'Revenue']}
                  contentStyle={{
                    backgroundColor: 'var(--bg-surface)',
                    borderColor: 'var(--border-color)',
                    borderRadius: 'var(--radius-md)',
                    boxShadow: 'var(--shadow-md)',
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="revenue"
                  stroke="var(--primary)"
                  strokeWidth={3}
                  fillOpacity={1}
                  fill="url(#colorRevenue)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Quick Platform Health & Highlights */}
        <div className="card" style={{ display: 'flex', flexDirection: 'column' }}>
          <div className="card-header">
            <div>
              <h3 className="card-title">Platform Statistics</h3>
              <p className="card-subtitle">Marketplace customer & merchant distribution</p>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem', flex: 1, justifyContent: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', background: 'var(--bg-app)', borderRadius: 'var(--radius-md)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <Users size={20} color="var(--primary)" />
                <div>
                  <p style={{ fontWeight: 700, fontSize: '0.9375rem' }}>Active Customers</p>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Registered buyer accounts</p>
                </div>
              </div>
              <span style={{ fontSize: '1.25rem', fontWeight: 800 }}>{metrics.totalCustomers.toLocaleString()}</span>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', background: 'var(--bg-app)', borderRadius: 'var(--radius-md)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <Store size={20} color="var(--accent)" />
                <div>
                  <p style={{ fontWeight: 700, fontSize: '0.9375rem' }}>Active Vendors</p>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Selling in 9 Sri Lankan provinces</p>
                </div>
              </div>
              <span style={{ fontSize: '1.25rem', fontWeight: 800 }}>{metrics.totalSellers.toLocaleString()}</span>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '1rem', background: 'var(--bg-app)', borderRadius: 'var(--radius-md)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                <Bike size={20} color="var(--success)" />
                <div>
                  <p style={{ fontWeight: 700, fontSize: '0.9375rem' }}>Active Delivery Fleet</p>
                  <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Bikes, Three-wheelers & Vans</p>
                </div>
              </div>
              <span style={{ fontSize: '1.25rem', fontWeight: 800 }}>{metrics.totalRiders.toLocaleString()}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Orders Table */}
      <div className="card">
        <div className="card-header">
          <div>
            <h3 className="card-title">Recent Customer Orders</h3>
            <p className="card-subtitle">Latest transactions placed on the BuyLanka platform</p>
          </div>
          <Link to="/orders" className="btn btn-secondary btn-sm">
            View All Orders <ArrowRight size={14} />
          </Link>
        </div>

        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Order #</th>
                <th>Customer</th>
                <th>Shop / Vendor</th>
                <th>Total (LKR)</th>
                <th>Payment</th>
                <th>Order Status</th>
                <th>Date Placed</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {metrics.recentOrders.map((order) => (
                <tr key={order.id}>
                  <td>
                    <strong style={{ color: 'var(--primary)', fontFamily: 'monospace', fontSize: '0.875rem' }}>
                      {order.order_number}
                    </strong>
                  </td>
                  <td>
                    <div>
                      <p style={{ fontWeight: 600 }}>{order.customer?.full_name || 'Guest'}</p>
                      <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{order.customer?.phone_number}</p>
                    </div>
                  </td>
                  <td>
                    <span style={{ fontWeight: 600 }}>{order.shop?.name || 'Multi-Vendor'}</span>
                  </td>
                  <td>
                    <strong style={{ fontSize: '0.9375rem' }}>{formatLKR(order.total_amount)}</strong>
                  </td>
                  <td>
                    <Badge variant="neutral">{order.payment_method.toUpperCase()}</Badge>
                  </td>
                  <td>
                    <Badge status={order.order_status}>{order.order_status.replace('_', ' ')}</Badge>
                  </td>
                  <td style={{ color: 'var(--text-muted)', fontSize: '0.8125rem' }}>
                    {formatDate(order.created_at)}
                  </td>
                  <td>
                    <Link to="/orders" className="btn btn-secondary btn-sm">
                      Details
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}

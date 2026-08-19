import React, { useEffect, useState } from 'react'
import { UserCheck, ShieldAlert, CheckCircle, Mail, Phone, ShoppingBag } from 'lucide-react'
import { PageHeader } from '../../components/common/PageHeader'
import { SearchBar } from '../../components/common/SearchBar'
import { Button } from '../../components/ui/Button'
import { Badge } from '../../components/ui/Badge'
import { Spinner } from '../../components/ui/Spinner'
import { EmptyState } from '../../components/common/EmptyState'
import { customersService } from '../../services/customers.service'
import { Profile, UserStatus } from '../../types'
import { useToast } from '../../context/ToastContext'
import { formatLKR, formatDate } from '../../utils/formatters'

export const CustomersPage: React.FC = () => {
  const [customers, setCustomers] = useState<(Profile & { orders_count?: number; total_spent?: number })[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  const { success, error: toastError } = useToast()

  const loadCustomers = async () => {
    setLoading(true)
    try {
      const data = await customersService.getCustomers(search, statusFilter)
      setCustomers(data)
    } catch (err) {
      toastError('Failed to load customer directory')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadCustomers()
  }, [search, statusFilter])

  const handleToggleStatus = async (customer: Profile) => {
    const newStatus: UserStatus = customer.status === 'active' ? 'suspended' : 'active'
    try {
      await customersService.updateCustomerStatus(customer.id, newStatus)
      success(`Customer ${customer.full_name} is now ${newStatus}`)
      loadCustomers()
    } catch (err) {
      toastError('Failed to update customer status')
    }
  }

  return (
    <div>
      <PageHeader
        title="Customer Directory"
        subtitle="View registered marketplace consumers, purchase history summaries, and access status"
      />

      {/* Filter Bar */}
      <div className="card" style={{ marginBottom: '1.5rem', padding: '1rem 1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <SearchBar
              value={search}
              onChange={setSearch}
              placeholder="Search by customer name, email, phone..."
              width="320px"
            />
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              {['all', 'active', 'suspended'].map((status) => (
                <button
                  key={status}
                  className={`btn btn-sm ${statusFilter === status ? 'btn-primary' : 'btn-secondary'}`}
                  onClick={() => setStatusFilter(status)}
                  style={{ textTransform: 'capitalize' }}
                >
                  {status}
                </button>
              ))}
            </div>
          </div>
          <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
            Showing <strong>{customers.length}</strong> customers
          </div>
        </div>
      </div>

      {loading ? (
        <Spinner fullPage />
      ) : customers.length === 0 ? (
        <EmptyState
          icon={<UserCheck size={32} />}
          title="No Customers Found"
          description="No buyers match the specified search or filter criteria."
        />
      ) : (
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Customer</th>
                <th>Contact Details</th>
                <th>Orders Placed</th>
                <th>Lifetime Spent</th>
                <th>Account Status</th>
                <th>Joined Date</th>
                <th style={{ textAlign: 'right' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {customers.map((cust) => (
                <tr key={cust.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      <img
                        src={
                          cust.avatar_url ||
                          `https://ui-avatars.com/api/?name=${encodeURIComponent(cust.full_name)}&background=059669&color=fff`
                        }
                        alt={cust.full_name}
                        style={{ width: 40, height: 40, borderRadius: '50%', objectFit: 'cover' }}
                      />
                      <div>
                        <p style={{ fontWeight: 700, color: 'var(--text-main)' }}>{cust.full_name}</p>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>ID: {cust.id.substring(0, 8)}</p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.8125rem' }}>
                      <p style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                        <Mail size={12} color="var(--text-muted)" /> {cust.email}
                      </p>
                      <p style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', color: 'var(--text-muted)', marginTop: 2 }}>
                        <Phone size={12} /> {cust.phone_number || 'No phone'}
                      </p>
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontWeight: 600 }}>
                      <ShoppingBag size={14} color="var(--primary)" />
                      <span>{cust.orders_count !== undefined ? `${cust.orders_count} orders` : '—'}</span>
                    </div>
                  </td>
                  <td>
                    <strong style={{ fontSize: '0.9375rem' }}>
                      {cust.total_spent !== undefined ? formatLKR(cust.total_spent) : '—'}
                    </strong>
                  </td>
                  <td>
                    <Badge status={cust.status}>{cust.status}</Badge>
                  </td>
                  <td style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                    {formatDate(cust.created_at)}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <Button
                      variant={cust.status === 'active' ? 'danger' : 'success'}
                      size="sm"
                      onClick={() => handleToggleStatus(cust)}
                      icon={cust.status === 'active' ? <ShieldAlert size={14} /> : <CheckCircle size={14} />}
                    >
                      {cust.status === 'active' ? 'Suspend' : 'Activate'}
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

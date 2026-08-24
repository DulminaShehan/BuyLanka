import React, { useEffect, useState } from 'react'
import {
  ShieldCheck,
  Plus,
  Mail,
  Phone,
  Lock,
  User,
  Shield,
  CheckCircle,
  XCircle,
  Copy,
  Check,
  KeyRound,
  AlertCircle,
  Sparkles,
} from 'lucide-react'
import { PageHeader } from '../../components/common/PageHeader'
import { SearchBar } from '../../components/common/SearchBar'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { Select } from '../../components/ui/Select'
import { Badge } from '../../components/ui/Badge'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { EmptyState } from '../../components/common/EmptyState'
import { adminsService } from '../../services/admins.service'
import { Profile, UserStatus } from '../../types'
import { useAuth } from '../../context/AuthContext'
import { useToast } from '../../context/ToastContext'
import { formatDate } from '../../utils/formatters'

export const AdminsPage: React.FC = () => {
  const [admins, setAdmins] = useState<Profile[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  // Create Modal state
  const [isCreateOpen, setIsCreateOpen] = useState(false)
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [phoneNumber, setPhoneNumber] = useState('')
  const [status, setStatus] = useState<UserStatus>('active')
  const [copiedPassword, setCopiedPassword] = useState(false)
  const [submitting, setSubmitting] = useState(false)

  // Status Action Modal state
  const [selectedAdmin, setSelectedAdmin] = useState<Profile | null>(null)
  const [isStatusModalOpen, setIsStatusModalOpen] = useState(false)

  const { user: currentUser } = useAuth()
  const { success, error: toastError } = useToast()

  const loadAdmins = async () => {
    setLoading(true)
    try {
      const data = await adminsService.getAdmins(search, statusFilter)
      setAdmins(data)
    } catch (err) {
      toastError('Failed to load administrator accounts.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadAdmins()
  }, [search, statusFilter])

  const generateSecurePassword = () => {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%&*'
    let gen = ''
    for (let i = 0; i < 12; i++) {
      gen += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    setPassword(gen)
  }

  const handleCopyPassword = () => {
    if (!password) return
    navigator.clipboard.writeText(password)
    setCopiedPassword(true)
    setTimeout(() => setCopiedPassword(false), 2000)
  }

  const handleCreateAdmin = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!fullName.trim() || !email.trim() || !password.trim()) {
      toastError('Please fill in all required administrator fields.')
      return
    }

    if (password.length < 6) {
      toastError('Password must be at least 6 characters long.')
      return
    }

    setSubmitting(true)
    try {
      await adminsService.createAdmin({
        fullName,
        email,
        password,
        phoneNumber,
        status,
      })

      success(`Administrator "${fullName}" created successfully!`)
      setIsCreateOpen(false)
      // Reset form
      setFullName('')
      setEmail('')
      setPassword('')
      setPhoneNumber('')
      setStatus('active')
      loadAdmins()
    } catch (err: any) {
      toastError(err.message || 'Failed to create administrator account.')
    } finally {
      setSubmitting(false)
    }
  }

  const handleToggleStatus = async (admin: Profile, newStatus: UserStatus) => {
    if (admin.id === currentUser?.id) {
      toastError('You cannot alter the status of your own currently active account.')
      return
    }

    setSubmitting(true)
    try {
      await adminsService.updateAdminStatus(admin.id, newStatus)
      success(`Admin status updated to ${newStatus}`)
      setIsStatusModalOpen(false)
      loadAdmins()
    } catch (err: any) {
      toastError(err.message || 'Failed to update administrator status.')
    } finally {
      setSubmitting(false)
    }
  }

  const activeCount = admins.filter((a) => a.status === 'active').length
  const suspendedCount = admins.filter((a) => a.status === 'suspended').length

  return (
    <div>
      <PageHeader
        title="Administrator Management"
        subtitle="Super Admin Control Center: Create and manage platform administrators and security access"
        actions={
          <Button
            variant="primary"
            onClick={() => {
              generateSecurePassword()
              setIsCreateOpen(true)
            }}
            icon={<Plus size={16} />}
          >
            Add New Admin
          </Button>
        }
      />

      {/* Metrics Banner */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: '1rem',
          marginBottom: '1.5rem',
        }}
      >
        <div
          className="card"
          style={{
            padding: '1.25rem 1.5rem',
            display: 'flex',
            alignItems: 'center',
            gap: '1rem',
          }}
        >
          <div
            style={{
              width: 44,
              height: 44,
              borderRadius: 'var(--radius-md)',
              backgroundColor: 'var(--primary-light)',
              color: 'var(--primary)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <ShieldCheck size={24} />
          </div>
          <div>
            <p style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Total Admins
            </p>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--text-main)', margin: 0 }}>
              {admins.length}
            </h3>
          </div>
        </div>

        <div
          className="card"
          style={{
            padding: '1.25rem 1.5rem',
            display: 'flex',
            alignItems: 'center',
            gap: '1rem',
          }}
        >
          <div
            style={{
              width: 44,
              height: 44,
              borderRadius: 'var(--radius-md)',
              backgroundColor: 'var(--success-bg)',
              color: 'var(--success-text)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <CheckCircle size={24} />
          </div>
          <div>
            <p style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Active Access
            </p>
            <h3 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--success-text)', margin: 0 }}>
              {activeCount}
            </h3>
          </div>
        </div>

        <div
          className="card"
          style={{
            padding: '1.25rem 1.5rem',
            display: 'flex',
            alignItems: 'center',
            gap: '1rem',
          }}
        >
          <div
            style={{
              width: 44,
              height: 44,
              borderRadius: 'var(--radius-md)',
              backgroundColor: suspendedCount > 0 ? 'var(--danger-bg)' : 'var(--bg-main)',
              color: suspendedCount > 0 ? 'var(--danger-text)' : 'var(--text-muted)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <XCircle size={24} />
          </div>
          <div>
            <p style={{ fontSize: '0.75rem', fontWeight: 600, color: 'var(--text-muted)', textTransform: 'uppercase' }}>
              Suspended Accounts
            </p>
            <h3
              style={{
                fontSize: '1.5rem',
                fontWeight: 800,
                color: suspendedCount > 0 ? 'var(--danger-text)' : 'var(--text-main)',
                margin: 0,
              }}
            >
              {suspendedCount}
            </h3>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="card" style={{ marginBottom: '1.5rem', padding: '1rem 1.5rem' }}>
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: '1rem',
          }}
        >
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <SearchBar
              value={search}
              onChange={setSearch}
              placeholder="Search by admin name, email, phone..."
              width="320px"
            />
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              {['all', 'active', 'suspended'].map((tab) => (
                <button
                  key={tab}
                  type="button"
                  onClick={() => setStatusFilter(tab)}
                  className={`btn btn-sm ${statusFilter === tab ? 'btn-primary' : 'btn-secondary'}`}
                  style={{ textTransform: 'capitalize' }}
                >
                  {tab}
                </button>
              ))}
            </div>
          </div>

          <p style={{ fontSize: '0.8125rem', color: 'var(--text-muted)', margin: 0 }}>
            Showing <strong>{admins.length}</strong> administrator accounts
          </p>
        </div>
      </div>

      {/* Admins Table */}
      {loading ? (
        <Spinner fullPage />
      ) : admins.length === 0 ? (
        <EmptyState
          icon={<Shield size={48} />}
          title="No Administrators Found"
          description={
            search
              ? 'No administrator accounts match your search filters.'
              : 'There are currently no additional administrator accounts. Click "Add New Admin" to invite team members.'
          }
          action={
            <Button
              variant="primary"
              onClick={() => {
                generateSecurePassword()
                setIsCreateOpen(true)
              }}
            >
              Add First Administrator
            </Button>
          }
        />
      ) : (
        <div className="card table-container">
          <table>
            <thead>
              <tr>
                <th>Administrator</th>
                <th>Role</th>
                <th>Contact Phone</th>
                <th>Status</th>
                <th>Created Date</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {admins.map((admin) => {
                const isCurrent = admin.id === currentUser?.id
                return (
                  <tr key={admin.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        <div
                          style={{
                            width: 38,
                            height: 38,
                            borderRadius: '50%',
                            backgroundColor: isCurrent ? 'var(--primary)' : 'var(--primary-light)',
                            color: isCurrent ? '#ffffff' : 'var(--primary)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            fontWeight: 700,
                            fontSize: '0.875rem',
                            flexShrink: 0,
                          }}
                        >
                          {admin.full_name?.charAt(0).toUpperCase() || 'A'}
                        </div>
                        <div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.4rem' }}>
                            <p style={{ fontWeight: 700, color: 'var(--text-main)', margin: 0 }}>
                              {admin.full_name || 'Admin User'}
                            </p>
                            {isCurrent && (
                              <span
                                style={{
                                  fontSize: '0.625rem',
                                  backgroundColor: 'var(--primary-light)',
                                  color: 'var(--primary)',
                                  padding: '0.1rem 0.35rem',
                                  borderRadius: 'var(--radius-sm)',
                                  fontWeight: 700,
                                }}
                              >
                                YOU
                              </span>
                            )}
                          </div>
                          <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', margin: 0 }}>
                            {admin.email}
                          </p>
                        </div>
                      </div>
                    </td>

                    <td>
                      <Badge variant="info">
                        Administrator
                      </Badge>
                    </td>

                    <td>
                      <span style={{ fontSize: '0.8125rem', color: admin.phone_number ? 'var(--text-main)' : 'var(--text-muted)' }}>
                        {admin.phone_number || '—'}
                      </span>
                    </td>

                    <td>
                      <Badge variant={admin.status === 'active' ? 'success' : 'danger'}>
                        {admin.status === 'active' ? 'Active' : 'Suspended'}
                      </Badge>
                    </td>

                    <td>
                      <span style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                        {formatDate(admin.created_at)}
                      </span>
                    </td>

                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '0.4rem', alignItems: 'center' }}>
                        {admin.status === 'active' ? (
                          <Button
                            variant="secondary"
                            size="sm"
                            disabled={isCurrent}
                            title={isCurrent ? 'You cannot suspend your own session' : 'Suspend this administrator'}
                            onClick={() => {
                              setSelectedAdmin(admin)
                              setIsStatusModalOpen(true)
                            }}
                            style={{
                              color: isCurrent ? 'var(--text-muted)' : 'var(--danger-text)',
                              borderColor: isCurrent ? 'var(--border-color)' : 'var(--danger-border)',
                            }}
                          >
                            Suspend
                          </Button>
                        ) : (
                          <Button
                            variant="secondary"
                            size="sm"
                            onClick={() => handleToggleStatus(admin, 'active')}
                            style={{
                              color: 'var(--success-text)',
                              borderColor: 'var(--success-border)',
                            }}
                          >
                            Activate
                          </Button>
                        )}
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Add Administrator Modal */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Add New Administrator"
        footer={
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
            <Button variant="secondary" onClick={() => setIsCreateOpen(false)} disabled={submitting}>
              Cancel
            </Button>
            <Button
              variant="primary"
              onClick={handleCreateAdmin}
              isLoading={submitting}
              icon={<ShieldCheck size={16} />}
            >
              Create Administrator
            </Button>
          </div>
        }
      >
        <form onSubmit={handleCreateAdmin} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          <div
            style={{
              padding: '0.75rem 1rem',
              backgroundColor: 'var(--primary-light)',
              borderRadius: 'var(--radius-md)',
              border: '1px solid var(--primary-border)',
              display: 'flex',
              alignItems: 'flex-start',
              gap: '0.6rem',
            }}
          >
            <Sparkles size={18} style={{ color: 'var(--primary)', flexShrink: 0, marginTop: '2px' }} />
            <p style={{ fontSize: '0.8125rem', color: 'var(--primary-dark)', margin: 0, lineHeight: 1.4 }}>
              As a <strong>Super Admin</strong>, you can grant administrator access. The new admin will be able to sign in immediately with the provided email and password.
            </p>
          </div>

          <Input
            label="Full Name *"
            placeholder="e.g. Kasun Fernando"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            icon={<User size={18} />}
            required
          />

          <Input
            label="Admin Email Address *"
            type="email"
            placeholder="kasun.admin@buylanka.lk"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            icon={<Mail size={18} />}
            required
          />

          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.35rem' }}>
              <label style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--text-main)' }}>
                Access Password *
              </label>
              <button
                type="button"
                onClick={generateSecurePassword}
                style={{
                  background: 'none',
                  border: 'none',
                  color: 'var(--primary)',
                  fontSize: '0.75rem',
                  fontWeight: 600,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.25rem',
                }}
              >
                <KeyRound size={12} /> Generate Secure
              </button>
            </div>
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              <div style={{ flex: 1 }}>
                <Input
                  type="text"
                  placeholder="Min 6 characters"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  icon={<Lock size={18} />}
                  required
                />
              </div>
              <Button
                type="button"
                variant="secondary"
                onClick={handleCopyPassword}
                title="Copy Password"
                style={{ height: '42px', padding: '0 0.875rem' }}
              >
                {copiedPassword ? <Check size={16} color="var(--success-text)" /> : <Copy size={16} />}
              </Button>
            </div>
          </div>

          <Input
            label="Contact Phone Number (Optional)"
            placeholder="+94 77 123 4567"
            value={phoneNumber}
            onChange={(e) => setPhoneNumber(e.target.value)}
            icon={<Phone size={18} />}
          />

          <Select
            label="Initial Account Status"
            value={status}
            onChange={(e) => setStatus(e.target.value as UserStatus)}
            options={[
              { label: 'Active (Can login immediately)', value: 'active' },
              { label: 'Suspended (Access blocked)', value: 'suspended' },
            ]}
          />
        </form>
      </Modal>

      {/* Suspend Confirmation Modal */}
      <Modal
        isOpen={isStatusModalOpen}
        onClose={() => setIsStatusModalOpen(false)}
        title="Suspend Administrator Account"
        footer={
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
            <Button variant="secondary" onClick={() => setIsStatusModalOpen(false)} disabled={submitting}>
              Cancel
            </Button>
            <Button
              variant="danger"
              onClick={() => selectedAdmin && handleToggleStatus(selectedAdmin, 'suspended')}
              isLoading={submitting}
            >
              Confirm Suspend
            </Button>
          </div>
        }
      >
        <div style={{ display: 'flex', gap: '1rem', alignItems: 'flex-start' }}>
          <div
            style={{
              width: 40,
              height: 40,
              borderRadius: '50%',
              backgroundColor: 'var(--danger-bg)',
              color: 'var(--danger-text)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              flexShrink: 0,
            }}
          >
            <AlertCircle size={22} />
          </div>
          <div>
            <p style={{ fontWeight: 700, color: 'var(--text-main)', margin: '0 0 0.4rem 0' }}>
              Are you sure you want to suspend {selectedAdmin?.full_name || selectedAdmin?.email}?
            </p>
            <p style={{ fontSize: '0.8125rem', color: 'var(--text-muted)', margin: 0, lineHeight: 1.4 }}>
              This administrator will immediately lose access to the BuyLanka Admin Portal and won't be able to moderate orders, shops, sellers, or riders until re-activated.
            </p>
          </div>
        </div>
      </Modal>
    </div>
  )
}

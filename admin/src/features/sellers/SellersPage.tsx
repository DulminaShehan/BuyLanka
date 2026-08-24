import React, { useEffect, useState } from 'react'
import { Plus, Users, CheckCircle, XCircle, ShieldAlert, Building2, Trash2, AlertTriangle } from 'lucide-react'
import { PageHeader } from '../../components/common/PageHeader'
import { SearchBar } from '../../components/common/SearchBar'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { Select } from '../../components/ui/Select'
import { Badge } from '../../components/ui/Badge'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { EmptyState } from '../../components/common/EmptyState'
import { sellersService } from '../../services/sellers.service'
import { SellerWithProfile, SellerVerificationStatus } from '../../types'
import { useToast } from '../../context/ToastContext'
import { formatDate } from '../../utils/formatters'

export const SellersPage: React.FC = () => {
  const [sellers, setSellers] = useState<SellerWithProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  // Modals
  const [isCreateOpen, setIsCreateOpen] = useState(false)
  const [selectedSeller, setSelectedSeller] = useState<SellerWithProfile | null>(null)
  const [isVerificationModalOpen, setIsVerificationModalOpen] = useState(false)
  const [newCommissionRate, setNewCommissionRate] = useState<number>(10)
  const [submitting, setSubmitting] = useState(false)

  // Delete state
  const [sellerToDelete, setSellerToDelete] = useState<SellerWithProfile | null>(null)
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)

  // Create form state
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [phoneNumber, setPhoneNumber] = useState('')
  const [businessName, setBusinessName] = useState('')
  const [brNumber, setBrNumber] = useState('')
  const [nicNumber, setNicNumber] = useState('')
  const [commissionRate, setCommissionRate] = useState(10.0)
  const [bankName, setBankName] = useState('Commercial Bank')
  const [accountNumber, setAccountNumber] = useState('')
  const [bankBranch, setBankBranch] = useState('')

  const { success, error: toastError } = useToast()

  const loadSellers = async () => {
    setLoading(true)
    try {
      const data = await sellersService.getSellers(search, statusFilter)
      setSellers(data)
    } catch (err) {
      toastError('Failed to load sellers')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadSellers()
  }, [search, statusFilter])

  const handleCreateSeller = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!fullName || !email || !businessName || !nicNumber) {
      toastError('Please fill in all required vendor fields')
      return
    }

    setSubmitting(true)
    try {
      await sellersService.createSeller({
        fullName,
        email,
        phoneNumber,
        businessName,
        businessRegistrationNumber: brNumber,
        nicNumber,
        commissionRate: Number(commissionRate),
        bankName,
        bankAccountNumber: accountNumber,
        bankBranch,
      })
      success(`Seller "${businessName}" onboarded successfully`)
      setIsCreateOpen(false)
      loadSellers()
    } catch (err: any) {
      toastError(err.message || 'Failed to create seller')
    } finally {
      setSubmitting(false)
    }
  }

  const openVerifyModal = (seller: SellerWithProfile) => {
    setSelectedSeller(seller)
    setNewCommissionRate(seller.commission_rate)
    setIsVerificationModalOpen(true)
  }

  const handleUpdateStatus = async (status: SellerVerificationStatus) => {
    if (!selectedSeller) return
    setSubmitting(true)
    try {
      await sellersService.updateVerificationStatus(
        selectedSeller.id,
        status,
        Number(newCommissionRate)
      )
      success(`Seller status updated to ${status}`)
      setIsVerificationModalOpen(false)
      loadSellers()
    } catch (err: any) {
      toastError(err.message || 'Failed to update seller status')
    } finally {
      setSubmitting(false)
    }
  }

  const handleDeleteSeller = async () => {
    if (!sellerToDelete) return
    setIsDeleting(true)
    try {
      await sellersService.deleteSeller(sellerToDelete.id)
      success(`Seller "${sellerToDelete.business_name}" has been removed successfully`)
      setIsDeleteModalOpen(false)
      setSellerToDelete(null)
      if (selectedSeller?.id === sellerToDelete.id) {
        setIsVerificationModalOpen(false)
        setSelectedSeller(null)
      }
      loadSellers()
    } catch (err: any) {
      toastError(err.message || 'Failed to remove seller')
    } finally {
      setIsDeleting(false)
    }
  }

  return (
    <div>
      <PageHeader
        title="Seller & Vendor Management"
        subtitle="Review marketplace vendor registrations, KYC credentials, and commission rates"
        actions={
          <Button variant="primary" onClick={() => setIsCreateOpen(true)} icon={<Plus size={16} />}>
            Register Seller
          </Button>
        }
      />

      {/* Filter Bar */}
      <div className="card" style={{ marginBottom: '1.5rem', padding: '1rem 1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <SearchBar
              value={search}
              onChange={setSearch}
              placeholder="Search by vendor, owner, NIC, email..."
              width="320px"
            />
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              {['all', 'verified', 'pending', 'suspended'].map((status) => (
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
            Showing <strong>{sellers.length}</strong> sellers
          </div>
        </div>
      </div>

      {loading ? (
        <Spinner fullPage />
      ) : sellers.length === 0 ? (
        <EmptyState
          icon={<Users size={32} />}
          title="No Sellers Found"
          description="No vendor profiles match your current search or status filter."
        />
      ) : (
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Vendor / Business</th>
                <th>Owner Details</th>
                <th>NIC & Registration</th>
                <th>Commission</th>
                <th>Bank Payout Info</th>
                <th>Status</th>
                <th>Joined</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {sellers.map((seller) => (
                <tr key={seller.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      <div
                        style={{
                          width: 40,
                          height: 40,
                          borderRadius: 'var(--radius-md)',
                          backgroundColor: 'var(--accent-light)',
                          color: 'var(--accent)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                        }}
                      >
                        <Building2 size={20} />
                      </div>
                      <div>
                        <p style={{ fontWeight: 700, color: 'var(--text-main)' }}>{seller.business_name}</p>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                          BR: {seller.business_registration_number || 'Not provided'}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div>
                      <p style={{ fontWeight: 600 }}>{seller.profile.full_name}</p>
                      <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{seller.profile.email}</p>
                      <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{seller.profile.phone_number}</p>
                    </div>
                  </td>
                  <td>
                    <span style={{ fontFamily: 'monospace', fontWeight: 600, fontSize: '0.8125rem' }}>
                      {seller.nic_number || '—'}
                    </span>
                  </td>
                  <td>
                    <Badge variant="info">{seller.commission_rate}%</Badge>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.75rem' }}>
                      <p style={{ fontWeight: 600 }}>{seller.bank_name || 'Not configured'}</p>
                      <p style={{ color: 'var(--text-muted)' }}>{seller.bank_account_number ? `A/C: ${seller.bank_account_number}` : ''}</p>
                    </div>
                  </td>
                  <td>
                    <Badge status={seller.verification_status}>{seller.verification_status}</Badge>
                  </td>
                  <td style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                    {formatDate(seller.created_at)}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '0.5rem', alignItems: 'center' }}>
                      <Button variant="secondary" size="sm" onClick={() => openVerifyModal(seller)}>
                        Manage / Verify
                      </Button>
                      <Button
                        variant="danger"
                        size="sm"
                        icon={<Trash2 size={14} />}
                        title="Remove Seller"
                        onClick={() => {
                          setSellerToDelete(seller)
                          setIsDeleteModalOpen(true)
                        }}
                      >
                        Remove
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Create Seller Modal */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Register New Marketplace Vendor"
        subtitle="Onboard a Sri Lankan merchant to list products on BuyLanka"
        size="lg"
      >
        <form onSubmit={handleCreateSeller}>
          <div className="form-grid-2">
            <Input
              label="Proprietor / Contact Name"
              placeholder="e.g. Nimal Jayawardena"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              required
            />
            <Input
              label="Contact Email"
              type="email"
              placeholder="nimal.spices@gmail.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          <div className="form-grid-2">
            <Input
              label="Contact Phone Number"
              placeholder="+94 77 123 4567"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              required
            />
            <Input
              label="National Identity Card (NIC)"
              placeholder="e.g. 198823401234 or 882341234V"
              value={nicNumber}
              onChange={(e) => setNicNumber(e.target.value)}
              required
            />
          </div>

          <div className="form-grid-2">
            <Input
              label="Business / Trading Name"
              placeholder="Ceylon Spice Haven Exports"
              value={businessName}
              onChange={(e) => setBusinessName(e.target.value)}
              required
            />
            <Input
              label="Business Registration (BR) Number"
              placeholder="PV-89210"
              value={brNumber}
              onChange={(e) => setBrNumber(e.target.value)}
            />
          </div>

          <Input
            label="Platform Commission Rate (%)"
            type="number"
            step="0.5"
            value={commissionRate}
            onChange={(e) => setCommissionRate(Number(e.target.value))}
            helperText="Default rate is 10%. Admin can set custom agreed vendor rates."
          />

          <h4 style={{ fontSize: '0.875rem', fontWeight: 700, marginTop: '1rem', marginBottom: '0.5rem', color: 'var(--text-muted)' }}>
            Bank Payout Details
          </h4>

          <div className="form-grid-3">
            <Select
              label="Bank Name"
              value={bankName}
              onChange={(e) => setBankName(e.target.value)}
              options={[
                { value: 'Commercial Bank of Ceylon', label: 'Commercial Bank' },
                { value: 'Sampath Bank PLC', label: 'Sampath Bank' },
                { value: 'Bank of Ceylon (BOC)', label: 'Bank of Ceylon' },
                { value: "People's Bank", label: "People's Bank" },
                { value: 'Hatton National Bank (HNB)', label: 'HNB' },
                { value: 'Nations Trust Bank', label: 'Nations Trust' },
              ]}
            />
            <Input
              label="Account Number"
              placeholder="8001234567"
              value={accountNumber}
              onChange={(e) => setAccountNumber(e.target.value)}
            />
            <Input
              label="Branch"
              placeholder="Matale"
              value={bankBranch}
              onChange={(e) => setBankBranch(e.target.value)}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '1.5rem' }}>
            <Button type="button" variant="secondary" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" variant="primary" isLoading={submitting}>
              Create & Verify Seller
            </Button>
          </div>
        </form>
      </Modal>

      {/* Verification & Commission Modal */}
      {selectedSeller && (
        <Modal
          isOpen={isVerificationModalOpen}
          onClose={() => setIsVerificationModalOpen(false)}
          title={`Manage Seller: ${selectedSeller.business_name}`}
          subtitle={`Owner: ${selectedSeller.profile.full_name} (${selectedSeller.profile.email})`}
        >
          <div style={{ marginBottom: '1.5rem' }}>
            <Input
              label="Marketplace Commission Rate (%)"
              type="number"
              step="0.5"
              value={newCommissionRate}
              onChange={(e) => setNewCommissionRate(Number(e.target.value))}
              helperText="Percentage deducted per order item sold by this vendor"
            />
          </div>

          <p style={{ fontWeight: 700, fontSize: '0.875rem', marginBottom: '0.75rem' }}>
            Change Verification Status:
          </p>

          <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap', marginBottom: '1.5rem' }}>
            <Button
              variant="success"
              isLoading={submitting}
              onClick={() => handleUpdateStatus('verified')}
              icon={<CheckCircle size={16} />}
            >
              Verify & Approve
            </Button>
            <Button
              variant="danger"
              isLoading={submitting}
              onClick={() => handleUpdateStatus('suspended')}
              icon={<ShieldAlert size={16} />}
            >
              Suspend Seller
            </Button>
            <Button
              variant="secondary"
              isLoading={submitting}
              onClick={() => handleUpdateStatus('rejected')}
              icon={<XCircle size={16} />}
            >
              Reject KYC
            </Button>
          </div>

          <div style={{ borderTop: '1px solid var(--border-color)', paddingTop: '1rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <p style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--danger-text)', margin: 0 }}>
                Super Admin Actions
              </p>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', margin: 0 }}>
                Permanently delete this vendor and their shop listings
              </p>
            </div>
            <Button
              variant="danger"
              size="sm"
              icon={<Trash2 size={14} />}
              onClick={() => {
                setSellerToDelete(selectedSeller)
                setIsDeleteModalOpen(true)
              }}
            >
              Remove Seller
            </Button>
          </div>
        </Modal>
      )}

      {/* Delete Confirmation Modal */}
      {sellerToDelete && (
        <Modal
          isOpen={isDeleteModalOpen}
          onClose={() => {
            if (!isDeleting) {
              setIsDeleteModalOpen(false)
              setSellerToDelete(null)
            }
          }}
          title="Remove Vendor Account"
          size="sm"
        >
          <div style={{ textAlign: 'center', padding: '1rem 0' }}>
            <div
              style={{
                width: 56,
                height: 56,
                borderRadius: '50%',
                backgroundColor: 'rgba(239, 68, 68, 0.1)',
                color: 'var(--danger)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                margin: '0 auto 1rem',
              }}
            >
              <AlertTriangle size={28} />
            </div>

            <h3 style={{ fontSize: '1.125rem', fontWeight: 700, marginBottom: '0.5rem', color: 'var(--text-main)' }}>
              Confirm Vendor Removal
            </h3>

            <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginBottom: '1.25rem', lineHeight: 1.5 }}>
              Are you sure you want to remove <strong>{sellerToDelete.business_name}</strong> (Owner: {sellerToDelete.profile.full_name})?
            </p>

            <div
              style={{
                padding: '0.75rem 1rem',
                backgroundColor: 'var(--bg-hover)',
                borderRadius: 'var(--radius-md)',
                fontSize: '0.8125rem',
                color: 'var(--danger-text)',
                border: '1px solid var(--danger-border)',
                textAlign: 'left',
                marginBottom: '1.5rem',
              }}
            >
              <strong>⚠️ Warning:</strong> This action will permanently remove this seller, their registered shops, and product catalog items from BuyLanka.
            </div>

            <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
              <Button
                variant="secondary"
                disabled={isDeleting}
                onClick={() => {
                  setIsDeleteModalOpen(false)
                  setSellerToDelete(null)
                }}
              >
                Cancel
              </Button>
              <Button
                variant="danger"
                isLoading={isDeleting}
                icon={<Trash2 size={16} />}
                onClick={handleDeleteSeller}
              >
                Yes, Remove Seller
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  )
}

import React, { useEffect, useState } from 'react'
import { Plus, Store, Check, ShieldAlert, Star, MapPin } from 'lucide-react'
import { PageHeader } from '../../components/common/PageHeader'
import { SearchBar } from '../../components/common/SearchBar'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { Select } from '../../components/ui/Select'
import { Badge } from '../../components/ui/Badge'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { EmptyState } from '../../components/common/EmptyState'
import { shopsService } from '../../services/shops.service'
import { sellersService } from '../../services/sellers.service'
import { ShopWithSeller, ShopStatus, SellerWithProfile } from '../../types'
import { useToast } from '../../context/ToastContext'
import { formatDate } from '../../utils/formatters'

export const ShopsPage: React.FC = () => {
  const [shops, setShops] = useState<ShopWithSeller[]>([])
  const [sellers, setSellers] = useState<SellerWithProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  // Create Shop State
  const [isCreateOpen, setIsCreateOpen] = useState(false)
  const [sellerId, setSellerId] = useState('')
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [address, setAddress] = useState('')
  const [city, setCity] = useState('')
  const [district, setDistrict] = useState('Colombo')
  const [contactPhone, setContactPhone] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const { success, error: toastError } = useToast()

  const loadData = async () => {
    setLoading(true)
    try {
      const [shopsData, sellersData] = await Promise.all([
        shopsService.getShops(search, statusFilter),
        sellersService.getSellers(),
      ])
      setShops(shopsData)
      setSellers(sellersData)
      if (sellersData.length > 0 && !sellerId) {
        setSellerId(sellersData[0].id)
      }
    } catch (err) {
      toastError('Failed to load shops')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [search, statusFilter])

  const handleStatusChange = async (id: string, status: ShopStatus, shopName: string) => {
    try {
      await shopsService.updateShopStatus(id, status)
      success(`Shop "${shopName}" is now ${status}`)
      loadData()
    } catch (err) {
      toastError('Failed to update shop status')
    }
  }

  const handleCreateShop = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!name || !sellerId) {
      toastError('Shop name and owner are required')
      return
    }

    setSubmitting(true)
    try {
      await shopsService.createShop({
        sellerId,
        name,
        description,
        address,
        city,
        district,
        contactPhone,
      })
      success(`Shop "${name}" created successfully`)
      setIsCreateOpen(false)
      setName('')
      setDescription('')
      loadData()
    } catch (err: any) {
      toastError(err.message || 'Failed to create shop')
    } finally {
      setSubmitting(false)
    }
  }

  const sriLankanDistricts = [
    'Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale', 'Nuwara Eliya',
    'Galle', 'Matara', 'Hambantota', 'Jaffna', 'Kilinochchi', 'Mannar',
    'Vavuniya', 'Mullaitivu', 'Batticaloa', 'Ampara', 'Trincomalee',
    'Kurunegala', 'Puttalam', 'Anuradhapura', 'Polonnaruwa', 'Badulla',
    'Monaragala', 'Ratnapura', 'Kegalle'
  ]

  return (
    <div>
      <PageHeader
        title="Marketplace Shops"
        subtitle="Manage merchant storefronts, business locations, customer ratings, and visibility"
        actions={
          <Button variant="primary" onClick={() => setIsCreateOpen(true)} icon={<Plus size={16} />}>
            Create Shop
          </Button>
        }
      />

      <div className="card" style={{ marginBottom: '1.5rem', padding: '1rem 1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <SearchBar
              value={search}
              onChange={setSearch}
              placeholder="Search by shop name, city, district..."
              width="320px"
            />
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              {['all', 'approved', 'pending', 'suspended'].map((status) => (
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
            Showing <strong>{shops.length}</strong> storefronts
          </div>
        </div>
      </div>

      {loading ? (
        <Spinner fullPage />
      ) : shops.length === 0 ? (
        <EmptyState
          icon={<Store size={32} />}
          title="No Shops Found"
          description="No storefronts match your current filter."
        />
      ) : (
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Storefront</th>
                <th>Owner / Vendor</th>
                <th>Location</th>
                <th>Contact</th>
                <th>Rating</th>
                <th>Status</th>
                <th>Registered</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {shops.map((shop) => (
                <tr key={shop.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      {shop.logo_url ? (
                        <img
                          src={shop.logo_url}
                          alt={shop.name}
                          style={{ width: 44, height: 44, borderRadius: 'var(--radius-md)', objectFit: 'cover' }}
                        />
                      ) : (
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
                          <Store size={22} />
                        </div>
                      )}
                      <div>
                        <p style={{ fontWeight: 700, color: 'var(--text-main)' }}>{shop.name}</p>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>slug: {shop.slug}</p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div>
                      <p style={{ fontWeight: 600 }}>{shop.seller?.business_name || 'Individual Seller'}</p>
                      <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                        {shop.seller?.profile?.full_name}
                      </p>
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.8125rem' }}>
                      <MapPin size={14} color="var(--primary)" />
                      <span>
                        {shop.city || '—'}, <strong>{shop.district || 'Sri Lanka'}</strong>
                      </span>
                    </div>
                  </td>
                  <td>
                    <span style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                      {shop.contact_phone || '—'}
                    </span>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                      <Star size={14} fill="#f59e0b" color="#f59e0b" />
                      <strong style={{ fontSize: '0.875rem' }}>{shop.rating > 0 ? shop.rating.toFixed(1) : 'New'}</strong>
                      <span style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                        ({shop.total_reviews})
                      </span>
                    </div>
                  </td>
                  <td>
                    <Badge status={shop.status}>{shop.status}</Badge>
                  </td>
                  <td style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                    {formatDate(shop.created_at)}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '0.5rem' }}>
                      {shop.status === 'pending' && (
                        <Button
                          variant="success"
                          size="sm"
                          onClick={() => handleStatusChange(shop.id, 'approved', shop.name)}
                          icon={<Check size={14} />}
                        >
                          Approve
                        </Button>
                      )}
                      {shop.status === 'approved' && (
                        <Button
                          variant="danger"
                          size="sm"
                          onClick={() => handleStatusChange(shop.id, 'suspended', shop.name)}
                          icon={<ShieldAlert size={14} />}
                        >
                          Suspend
                        </Button>
                      )}
                      {shop.status === 'suspended' && (
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => handleStatusChange(shop.id, 'approved', shop.name)}
                        >
                          Reactivate
                        </Button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Create Shop Modal */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Create New Storefront"
        subtitle="Establish a vendor shop profile for marketplace listings"
        size="lg"
      >
        <form onSubmit={handleCreateShop}>
          <Select
            label="Select Verified Vendor / Owner"
            value={sellerId}
            onChange={(e) => setSellerId(e.target.value)}
            options={sellers.map((s) => ({
              value: s.id,
              label: `${s.business_name} (${s.profile.full_name})`,
            }))}
            required
          />

          <Input
            label="Shop Name"
            placeholder="e.g. Ruhunu Handloom Boutique"
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
          />

          <div className="form-group">
            <label className="form-label">Shop Description</label>
            <textarea
              className="form-textarea"
              placeholder="Tell buyers about this shop's specialty and origin..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <Input
              label="Street Address"
              placeholder="No. 15 Galle Road"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
            />
            <Input
              label="City / Town"
              placeholder="Hikkaduwa"
              value={city}
              onChange={(e) => setCity(e.target.value)}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem' }}>
            <Select
              label="District"
              value={district}
              onChange={(e) => setDistrict(e.target.value)}
              options={sriLankanDistricts.map((d) => ({ value: d, label: d }))}
            />
            <Input
              label="Contact Phone"
              placeholder="+94 91 333 4455"
              value={contactPhone}
              onChange={(e) => setContactPhone(e.target.value)}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '1.5rem' }}>
            <Button type="button" variant="secondary" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" variant="primary" isLoading={submitting}>
              Establish Shop
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}

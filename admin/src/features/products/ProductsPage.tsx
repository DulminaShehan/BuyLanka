import React, { useEffect, useState } from 'react'
import { Package, Check, X, Trash2, Eye, Store, Layers } from 'lucide-react'
import { PageHeader } from '../../components/common/PageHeader'
import { SearchBar } from '../../components/common/SearchBar'
import { Button } from '../../components/ui/Button'
import { Badge } from '../../components/ui/Badge'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { EmptyState } from '../../components/common/EmptyState'
import { productsService } from '../../services/products.service'
import { ProductWithShopAndCategory, ProductStatus } from '../../types'
import { useToast } from '../../context/ToastContext'
import { formatLKR, formatDate } from '../../utils/formatters'

export const ProductsPage: React.FC = () => {
  const [products, setProducts] = useState<ProductWithShopAndCategory[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  const [selectedProduct, setSelectedProduct] = useState<ProductWithShopAndCategory | null>(null)
  const [isDetailOpen, setIsDetailOpen] = useState(false)

  const { success, error: toastError } = useToast()

  const loadProducts = async () => {
    setLoading(true)
    try {
      const data = await productsService.getProducts(search, statusFilter)
      setProducts(data)
    } catch (err) {
      toastError('Failed to load products')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadProducts()
  }, [search, statusFilter])

  const handleStatusChange = async (id: string, status: ProductStatus, title: string) => {
    try {
      await productsService.updateProductStatus(id, status)
      success(`Product "${title}" status changed to ${status.replace('_', ' ')}`)
      loadProducts()
    } catch (err) {
      toastError('Failed to update product status')
    }
  }

  const handleDelete = async (id: string, title: string) => {
    if (!window.confirm(`Are you sure you want to delete "${title}"?`)) return
    try {
      await productsService.deleteProduct(id)
      success(`Product deleted`)
      loadProducts()
    } catch (err) {
      toastError('Failed to delete product')
    }
  }

  const openDetail = (prod: ProductWithShopAndCategory) => {
    setSelectedProduct(prod)
    setIsDetailOpen(true)
  }

  return (
    <div>
      <PageHeader
        title="Product Moderation & Catalog"
        subtitle="Review vendor listings, verify product quality & pricing in LKR, and manage marketplace catalog"
      />

      {/* Filter Bar */}
      <div className="card" style={{ marginBottom: '1.5rem', padding: '1rem 1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <SearchBar
              value={search}
              onChange={setSearch}
              placeholder="Search by title, SKU, vendor shop..."
              width="320px"
            />
            <div style={{ display: 'flex', gap: '0.5rem' }}>
              {[
                { label: 'All', value: 'all' },
                { label: 'Published', value: 'published' },
                { label: 'Pending Approval', value: 'pending_approval' },
                { label: 'Rejected', value: 'rejected' },
              ].map((tab) => (
                <button
                  key={tab.value}
                  className={`btn btn-sm ${statusFilter === tab.value ? 'btn-primary' : 'btn-secondary'}`}
                  onClick={() => setStatusFilter(tab.value)}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>
          <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
            Showing <strong>{products.length}</strong> items
          </div>
        </div>
      </div>

      {loading ? (
        <Spinner fullPage />
      ) : products.length === 0 ? (
        <EmptyState
          icon={<Package size={32} />}
          title="No Products Found"
          description="No marketplace listings match the selected filters."
        />
      ) : (
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Product</th>
                <th>Storefront / Vendor</th>
                <th>Category</th>
                <th>Price (LKR)</th>
                <th>Stock</th>
                <th>Status</th>
                <th>Created</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {products.map((prod) => (
                <tr key={prod.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      <img
                        src={
                          prod.images[0] ||
                          'https://images.unsplash.com/photo-1560343090-f0409e92791a?w=100&auto=format&fit=crop&q=80'
                        }
                        alt={prod.title}
                        style={{ width: 44, height: 44, borderRadius: 'var(--radius-md)', objectFit: 'cover' }}
                      />
                      <div style={{ maxWidth: 280 }}>
                        <p style={{ fontWeight: 700, color: 'var(--text-main)', fontSize: '0.875rem', lineHeight: 1.3 }}>
                          {prod.title}
                        </p>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', fontFamily: 'monospace' }}>
                          SKU: {prod.sku || 'N/A'}
                        </p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.8125rem' }}>
                      <Store size={14} color="var(--accent)" />
                      <span style={{ fontWeight: 600 }}>{prod.shop?.name || 'Unknown Vendor'}</span>
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.8125rem' }}>
                      <Layers size={14} color="var(--primary)" />
                      <span>{prod.category?.name || 'Uncategorized'}</span>
                    </div>
                  </td>
                  <td>
                    <div>
                      <strong style={{ fontSize: '0.9375rem' }}>{formatLKR(prod.price)}</strong>
                      {prod.original_price && (
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-subtle)', textDecoration: 'line-through' }}>
                          {formatLKR(prod.original_price)}
                        </p>
                      )}
                    </div>
                  </td>
                  <td>
                    <span
                      style={{
                        fontWeight: 700,
                        fontSize: '0.875rem',
                        color: prod.stock_quantity <= 5 ? 'var(--danger)' : 'var(--text-main)',
                      }}
                    >
                      {prod.stock_quantity} units
                    </span>
                  </td>
                  <td>
                    <Badge status={prod.status}>{prod.status.replace('_', ' ')}</Badge>
                  </td>
                  <td style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                    {formatDate(prod.created_at)}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '0.35rem' }}>
                      <Button variant="secondary" size="sm" onClick={() => openDetail(prod)} icon={<Eye size={14} />}>
                        View
                      </Button>

                      {prod.status === 'pending_approval' && (
                        <>
                          <Button
                            variant="success"
                            size="sm"
                            onClick={() => handleStatusChange(prod.id, 'published', prod.title)}
                            icon={<Check size={14} />}
                          >
                            Approve
                          </Button>
                          <Button
                            variant="danger"
                            size="sm"
                            onClick={() => handleStatusChange(prod.id, 'rejected', prod.title)}
                            icon={<X size={14} />}
                          >
                            Reject
                          </Button>
                        </>
                      )}

                      {prod.status === 'published' && (
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => handleStatusChange(prod.id, 'archived', prod.title)}
                        >
                          Archive
                        </Button>
                      )}

                      <button
                        className="btn-icon"
                        onClick={() => handleDelete(prod.id, prod.title)}
                        title="Delete product"
                        style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: 'var(--danger)' }}
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Product Detail Modal */}
      {selectedProduct && (
        <Modal
          isOpen={isDetailOpen}
          onClose={() => setIsDetailOpen(false)}
          title={selectedProduct.title}
          subtitle={`Store: ${selectedProduct.shop?.name} | Category: ${selectedProduct.category?.name}`}
          size="lg"
        >
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.2fr', gap: '1.5rem' }}>
            <div>
              <img
                src={
                  selectedProduct.images[0] ||
                  'https://images.unsplash.com/photo-1560343090-f0409e92791a?w=400&auto=format&fit=crop&q=80'
                }
                alt={selectedProduct.title}
                style={{ width: '100%', height: 260, objectFit: 'cover', borderRadius: 'var(--radius-lg)' }}
              />
            </div>
            <div>
              <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '0.75rem' }}>
                <Badge status={selectedProduct.status}>{selectedProduct.status.replace('_', ' ')}</Badge>
                {selectedProduct.is_featured && <Badge variant="info">Featured Item</Badge>}
              </div>

              <h2 style={{ fontSize: '1.5rem', fontWeight: 800, color: 'var(--primary)', marginBottom: '0.5rem' }}>
                {formatLKR(selectedProduct.price)}
              </h2>

              <p style={{ color: 'var(--text-muted)', fontSize: '0.875rem', marginBottom: '1rem', lineHeight: 1.6 }}>
                {selectedProduct.description || 'No description provided by vendor.'}
              </p>

              <div style={{ background: 'var(--bg-app)', padding: '0.875rem', borderRadius: 'var(--radius-md)', fontSize: '0.8125rem', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0.5rem' }}>
                <p><strong>SKU:</strong> {selectedProduct.sku || 'None'}</p>
                <p><strong>Available Stock:</strong> {selectedProduct.stock_quantity} pcs</p>
                <p><strong>Shop City:</strong> {selectedProduct.shop?.city || 'Sri Lanka'}</p>
                <p><strong>Commission:</strong> Standard Rate</p>
              </div>

              <div style={{ display: 'flex', gap: '0.75rem', marginTop: '1.25rem' }}>
                {selectedProduct.status === 'pending_approval' && (
                  <Button
                    variant="success"
                    onClick={() => {
                      handleStatusChange(selectedProduct.id, 'published', selectedProduct.title)
                      setIsDetailOpen(false)
                    }}
                    icon={<Check size={16} />}
                  >
                    Approve Listing
                  </Button>
                )}
                <Button variant="secondary" onClick={() => setIsDetailOpen(false)}>
                  Close
                </Button>
              </div>
            </div>
          </div>
        </Modal>
      )}
    </div>
  )
}

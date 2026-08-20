import React, { useEffect, useState } from 'react'
import { ShoppingBag, Eye, Store, MapPin } from 'lucide-react'
import { PageHeader } from '../../components/common/PageHeader'
import { SearchBar } from '../../components/common/SearchBar'
import { Button } from '../../components/ui/Button'
import { Badge } from '../../components/ui/Badge'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { EmptyState } from '../../components/common/EmptyState'
import { ordersService } from '../../services/orders.service'
import { OrderWithDetails, OrderStatus } from '../../types'
import { useToast } from '../../context/ToastContext'
import { formatLKR, formatDate } from '../../utils/formatters'

export const OrdersPage: React.FC = () => {
  const [orders, setOrders] = useState<OrderWithDetails[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  const [selectedOrder, setSelectedOrder] = useState<OrderWithDetails | null>(null)
  const [isDetailOpen, setIsDetailOpen] = useState(false)
  const [updatingStatus, setUpdatingStatus] = useState(false)

  const { success, error: toastError } = useToast()

  const loadOrders = async () => {
    setLoading(true)
    try {
      const data = await ordersService.getOrders(search, statusFilter)
      setOrders(data)
    } catch (err) {
      toastError('Failed to load orders')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadOrders()
  }, [search, statusFilter])

  const handleStatusChange = async (orderId: string, newStatus: OrderStatus) => {
    setUpdatingStatus(true)
    try {
      await ordersService.updateOrderStatus(orderId, newStatus)
      success(`Order status updated to ${newStatus.replace('_', ' ')}`)
      if (selectedOrder && selectedOrder.id === orderId) {
        setSelectedOrder({ ...selectedOrder, order_status: newStatus })
      }
      loadOrders()
    } catch (err) {
      toastError('Failed to update order status')
    } finally {
      setUpdatingStatus(false)
    }
  }

  const openOrderDetail = (order: OrderWithDetails) => {
    setSelectedOrder(order)
    setIsDetailOpen(true)
  }

  const shippingInfo = selectedOrder?.shipping_address as any

  return (
    <div>
      <PageHeader
        title="Order Management"
        subtitle="Track customer orders, monitor payment statuses, and coordinate multi-vendor fulfillment"
      />

      {/* Filter Bar */}
      <div className="card" style={{ marginBottom: '1.5rem', padding: '1rem 1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', flexWrap: 'wrap' }}>
            <SearchBar
              value={search}
              onChange={setSearch}
              placeholder="Search by order #, customer, vendor..."
              width="320px"
            />
            <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
              {[
                { label: 'All', value: 'all' },
                { label: 'Pending', value: 'pending' },
                { label: 'Processing', value: 'processing' },
                { label: 'Shipped', value: 'shipped' },
                { label: 'Delivered', value: 'delivered' },
                { label: 'Cancelled', value: 'cancelled' },
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
            Showing <strong>{orders.length}</strong> orders
          </div>
        </div>
      </div>

      {loading ? (
        <Spinner fullPage />
      ) : orders.length === 0 ? (
        <EmptyState
          icon={<ShoppingBag size={32} />}
          title="No Orders Found"
          description="No customer transactions match the selected filter."
        />
      ) : (
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Order #</th>
                <th>Customer</th>
                <th>Storefront / Vendor</th>
                <th>Total (LKR)</th>
                <th>Payment</th>
                <th>Order Status</th>
                <th>Date Placed</th>
                <th style={{ textAlign: 'right' }}>Action</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((order) => (
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
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontSize: '0.8125rem' }}>
                      <Store size={14} color="var(--accent)" />
                      <span style={{ fontWeight: 600 }}>{order.shop?.name || 'Multi-Vendor'}</span>
                    </div>
                  </td>
                  <td>
                    <strong style={{ fontSize: '0.9375rem' }}>{formatLKR(order.total_amount)}</strong>
                  </td>
                  <td>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.2rem' }}>
                      <Badge variant="neutral">{order.payment_method.toUpperCase()}</Badge>
                      <span style={{ fontSize: '0.6875rem', color: 'var(--text-muted)' }}>
                        Status: <strong style={{ textTransform: 'capitalize' }}>{order.payment_status}</strong>
                      </span>
                    </div>
                  </td>
                  <td>
                    <Badge status={order.order_status}>{order.order_status.replace('_', ' ')}</Badge>
                  </td>
                  <td style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                    {formatDate(order.created_at)}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <Button variant="secondary" size="sm" onClick={() => openOrderDetail(order)} icon={<Eye size={14} />}>
                      View & Manage
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Order Details Modal */}
      {selectedOrder && (
        <Modal
          isOpen={isDetailOpen}
          onClose={() => setIsDetailOpen(false)}
          title={`Order Breakdown: ${selectedOrder.order_number}`}
          subtitle={`Placed on ${formatDate(selectedOrder.created_at)} | Store: ${selectedOrder.shop?.name}`}
          size="lg"
        >
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'var(--bg-app)', padding: '1rem', borderRadius: 'var(--radius-md)', marginBottom: '1.5rem', flexWrap: 'wrap', gap: '1rem' }}>
            <div>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', textTransform: 'uppercase', fontWeight: 700 }}>
                Fulfillment Status
              </p>
              <div style={{ marginTop: '0.25rem' }}>
                <Badge status={selectedOrder.order_status}>{selectedOrder.order_status.replace('_', ' ')}</Badge>
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <span style={{ fontSize: '0.875rem', fontWeight: 600 }}>Update Status:</span>
              <select
                className="form-select"
                style={{ width: 'auto', padding: '0.4rem 0.75rem' }}
                value={selectedOrder.order_status}
                onChange={(e) => handleStatusChange(selectedOrder.id, e.target.value as OrderStatus)}
                disabled={updatingStatus}
              >
                <option value="pending">Pending</option>
                <option value="processing">Processing</option>
                <option value="ready_for_pickup">Ready for Pickup</option>
                <option value="shipped">Shipped (In Transit)</option>
                <option value="delivered">Delivered</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
          </div>

          {/* Line Items */}
          <h4 style={{ fontSize: '0.9375rem', fontWeight: 700, marginBottom: '0.75rem' }}>Order Items</h4>
          <div className="table-container" style={{ marginBottom: '1.5rem' }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Item Description</th>
                  <th>Unit Price</th>
                  <th>Quantity</th>
                  <th style={{ textAlign: 'right' }}>Total</th>
                </tr>
              </thead>
              <tbody>
                {selectedOrder.items?.map((item) => (
                  <tr key={item.id}>
                    <td style={{ fontWeight: 600 }}>{item.product_title}</td>
                    <td>{formatLKR(item.unit_price)}</td>
                    <td>{item.quantity}</td>
                    <td style={{ textAlign: 'right', fontWeight: 700 }}>{formatLKR(item.total_price)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Totals & Delivery Address */}
          <div className="modal-split-view">
            <div style={{ background: 'var(--bg-app)', padding: '1rem', borderRadius: 'var(--radius-md)', fontSize: '0.8125rem' }}>
              <h5 style={{ fontWeight: 700, fontSize: '0.875rem', marginBottom: '0.5rem', display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                <MapPin size={14} color="var(--primary)" /> Shipping Address
              </h5>
              <p><strong>Recipient:</strong> {shippingInfo?.fullName || selectedOrder.customer?.full_name}</p>
              <p><strong>Contact:</strong> {shippingInfo?.phone || selectedOrder.customer?.phone_number}</p>
              <p><strong>Address:</strong> {shippingInfo?.addressLine || shippingInfo?.line || 'Colombo'}</p>
              <p><strong>City & District:</strong> {shippingInfo?.city || 'Colombo'}, {shippingInfo?.district || 'Western Province'}</p>
              {selectedOrder.customer_notes && (
                <p style={{ marginTop: '0.5rem', color: 'var(--accent)', fontStyle: 'italic' }}>
                  Note: "{selectedOrder.customer_notes}"
                </p>
              )}
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', fontSize: '0.875rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Items Subtotal:</span>
                <span>{formatLKR(selectedOrder.total_amount - selectedOrder.delivery_fee + selectedOrder.discount_amount)}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: 'var(--text-muted)' }}>Delivery Fee:</span>
                <span>{formatLKR(selectedOrder.delivery_fee)}</span>
              </div>
              {selectedOrder.discount_amount > 0 && (
                <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--danger)' }}>
                  <span>Discount:</span>
                  <span>-{formatLKR(selectedOrder.discount_amount)}</span>
                </div>
              )}
              <hr style={{ border: 'none', borderTop: '1px solid var(--border-color)', margin: '0.25rem 0' }} />
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '1.125rem', fontWeight: 800 }}>
                <span>Grand Total (LKR):</span>
                <span style={{ color: 'var(--primary)' }}>{formatLKR(selectedOrder.total_amount)}</span>
              </div>
            </div>
          </div>
        </Modal>
      )}
    </div>
  )
}

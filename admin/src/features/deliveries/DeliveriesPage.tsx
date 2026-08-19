import React, { useEffect, useState } from 'react'
import { Navigation, Bike, MapPin, CheckCircle, UserPlus } from 'lucide-react'
import { PageHeader } from '../../components/common/PageHeader'
import { Button } from '../../components/ui/Button'
import { Select } from '../../components/ui/Select'
import { Badge } from '../../components/ui/Badge'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { EmptyState } from '../../components/common/EmptyState'
import { deliveriesService, DeliveryWithDetails } from '../../services/deliveries.service'
import { ridersService } from '../../services/riders.service'
import { RiderWithProfile, DeliveryStatus } from '../../types'
import { useToast } from '../../context/ToastContext'
import { formatDate } from '../../utils/formatters'

export const DeliveriesPage: React.FC = () => {
  const [deliveries, setDeliveries] = useState<DeliveryWithDetails[]>([])
  const [riders, setRiders] = useState<RiderWithProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState('all')

  // Assign modal
  const [isAssignOpen, setIsAssignOpen] = useState(false)
  const [selectedDelivery, setSelectedDelivery] = useState<DeliveryWithDetails | null>(null)
  const [selectedRiderId, setSelectedRiderId] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const { success, error: toastError } = useToast()

  const loadData = async () => {
    setLoading(true)
    try {
      const [delData, riderData] = await Promise.all([
        deliveriesService.getDeliveries(statusFilter),
        ridersService.getRiders('', 'approved'),
      ])
      setDeliveries(delData)
      setRiders(riderData)
      if (riderData.length > 0 && !selectedRiderId) {
        setSelectedRiderId(riderData[0].id)
      }
    } catch (err) {
      toastError('Failed to load deliveries')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadData()
  }, [statusFilter])

  const openAssignModal = (del: DeliveryWithDetails) => {
    setSelectedDelivery(del)
    if (del.rider_id) {
      setSelectedRiderId(del.rider_id)
    }
    setIsAssignOpen(true)
  }

  const handleAssignRider = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedDelivery || !selectedRiderId) return

    setSubmitting(true)
    try {
      const chosenRider = riders.find((r) => r.id === selectedRiderId)
      await deliveriesService.assignRider(selectedDelivery.id, selectedRiderId, chosenRider)
      success(`Rider ${chosenRider?.profile.full_name} assigned to Order ${selectedDelivery.order?.order_number}`)
      setIsAssignOpen(false)
      loadData()
    } catch (err) {
      toastError('Failed to assign rider')
    } finally {
      setSubmitting(false)
    }
  }

  const handleStatusChange = async (deliveryId: string, status: DeliveryStatus) => {
    try {
      await deliveriesService.updateDeliveryStatus(deliveryId, status)
      success(`Delivery status updated to ${status.replace('_', ' ')}`)
      loadData()
    } catch (err) {
      toastError('Failed to update delivery status')
    }
  }

  return (
    <div>
      <PageHeader
        title="Delivery Dispatch & Logistics"
        subtitle="Coordinate pickup routes, assign delivery riders, and monitor Sri Lanka territory orders"
      />

      {/* Filter Tabs */}
      <div className="card" style={{ marginBottom: '1.5rem', padding: '1rem 1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
            {[
              { label: 'All Dispatches', value: 'all' },
              { label: 'Unassigned', value: 'unassigned' },
              { label: 'Assigned', value: 'assigned' },
              { label: 'In Transit', value: 'in_transit' },
              { label: 'Delivered', value: 'delivered' },
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
          <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
            Showing <strong>{deliveries.length}</strong> dispatches
          </div>
        </div>
      </div>

      {loading ? (
        <Spinner fullPage />
      ) : deliveries.length === 0 ? (
        <EmptyState
          icon={<Navigation size={32} />}
          title="No Deliveries Found"
          description="No active dispatches match the selected filter."
        />
      ) : (
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Order #</th>
                <th>Pickup Location</th>
                <th>Dropoff Destination</th>
                <th>Assigned Delivery Rider</th>
                <th>Status</th>
                <th>Dispatched At</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {deliveries.map((del) => (
                <tr key={del.id}>
                  <td>
                    <strong style={{ color: 'var(--primary)', fontFamily: 'monospace' }}>
                      {del.order?.order_number || 'BL-ORD'}
                    </strong>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.35rem', fontSize: '0.8125rem', maxWidth: 220 }}>
                      <MapPin size={14} color="var(--accent)" style={{ flexShrink: 0, marginTop: 2 }} />
                      <span>{del.pickup_address}</span>
                    </div>
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.35rem', fontSize: '0.8125rem', maxWidth: 220 }}>
                      <MapPin size={14} color="var(--primary)" style={{ flexShrink: 0, marginTop: 2 }} />
                      <span>{del.dropoff_address}</span>
                    </div>
                  </td>
                  <td>
                    {del.rider ? (
                      <div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontWeight: 600 }}>
                          <Bike size={14} color="var(--primary)" />
                          <span>{del.rider.profile?.full_name}</span>
                        </div>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                          {del.rider.vehicle_number} ({del.rider.vehicle_type})
                        </p>
                      </div>
                    ) : (
                      <span style={{ color: 'var(--warning)', fontWeight: 600, fontSize: '0.8125rem' }}>
                        ● Unassigned
                      </span>
                    )}
                  </td>
                  <td>
                    <Badge status={del.delivery_status}>{del.delivery_status.replace('_', ' ')}</Badge>
                  </td>
                  <td style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                    {formatDate(del.assigned_at || del.created_at)}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '0.35rem' }}>
                      <Button
                        variant={del.rider ? 'secondary' : 'primary'}
                        size="sm"
                        onClick={() => openAssignModal(del)}
                        icon={<UserPlus size={14} />}
                      >
                        {del.rider ? 'Reassign' : 'Assign Rider'}
                      </Button>

                      {del.delivery_status === 'assigned' && (
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => handleStatusChange(del.id, 'picked_up')}
                        >
                          Mark Picked Up
                        </Button>
                      )}

                      {del.delivery_status === 'picked_up' && (
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => handleStatusChange(del.id, 'in_transit')}
                        >
                          In Transit
                        </Button>
                      )}

                      {del.delivery_status === 'in_transit' && (
                        <Button
                          variant="success"
                          size="sm"
                          onClick={() => handleStatusChange(del.id, 'delivered')}
                          icon={<CheckCircle size={14} />}
                        >
                          Delivered
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

      {/* Assign Rider Modal */}
      {selectedDelivery && (
        <Modal
          isOpen={isAssignOpen}
          onClose={() => setIsAssignOpen(false)}
          title={`Assign Delivery Rider: ${selectedDelivery.order?.order_number}`}
          subtitle="Dispatch order delivery to an available fleet rider"
        >
          <form onSubmit={handleAssignRider}>
            <div style={{ background: 'var(--bg-app)', padding: '0.875rem', borderRadius: 'var(--radius-md)', marginBottom: '1.25rem', fontSize: '0.8125rem' }}>
              <p><strong>Pickup:</strong> {selectedDelivery.pickup_address}</p>
              <p style={{ marginTop: '0.25rem' }}><strong>Dropoff:</strong> {selectedDelivery.dropoff_address}</p>
            </div>

            <Select
              label="Select Available Rider"
              value={selectedRiderId}
              onChange={(e) => setSelectedRiderId(e.target.value)}
              options={riders.map((r) => ({
                value: r.id,
                label: `${r.profile.full_name} (${r.vehicle_number} - ${r.assigned_zone || 'Any Zone'})`,
              }))}
              required
            />

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '1.5rem' }}>
              <Button type="button" variant="secondary" onClick={() => setIsAssignOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" variant="primary" isLoading={submitting}>
                Dispatch Delivery
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  )
}

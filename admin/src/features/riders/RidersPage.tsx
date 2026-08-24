import React, { useEffect, useState } from 'react'
import { Plus, Bike, Check, ShieldAlert, Star, MapPin, Truck, Car, Trash2, AlertTriangle } from 'lucide-react'
import { PageHeader } from '../../components/common/PageHeader'
import { SearchBar } from '../../components/common/SearchBar'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { Select } from '../../components/ui/Select'
import { Badge } from '../../components/ui/Badge'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { EmptyState } from '../../components/common/EmptyState'
import { ridersService } from '../../services/riders.service'
import { RiderWithProfile, RiderVerificationStatus, RiderVehicleType } from '../../types'
import { useToast } from '../../context/ToastContext'
import { formatDate } from '../../utils/formatters'

export const RidersPage: React.FC = () => {
  const [riders, setRiders] = useState<RiderWithProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  // Create Rider Modal
  const [isCreateOpen, setIsCreateOpen] = useState(false)
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [phoneNumber, setPhoneNumber] = useState('')
  const [vehicleType, setVehicleType] = useState<RiderVehicleType>('motorcycle')
  const [vehicleNumber, setVehicleNumber] = useState('')
  const [licenseNumber, setLicenseNumber] = useState('')
  const [assignedZone, setAssignedZone] = useState('Colombo Central & Western Province')
  const [submitting, setSubmitting] = useState(false)

  // Edit Zone Modal
  const [isZoneModalOpen, setIsZoneModalOpen] = useState(false)
  const [selectedRider, setSelectedRider] = useState<RiderWithProfile | null>(null)
  const [newZone, setNewZone] = useState('')

  // Delete Rider state
  const [riderToDelete, setRiderToDelete] = useState<RiderWithProfile | null>(null)
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)

  const { success, error: toastError } = useToast()

  const loadRiders = async () => {
    setLoading(true)
    try {
      const data = await ridersService.getRiders(search, statusFilter)
      setRiders(data)
    } catch (err) {
      toastError('Failed to load delivery riders')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadRiders()
  }, [search, statusFilter])

  const handleStatusChange = async (id: string, status: RiderVerificationStatus, riderName: string) => {
    try {
      await ridersService.updateRiderStatus(id, status)
      success(`Rider "${riderName}" is now ${status}`)
      loadRiders()
    } catch (err) {
      toastError('Failed to update rider status')
    }
  }

  const handleCreateRider = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!fullName || !email || !vehicleNumber || !licenseNumber) {
      toastError('Please fill in all required rider fields')
      return
    }

    setSubmitting(true)
    try {
      await ridersService.createRider({
        fullName,
        email,
        phoneNumber,
        vehicleType,
        vehicleNumber,
        drivingLicenseNumber: licenseNumber,
        assignedZone,
      })
      success(`Delivery rider "${fullName}" registered and verified`)
      setIsCreateOpen(false)
      loadRiders()
    } catch (err: any) {
      toastError(err.message || 'Failed to create rider')
    } finally {
      setSubmitting(false)
    }
  }

  const openZoneModal = (rider: RiderWithProfile) => {
    setSelectedRider(rider)
    setNewZone(rider.assigned_zone || '')
    setIsZoneModalOpen(true)
  }

  const handleSaveZone = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedRider) return
    try {
      await ridersService.updateRiderZone(selectedRider.id, newZone)
      success(`Delivery zone updated for ${selectedRider.profile.full_name}`)
      setIsZoneModalOpen(false)
      loadRiders()
    } catch (err) {
      toastError('Failed to update zone')
    }
  }

  const handleDeleteRider = async () => {
    if (!riderToDelete) return
    setIsDeleting(true)
    try {
      await ridersService.deleteRider(riderToDelete.id)
      success(`Delivery rider "${riderToDelete.profile.full_name}" removed from the fleet`)
      setIsDeleteModalOpen(false)
      setRiderToDelete(null)
      loadRiders()
    } catch (err: any) {
      toastError(err.message || 'Failed to remove delivery rider')
    } finally {
      setIsDeleting(false)
    }
  }

  const getVehicleIcon = (type: RiderVehicleType) => {
    switch (type) {
      case 'motorcycle':
      case 'bicycle':
        return <Bike size={18} />
      case 'three_wheeler':
        return <Car size={18} />
      case 'van':
      case 'car':
        return <Truck size={18} />
      default:
        return <Bike size={18} />
    }
  }

  return (
    <div>
      <PageHeader
        title="Delivery Fleet & Riders"
        subtitle="Manage logistics personnel, vehicle registrations, assigned delivery zones, and availability"
        actions={
          <Button variant="primary" onClick={() => setIsCreateOpen(true)} icon={<Plus size={16} />}>
            Register Rider
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
              placeholder="Search by rider, vehicle #, zone, license..."
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
            Showing <strong>{riders.length}</strong> active riders
          </div>
        </div>
      </div>

      {loading ? (
        <Spinner fullPage />
      ) : riders.length === 0 ? (
        <EmptyState
          icon={<Bike size={32} />}
          title="No Delivery Riders Found"
          description="No rider records match your search query."
        />
      ) : (
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Rider Profile</th>
                <th>Vehicle & License</th>
                <th>Assigned Delivery Zone</th>
                <th>Availability</th>
                <th>Rating & Trips</th>
                <th>Status</th>
                <th>Registered</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {riders.map((rider) => (
                <tr key={rider.id}>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      <div
                        style={{
                          width: 40,
                          height: 40,
                          borderRadius: '50%',
                          backgroundColor: 'var(--primary-light)',
                          color: 'var(--primary)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                        }}
                      >
                        <Bike size={20} />
                      </div>
                      <div>
                        <p style={{ fontWeight: 700, color: 'var(--text-main)' }}>{rider.profile.full_name}</p>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{rider.profile.phone_number}</p>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>{rider.profile.email}</p>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem', fontWeight: 600, fontSize: '0.875rem' }}>
                        {getVehicleIcon(rider.vehicle_type)}
                        <span>{rider.vehicle_number}</span>
                      </div>
                      <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                        DL: {rider.driving_license_number} ({rider.vehicle_type.replace('_', ' ')})
                      </p>
                    </div>
                  </td>
                  <td>
                    <div
                      onClick={() => openZoneModal(rider)}
                      style={{ cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '0.35rem' }}
                      title="Click to edit zone"
                    >
                      <MapPin size={14} color="var(--primary)" />
                      <span style={{ fontSize: '0.8125rem', fontWeight: 600, color: 'var(--primary)' }}>
                        {rider.assigned_zone || 'Assign Zone'}
                      </span>
                    </div>
                  </td>
                  <td>
                    <Badge
                      variant={
                        rider.availability_status === 'available'
                          ? 'success'
                          : rider.availability_status === 'busy'
                          ? 'warning'
                          : 'neutral'
                      }
                    >
                      {rider.availability_status}
                    </Badge>
                  </td>
                  <td>
                    <div style={{ fontSize: '0.8125rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                        <Star size={14} fill="#f59e0b" color="#f59e0b" />
                        <strong>{rider.rating > 0 ? rider.rating.toFixed(1) : '5.0'}</strong>
                      </div>
                      <span style={{ color: 'var(--text-muted)' }}>{rider.total_deliveries} deliveries</span>
                    </div>
                  </td>
                  <td>
                    <Badge status={rider.verification_status}>{rider.verification_status}</Badge>
                  </td>
                  <td style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                    {formatDate(rider.created_at)}
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '0.4rem', alignItems: 'center' }}>
                      {rider.verification_status === 'pending' && (
                        <Button
                          variant="success"
                          size="sm"
                          onClick={() => handleStatusChange(rider.id, 'approved', rider.profile.full_name)}
                          icon={<Check size={14} />}
                        >
                          Approve
                        </Button>
                      )}
                      {rider.verification_status === 'approved' && (
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => handleStatusChange(rider.id, 'suspended', rider.profile.full_name)}
                          icon={<ShieldAlert size={14} />}
                        >
                          Suspend
                        </Button>
                      )}
                      {rider.verification_status === 'suspended' && (
                        <Button
                          variant="secondary"
                          size="sm"
                          onClick={() => handleStatusChange(rider.id, 'approved', rider.profile.full_name)}
                        >
                          Reactivate
                        </Button>
                      )}
                      <Button
                        variant="danger"
                        size="sm"
                        icon={<Trash2 size={14} />}
                        title="Remove Delivery Rider"
                        onClick={() => {
                          setRiderToDelete(rider)
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

      {/* Create Rider Modal */}
      <Modal
        isOpen={isCreateOpen}
        onClose={() => setIsCreateOpen(false)}
        title="Register Delivery Rider"
        subtitle="Onboard a logistics driver to the BuyLanka fleet"
        size="lg"
      >
        <form onSubmit={handleCreateRider}>
          <div className="form-grid-2">
            <Input
              label="Full Name"
              placeholder="e.g. Dhanushka Kumara"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              required
            />
            <Input
              label="Email Address"
              type="email"
              placeholder="dhanushka@gmail.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          <div className="form-grid-2">
            <Input
              label="Phone Number"
              placeholder="+94 77 123 9988"
              value={phoneNumber}
              onChange={(e) => setPhoneNumber(e.target.value)}
              required
            />
            <Input
              label="Driving License Number"
              placeholder="e.g. B8291024"
              value={licenseNumber}
              onChange={(e) => setLicenseNumber(e.target.value)}
              required
            />
          </div>

          <div className="form-grid-2">
            <Select
              label="Vehicle Type"
              value={vehicleType}
              onChange={(e) => setVehicleType(e.target.value as RiderVehicleType)}
              options={[
                { value: 'motorcycle', label: 'Motorcycle' },
                { value: 'three_wheeler', label: 'Three Wheeler (Tuk-Tuk)' },
                { value: 'car', label: 'Car' },
                { value: 'van', label: 'Delivery Van' },
                { value: 'bicycle', label: 'Bicycle' },
              ]}
            />
            <Input
              label="Vehicle Registration Number"
              placeholder="e.g. WP BDF-1290"
              value={vehicleNumber}
              onChange={(e) => setVehicleNumber(e.target.value)}
              required
            />
          </div>

          <Input
            label="Assigned Delivery District / Zone"
            placeholder="e.g. Colombo Central & Colombo 03/07"
            value={assignedZone}
            onChange={(e) => setAssignedZone(e.target.value)}
            helperText="The primary territory or district where this rider will receive pickup dispatches"
            required
          />

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '1.5rem' }}>
            <Button type="button" variant="secondary" onClick={() => setIsCreateOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" variant="primary" isLoading={submitting}>
              Register Rider
            </Button>
          </div>
        </form>
      </Modal>

      {/* Edit Zone Modal */}
      {selectedRider && (
        <Modal
          isOpen={isZoneModalOpen}
          onClose={() => setIsZoneModalOpen(false)}
          title={`Assign Delivery Zone: ${selectedRider.profile.full_name}`}
        >
          <form onSubmit={handleSaveZone}>
            <Input
              label="Delivery Operating Territory"
              placeholder="e.g. Kandy Metro & Peradeniya"
              value={newZone}
              onChange={(e) => setNewZone(e.target.value)}
              required
            />
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '1.5rem' }}>
              <Button type="button" variant="secondary" onClick={() => setIsZoneModalOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" variant="primary">
                Save Zone
              </Button>
            </div>
          </form>
        </Modal>
      )}

      {/* Delete Rider Confirmation Modal */}
      {riderToDelete && (
        <Modal
          isOpen={isDeleteModalOpen}
          onClose={() => {
            if (!isDeleting) {
              setIsDeleteModalOpen(false)
              setRiderToDelete(null)
            }
          }}
          title="Remove Delivery Rider"
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
              Confirm Rider Removal
            </h3>

            <p style={{ fontSize: '0.875rem', color: 'var(--text-muted)', marginBottom: '1.25rem', lineHeight: 1.5 }}>
              Are you sure you want to remove rider <strong>{riderToDelete.profile.full_name}</strong> ({riderToDelete.vehicle_number} - {riderToDelete.vehicle_type.replace('_', ' ')}) from the delivery fleet?
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
              <strong>⚠️ Notice:</strong> Active and queued order dispatches for this rider will be safely unassigned back to the dispatch pool.
            </div>

            <div style={{ display: 'flex', gap: '0.75rem', justifyContent: 'flex-end' }}>
              <Button
                variant="secondary"
                disabled={isDeleting}
                onClick={() => {
                  setIsDeleteModalOpen(false)
                  setRiderToDelete(null)
                }}
              >
                Cancel
              </Button>
              <Button
                variant="danger"
                isLoading={isDeleting}
                icon={<Trash2 size={16} />}
                onClick={handleDeleteRider}
              >
                Yes, Remove Rider
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  )
}

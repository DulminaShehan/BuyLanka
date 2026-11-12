import React, { useEffect, useState } from 'react'
import { Plus, Bike, Check, ShieldAlert, Star, MapPin, Truck, Car, Trash2, AlertTriangle, Eye, Clock, CheckCircle2, XCircle } from 'lucide-react'
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
import { RiderWithProfile, RiderVerificationStatus, RiderVehicleType, RiderProfileChangeRequest } from '../../types'
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

  // Rider Details & Review Modal
  const [detailsRider, setDetailsRider] = useState<RiderWithProfile | null>(null)
  const [isDetailsOpen, setIsDetailsOpen] = useState(false)
  const [reviewingRequestId, setReviewingRequestId] = useState<string | null>(null)
  const [rejectionRemarks, setRejectionRemarks] = useState('')
  const [isRejecting, setIsRejecting] = useState(false)
  const [processingAction, setProcessingAction] = useState(false)

  const { success, error: toastError } = useToast()

  const loadRiders = async () => {
    try {
      const data = await ridersService.getRiders(search, statusFilter)
      setRiders(data)
      if (detailsRider) {
        const updated = data.find((r) => r.id === detailsRider.id)
        if (updated) setDetailsRider(updated)
      }
    } catch (err) {
      toastError('Failed to load delivery riders')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    setLoading(true)
    loadRiders()

    // Realtime Supabase Subscription
    const unsubscribe = ridersService.subscribeToRiders(() => {
      loadRiders()
    })

    return () => {
      unsubscribe()
    }
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

  const handleApproveChanges = async (req: RiderProfileChangeRequest) => {
    if (!detailsRider) return
    setProcessingAction(true)
    try {
      await ridersService.approveChangeRequest(req.id, detailsRider.id, req.requested_changes)
      success('Rider sensitive profile changes approved and synchronized!')
      loadRiders()
    } catch (err: any) {
      toastError(err.message || 'Failed to approve change request')
    } finally {
      setProcessingAction(false)
    }
  }

  const handleRejectChanges = async (req: RiderProfileChangeRequest) => {
    if (!detailsRider) return
    if (!rejectionRemarks.trim()) {
      toastError('Please enter a remark explaining the rejection to the rider')
      return
    }

    setProcessingAction(true)
    try {
      await ridersService.rejectChangeRequest(req.id, detailsRider.id, rejectionRemarks.trim())
      success('Change request rejected with remarks sent to the rider.')
      setIsRejecting(false)
      setReviewingRequestId(null)
      setRejectionRemarks('')
      loadRiders()
    } catch (err: any) {
      toastError(err.message || 'Failed to reject change request')
    } finally {
      setProcessingAction(false)
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
        subtitle="Manage logistics personnel, vehicle registrations, real-time profile updates, and fleet availability"
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
            <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
              {['all', 'approved', 'pending', 'pending_update', 'suspended'].map((status) => (
                <button
                  key={status}
                  className={`btn btn-sm ${statusFilter === status ? 'btn-primary' : 'btn-secondary'}`}
                  onClick={() => setStatusFilter(status)}
                  style={{ textTransform: 'capitalize' }}
                >
                  {status === 'pending_update' ? 'Pending Updates ⚠️' : status}
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
                <th>Assigned Zone</th>
                <th>Availability</th>
                <th>Rating & Deliveries</th>
                <th>Profile Status</th>
                <th>Last Updated</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {riders.map((rider) => {
                const hasPendingUpdate =
                  rider.profile_update_status === 'pending_review' ||
                  rider.pending_change_requests?.some((r) => r.status === 'pending')

                return (
                  <tr key={rider.id}>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        {rider.profile.avatar_url ? (
                          <img
                            src={rider.profile.avatar_url}
                            alt={rider.profile.full_name}
                            style={{
                              width: 44,
                              height: 44,
                              borderRadius: '50%',
                              objectFit: 'cover',
                              border: '2px solid var(--primary-light)',
                            }}
                            onError={(e) => {
                              // Fallback on broken image
                              ;(e.target as HTMLElement).style.display = 'none'
                            }}
                          />
                        ) : (
                          <div
                            style={{
                              width: 44,
                              height: 44,
                              borderRadius: '50%',
                              backgroundColor: 'var(--primary-light)',
                              color: 'var(--primary)',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                            }}
                          >
                            <Bike size={22} />
                          </div>
                        )}
                        <div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.35rem' }}>
                            <p style={{ fontWeight: 700, color: 'var(--text-main)', fontSize: '0.9375rem' }}>
                              {rider.profile.full_name}
                            </p>
                            {hasPendingUpdate && (
                              <span
                                title="Rider submitted sensitive profile changes pending admin approval"
                                style={{
                                  backgroundColor: '#fef3c7',
                                  color: '#b45309',
                                  fontSize: '0.65rem',
                                  fontWeight: 700,
                                  padding: '2px 6px',
                                  borderRadius: 4,
                                  border: '1px solid #fde68a',
                                }}
                              >
                                REVIEW NEEDED
                              </span>
                            )}
                          </div>
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
                          {rider.vehicle_model ? `${rider.vehicle_model} • ` : ''}
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
                      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                        <Badge status={rider.verification_status}>{rider.verification_status}</Badge>
                        {rider.profile_update_status === 'pending_review' && (
                          <Badge variant="warning">Update Pending</Badge>
                        )}
                        {rider.profile_update_status === 'rejected' && (
                          <Badge variant="danger">Update Rejected</Badge>
                        )}
                      </div>
                    </td>
                    <td style={{ fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                      {formatDate(rider.updated_at || rider.created_at)}
                    </td>
                    <td style={{ textAlign: 'right' }}>
                      <div style={{ display: 'inline-flex', gap: '0.4rem', alignItems: 'center' }}>
                        <Button
                          variant="secondary"
                          size="sm"
                          icon={<Eye size={14} />}
                          onClick={() => {
                            setDetailsRider(rider)
                            setIsDetailsOpen(true)
                          }}
                          title="View Profile & Review Changes"
                        >
                          Details
                        </Button>

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
                )
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Rider Details & Sensitive Changes Review Modal */}
      {detailsRider && (
        <Modal
          isOpen={isDetailsOpen}
          onClose={() => {
            setIsDetailsOpen(false)
            setDetailsRider(null)
            setIsRejecting(false)
            setReviewingRequestId(null)
          }}
          title={`Rider Profile & Fleet Record: ${detailsRider.profile.full_name}`}
          size="lg"
        >
          <div>
            {/* Header / Avatar banner */}
            <div
              style={{
                display: 'flex',
                gap: '1.25rem',
                alignItems: 'center',
                padding: '1.25rem',
                backgroundColor: 'var(--bg-main)',
                borderRadius: 'var(--radius-md)',
                marginBottom: '1.5rem',
                border: '1px solid var(--border-color)',
              }}
            >
              {detailsRider.profile.avatar_url ? (
                <img
                  src={detailsRider.profile.avatar_url}
                  alt={detailsRider.profile.full_name}
                  style={{
                    width: 72,
                    height: 72,
                    borderRadius: '50%',
                    objectFit: 'cover',
                    border: '3px solid var(--primary)',
                  }}
                />
              ) : (
                <div
                  style={{
                    width: 72,
                    height: 72,
                    borderRadius: '50%',
                    backgroundColor: 'var(--primary-light)',
                    color: 'var(--primary)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <Bike size={36} />
                </div>
              )}

              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: 4 }}>
                  <h3 style={{ fontSize: '1.25rem', fontWeight: 700, margin: 0, color: 'var(--text-main)' }}>
                    {detailsRider.profile.full_name}
                  </h3>
                  <Badge status={detailsRider.verification_status}>{detailsRider.verification_status}</Badge>
                </div>
                <p style={{ margin: 0, fontSize: '0.875rem', color: 'var(--text-muted)' }}>
                  Email: {detailsRider.profile.email} • Phone: {detailsRider.profile.phone_number || 'N/A'}
                </p>
                <p style={{ margin: '4px 0 0', fontSize: '0.8125rem', color: 'var(--text-muted)' }}>
                  Registered on: {formatDate(detailsRider.created_at)} • Last Profile Update: {formatDate(detailsRider.updated_at || detailsRider.created_at)}
                </p>
              </div>
            </div>

            {/* Sensitive Profile Change Requests Review Section */}
            {detailsRider.pending_change_requests &&
              detailsRider.pending_change_requests.filter((r) => r.status === 'pending').length > 0 && (
                <div
                  style={{
                    marginBottom: '1.5rem',
                    border: '2px solid #f59e0b',
                    borderRadius: 'var(--radius-md)',
                    overflow: 'hidden',
                  }}
                >
                  <div
                    style={{
                      backgroundColor: '#fef3c7',
                      padding: '0.75rem 1rem',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem',
                      color: '#b45309',
                      fontWeight: 700,
                      fontSize: '0.9375rem',
                    }}
                  >
                    <Clock size={18} />
                    <span>Pending Sensitive Change Request Requires Admin Approval</span>
                  </div>

                  <div style={{ padding: '1rem', backgroundColor: '#fffbeb' }}>
                    <p style={{ fontSize: '0.875rem', color: '#92400e', marginBottom: '1rem', lineHeight: 1.5 }}>
                      The rider has submitted modifications to their official vehicle or license details. Current details remain active until approved.
                    </p>

                    {detailsRider.pending_change_requests
                      .filter((r) => r.status === 'pending')
                      .map((req) => (
                        <div
                          key={req.id}
                          style={{
                            backgroundColor: '#ffffff',
                            border: '1px solid #fde68a',
                            borderRadius: 'var(--radius-sm)',
                            padding: '1rem',
                            marginBottom: '0.75rem',
                          }}
                        >
                          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1rem', marginBottom: '1rem' }}>
                            {/* Current Values */}
                            <div style={{ padding: '0.75rem', backgroundColor: '#f9fafb', borderRadius: 6 }}>
                              <h4 style={{ fontSize: '0.8125rem', textTransform: 'uppercase', color: 'var(--text-muted)', marginBottom: 8 }}>
                                Current Approved Record
                              </h4>
                              <div style={{ fontSize: '0.875rem', display: 'flex', flexDirection: 'column', gap: 4 }}>
                                <div><strong>Vehicle Plate:</strong> {detailsRider.vehicle_number}</div>
                                <div><strong>Vehicle Type:</strong> {detailsRider.vehicle_type}</div>
                                <div><strong>License #:</strong> {detailsRider.driving_license_number}</div>
                                {detailsRider.vehicle_model && <div><strong>Model:</strong> {detailsRider.vehicle_model}</div>}
                                {detailsRider.vehicle_color && <div><strong>Color:</strong> {detailsRider.vehicle_color}</div>}
                              </div>
                            </div>

                            {/* Proposed Changes */}
                            <div style={{ padding: '0.75rem', backgroundColor: '#eff6ff', borderRadius: 6, border: '1px solid #bfdbfe' }}>
                              <h4 style={{ fontSize: '0.8125rem', textTransform: 'uppercase', color: '#1e40af', marginBottom: 8 }}>
                                Proposed New Details
                              </h4>
                              <div style={{ fontSize: '0.875rem', display: 'flex', flexDirection: 'column', gap: 4, color: '#1e3a8a' }}>
                                {req.requested_changes.vehicle_number && (
                                  <div>
                                    <strong>New Vehicle Plate:</strong>{' '}
                                    <span style={{ color: 'var(--primary)', fontWeight: 700 }}>
                                      {req.requested_changes.vehicle_number}
                                    </span>
                                  </div>
                                )}
                                {req.requested_changes.driving_license_number && (
                                  <div>
                                    <strong>New License #:</strong>{' '}
                                    <span style={{ color: 'var(--primary)', fontWeight: 700 }}>
                                      {req.requested_changes.driving_license_number}
                                    </span>
                                  </div>
                                )}
                                {req.requested_changes.vehicle_type && (
                                  <div>
                                    <strong>New Vehicle Type:</strong>{' '}
                                    <span style={{ color: 'var(--primary)', fontWeight: 700 }}>
                                      {req.requested_changes.vehicle_type}
                                    </span>
                                  </div>
                                )}
                                {req.requested_changes.vehicle_model && (
                                  <div>
                                    <strong>New Model:</strong> {req.requested_changes.vehicle_model}
                                  </div>
                                )}
                                {req.requested_changes.vehicle_color && (
                                  <div>
                                    <strong>New Color:</strong> {req.requested_changes.vehicle_color}
                                  </div>
                                )}
                              </div>
                            </div>
                          </div>

                          {/* Rejection input when toggled */}
                          {isRejecting && reviewingRequestId === req.id && (
                            <div style={{ marginBottom: '1rem', padding: '0.75rem', backgroundColor: '#fff1f2', borderRadius: 6 }}>
                              <Input
                                label="Reason for Rejection (Will be sent to rider)"
                                placeholder="e.g. Vehicle registration document could not be matched with new plate number"
                                value={rejectionRemarks}
                                onChange={(e) => setRejectionRemarks(e.target.value)}
                                required
                              />
                            </div>
                          )}

                          {/* Review Action Buttons */}
                          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem' }}>
                            {isRejecting && reviewingRequestId === req.id ? (
                              <>
                                <Button
                                  variant="secondary"
                                  size="sm"
                                  onClick={() => {
                                    setIsRejecting(false)
                                    setReviewingRequestId(null)
                                  }}
                                  disabled={processingAction}
                                >
                                  Cancel
                                </Button>
                                <Button
                                  variant="danger"
                                  size="sm"
                                  icon={<XCircle size={14} />}
                                  isLoading={processingAction}
                                  onClick={() => handleRejectChanges(req)}
                                >
                                  Confirm Rejection
                                </Button>
                              </>
                            ) : (
                              <>
                                <Button
                                  variant="danger"
                                  size="sm"
                                  icon={<XCircle size={14} />}
                                  disabled={processingAction}
                                  onClick={() => {
                                    setIsRejecting(true)
                                    setReviewingRequestId(req.id)
                                  }}
                                >
                                  Reject Request
                                </Button>
                                <Button
                                  variant="success"
                                  size="sm"
                                  icon={<CheckCircle2 size={14} />}
                                  isLoading={processingAction}
                                  onClick={() => handleApproveChanges(req)}
                                >
                                  Approve & Apply Changes
                                </Button>
                              </>
                            )}
                          </div>
                        </div>
                      ))}
                  </div>
                </div>
              )}

            {/* Current Fleet & Personal Details Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '1.25rem', marginBottom: '1.5rem' }}>
              <div className="card" style={{ padding: '1rem' }}>
                <h4 style={{ fontWeight: 700, marginBottom: '0.75rem', color: 'var(--text-main)', fontSize: '0.9375rem' }}>
                  Personal Information
                </h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', fontSize: '0.875rem' }}>
                  <div><span style={{ color: 'var(--text-muted)' }}>Full Legal Name:</span> <strong>{detailsRider.profile.full_name}</strong></div>
                  <div><span style={{ color: 'var(--text-muted)' }}>Contact Phone:</span> <strong>{detailsRider.profile.phone_number || 'N/A'}</strong></div>
                  <div><span style={{ color: 'var(--text-muted)' }}>Email Address:</span> <strong>{detailsRider.profile.email}</strong></div>
                  <div><span style={{ color: 'var(--text-muted)' }}>Residential Address:</span> <strong>{detailsRider.residential_address || 'Not Provided'}</strong></div>
                  <div><span style={{ color: 'var(--text-muted)' }}>National Identity Card (NIC):</span> <strong>{detailsRider.nic_number || 'Enrolled in verification'}</strong></div>
                </div>
              </div>

              <div className="card" style={{ padding: '1rem' }}>
                <h4 style={{ fontWeight: 700, marginBottom: '0.75rem', color: 'var(--text-main)', fontSize: '0.9375rem' }}>
                  Vehicle & License Details
                </h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem', fontSize: '0.875rem' }}>
                  <div><span style={{ color: 'var(--text-muted)' }}>Vehicle Type:</span> <strong>{detailsRider.vehicle_type.replace('_', ' ').toUpperCase()}</strong></div>
                  <div><span style={{ color: 'var(--text-muted)' }}>Registration Plate:</span> <strong>{detailsRider.vehicle_number}</strong></div>
                  <div><span style={{ color: 'var(--text-muted)' }}>Vehicle Model:</span> <strong>{detailsRider.vehicle_model || 'Standard'}</strong></div>
                  <div><span style={{ color: 'var(--text-muted)' }}>Vehicle Color:</span> <strong>{detailsRider.vehicle_color || 'Default'}</strong></div>
                  <div><span style={{ color: 'var(--text-muted)' }}>Driving License:</span> <strong>{detailsRider.driving_license_number}</strong></div>
                  <div><span style={{ color: 'var(--text-muted)' }}>Operational Territory:</span> <strong>{detailsRider.assigned_zone || 'Colombo District'}</strong></div>
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
              <Button
                variant="secondary"
                onClick={() => {
                  setIsDetailsOpen(false)
                  setDetailsRider(null)
                }}
              >
                Close Window
              </Button>
            </div>
          </div>
        </Modal>
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

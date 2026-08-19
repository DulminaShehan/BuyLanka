// Currency and Date Formatters for Sri Lankan Marketplace (LKR)

export function formatLKR(amount: number | null | undefined): string {
  if (amount === null || amount === undefined || isNaN(amount)) {
    return 'Rs. 0.00'
  }
  return new Intl.NumberFormat('en-LK', {
    style: 'currency',
    currency: 'LKR',
    currencyDisplay: 'narrowSymbol',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  })
    .format(amount)
    .replace('LKR', 'Rs.')
}

export function formatDate(dateString: string | null | undefined): string {
  if (!dateString) return '—'
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('en-LK', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  }).format(date)
}

export function formatDateOnly(dateString: string | null | undefined): string {
  if (!dateString) return '—'
  const date = new Date(dateString)
  return new Intl.DateTimeFormat('en-LK', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(date)
}

export function slugify(text: string): string {
  return text
    .toString()
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-') // Replace spaces with -
    .replace(/[^\w-]+/g, '') // Remove all non-word chars
    .replace(/--+/g, '-') // Replace multiple - with single -
}

export function truncateText(text: string | null | undefined, maxLength: number = 30): string {
  if (!text) return ''
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}

export function getStatusBadgeVariant(
  status: string
): 'success' | 'warning' | 'danger' | 'info' | 'neutral' {
  switch (status?.toLowerCase()) {
    case 'active':
    case 'approved':
    case 'verified':
    case 'published':
    case 'delivered':
    case 'paid':
    case 'available':
      return 'success'

    case 'pending':
    case 'pending_approval':
    case 'processing':
    case 'assigned':
    case 'in_transit':
    case 'busy':
      return 'warning'

    case 'rejected':
    case 'suspended':
    case 'cancelled':
    case 'failed':
    case 'offline':
      return 'danger'

    case 'shipped':
    case 'picked_up':
    case 'ready_for_pickup':
    case 'draft':
      return 'info'

    default:
      return 'neutral'
  }
}

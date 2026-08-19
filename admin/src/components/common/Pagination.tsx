import React from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'

interface PaginationProps {
  currentPage: number
  totalPages: number
  onPageChange: (page: number) => void
  totalItems?: number
  pageSize?: number
}

export const Pagination: React.FC<PaginationProps> = ({
  currentPage,
  totalPages,
  onPageChange,
  totalItems,
  pageSize = 10,
}) => {
  if (totalPages <= 1) return null

  const startItem = (currentPage - 1) * pageSize + 1
  const endItem = totalItems ? Math.min(currentPage * pageSize, totalItems) : currentPage * pageSize

  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '1rem 1.25rem',
        borderTop: '1px solid var(--border-color)',
        background: 'var(--bg-surface)',
        borderBottomLeftRadius: 'var(--radius-lg)',
        borderBottomRightRadius: 'var(--radius-lg)',
        fontSize: '0.875rem',
        color: 'var(--text-muted)',
      }}
    >
      <div>
        {totalItems !== undefined && (
          <span>
            Showing <strong style={{ color: 'var(--text-main)' }}>{startItem}</strong> to{' '}
            <strong style={{ color: 'var(--text-main)' }}>{endItem}</strong> of{' '}
            <strong style={{ color: 'var(--text-main)' }}>{totalItems}</strong> entries
          </span>
        )}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
        <button
          className="btn btn-secondary btn-sm"
          onClick={() => onPageChange(currentPage - 1)}
          disabled={currentPage <= 1}
        >
          <ChevronLeft size={16} /> Previous
        </button>
        <span style={{ padding: '0 0.5rem', fontWeight: 600, color: 'var(--text-main)' }}>
          Page {currentPage} of {totalPages}
        </span>
        <button
          className="btn btn-secondary btn-sm"
          onClick={() => onPageChange(currentPage + 1)}
          disabled={currentPage >= totalPages}
        >
          Next <ChevronRight size={16} />
        </button>
      </div>
    </div>
  )
}

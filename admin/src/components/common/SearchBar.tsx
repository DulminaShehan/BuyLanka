import React from 'react'
import { Search, X } from 'lucide-react'

interface SearchBarProps {
  value: string
  onChange: (value: string) => void
  placeholder?: string
  className?: string
  width?: string | number
}

export const SearchBar: React.FC<SearchBarProps> = ({
  value,
  onChange,
  placeholder = 'Search...',
  className = '',
  width = '320px',
}) => {
  return (
    <div
      className={className}
      style={{
        position: 'relative',
        display: 'flex',
        alignItems: 'center',
        width,
        maxWidth: '100%',
      }}
    >
      <Search
        size={18}
        style={{
          position: 'absolute',
          left: '0.875rem',
          color: 'var(--text-muted)',
          pointerEvents: 'none',
        }}
      />
      <input
        type="text"
        className="form-input"
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        style={{
          paddingLeft: '2.5rem',
          paddingRight: value ? '2.5rem' : '0.875rem',
          borderRadius: 'var(--radius-md)',
        }}
      />
      {value && (
        <button
          type="button"
          onClick={() => onChange('')}
          style={{
            position: 'absolute',
            right: '0.75rem',
            background: 'transparent',
            border: 'none',
            color: 'var(--text-subtle)',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
          }}
          aria-label="Clear search"
        >
          <X size={16} />
        </button>
      )}
    </div>
  )
}

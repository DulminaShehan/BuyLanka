import React, { useEffect, useState } from 'react'
import { Plus, Edit2, Trash2, Layers } from 'lucide-react'
import { PageHeader } from '../../components/common/PageHeader'
import { SearchBar } from '../../components/common/SearchBar'
import { Button } from '../../components/ui/Button'
import { Input } from '../../components/ui/Input'
import { Badge } from '../../components/ui/Badge'
import { Modal } from '../../components/ui/Modal'
import { Spinner } from '../../components/ui/Spinner'
import { EmptyState } from '../../components/common/EmptyState'
import { categoriesService } from '../../services/categories.service'
import { Category } from '../../types'
import { useToast } from '../../context/ToastContext'

export const CategoriesPage: React.FC = () => {
  const [categories, setCategories] = useState<Category[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingCategory, setEditingCategory] = useState<Category | null>(null)
  const [submitting, setSubmitting] = useState(false)

  // Form fields
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [icon, setIcon] = useState('Layers')
  const [imageUrl, setImageUrl] = useState('')
  const [displayOrder, setDisplayOrder] = useState(1)
  const [isActive, setIsActive] = useState(true)

  const { success, error: toastError } = useToast()

  const loadCategories = async () => {
    setLoading(true)
    try {
      const data = await categoriesService.getCategories(search)
      setCategories(data)
    } catch (err) {
      toastError('Failed to load categories')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    loadCategories()
  }, [search])

  const openCreateModal = () => {
    setEditingCategory(null)
    setName('')
    setDescription('')
    setIcon('Layers')
    setImageUrl('')
    setDisplayOrder(categories.length + 1)
    setIsActive(true)
    setIsModalOpen(true)
  }

  const openEditModal = (cat: Category) => {
    setEditingCategory(cat)
    setName(cat.name)
    setDescription(cat.description || '')
    setIcon(cat.icon || 'Layers')
    setImageUrl(cat.image_url || '')
    setDisplayOrder(cat.display_order)
    setIsActive(cat.is_active)
    setIsModalOpen(true)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim()) {
      toastError('Category name is required')
      return
    }

    setSubmitting(true)
    try {
      if (editingCategory) {
        await categoriesService.updateCategory(editingCategory.id, {
          name,
          description,
          icon,
          image_url: imageUrl || null,
          display_order: Number(displayOrder),
          is_active: isActive,
        })
        success(`Category "${name}" updated successfully`)
      } else {
        await categoriesService.createCategory({
          name,
          description,
          icon,
          image_url: imageUrl || undefined,
          display_order: Number(displayOrder),
          is_active: isActive,
        })
        success(`Category "${name}" created successfully`)
      }
      setIsModalOpen(false)
      loadCategories()
    } catch (err: any) {
      toastError(err.message || 'Operation failed')
    } finally {
      setSubmitting(false)
    }
  }

  const handleDelete = async (id: string, catName: string) => {
    if (!window.confirm(`Are you sure you want to delete category "${catName}"?`)) return
    try {
      await categoriesService.deleteCategory(id)
      success(`Category "${catName}" deleted`)
      loadCategories()
    } catch (err: any) {
      toastError(err.message || 'Failed to delete category')
    }
  }

  const handleToggleStatus = async (cat: Category) => {
    try {
      await categoriesService.updateCategory(cat.id, { is_active: !cat.is_active })
      success(`Category "${cat.name}" is now ${!cat.is_active ? 'Active' : 'Inactive'}`)
      loadCategories()
    } catch (err) {
      toastError('Failed to update status')
    }
  }

  return (
    <div>
      <PageHeader
        title="Category Management"
        subtitle="Manage product categories, marketplace taxonomies, and navigation hierarchy"
        actions={
          <Button variant="primary" onClick={openCreateModal} icon={<Plus size={16} />}>
            Add Category
          </Button>
        }
      />

      <div className="card" style={{ marginBottom: '1.5rem', padding: '1rem 1.5rem' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '1rem' }}>
          <SearchBar
            value={search}
            onChange={setSearch}
            placeholder="Search categories by name or keyword..."
            width="360px"
          />
          <div style={{ fontSize: '0.875rem', color: 'var(--text-muted)' }}>
            Showing <strong>{categories.length}</strong> categories
          </div>
        </div>
      </div>

      {loading ? (
        <Spinner fullPage />
      ) : categories.length === 0 ? (
        <EmptyState
          icon={<Layers size={32} />}
          title="No Categories Found"
          description="Create your first marketplace category to organize vendor products."
          action={
            <Button variant="primary" onClick={openCreateModal} icon={<Plus size={16} />}>
              Add First Category
            </Button>
          }
        />
      ) : (
        <div className="table-container">
          <table className="data-table">
            <thead>
              <tr>
                <th>Order</th>
                <th>Category</th>
                <th>Slug</th>
                <th>Description</th>
                <th>Status</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {categories.map((cat) => (
                <tr key={cat.id}>
                  <td style={{ width: 60, fontWeight: 700, color: 'var(--text-muted)' }}>
                    #{cat.display_order}
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      {cat.image_url ? (
                        <img
                          src={cat.image_url}
                          alt={cat.name}
                          style={{ width: 42, height: 42, borderRadius: 'var(--radius-md)', objectFit: 'cover', border: '1px solid var(--border-color)' }}
                        />
                      ) : (
                        <div
                          style={{
                            width: 42,
                            height: 42,
                            borderRadius: 'var(--radius-md)',
                            backgroundColor: 'var(--primary-light)',
                            color: 'var(--primary)',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                          }}
                        >
                          <Layers size={20} />
                        </div>
                      )}
                      <div>
                        <p style={{ fontWeight: 700, color: 'var(--text-main)' }}>{cat.name}</p>
                        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Icon: {cat.icon || 'Layers'}</p>
                      </div>
                    </div>
                  </td>
                  <td style={{ fontFamily: 'monospace', color: 'var(--text-muted)', fontSize: '0.8125rem' }}>
                    {cat.slug}
                  </td>
                  <td style={{ maxWidth: 300, color: 'var(--text-muted)', fontSize: '0.8125rem' }}>
                    {cat.description || '—'}
                  </td>
                  <td>
                    <button
                      onClick={() => handleToggleStatus(cat)}
                      style={{ background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
                      title="Click to toggle status"
                    >
                      <Badge variant={cat.is_active ? 'success' : 'danger'}>
                        {cat.is_active ? 'Active' : 'Inactive'}
                      </Badge>
                    </button>
                  </td>
                  <td style={{ textAlign: 'right' }}>
                    <div style={{ display: 'inline-flex', gap: '0.5rem' }}>
                      <button
                        className="btn-icon"
                        onClick={() => openEditModal(cat)}
                        title="Edit category"
                        style={{ border: 'none', background: 'transparent', cursor: 'pointer' }}
                      >
                        <Edit2 size={16} />
                      </button>
                      <button
                        className="btn-icon"
                        onClick={() => handleDelete(cat.id, cat.name)}
                        title="Delete category"
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

      {/* Create / Edit Modal */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingCategory ? 'Edit Category' : 'Create New Category'}
        subtitle="Configure the category title, taxonomy details, and display parameters"
      >
        <form onSubmit={handleSubmit}>
          <Input
            label="Category Name (English)"
            placeholder="e.g. Ceylon Spices & Herbal Infusions"
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
          />

          <div className="form-group">
            <label className="form-label">Description</label>
            <textarea
              className="form-textarea"
              placeholder="Brief description of products in this category..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={3}
            />
          </div>

          <div className="form-grid-2">
            <Input
              label="Lucide Icon Tag"
              placeholder="e.g. Coffee, Palette, Shirt"
              value={icon}
              onChange={(e) => setIcon(e.target.value)}
            />
            <Input
              label="Display Sequence / Priority"
              type="number"
              value={displayOrder}
              onChange={(e) => setDisplayOrder(Number(e.target.value))}
              required
            />
          </div>

          <Input
            label="Image Banner URL"
            placeholder="https://images.unsplash.com/..."
            value={imageUrl}
            onChange={(e) => setImageUrl(e.target.value)}
            helperText="Provide a high-resolution preview URL for mobile app category cards"
          />

          <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginTop: '1rem' }}>
            <input
              type="checkbox"
              id="is-active-check"
              checked={isActive}
              onChange={(e) => setIsActive(e.target.checked)}
              style={{ width: 18, height: 18, accentColor: 'var(--primary)' }}
            />
            <label htmlFor="is-active-check" style={{ fontWeight: 600, fontSize: '0.875rem', cursor: 'pointer' }}>
              Publish this category (Visible on customer app)
            </label>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '0.75rem', marginTop: '1.5rem' }}>
            <Button type="button" variant="secondary" onClick={() => setIsModalOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" variant="primary" isLoading={submitting}>
              {editingCategory ? 'Update Category' : 'Create Category'}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  )
}

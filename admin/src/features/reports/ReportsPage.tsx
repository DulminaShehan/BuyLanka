import React, { useEffect, useState } from 'react'
import { Download, DollarSign, TrendingUp, Store, FileText } from 'lucide-react'
import { PageHeader } from '../../components/common/PageHeader'
import { StatCard } from '../../components/common/StatCard'
import { Button } from '../../components/ui/Button'
import { Spinner } from '../../components/ui/Spinner'
import { reportsService, PlatformReportSummary } from '../../services/reports.service'
import { useToast } from '../../context/ToastContext'
import { formatLKR } from '../../utils/formatters'

export const ReportsPage: React.FC = () => {
  const [report, setReport] = useState<PlatformReportSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const { success } = useToast()

  useEffect(() => {
    const loadReport = async () => {
      setLoading(true)
      try {
        const data = await reportsService.getFinancialReport()
        setReport(data)
      } catch (err) {
        console.error(err)
      } finally {
        setLoading(false)
      }
    }
    loadReport()
  }, [])

  const handleExportVendors = () => {
    if (!report?.topSellingVendors) return
    reportsService.exportToCSV(report.topSellingVendors, 'BuyLanka_Vendor_Performance')
    success('Vendor performance report exported to CSV')
  }

  const handleExportCategories = () => {
    if (!report?.topCategories) return
    reportsService.exportToCSV(report.topCategories, 'BuyLanka_Category_Performance')
    success('Category performance report exported to CSV')
  }

  if (loading || !report) {
    return <Spinner fullPage />
  }

  return (
    <div>
      <PageHeader
        title="Platform Reports & Analytics"
        subtitle="Financial intelligence, gross marketplace volumes, commission balances, and merchant analytics"
        actions={
          <div style={{ display: 'flex', gap: '0.75rem' }}>
            <Button variant="secondary" onClick={handleExportCategories} icon={<Download size={16} />}>
              Export Categories (CSV)
            </Button>
            <Button variant="primary" onClick={handleExportVendors} icon={<Download size={16} />}>
              Export Vendor Payouts (CSV)
            </Button>
          </div>
        }
      />

      {/* Financial Summary Cards */}
      <div className="grid-metrics">
        <StatCard
          title="Gross Merchandise Value (GMV)"
          value={formatLKR(report.grossMerchandiseValue)}
          icon={<DollarSign size={24} />}
          trend={{ value: '22.5%', isPositive: true, label: 'monthly growth' }}
          colorScheme="primary"
        />

        <StatCard
          title="Platform Net Commission"
          value={formatLKR(report.totalPlatformCommission)}
          icon={<TrendingUp size={24} />}
          trend={{ value: '14.2%', isPositive: true }}
          colorScheme="accent"
        />

        <StatCard
          title="Net Seller Payouts"
          value={formatLKR(report.netSellerPayouts)}
          icon={<Store size={24} />}
          colorScheme="info"
        />

        <StatCard
          title="Average Order Value (AOV)"
          value={formatLKR(report.averageOrderValue)}
          icon={<FileText size={24} />}
          colorScheme="success"
        />
      </div>

      {/* Top Performing Vendors Table */}
      <div className="grid-two-cols" style={{ marginBottom: '2rem' }}>
        <div className="card">
          <div className="card-header">
            <div>
              <h3 className="card-title">Top Vendor Performance</h3>
              <p className="card-subtitle">Highest grossing merchant storefronts</p>
            </div>
          </div>
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Storefront</th>
                  <th>Orders</th>
                  <th>Gross Sales</th>
                  <th>Commission (10%)</th>
                </tr>
              </thead>
              <tbody>
                {report.topSellingVendors.map((vendor, idx) => (
                  <tr key={idx}>
                    <td style={{ fontWeight: 700 }}>{vendor.shopName}</td>
                    <td>{vendor.ordersCount}</td>
                    <td><strong>{formatLKR(vendor.grossRevenue)}</strong></td>
                    <td style={{ color: 'var(--primary)', fontWeight: 600 }}>{formatLKR(vendor.commission)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Category Breakdown Table */}
        <div className="card">
          <div className="card-header">
            <div>
              <h3 className="card-title">Category Sales Velocity</h3>
              <p className="card-subtitle">Marketplace product category distribution</p>
            </div>
          </div>
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Category</th>
                  <th>Units Sold</th>
                  <th>Gross Revenue (LKR)</th>
                </tr>
              </thead>
              <tbody>
                {report.topCategories.map((cat, idx) => (
                  <tr key={idx}>
                    <td style={{ fontWeight: 700 }}>{cat.categoryName}</td>
                    <td>{cat.unitsSold} units</td>
                    <td><strong style={{ color: 'var(--primary)' }}>{formatLKR(cat.revenue)}</strong></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  )
}

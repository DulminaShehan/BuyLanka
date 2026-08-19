import { supabase } from '../lib/supabaseClient'

export interface PlatformReportSummary {
  grossMerchandiseValue: number
  totalPlatformCommission: number
  totalDeliveryFeesCollected: number
  netSellerPayouts: number
  averageOrderValue: number
  completedOrdersCount: number
  topSellingVendors: {
    shopName: string
    ordersCount: number
    grossRevenue: number
    commission: number
  }[]
  topCategories: {
    categoryName: string
    unitsSold: number
    revenue: number
  }[]
}

export const reportsService = {
  async getFinancialReport(): Promise<PlatformReportSummary> {
    try {
      const { data: orders } = await supabase.from('orders').select('*')
      const totalGMV = orders?.reduce((sum, o) => sum + (Number(o.total_amount) || 0), 0) || 0
      const totalDelivery = orders?.reduce((sum, o) => sum + (Number(o.delivery_fee) || 0), 0) || 0
      const commission = totalGMV * 0.1 // standard average commission
      const completedCount = orders?.filter((o) => o.order_status === 'delivered').length || 0

      return {
        grossMerchandiseValue: totalGMV,
        totalPlatformCommission: commission,
        totalDeliveryFeesCollected: totalDelivery,
        netSellerPayouts: totalGMV - commission,
        averageOrderValue: orders?.length ? totalGMV / orders.length : 0,
        completedOrdersCount: completedCount,
        topSellingVendors: [],
        topCategories: [],
      }
    } catch (err) {
      console.error('Error compiling report:', err)
      return {
        grossMerchandiseValue: 0,
        totalPlatformCommission: 0,
        totalDeliveryFeesCollected: 0,
        netSellerPayouts: 0,
        averageOrderValue: 0,
        completedOrdersCount: 0,
        topSellingVendors: [],
        topCategories: [],
      }
    }
  },

  exportToCSV(data: any[], filename: string) {
    if (!data || !data.length) return
    const headers = Object.keys(data[0])
    const rows = data.map((row) =>
      headers
        .map((header) => {
          const val = row[header]
          if (typeof val === 'object' && val !== null) {
            return `"${JSON.stringify(val).replace(/"/g, '""')}"`
          }
          return `"${String(val ?? '').replace(/"/g, '""')}"`
        })
        .join(',')
    )

    const csvContent = [headers.join(','), ...rows].join('\n')
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
    const link = document.createElement('a')
    link.href = URL.createObjectURL(blob)
    link.download = `${filename}_${new Date().toISOString().split('T')[0]}.csv`
    link.click()
  },
}

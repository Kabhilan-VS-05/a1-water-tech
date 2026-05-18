import { useState, useEffect } from 'react'
import { Search, Loader2, Package, CheckCircle, Clock, Truck, ChevronRight } from 'lucide-react'
import { useAuth } from '../state/AuthContext.jsx'

const formatDateTime = (value) => {
  if (!value) return 'Not available'
  if (typeof value?.toDate === 'function') return value.toDate().toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
  const parsed = new Date(value)
  return Number.isNaN(parsed.getTime()) ? 'Not available' : parsed.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
}

const steps = [
  { key: 'placed',    label: 'Order Placed',    icon: CheckCircle, activeOn: ['pending', 'confirmed', 'shipped', 'delivered'] },
  { key: 'confirmed', label: 'Confirmed',        icon: Package,     activeOn: ['confirmed', 'shipped', 'delivered'] },
  { key: 'shipped',   label: 'Shipped',          icon: Truck,       activeOn: ['shipped', 'delivered'] },
  { key: 'delivered', label: 'Delivered',        icon: CheckCircle, activeOn: ['delivered'] },
]

export default function TrackOrder() {
  const { user } = useAuth()
  const [searchId, setSearchId] = useState('')
  const [order, setOrder] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  // Poll order status every 5 seconds for instant updates from admin changes
  useEffect(() => {
    if (!order || !user || ['delivered', 'cancelled', 'rejected'].includes(order.status?.toLowerCase())) return

    let active = true
    const interval = setInterval(async () => {
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) return
        const res = await fetch(
          `${baseUrl}/orders/track?userId=${encodeURIComponent(user.uid)}&orderId=${encodeURIComponent(order.orderId || order.id)}`
        )
        if (res.ok && active) {
          const data = await res.json()
          if (data.item) {
            setOrder(data.item)
          }
        }
      } catch (err) {
        console.error('Polling track order error:', err)
      }
    }, 5000)

    return () => {
      active = false
      clearInterval(interval)
    }
  }, [order?.status, order?.orderId, order?.id, user])

  const handleTrack = async (e) => {
    e.preventDefault()
    if (!searchId.trim() || !user) return
    const orderId = searchId.trim().replace(/^#/, '')
    setLoading(true); setError(''); setOrder(null)
    try {
      const baseUrl = import.meta.env.VITE_API_BASE_URL
      if (!baseUrl) throw new Error('Missing VITE_API_BASE_URL')
      const res = await fetch(
        `${baseUrl}/orders/track?userId=${encodeURIComponent(user.uid)}&orderId=${encodeURIComponent(orderId)}`
      )
      if (res.status === 404) {
        setError('Order not found. Please check your Order ID.')
      } else if (!res.ok) {
        throw new Error(`Request failed: ${res.status}`)
      } else {
        const data = await res.json()
        setOrder(data.item || null)
      }
    } catch (err) {
      console.error(err)
      setError('Could not fetch order details. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const statusLower = order?.status?.toLowerCase() || 'pending'

  return (
    <div className="page-bg">
      <div className="container mx-auto px-4 max-w-xl py-8">

        <div className="mb-7">
          <h1 className="text-2xl font-bold text-slate-900">Track Order</h1>
          <p className="text-sm text-slate-500 mt-1">Enter your Order ID to see its current status.</p>
        </div>

        {/* Search form */}
        <form onSubmit={handleTrack} className="flex gap-2 mb-5">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              value={searchId}
              onChange={e => setSearchId(e.target.value)}
              placeholder="Order ID (e.g., A1-123456-789)"
              className="input pl-9 py-2.5"
            />
          </div>
          <button
            type="submit"
            disabled={loading || !searchId.trim()}
            className="btn-primary px-5 py-2.5 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Track'}
          </button>
        </form>

        {/* Error */}
        {error && (
          <div className="card p-4 bg-red-50 border-red-200 text-sm text-red-600 mb-4">
            {error}
          </div>
        )}

        {/* Order result */}
        {order && (
          <div className="card p-5">
            {/* Header */}
            <div className="flex items-center justify-between mb-5 pb-4 border-b border-slate-50">
              <div>
                <h2 className="text-base font-bold text-slate-900">Order #{order.orderId}</h2>
                <p className="text-xs text-slate-400 mt-0.5">Placed on {formatDateTime(order.createdAt)}</p>
              </div>
              <span className={`badge capitalize ${
                statusLower === 'delivered' ? 'badge-success'
                : statusLower === 'cancelled' ? 'badge-error'
                : 'badge-primary'
              }`}>
                {order.status || 'Processing'}
              </span>
            </div>

            {/* Timeline */}
            <div className="relative mb-5">
              <div className="absolute left-3.5 top-4 bottom-4 w-0.5 bg-slate-100 z-0" />
              <div className="space-y-5">
                {steps.map(s => {
                  const isActive = s.activeOn.includes(statusLower)
                  return (
                    <div key={s.key} className="relative flex items-start gap-3 z-10">
                      <div className={`w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 border-2 border-white shadow-sm ${
                        isActive ? 'bg-indigo-600 text-white' : 'bg-slate-100 text-slate-300'
                      }`}>
                        <s.icon className="w-3.5 h-3.5" />
                      </div>
                      <div className="pt-0.5">
                        <div className={`text-sm font-semibold ${isActive ? 'text-slate-900' : 'text-slate-400'}`}>
                          {s.label}
                        </div>
                        {s.key === 'placed' && isActive && (
                          <div className="text-xs text-slate-400 mt-0.5">{formatDateTime(order.createdAt)}</div>
                        )}
                        {s.key === 'delivered' && !isActive && (
                          <div className="text-xs text-slate-400 mt-0.5">Estimated 3–5 business days</div>
                        )}
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>

            {/* Items */}
            {order.items?.length > 0 && (
              <div className="border-t border-slate-50 pt-4">
                <div className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-3">Items</div>
                <ul className="space-y-2">
                  {order.items.map((item, i) => (
                    <li key={i} className="flex justify-between text-sm">
                      <span className="text-slate-700 truncate max-w-[200px]">{item.name}</span>
                      <span className="text-slate-400 flex-shrink-0 ml-2">×{item.qty}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            <button
              onClick={() => {
                sessionStorage.setItem('lastOrder', JSON.stringify(order))
                window.location.href = `/order-confirmation/${order.orderId || order.id}`
              }}
              className="btn-secondary w-full justify-center mt-4 py-2.5 text-sm"
            >
              View Full Order Details <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

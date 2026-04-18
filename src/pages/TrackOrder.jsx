import { useState } from 'react'
import {
  collection,
  getDocs,
  limit,
  query,
  where,
} from 'firebase/firestore'
import { db } from '../firebase.js'
import { Search, Loader2, Package, CheckCircle, Clock } from 'lucide-react'
import { useAuth } from '../state/AuthContext.jsx'

const formatDateTime = (value) => {
  if (!value) return 'Not available'
  if (typeof value?.toDate === 'function') return value.toDate().toLocaleString()
  const parsed = new Date(value)
  return Number.isNaN(parsed.getTime()) ? 'Not available' : parsed.toLocaleString()
}

export default function TrackOrder() {
  const { user } = useAuth()
  const [searchId, setSearchId] = useState('')
  const [order, setOrder] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleTrack = async (e) => {
    e.preventDefault()
    if (!searchId.trim()) return

    const normalizedOrderId = searchId.trim().replace(/^#/, '')

    setLoading(true)
    setError('')
    setOrder(null)

    try {
      const q = query(
        collection(db, 'orders'),
        where('userId', '==', user.uid),
        where('orderId', '==', normalizedOrderId),
        limit(1),
      )
      const querySnapshot = await getDocs(q)
      if (querySnapshot.empty) {
        setError('Order not found. Please check the ID.')
      } else {
        const orderData = querySnapshot.docs[0].data()
        setOrder({ id: querySnapshot.docs[0].id, ...orderData })
      }
    } catch (err) {
      console.error(err)
      setError('Failed to fetch order details. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="container mx-auto px-4 py-8 lg:py-16 font-sans">
      <div className="max-w-xl mx-auto text-center mb-10">
        <h1 className="text-3xl font-bold text-slate-900 mb-2">Track Your Order</h1>
        <p className="text-slate-500">Enter your Order ID to see the current status.</p>
      </div>

      <div className="max-w-md mx-auto">
        <form onSubmit={handleTrack} className="flex flex-col gap-4 mb-8">
          <div className="relative">
            <input
              type="text"
              placeholder="Enter Order ID (e.g., A1-123456-123)"
              value={searchId}
              onChange={(e) => setSearchId(e.target.value)}
              className="w-full pl-5 pr-12 py-3.5 bg-white border border-slate-200 rounded-xl text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 shadow-sm"
            />
            <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
              <Search className="w-5 h-5 text-slate-400" />
            </div>
          </div>
          <button
            type="submit"
            disabled={loading || !searchId}
            className="w-full py-3.5 px-6 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-lg shadow-indigo-200 transition-all disabled:bg-indigo-400 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          >
            {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Track Order'}
          </button>
        </form>

        {error && (
          <div className="p-4 bg-red-50 text-red-700 rounded-xl border border-red-100 font-medium text-center">
            {error}
          </div>
        )}

        {order && (
          <div className="bg-white rounded-2xl p-6 border border-slate-100 shadow-xl shadow-slate-200/50 animate-accordion-down">
            <div className="flex justify-between items-start mb-6 border-b border-slate-100 pb-4">
              <div>
                <h2 className="text-lg font-bold text-slate-900">Order Status</h2>
                <p className="text-sm text-slate-500">ID: {order.orderId}</p>
              </div>
              <div className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide border ${order.status === 'Delivered'
                  ? 'bg-green-50 text-green-700 border-green-200'
                  : 'bg-indigo-50 text-indigo-700 border-indigo-200'
                }`}>
                {order.status || 'Processing'}
              </div>
            </div>

            <div className="space-y-6 relative">
              {/* Timeline (Simplified) */}
              <div className="absolute left-3.5 top-2 bottom-2 w-0.5 bg-slate-100"></div>

              <div className="relative flex items-start gap-4">
                <div className="w-8 h-8 rounded-full bg-green-100 text-green-600 flex items-center justify-center border-2 border-white shadow-sm z-10">
                  <CheckCircle className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="font-bold text-slate-900 text-sm">Order Placed</h4>
                  <p className="text-xs text-slate-500">{formatDateTime(order.createdAt)}</p>
                </div>
              </div>

              <div className="relative flex items-start gap-4">
                <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 border-white shadow-sm z-10 ${order.status !== 'Pending' ? 'bg-indigo-100 text-indigo-600' : 'bg-slate-100 text-slate-400'}`}>
                  <Package className="w-4 h-4" />
                </div>
                <div>
                  <h4 className={`font-bold text-sm ${order.status !== 'Pending' ? 'text-slate-900' : 'text-slate-400'}`}>Processing</h4>
                  <p className="text-xs text-slate-500">Your order is being prepared.</p>
                </div>
              </div>

              <div className="relative flex items-start gap-4">
                <div className={`w-8 h-8 rounded-full flex items-center justify-center border-2 border-white shadow-sm z-10 ${order.status === 'Delivered' ? 'bg-green-100 text-green-600' : 'bg-slate-100 text-slate-400'}`}>
                  <Clock className="w-4 h-4" />
                </div>
                <div>
                  <h4 className={`font-bold text-sm ${order.status === 'Delivered' ? 'text-slate-900' : 'text-slate-400'}`}>Delivery</h4>
                  <p className="text-xs text-slate-500">Estimated within 3-5 days.</p>
                </div>
              </div>
            </div>

            <div className="mt-8 pt-4 border-t border-slate-100">
              <p className="text-xs font-bold text-slate-400 uppercase tracking-wide mb-3">Items Ordered</p>
              <ul className="space-y-3">
                {order.items?.map((item, i) => (
                  <li key={i} className="flex justify-between items-center text-sm">
                    <span className="text-slate-700 font-medium truncate max-w-[200px]">{item.name}</span>
                    <span className="text-slate-500">x{item.qty}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

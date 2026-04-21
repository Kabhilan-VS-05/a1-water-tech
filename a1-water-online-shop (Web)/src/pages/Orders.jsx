import { useAuth } from '../state/AuthContext.jsx'
import useOrders from '../hooks/useOrders.js'
import useProducts from '../hooks/useProducts.js'
import { formatCurrency } from '../utils/format.js'
import { Box, Calendar, Clock, CheckCircle, Truck, AlertCircle, RefreshCcw } from 'lucide-react'

const formatDate = (value) => {
  if (!value) return 'Pending'
  if (value?.toDate) return value.toDate().toLocaleString()
  return new Date(value).toLocaleString()
}

const getStatusColor = (status) => {
  switch (status?.toLowerCase()) {
    case 'delivered': return 'text-green-600 bg-green-50 border-green-200';
    case 'cancelled': return 'text-red-600 bg-red-50 border-red-200';
    case 'shipped': return 'text-indigo-600 bg-indigo-50 border-indigo-200';
    default: return 'text-amber-600 bg-amber-50 border-amber-200';
  }
}

const getStatusIcon = (status) => {
  switch (status?.toLowerCase()) {
    case 'delivered': return <CheckCircle className="w-4 h-4" />;
    case 'cancelled': return <AlertCircle className="w-4 h-4" />;
    case 'shipped': return <Truck className="w-4 h-4" />;
    default: return <Clock className="w-4 h-4" />;
  }
}

export default function Orders() {
  const { user } = useAuth()
  const { orders, loading } = useOrders(user?.uid)
  const { items: products } = useProducts()
  const productById = Object.fromEntries(products.map((p) => [p.id, p]))

  return (
    <div className="container mx-auto px-4 py-8 lg:py-12 max-w-5xl font-sans">
      <h1 className="text-3xl font-bold text-slate-900 mb-2">My Orders</h1>
      <p className="text-slate-500 mb-8">Track current orders and view past purchases.</p>

      {loading ? (
        <div className="space-y-4 animate-pulse">
          {[1, 2, 3].map(i => (
            <div key={i} className="h-40 bg-slate-100 rounded-2xl"></div>
          ))}
        </div>
      ) : orders.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-3xl border border-dashed border-slate-200">
          <div className="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center text-slate-400 mx-auto mb-4">
            <Box className="w-8 h-8" />
          </div>
          <h3 className="text-lg font-bold text-slate-900 mb-1">No orders yet</h3>
          <p className="text-slate-500 text-sm mb-6">Start shopping to see your orders here.</p>
          <a href="/shop" className="inline-flex items-center justify-center px-6 py-2.5 bg-indigo-600 text-white font-bold rounded-xl text-sm shadow-md hover:bg-indigo-700 transition-colors">
            Browse Products
          </a>
        </div>
      ) : (
        <div className="space-y-6">
          {orders.map((order) => (
            <div key={order.id} className="bg-white border border-slate-100 rounded-2xl shadow-sm overflow-hidden hover:shadow-md transition-shadow">
              {/* Order Header */}
              <div className="bg-slate-50/50 p-6 border-b border-slate-100 flex flex-col md:flex-row justify-between md:items-center gap-4">
                <div className="flex flex-col gap-1">
                  <div className="flex items-center gap-3">
                    <span className="font-bold text-slate-900 text-lg">#{order.orderId || order.id.slice(0, 8)}</span>
                    <span className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border uppercase tracking-wide ${getStatusColor(order.status)}`}>
                      {getStatusIcon(order.status)} {order.status || 'Processing'}
                    </span>
                  </div>
                  <div className="flex items-center gap-4 text-xs text-slate-500 font-medium ml-1">
                    <span className="flex items-center gap-1"><Calendar className="w-3 h-3" /> {formatDate(order.createdAt)}</span>
                    <span className="flex items-center gap-1">Payment: {order.customer?.paymentMethod || 'Online'}</span>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-xs text-slate-400 uppercase font-bold tracking-wide">Total Amount</p>
                  <p className="text-xl font-bold text-slate-900">{formatCurrency(order.total || 0)}</p>
                </div>
              </div>

              {/* Order Items */}
              <div className="p-6">
                <div className="space-y-6">
                  {(order.items || []).map((item, index) => {
                    const product = productById[item.productId || item.id]
                    return (
                      <div key={index} className="flex gap-4 items-start">
                        <div className="w-16 h-16 bg-slate-100 rounded-xl border border-slate-200 flex-shrink-0 overflow-hidden">
                          <img
                            src={item.image || product?.imageUrl || '/sample-product.jpg'}
                            alt={item.name}
                            onError={(event) => {
                              event.currentTarget.onerror = null
                              event.currentTarget.src = '/sample-product.jpg'
                            }}
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex justify-between items-start">
                            <h4 className="font-bold text-slate-900 truncate pr-2">{item.name || product?.name || 'Product'}</h4>
                            <span className="font-bold text-slate-700 text-sm whitespace-nowrap">
                              {formatCurrency((item.unitPrice ?? item.price ?? 0) * (item.qty ?? 1))}
                            </span>
                          </div>
                          <p className="text-sm text-slate-500 mt-0.5">Qty: {item.qty}</p>

                          {/* Dynamic Action Buttons based on context could go here */}
                          <div className="mt-2 flex gap-3">
                            <button className="text-xs font-bold text-indigo-600 hover:text-indigo-700 flex items-center gap-1">
                              <RefreshCcw className="w-3 h-3" /> Buy Again
                            </button>
                          </div>
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>

              {/* Footer / Actions */}
              <div className="px-6 py-4 bg-slate-50 border-t border-slate-100 flex justify-between items-center text-sm">
                <button className="text-slate-500 hover:text-slate-800 font-medium transition-colors">
                  View Invoice
                </button>
                <button className="text-indigo-600 hover:text-indigo-800 font-bold transition-colors">
                  Track Shipment
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

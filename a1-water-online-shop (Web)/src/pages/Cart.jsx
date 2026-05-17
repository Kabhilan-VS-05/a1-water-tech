import { Link } from 'react-router-dom'
import { ShoppingCart, Trash2, Plus, Minus, ShieldCheck, ArrowRight } from 'lucide-react'
import { useCart } from '../state/CartContext.jsx'
import { useSiteSettings } from '../state/SiteSettingsContext.jsx'
import { formatCurrency } from '../utils/format.js'

export default function Cart() {
  const { items, updateItem, removeItem, subtotal } = useCart()
  const settings = useSiteSettings()
  const gstRate   = settings.gstEnabled ? settings.gstRate : 0
  const gstAmount = subtotal * gstRate
  const total     = subtotal + gstAmount
  const gstLabel  = gstRate > 0 ? `GST (${(gstRate * 100).toFixed(0)}%)` : 'GST'

  if (items.length === 0) {
    return (
      <div className="page-bg">
        <div className="container mx-auto px-4 max-w-2xl py-20 text-center">
          <div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center text-slate-400 mx-auto mb-5">
            <ShoppingCart className="w-7 h-7" />
          </div>
          <h2 className="text-xl font-bold text-slate-900 mb-2">Your cart is empty</h2>
          <p className="text-sm text-slate-500 mb-6">Add products to your cart to proceed with an order.</p>
          <Link to="/shop" className="btn-primary px-6 py-2.5 text-sm">
            Browse Products <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="page-bg">
      <div className="container mx-auto px-4 max-w-6xl py-8">
        <h1 className="text-2xl font-bold text-slate-900 mb-6">Shopping Cart</h1>

        <div className="flex flex-col lg:flex-row gap-8 items-start">
          {/* Cart items */}
          <div className="flex-1 space-y-3">
            {items.map(item => (
              <div key={item.id} className="card p-4 flex gap-4 items-center">
                <div className="w-16 h-16 bg-slate-50 rounded-lg overflow-hidden flex-shrink-0 border border-slate-100">
                  <img
                    src={item.imageUrl || '/sample-product.jpg'}
                    alt={item.name}
                    onError={e => { e.currentTarget.onerror = null; e.currentTarget.src = '/sample-product.jpg' }}
                    className="w-full h-full object-cover"
                  />
                </div>

                <div className="flex-1 min-w-0">
                  <h3 className="text-sm font-semibold text-slate-800 truncate">{item.name}</h3>
                  {item.category && <p className="text-xs text-slate-400 mt-0.5">{item.category}</p>}
                  <div className="text-sm font-bold text-indigo-600 mt-1">{formatCurrency(item.price)}</div>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => updateItem(item.id, item.qty - 1)}
                    className="w-7 h-7 rounded-md border border-slate-200 flex items-center justify-center hover:bg-slate-50 transition-colors text-slate-600"
                  >
                    <Minus className="w-3 h-3" />
                  </button>
                  <span className="w-7 text-center text-sm font-semibold text-slate-800">{item.qty}</span>
                  <button
                    onClick={() => updateItem(item.id, item.qty + 1)}
                    className="w-7 h-7 rounded-md border border-slate-200 flex items-center justify-center hover:bg-slate-50 transition-colors text-slate-600"
                  >
                    <Plus className="w-3 h-3" />
                  </button>
                </div>

                <div className="text-sm font-bold text-slate-900 w-20 text-right">
                  {formatCurrency(item.price * item.qty)}
                </div>

                <button
                  onClick={() => removeItem(item.id)}
                  className="p-1.5 text-slate-300 hover:text-red-500 transition-colors"
                  title="Remove"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            ))}
          </div>

          {/* Order summary */}
          <div className="lg:w-72 flex-shrink-0 w-full">
            <div className="card p-5 sticky top-20">
              <h2 className="text-base font-bold text-slate-900 mb-4">Order Summary</h2>

              <div className="space-y-3 text-sm mb-4">
                <div className="flex justify-between text-slate-600">
                  <span>Subtotal ({items.length} {items.length === 1 ? 'item' : 'items'})</span>
                  <span className="font-medium text-slate-800">{formatCurrency(subtotal)}</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>{gstLabel}</span>
                  <span className="font-medium text-slate-800">{formatCurrency(gstAmount)}</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>Delivery</span>
                  <span className="font-medium text-emerald-600">Free</span>
                </div>
                <hr className="divider" />
                <div className="flex justify-between font-bold text-slate-900 text-base">
                  <span>Total</span>
                  <span>{formatCurrency(total)}</span>
                </div>
              </div>

              <Link
                to="/checkout"
                className="btn-primary w-full justify-center py-2.5 text-sm"
              >
                Proceed to Checkout
              </Link>

              <div className="flex items-center justify-center gap-1.5 mt-3 text-xs text-slate-400">
                <ShieldCheck className="w-3.5 h-3.5" />
                Secure, encrypted checkout
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

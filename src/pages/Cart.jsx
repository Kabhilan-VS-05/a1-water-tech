import { Link } from 'react-router-dom'
import { ShoppingCart, ArrowLeft, Trash2, Plus, Minus, ShieldCheck } from 'lucide-react'
import { useCart } from '../state/CartContext.jsx'
import { formatCurrency } from '../utils/format.js'

export default function Cart() {
  const { items, updateItem, removeItem, subtotal } = useCart()

  if (items.length === 0) {
    return (
      <div className="container mx-auto px-4 py-20 text-center font-sans">
        <div className="w-20 h-20 bg-slate-100 rounded-full flex items-center justify-center text-slate-400 mx-auto mb-6">
          <ShoppingCart className="w-10 h-10" />
        </div>
        <h2 className="text-2xl font-bold text-slate-900 mb-2">Your cart is empty</h2>
        <p className="text-slate-500 mb-8 max-w-sm mx-auto">Looks like you haven't added anything to your cart yet.</p>
        <Link to="/shop" className="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-3 rounded-xl font-bold transition-all shadow-lg hover:shadow-indigo-500/30">
          Start Shopping <ArrowLeft className="w-4 h-4 rotate-180" />
        </Link>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-8 lg:py-12 max-w-7xl font-sans">
      <h1 className="text-3xl font-bold text-slate-900 mb-8">Shopping Cart</h1>

      <div className="flex flex-col lg:flex-row gap-12">
        {/* Cart Items */}
        <div className="flex-1 space-y-6">
          {items.map((item) => (
            <div key={item.id} className="flex flex-col sm:flex-row items-start sm:items-center gap-6 p-6 bg-white border border-slate-100 rounded-2xl shadow-sm hover:shadow-md transition-shadow">
              <div className="w-24 h-24 bg-slate-50 rounded-xl flex-shrink-0 border border-slate-100 overflow-hidden">
                <img
                  src={item.imageUrl || '/sample-product.jpg'}
                  alt={item.name}
                  onError={(event) => {
                    event.currentTarget.onerror = null
                    event.currentTarget.src = '/sample-product.jpg'
                  }}
                  className="w-full h-full object-cover"
                />
              </div>

              <div className="flex-1 min-w-0">
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-bold text-slate-900 truncate pr-4">{item.name}</h3>
                  <p className="font-bold text-slate-900">{formatCurrency(item.price * item.qty)}</p>
                </div>
                <p className="text-sm text-slate-500 mb-4">{item.category}</p>

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3 bg-slate-50 rounded-lg p-1 border border-slate-200/50">
                    <button
                      onClick={() => updateItem(item.id, item.qty - 1)}
                      className="w-8 h-8 flex items-center justify-center bg-white rounded-md shadow-sm hover:bg-slate-100 text-slate-600 disabled:opacity-50 transition-colors"
                    >
                      <Minus className="w-4 h-4" />
                    </button>
                    <span className="w-8 text-center font-bold text-slate-700">{item.qty}</span>
                    <button
                      onClick={() => updateItem(item.id, item.qty + 1)}
                      className="w-8 h-8 flex items-center justify-center bg-white rounded-md shadow-sm hover:bg-slate-100 text-slate-600 transition-colors"
                    >
                      <Plus className="w-4 h-4" />
                    </button>
                  </div>

                  <button
                    onClick={() => removeItem(item.id)}
                    className="text-red-500 hover:text-red-700 text-sm font-medium flex items-center gap-1 px-3 py-1.5 hover:bg-red-50 rounded-lg transition-colors"
                  >
                    <Trash2 className="w-4 h-4" /> Remove
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Order Summary */}
        <div className="lg:w-96 flex-shrink-0">
          <div className="bg-white p-8 rounded-3xl border border-slate-100 shadow-lg sticky top-24">
            <h2 className="text-xl font-bold text-slate-900 mb-6">Order Summary</h2>

            <div className="space-y-4 mb-8">
              <div className="flex justify-between text-slate-600">
                <span>Subtotal</span>
                <span className="font-medium text-slate-900">{formatCurrency(subtotal)}</span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>GST (18%)</span>
                <span className="font-medium text-slate-900">{formatCurrency(subtotal * 0.18)}</span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>Delivery</span>
                <span className="text-green-600 font-medium">Free</span>
              </div>
              <div className="h-px bg-slate-100 my-4" />
              <div className="flex justify-between text-lg font-bold text-slate-900">
                <span>Total</span>
                <span>{formatCurrency(subtotal * 1.18)}</span>
              </div>
            </div>

            <Link to="/checkout" className="block w-full bg-slate-900 hover:bg-indigo-600 text-white text-center py-4 rounded-xl font-bold text-lg shadow-xl shadow-slate-200 hover:shadow-indigo-200 transition-all transform active:scale-95">
              Proceed to Checkout
            </Link>

            <p className="text-xs text-slate-400 text-center mt-4 flex items-center justify-center gap-1">
              <ShieldCheck className="w-3 h-3" /> Secure Checkout
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

import { Link } from 'react-router-dom'
import { Star, ShoppingCart, Check } from 'lucide-react'
import { useCart } from '../state/CartContext.jsx'
import { useToast } from '../state/ToastContext.jsx'
import { formatCurrency } from '../utils/format.js'
import { useState } from 'react'

export default function ProductCard({ product }) {
  const { addItem } = useCart()
  const { showToast } = useToast()
  const [adding, setAdding] = useState(false)

  const handleAdd = () => {
    setAdding(true)
    addItem(product.id)
    showToast(`${product.name} added to cart`)
    setTimeout(() => setAdding(false), 800)
  }

  return (
    <div className="group bg-white rounded-2xl border border-slate-100 shadow-sm hover:shadow-xl hover:border-slate-200 transition-all duration-300 flex flex-col h-full overflow-hidden">
      {/* Image Container */}
      <div className="relative aspect-[4/3] overflow-hidden bg-slate-50">
        <Link to={`/shop/${product.id}`} className="block h-full w-full">
          <img
            src={product.imageUrl || '/sample-product.jpg'}
            alt={product.name}
            onError={(event) => {
              event.currentTarget.onerror = null
              event.currentTarget.src = '/sample-product.jpg'
            }}
            className="h-full w-full object-cover transition-transform duration-700 group-hover:scale-110"
          />
        </Link>
        {product.tag && (
          <span className="absolute top-3 left-3 bg-indigo-600 text-white text-[10px] uppercase font-bold px-2 py-1 rounded-full tracking-wide shadow-md">
            {product.tag}
          </span>
        )}
      </div>

      {/* Content */}
      <div className="p-5 flex flex-col flex-1">
        <div className="flex justify-between items-start gap-2 mb-2">
          <Link to={`/shop/${product.id}`} className="block">
            <h3 className="font-bold text-slate-900 leading-snug group-hover:text-indigo-600 transition-colors line-clamp-2">
              {product.name}
            </h3>
          </Link>
          <div className="flex items-center gap-1 bg-amber-50 px-1.5 py-0.5 rounded text-amber-700 flex-shrink-0">
            <span className="text-xs font-bold">{product.rating}</span>
            <Star className="w-3 h-3 fill-amber-500 text-amber-500" />
          </div>
        </div>

        <p className="text-xs text-slate-500 mb-4 line-clamp-2">{product.description}</p>

        <div className="mt-auto flex items-end justify-between gap-3">
          <div>
            <span className="text-xs text-slate-400 font-medium">Price</span>
            <p className="text-lg font-bold text-slate-900">{formatCurrency(product.price)}</p>
          </div>

          <button
            onClick={handleAdd}
            disabled={adding}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-lg text-sm font-semibold transition-all ${adding
                ? 'bg-green-100 text-green-700 cursor-default'
                : 'bg-slate-900 text-white hover:bg-indigo-600 shadow-md hover:shadow-indigo-200 active:scale-95'
              }`}
          >
            {adding ? (
              <>
                <Check className="w-4 h-4" /> Added
              </>
            ) : (
              <>
                <ShoppingCart className="w-4 h-4" /> Add
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  )
}

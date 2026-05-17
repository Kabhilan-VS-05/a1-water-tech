import { Link } from 'react-router-dom'
import { Star, ShoppingCart, Check } from 'lucide-react'
import { useCart } from '../state/CartContext.jsx'
import { useToast } from '../state/ToastContext.jsx'
import { formatCurrency } from '../utils/format.js'
import { useState } from 'react'
import { getProductImage, handleImageError } from '../utils/imageUtils.js'

export default function ProductCard({ product }) {
  const { addItem } = useCart()
  const { showToast } = useToast()
  const [adding, setAdding] = useState(false)

  const handleAdd = async (e) => {
    e.preventDefault()
    e.stopPropagation()
    setAdding(true)
    try {
      await addItem(product.id)
      showToast(`${product.name} added to cart`)
      setTimeout(() => setAdding(false), 1200)
    } catch {
      showToast('Unable to add item. Please try again.', 'error')
      setAdding(false)
    }
  }

  return (
    <div className="card flex flex-col h-full overflow-hidden group">
      {/* Image */}
      <div className="relative aspect-[4/3] overflow-hidden bg-slate-100">
        <Link to={`/shop/${product.id}`} className="block w-full h-full">
          <img
            src={getProductImage(product)}
            alt={product.name}
            onError={(e) => handleImageError(e, 'product')}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          />
        </Link>

        {product.category && (
          <span className="absolute top-3 left-3 badge badge-neutral text-[10px] bg-white/90 backdrop-blur-sm">
            {product.category}
          </span>
        )}

        <button
          onClick={handleAdd}
          disabled={adding}
          className={`absolute bottom-3 right-3 w-9 h-9 rounded-lg flex items-center justify-center shadow-md transition-all duration-200 active:scale-95 ${
            adding
              ? 'bg-emerald-500 text-white'
              : 'bg-white text-slate-700 hover:bg-indigo-600 hover:text-white'
          }`}
          title="Add to cart"
        >
          {adding ? <Check className="w-4 h-4" /> : <ShoppingCart className="w-4 h-4" />}
        </button>
      </div>

      {/* Content */}
      <div className="p-4 flex flex-col flex-1">
        <div className="flex items-start justify-between gap-2 mb-1.5">
          <Link to={`/shop/${product.id}`} className="flex-1 min-w-0">
            <h3 className="text-sm font-semibold text-slate-800 leading-snug line-clamp-2 group-hover:text-indigo-600 transition-colors">
              {product.name}
            </h3>
          </Link>
        </div>

        {product.description && (
          <p className="text-xs text-slate-400 mb-3 line-clamp-2 leading-relaxed">
            {product.description}
          </p>
        )}

        <div className="mt-auto pt-3 border-t border-slate-50 flex items-center justify-between">
          <div>
            <div className="text-xs text-slate-400">Price</div>
            <div className="text-base font-bold text-indigo-600">{formatCurrency(product.price)}</div>
          </div>
          <span className="badge badge-success text-[10px]">In Stock</span>
        </div>
      </div>
    </div>
  )
}

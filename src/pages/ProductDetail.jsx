import { Link, useParams } from 'react-router-dom'
import { ArrowLeft, Check, Star, ShoppingCart, Truck, ShieldCheck, Box } from 'lucide-react'
import useProducts from '../hooks/useProducts.js'
import { useCart } from '../state/CartContext.jsx'
import { useToast } from '../state/ToastContext.jsx'
import { formatCurrency } from '../utils/format.js'
import { useState } from 'react'

export default function ProductDetail() {
  const { id } = useParams()
  const { addItem } = useCart()
  const { showToast } = useToast()
  const { items: products } = useProducts()
  const product = products.find((entry) => entry.id === id)
  const [adding, setAdding] = useState(false)

  if (!product) {
    return (
      <div className="container mx-auto px-4 py-20 text-center">
        <h2 className="text-2xl font-bold text-slate-900 mb-4">Product Not Found</h2>
        <Link to="/shop" className="text-indigo-600 hover:text-indigo-700 font-semibold flex items-center justify-center gap-2">
          <ArrowLeft className="w-4 h-4" /> Back to Shop
        </Link>
      </div>
    )
  }

  const handleAdd = () => {
    setAdding(true)
    addItem(product.id)
    showToast(`${product.name} added to cart`)
    setTimeout(() => setAdding(false), 800)
  }

  return (
    <div className="container mx-auto px-4 py-8 max-w-7xl font-sans">
      <div className="flex items-center gap-2 text-sm text-slate-500 mb-8">
        <Link to="/shop" className="hover:text-indigo-600 transition-colors">Shop</Link>
        <span>/</span>
        <span className="text-slate-900 font-medium truncate">{product.name}</span>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 mb-16">
        {/* Product Image */}
        <div className="bg-white rounded-3xl p-8 border border-slate-100 shadow-sm flex items-center justify-center relative overflow-hidden group">
          <div className="absolute inset-0 bg-slate-50/50 z-0" />
          <img
            src={product.imageUrl || '/sample-product.jpg'}
            alt={product.name}
            onError={(event) => {
              event.currentTarget.onerror = null
              event.currentTarget.src = '/sample-product.jpg'
            }}
            className="w-full max-w-md object-contain relative z-10 transition-transform duration-500 group-hover:scale-105"
          />
          {product.tag && (
            <span className="absolute top-6 left-6 z-20 bg-indigo-600 text-white text-xs font-bold px-3 py-1.5 rounded-full uppercase tracking-wider shadow-lg shadow-indigo-200">
              {product.tag}
            </span>
          )}
        </div>

        {/* Product Info */}
        <div className="flex flex-col">
          <h1 className="text-3xl lg:text-4xl font-bold text-slate-900 mb-4 leading-tight">{product.name}</h1>

          <div className="flex items-center gap-4 mb-6">
            <div className="flex items-center gap-1 bg-amber-50 text-amber-700 px-2 py-1 rounded-md font-bold text-sm">
              <span>{product.rating}</span>
              <Star className="w-4 h-4 fill-amber-500 text-amber-500" />
            </div>
            <span className="text-slate-400 text-sm border-l border-slate-200 pl-4">{product.category}</span>
            <span className="text-green-600 text-sm font-medium flex items-center gap-1 border-l border-slate-200 pl-4">
              <Check className="w-4 h-4" /> In Stock
            </span>
          </div>

          <div className="text-4xl font-bold text-slate-900 mb-2">{formatCurrency(product.price)}</div>
          <p className="text-slate-500 text-sm mb-8">Inclusive of all taxes</p>

          <p className="text-slate-600 leading-relaxed mb-8 text-lg">{product.description}</p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
            {product.features.map((feature, i) => (
              <div key={i} className="flex items-start gap-3">
                <div className="mt-1 w-5 h-5 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-600 flex-shrink-0">
                  <Check className="w-3 h-3" />
                </div>
                <span className="text-slate-700 font-medium">{feature}</span>
              </div>
            ))}
          </div>

          <div className="grid grid-cols-2 gap-4 mb-8 border-t border-b border-slate-100 py-6">
            <div className="flex items-center gap-3">
              <ShieldCheck className="w-6 h-6 text-slate-400" />
              <div>
                <p className="text-xs text-slate-500 uppercase font-bold tracking-wide">Warranty</p>
                <p className="font-semibold text-slate-900">{product.warranty}</p>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <Box className="w-6 h-6 text-slate-400" />
              <div>
                <p className="text-xs text-slate-500 uppercase font-bold tracking-wide">Suitability</p>
                <p className="font-semibold text-slate-900">{product.tds}</p>
              </div>
            </div>
          </div>

          <button
            onClick={handleAdd}
            disabled={adding}
            className={`w-full md:w-auto md:min-w-[200px] py-4 px-8 rounded-xl font-bold text-lg flex items-center justify-center gap-3 transition-all transform active:scale-95 ${adding
                ? 'bg-green-600 text-white cursor-default shadow-lg shadow-green-200'
                : 'bg-indigo-600 hover:bg-indigo-700 text-white shadow-xl shadow-indigo-200 hover:shadow-indigo-300'
              }`}
          >
            {adding ? (
              <>
                <Check className="w-6 h-6" /> Added to Cart
              </>
            ) : (
              <>
                <ShoppingCart className="w-6 h-6" /> Add to Cart
              </>
            )}
          </button>
        </div>
      </div>

      {/* Additional Info / Tabs placeholder */}
      <div className="bg-slate-50 rounded-3xl p-8 lg:p-12">
        <h3 className="text-2xl font-bold text-slate-900 mb-6">Why choose this product?</h3>
        <p className="text-slate-600 max-w-3xl mb-8">{product.recommendation}</p>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="bg-white p-6 rounded-2xl shadow-sm">
            <Truck className="w-8 h-8 text-indigo-600 mb-4" />
            <h4 className="font-bold text-slate-900 mb-2">Free Delivery</h4>
            <p className="text-sm text-slate-500">We ship across Tamil Nadu with no extra cost.</p>
          </div>
          <div className="bg-white p-6 rounded-2xl shadow-sm">
            <ShieldCheck className="w-8 h-8 text-indigo-600 mb-4" />
            <h4 className="font-bold text-slate-900 mb-2">Extended Warranty</h4>
            <p className="text-sm text-slate-500">Upgrade your warranty with our Care Plans.</p>
          </div>
          <div className="bg-white p-6 rounded-2xl shadow-sm">
            <Box className="w-8 h-8 text-indigo-600 mb-4" />
            <h4 className="font-bold text-slate-900 mb-2">Easy Returns</h4>
            <p className="text-sm text-slate-500">7-day replacement for manufacturing defects.</p>
          </div>
        </div>
      </div>

    </div>
  )
}

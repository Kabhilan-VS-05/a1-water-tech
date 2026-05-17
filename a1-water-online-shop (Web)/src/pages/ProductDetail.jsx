import { Link, useParams } from 'react-router-dom'
import { ArrowLeft, Check, Star, ShoppingCart, Truck, ShieldCheck, Box } from 'lucide-react'
import useProducts from '../hooks/useProducts.js'
import { useCart } from '../state/CartContext.jsx'
import { useToast } from '../state/ToastContext.jsx'
import { formatCurrency } from '../utils/format.js'
import { useState } from 'react'
import { getProductImage, handleImageError } from '../utils/imageUtils.js'

export default function ProductDetail() {
  const { id } = useParams()
  const { addItem } = useCart()
  const { showToast } = useToast()
  const { items: products } = useProducts()
  const product = products.find(p => p.id === id)
  const [adding, setAdding] = useState(false)

  if (!product) {
    return (
      <div className="page-bg">
        <div className="container mx-auto px-4 py-20 text-center">
          <h2 className="text-xl font-bold text-slate-800 mb-3">Product Not Found</h2>
          <Link to="/shop" className="btn-secondary text-sm inline-flex items-center gap-2">
            <ArrowLeft className="w-4 h-4" /> Back to Shop
          </Link>
        </div>
      </div>
    )
  }

  const handleAdd = async () => {
    setAdding(true)
    try {
      await addItem(product.id)
      showToast(`${product.name} added to cart`)
      setTimeout(() => setAdding(false), 1000)
    } catch {
      showToast('Unable to add item. Please try again.', 'error')
      setAdding(false)
    }
  }

  return (
    <div className="page-bg">
      <div className="container mx-auto px-4 max-w-6xl py-8">

        {/* Breadcrumb */}
        <div className="flex items-center gap-1.5 text-xs text-slate-400 mb-6">
          <Link to="/shop" className="hover:text-indigo-600 transition-colors font-medium">Shop</Link>
          <span>/</span>
          <span className="text-slate-600 font-medium truncate max-w-xs">{product.name}</span>
        </div>

        {/* Main product section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          {/* Image */}
          <div className="card p-6 flex items-center justify-center bg-white min-h-[320px] relative overflow-hidden">
            <img
              src={getProductImage(product)}
              alt={product.name}
              onError={e => handleImageError(e, 'product')}
              className="max-w-full max-h-72 object-contain"
            />
            {product.tag && (
              <span className="absolute top-4 left-4 badge badge-primary text-xs">
                {product.tag}
              </span>
            )}
          </div>

          {/* Info */}
          <div className="flex flex-col gap-5">
            <div>
              <h1 className="text-2xl font-bold text-slate-900 mb-2 leading-snug">{product.name}</h1>
              <div className="flex flex-wrap items-center gap-3 text-sm">
                {product.category && (
                  <span className="badge badge-neutral">{product.category}</span>
                )}
                <span className="badge badge-success flex items-center gap-1">
                  <Check className="w-3 h-3" /> In Stock
                </span>
              </div>
            </div>

            <div>
              <div className="text-3xl font-bold text-slate-900">{formatCurrency(product.price)}</div>
              <div className="text-xs text-slate-400 mt-1">Inclusive of all applicable taxes</div>
            </div>

            {product.description && (
              <p className="text-sm text-slate-600 leading-relaxed">{product.description}</p>
            )}

            {product.features?.length > 0 && (
              <div className="space-y-2">
                {product.features.map((f, i) => (
                  <div key={i} className="flex items-center gap-2 text-sm text-slate-700">
                    <div className="w-4 h-4 bg-indigo-50 rounded-full flex items-center justify-center flex-shrink-0">
                      <Check className="w-2.5 h-2.5 text-indigo-600" />
                    </div>
                    {f}
                  </div>
                ))}
              </div>
            )}

            {/* Specs strip */}
            {(product.warranty || product.tds) && (
              <div className="grid grid-cols-2 gap-3 py-4 border-t border-b border-slate-100">
                {product.warranty && (
                  <div className="flex items-center gap-2.5">
                    <ShieldCheck className="w-5 h-5 text-slate-400 flex-shrink-0" />
                    <div>
                      <div className="text-[10px] font-semibold text-slate-400 uppercase tracking-wide">Warranty</div>
                      <div className="text-sm font-semibold text-slate-800">{product.warranty}</div>
                    </div>
                  </div>
                )}
                {product.tds && (
                  <div className="flex items-center gap-2.5">
                    <Box className="w-5 h-5 text-slate-400 flex-shrink-0" />
                    <div>
                      <div className="text-[10px] font-semibold text-slate-400 uppercase tracking-wide">Suitability</div>
                      <div className="text-sm font-semibold text-slate-800">{product.tds}</div>
                    </div>
                  </div>
                )}
              </div>
            )}

            <button
              onClick={handleAdd}
              disabled={adding}
              className={`btn-primary py-3 px-8 text-sm justify-center w-full sm:w-auto ${
                adding ? 'bg-emerald-500 cursor-default' : ''
              }`}
            >
              {adding ? (
                <><Check className="w-4 h-4" /> Added to Cart</>
              ) : (
                <><ShoppingCart className="w-4 h-4" /> Add to Cart</>
              )}
            </button>
          </div>
        </div>

        {/* Why choose */}
        {product.recommendation && (
          <div className="card p-6 mb-6">
            <h3 className="text-base font-bold text-slate-900 mb-2">Why this product?</h3>
            <p className="text-sm text-slate-600 leading-relaxed">{product.recommendation}</p>
          </div>
        )}

        {/* Benefits */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
          {[
            { icon: Truck, title: 'Free Delivery', desc: 'Shipped across Tamil Nadu at no extra cost.' },
            { icon: ShieldCheck, title: 'Extended Warranty', desc: 'Upgrade your warranty with our Care Plans.' },
            { icon: Box, title: 'Easy Returns', desc: '7-day replacement for manufacturing defects.' },
          ].map(b => (
            <div key={b.title} className="card p-4 flex items-start gap-3">
              <div className="w-9 h-9 bg-indigo-50 rounded-lg flex items-center justify-center flex-shrink-0">
                <b.icon className="w-4 h-4 text-indigo-600" />
              </div>
              <div>
                <div className="text-sm font-semibold text-slate-800">{b.title}</div>
                <div className="text-xs text-slate-500 mt-0.5">{b.desc}</div>
              </div>
            </div>
          ))}
        </div>



      </div>
    </div>
  )
}

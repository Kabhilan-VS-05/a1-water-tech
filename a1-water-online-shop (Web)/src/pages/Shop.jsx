import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Search, AlertCircle, SlidersHorizontal, X } from 'lucide-react'
import ProductCard from '../components/ProductCard.jsx'
import useProducts from '../hooks/useProducts.js'

const priceOptions = [
  { label: 'All Prices', value: 'all' },
  { label: 'Under ₹5,000', value: '0-5000' },
  { label: '₹5,000 – ₹15,000', value: '5000-15000' },
  { label: '₹15,000 – ₹30,000', value: '15000-30000' },
  { label: 'Above ₹30,000', value: '30000-999999' },
]

export default function Shop() {
  const [searchParams] = useSearchParams()
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('All')
  const [priceRange, setPriceRange] = useState('all')
  const [showFilters, setShowFilters] = useState(false)
  const { items: products, loading, error } = useProducts()

  const categories = useMemo(
    () => ['All', ...new Set(products.map(p => p.category).filter(Boolean))],
    [products]
  )

  useEffect(() => {
    const cat = searchParams.get('category')
    const q   = searchParams.get('q')
    if (cat && categories.includes(cat)) setCategory(cat)
    else if (!cat) setCategory('All')
    setQuery(q || '')
  }, [searchParams, categories])

  const filtered = useMemo(() => {
    const [min, max] =
      priceRange === 'all' ? [0, Number.MAX_SAFE_INTEGER] : priceRange.split('-').map(Number)
    return products.filter(p => {
      const matchQ   = p.name.toLowerCase().includes(query.trim().toLowerCase())
      const matchCat = category === 'All' || p.category === category
      const matchP   = p.price >= min && p.price <= max
      return matchQ && matchCat && matchP
    })
  }, [query, category, priceRange, products])

  const resetFilters = () => { setQuery(''); setCategory('All'); setPriceRange('all') }
  const hasFilters = query || category !== 'All' || priceRange !== 'all'

  return (
    <div className="page-bg">
      <div className="container mx-auto px-4 max-w-7xl py-8">

        {/* Page header */}
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-slate-900">Shop</h1>
          <p className="text-sm text-slate-500 mt-1">Water purifiers, filters, and accessories</p>
        </div>

        {/* Search + filter row */}
        <div className="flex flex-col sm:flex-row gap-3 mb-6">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder="Search products..."
              className="input pl-9 py-2.5"
            />
            {query && (
              <button onClick={() => setQuery('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`lg:hidden btn-secondary px-4 py-2.5 gap-2 ${showFilters ? 'border-indigo-600 text-indigo-600 bg-indigo-50' : ''}`}
          >
            <SlidersHorizontal className="w-4 h-4" />
            Filters
            {hasFilters && <span className="w-2 h-2 rounded-full bg-indigo-600 ml-1" />}
          </button>
          {hasFilters && (
            <button onClick={resetFilters} className="text-sm text-slate-500 hover:text-rose-600 transition-colors hidden lg:block">
              Clear filters
            </button>
          )}
        </div>

        <div className="flex flex-col lg:flex-row gap-6">
          {/* Sidebar */}
          <aside className={`w-full lg:w-56 flex-shrink-0 space-y-6 bg-white lg:bg-transparent p-5 lg:p-0 rounded-2xl border border-slate-100 lg:border-none ${showFilters ? 'block' : 'hidden lg:block'}`}>

            {hasFilters && (
              <div className="lg:hidden flex items-center justify-between pb-3 border-b border-slate-100">
                <span className="text-xs font-bold text-slate-950 uppercase tracking-wider">Filters Active</span>
                <button onClick={resetFilters} className="text-xs font-bold text-rose-600 hover:text-rose-800 transition-colors">
                  Clear All
                </button>
              </div>
            )}

            {/* Categories */}
            <div>
              <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2 px-1">Category</div>
              <div className="space-y-0.5">
                {categories.map(cat => (
                  <button
                    key={cat}
                    onClick={() => setCategory(cat)}
                    className={`w-full text-left px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                      category === cat
                        ? 'bg-indigo-50 text-indigo-600'
                        : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
                    }`}
                  >
                    {cat}
                  </button>
                ))}
              </div>
            </div>

            <hr className="divider" />

            {/* Price */}
            <div>
              <div className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-2 px-1">Price Range</div>
              <div className="space-y-0.5">
                {priceOptions.map(opt => (
                  <button
                    key={opt.value}
                    onClick={() => setPriceRange(opt.value)}
                    className={`w-full text-left px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                      priceRange === opt.value
                        ? 'bg-indigo-50 text-indigo-600'
                        : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
                    }`}
                  >
                    {opt.label}
                  </button>
                ))}
              </div>
            </div>

            {hasFilters && (
              <button onClick={resetFilters} className="w-full text-sm text-rose-500 hover:text-rose-700 font-medium px-3 py-2 text-left">
                Clear all filters
              </button>
            )}
          </aside>

          {/* Product grid */}
          <div className="flex-1 min-w-0">
            {/* Results count */}
            {!loading && !error && (
              <div className="text-xs text-slate-400 mb-4">
                {filtered.length} {filtered.length === 1 ? 'product' : 'products'} found
              </div>
            )}

            {error ? (
              <div className="card p-10 text-center">
                <AlertCircle className="w-10 h-10 text-red-400 mx-auto mb-3" />
                <h3 className="font-semibold text-slate-800 mb-1">Failed to load products</h3>
                <p className="text-sm text-slate-500 mb-4">{error}</p>
                <button onClick={() => window.location.reload()} className="btn-primary text-sm">
                  Retry
                </button>
              </div>
            ) : loading ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
                {[1, 2, 3, 4, 5, 6].map(i => (
                  <div key={i} className="card aspect-[4/5] animate-pulse bg-slate-100" />
                ))}
              </div>
            ) : filtered.length === 0 ? (
              <div className="card p-12 text-center">
                <Search className="w-10 h-10 text-slate-300 mx-auto mb-3" />
                <h3 className="font-semibold text-slate-800 mb-1">No products found</h3>
                <p className="text-sm text-slate-500 mb-4">Try adjusting your search or filters.</p>
                <button onClick={resetFilters} className="btn-secondary text-sm">
                  Clear filters
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
                {filtered.map(product => (
                  <ProductCard key={product.id} product={product} />
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

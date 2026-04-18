import { useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { Filter, SlidersHorizontal, Search } from 'lucide-react'
import { categories } from '../data/products.js'
import ProductCard from '../components/ProductCard.jsx'
import useProducts from '../hooks/useProducts.js'

const priceOptions = [
  { label: 'All', value: 'all' },
  { label: 'Below ₹5,000', value: '0-5000' },
  { label: '₹5,000 - ₹15,000', value: '5000-15000' },
  { label: '₹15,000 - ₹30,000', value: '15000-30000' },
  { label: 'Above ₹30,000', value: '30000-999999' },
]

export default function Shop() {
  const [searchParams] = useSearchParams()
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('All')
  const [priceRange, setPriceRange] = useState('all')
  const [minRating, setMinRating] = useState('0')
  const { items: products, loading } = useProducts()
  const [showFilters, setShowFilters] = useState(false)

  useEffect(() => {
    const categoryParam = searchParams.get('category')
    const queryParam = searchParams.get('q')

    if (categoryParam && categories.includes(categoryParam)) {
      setCategory(categoryParam)
    } else if (!categoryParam) {
      setCategory('All')
    }

    setQuery(queryParam || '')
  }, [searchParams])

  const filtered = useMemo(() => {
    const [minPrice, maxPrice] =
      priceRange === 'all' ? [0, Number.MAX_SAFE_INTEGER] : priceRange.split('-')

    return products.filter((product) => {
      const matchesQuery = product.name
        .toLowerCase()
        .includes(query.trim().toLowerCase())
      const matchesCategory =
        category === 'All' || product.category === category
      const matchesPrice =
        product.price >= Number(minPrice) && product.price <= Number(maxPrice)
      const matchesRating = product.rating >= Number(minRating)
      return matchesQuery && matchesCategory && matchesPrice && matchesRating
    })
  }, [query, category, priceRange, minRating, products])

  return (
    <div className="container mx-auto px-4 py-8 lg:py-12 max-w-7xl">
      {/* Page Header */}
      <div className="mb-8 md:mb-12">
        <h1 className="text-3xl md:text-4xl font-bold text-slate-900 mb-2">Shop All Products</h1>
        <p className="text-slate-500 max-w-2xl">Browse our complete range of certified water purifiers, replacement filters, and service plans.</p>
      </div>

      <div className="flex flex-col lg:flex-row gap-8">
        {/* Mobile Filter Toggle */}
        <button
          className="lg:hidden flex items-center gap-2 w-full bg-white p-3 rounded-lg border border-slate-200 shadow-sm font-semibold text-slate-700"
          onClick={() => setShowFilters(!showFilters)}
        >
          <SlidersHorizontal className="w-5 h-5" />
          {showFilters ? 'Hide Filters' : 'Show Filters'}
        </button>

        {/* Sidebar Filters */}
        <aside className={`lg:w-64 flex-shrink-0 space-y-8 ${showFilters ? 'block' : 'hidden lg:block'}`}>
          {/* Search */}
          <div className="space-y-3">
            <label className="text-sm font-bold text-slate-900 uppercase tracking-wide">Search</label>
            <div className="relative">
              <input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Model or keyword"
                className="w-full bg-white border border-slate-200 rounded-lg py-2.5 pl-10 pr-4 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
            </div>
          </div>

          {/* Categories */}
          <div className="space-y-3">
            <label className="text-sm font-bold text-slate-900 uppercase tracking-wide">Category</label>
            <div className="space-y-2">
              {categories.map((cat) => (
                <label key={cat} className="flex items-center gap-2 cursor-pointer group">
                  <input
                    type="radio"
                    name="category"
                    checked={category === cat}
                    onChange={() => setCategory(cat)}
                    className="w-4 h-4 text-indigo-600 focus:ring-indigo-500 border-slate-300"
                  />
                  <span className={`text-sm group-hover:text-indigo-600 transition-colors ${category === cat ? 'font-semibold text-indigo-700' : 'text-slate-600'}`}>{cat}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Price */}
          <div className="space-y-3">
            <label className="text-sm font-bold text-slate-900 uppercase tracking-wide">Price Range</label>
            <div className="space-y-2">
              {priceOptions.map((opt) => (
                <label key={opt.value} className="flex items-center gap-2 cursor-pointer group">
                  <input
                    type="radio"
                    name="price"
                    checked={priceRange === opt.value}
                    onChange={() => setPriceRange(opt.value)}
                    className="w-4 h-4 text-indigo-600 focus:ring-indigo-500 border-slate-300"
                  />
                  <span className={`text-sm group-hover:text-indigo-600 transition-colors ${priceRange === opt.value ? 'font-semibold text-indigo-700' : 'text-slate-600'}`}>{opt.label}</span>
                </label>
              ))}
            </div>
          </div>

          {/* Rating */}
          <div className="space-y-3">
            <label className="text-sm font-bold text-slate-900 uppercase tracking-wide">Min Rating</label>
            <select
              value={minRating}
              onChange={(e) => setMinRating(e.target.value)}
              className="w-full bg-white border border-slate-200 rounded-lg py-2 px-3 text-sm focus:outline-none focus:border-indigo-500 cursor-pointer"
            >
              <option value="0">Any Rating</option>
              <option value="4.5">4.5+ Stars</option>
              <option value="4.8">4.8+ Stars</option>
            </select>
          </div>
        </aside>

        {/* Product Grid */}
        <div className="flex-1">
          {loading ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 animate-pulse">
              {[1, 2, 3, 4, 5, 6].map(i => (
                <div key={i} className="aspect-[3/4] bg-slate-200 rounded-2xl"></div>
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <div className="bg-white rounded-2xl p-12 text-center border border-dashed border-slate-300">
              <Filter className="w-12 h-12 text-slate-300 mx-auto mb-4" />
              <h3 className="text-lg font-bold text-slate-900 mb-2">No products found</h3>
              <p className="text-slate-500 max-w-xs mx-auto mb-6">Try adjusting your filters or search query to find what you're looking for.</p>
              <button
                onClick={() => { setQuery(''); setCategory('All'); setPriceRange('all'); }}
                className="text-indigo-600 font-semibold hover:underline"
              >
                Clear all filters
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-6">
              {filtered.map((product) => (
                <ProductCard key={product.id} product={product} />
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

import { useState, useMemo } from 'react'
import { Link, NavLink, useNavigate } from 'react-router-dom'
import { Search, ShoppingCart, User, Menu, X, Phone, Truck, Calendar, MapPin } from 'lucide-react'
import { useCart } from '../state/CartContext.jsx'
import { useAuth } from '../state/AuthContext.jsx'
import brandImage from '../assets/image.png'
import { COMPANY } from '../config/company.js'

export default function Header() {
  const { items } = useCart()
  const { user } = useAuth()
  const navigate = useNavigate()
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')

  const cartCount = useMemo(
    () => items.reduce((sum, item) => sum + item.qty, 0),
    [items]
  )

  const handleSearch = (e) => {
    e.preventDefault()
    if (searchQuery.trim()) {
      navigate(`/shop?q=${encodeURIComponent(searchQuery)}`)
    }
  }

  const navLinks = [
    { name: 'Home', path: '/' },
    { name: 'Shop All', path: '/shop' },
    { name: 'Purifiers', path: '/shop?category=Purifiers' },
    { name: 'Filters & Spares', path: '/shop?category=Filters' },
    { name: 'Commercial', path: '/shop?category=Commercial' },
  ]

  return (
    <header className="sticky top-0 z-50 w-full bg-white shadow-sm border-b border-gray-100 font-sans">
      {/* Top Utility Bar */}
      <div className="bg-slate-900 text-white text-[11px] py-1.5 px-4 hidden md:block">
        <div className="container mx-auto flex justify-between items-center max-w-7xl">
          <div className="flex gap-4">
            <span className="flex items-center gap-1 opacity-90 hover:opacity-100 transition"><Phone className="w-3 h-3" /> {COMPANY.phonePrimary}</span>
            <span className="flex items-center gap-1 opacity-90 hover:opacity-100 transition"><MapPin className="w-3 h-3" /> {COMPANY.locality}</span>
          </div>
          <div className="flex gap-4">
            <Link to="/track" className="hover:text-indigo-200 transition">Track Order</Link>
            <Link to="/orders" className="hover:text-indigo-200 transition">My Orders</Link>
            <Link to={user ? "/profile" : "/login"} className="hover:text-indigo-200 transition">My Account</Link>
          </div>
        </div>
      </div>

      {/* Main Header Row */}
      <div className="container mx-auto px-4 py-3 md:py-4 max-w-7xl">
        <div className="flex items-center justify-between gap-4 md:gap-8">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-2 flex-shrink-0 group">
            <img src={brandImage} alt="A1 Water Tech" className="w-8 h-8 md:w-10 md:h-10 rounded-full object-cover border border-slate-200 group-hover:scale-105 transition-transform" />
            <div className="flex flex-col">
              <span className="text-xl md:text-2xl font-bold text-indigo-950 tracking-tight leading-none">A1 Water Tech</span>
              <span className="text-[10px] md:text-xs text-slate-500 font-medium tracking-wide">Pure Water, Smart Service</span>
            </div>
          </Link>

          {/* Search Bar - Desktop */}
          <div className="hidden md:flex flex-1 max-w-2xl px-4">
            <form onSubmit={handleSearch} className="relative w-full group">
              <input
                type="text"
                placeholder="Search for purifiers, filters, or services..."
                className="w-full bg-slate-50 border border-slate-200 rounded-full py-2.5 pl-5 pr-12 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 transition-all placeholder:text-slate-400 text-slate-700"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
              <button type="submit" className="absolute right-1.5 top-1.5 p-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-full transition-colors cursor-pointer">
                <Search className="w-4 h-4" />
              </button>
            </form>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-3 md:gap-6">
            <Link to="/bookings" className="hidden lg:flex flex-col items-end group">
              <span className="text-[10px] font-semibold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded-full mb-0.5">Free Test</span>
              <span className="text-sm font-medium text-slate-700 group-hover:text-indigo-600 transition-colors flex items-center gap-1">
                Book Service <Calendar className="w-3.5 h-3.5" />
              </span>
            </Link>

            <Link to={user ? "/profile" : "/login"} className="hidden md:flex items-center gap-2 group text-slate-700 hover:text-indigo-600 transition-colors">
              <div className="p-2 bg-slate-50 rounded-full group-hover:bg-indigo-50 transition-colors">
                <User className="w-5 h-5" />
              </div>
              <div className="flex flex-col leading-none">
                <span className="text-[10px] text-slate-500">Hello, {user ? (user.displayName || 'User') : 'Sign In'}</span>
                <span className="text-sm font-semibold">Account</span>
              </div>
            </Link>

            <Link to="/cart" className="relative p-2 text-slate-700 hover:text-indigo-600 transition-colors group">
              <div className="p-2 bg-slate-50 rounded-full group-hover:bg-indigo-50 transition-colors">
                <ShoppingCart className="w-5 h-5" />
              </div>
              {cartCount > 0 && (
                <span className="absolute top-0 right-0 bg-red-500 text-white text-[10px] font-bold w-5 h-5 flex items-center justify-center rounded-full border-2 border-white shadow-sm">
                  {cartCount}
                </span>
              )}
            </Link>

            {/* Mobile Menu Toggle */}
            <button
              className="md:hidden p-2 text-slate-700"
              onClick={() => setIsMenuOpen(!isMenuOpen)}
            >
              {isMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Mobile Search Bar */}
        <div className="mt-3 md:hidden">
          <form onSubmit={handleSearch} className="relative w-full">
            <input
              type="text"
              placeholder="Search products..."
              className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2.5 pl-4 pr-10 text-sm focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            <button type="submit" className="absolute right-3 top-2.5 text-slate-400">
              <Search className="w-4 h-4" />
            </button>
          </form>
        </div>
      </div>

      {/* Navigation Bar (Desktop) */}
      <div className="hidden md:block border-t border-slate-100 bg-white">
        <div className="container mx-auto px-4 max-w-7xl">
          <nav className="flex items-center gap-8 overflow-x-auto no-scrollbar">
            {navLinks.map((link) => (
              <NavLink
                key={link.path}
                to={link.path}
                className={({ isActive }) =>
                  `text-sm font-medium py-3 border-b-2 transition-colors whitespace-nowrap ${isActive
                    ? 'border-indigo-600 text-indigo-600'
                    : 'border-transparent text-slate-600 hover:text-indigo-600 hover:border-indigo-100'
                  }`
                }
              >
                {link.name}
              </NavLink>
            ))}
            <div className="flex-1" />
            <Link to="/bookings" className="text-sm font-medium text-slate-500 hover:text-indigo-600 py-3 transition-colors flex items-center gap-1">
              <Calendar className="w-4 h-4" /> Service Request
            </Link>
            <Link to="/track" className="text-sm font-medium text-slate-500 hover:text-indigo-600 py-3 transition-colors flex items-center gap-1">
              <Truck className="w-4 h-4" /> Track Order
            </Link>
            <Link to="/orders" className="text-sm font-medium text-slate-500 hover:text-indigo-600 py-3 transition-colors">
              My Orders
            </Link>
          </nav>
        </div>
      </div>

      {/* Mobile Menu Dropdown */}
      {isMenuOpen && (
        <div className="md:hidden border-t border-slate-100 bg-white absolute w-full shadow-lg h-[calc(100vh-80px)] overflow-y-auto z-40">
          <div className="p-4 flex flex-col gap-2">
            {navLinks.map((link) => (
              <NavLink
                key={link.path}
                to={link.path}
                onClick={() => setIsMenuOpen(false)}
                className={({ isActive }) =>
                  `flex items-center justify-between p-3 rounded-lg text-sm font-medium transition-colors ${isActive ? 'bg-indigo-50 text-indigo-700' : 'text-slate-700 hover:bg-slate-50'
                  }`
                }
              >
                {link.name}
              </NavLink>
            ))}
            <div className="border-t border-slate-100 my-2 pt-2 flex flex-col gap-1">
              <Link
                to="/profile"
                onClick={() => setIsMenuOpen(false)}
                className="flex items-center gap-3 p-3 text-slate-700 hover:bg-slate-50 rounded-lg"
              >
                <User className="w-5 h-5 text-slate-400" />
                <span className="text-sm font-medium">My Account</span>
              </Link>
              <Link
                to="/orders"
                onClick={() => setIsMenuOpen(false)}
                className="flex items-center gap-3 p-3 text-slate-700 hover:bg-slate-50 rounded-lg"
              >
                <Truck className="w-5 h-5 text-slate-400" />
                <span className="text-sm font-medium">My Orders</span>
              </Link>
              <Link
                to="/bookings"
                onClick={() => setIsMenuOpen(false)}
                className="flex items-center gap-3 p-3 text-slate-700 hover:bg-slate-50 rounded-lg"
              >
                <Calendar className="w-5 h-5 text-slate-400" />
                <span className="text-sm font-medium">Book Service</span>
              </Link>
            </div>
            {!user && (
              <div className="mt-4 p-4 bg-slate-50 rounded-xl text-center">
                <p className="text-sm text-slate-600 mb-3">Sign in for exclusive offers & history</p>
                <Link to="/login" onClick={() => setIsMenuOpen(false)} className="block w-full py-2.5 bg-indigo-600 text-white rounded-full text-sm font-semibold shadow-sm shadow-indigo-200">
                  Login / Sign Up
                </Link>
              </div>
            )}
          </div>
        </div>
      )}
    </header>
  )
}

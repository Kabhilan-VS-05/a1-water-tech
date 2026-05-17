import { useState, useMemo } from 'react'
import { Link, NavLink, useNavigate } from 'react-router-dom'
import { Search, ShoppingCart, User, Menu, X, Phone, MapPin, Calendar, Truck } from 'lucide-react'
import { useCart } from '../state/CartContext.jsx'
import { useAuth } from '../state/AuthContext.jsx'
import { useSiteSettings } from '../state/SiteSettingsContext.jsx'
import brandImage from '../assets/image.png'

export default function Header() {
  const { items } = useCart()
  const { user } = useAuth()
  const settings = useSiteSettings()
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
      setIsMenuOpen(false)
    }
  }

  const navLinks = [
    { name: 'Home', path: '/' },
    { name: 'Book Service', path: '/bookings' },
    { name: 'Care Plans', path: '/services' },
    { name: 'Shop', path: '/shop' },
    { name: 'Contact', path: '/contact' },
  ]

  return (
    <header className="sticky top-0 z-50 bg-white border-b border-slate-100" style={{ boxShadow: '0 1px 4px 0 rgb(0 0 0 / 0.06)' }}>
      {/* Top bar */}
      <div className="hidden md:block bg-slate-900 text-slate-300 text-xs py-2 px-4">
        <div className="container mx-auto max-w-7xl flex items-center justify-between">
          <div className="flex items-center gap-6">
            <span className="flex items-center gap-1.5">
              <Phone className="w-3 h-3 text-indigo-400" />
              {settings.phonePrimary}
            </span>
            <span className="flex items-center gap-1.5">
              <MapPin className="w-3 h-3 text-indigo-400" />
              {settings.locality}
            </span>
          </div>
          <div className="flex items-center gap-5">
            <Link to="/track" className="hover:text-white transition-colors">Track Order</Link>
            <Link to="/orders" className="hover:text-white transition-colors">My Orders</Link>
            {user
              ? <Link to="/profile" className="hover:text-white transition-colors">My Account</Link>
              : <Link to="/login" className="hover:text-white transition-colors">Sign In</Link>
            }
          </div>
        </div>
      </div>

      {/* Main header */}
      <div className="container mx-auto px-4 max-w-7xl">
        <div className="flex items-center gap-6 h-16">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-2.5 flex-shrink-0">
            <img src={brandImage} alt={settings.name} className="w-9 h-9 rounded-lg object-cover" />
            <div>
              <div className="text-base font-bold text-slate-900 leading-none">{settings.name}</div>
              <div className="text-[10px] font-semibold text-indigo-600 uppercase tracking-wide">Water Solutions</div>
            </div>
          </Link>

          {/* Nav links — desktop */}
          <nav className="hidden lg:flex items-center gap-1 ml-4">
            {navLinks.map(link => (
              <NavLink
                key={link.path}
                to={link.path}
                className={({ isActive }) =>
                  `px-3.5 py-2 rounded-lg text-sm font-medium transition-colors ${
                    isActive
                      ? 'bg-indigo-50 text-indigo-600'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-50'
                  }`
                }
              >
                {link.name}
              </NavLink>
            ))}
          </nav>

          {/* Search */}
          <form onSubmit={handleSearch} className="hidden lg:flex flex-1 max-w-sm ml-auto">
            <div className="relative w-full">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                placeholder="Search products or services..."
                className="input pl-9 py-2 text-sm"
              />
            </div>
          </form>

          {/* Actions */}
          <div className="flex items-center gap-2 ml-auto lg:ml-0">
            <Link
              to="/bookings"
              className="hidden md:flex btn-primary text-sm px-4 py-2"
            >
              <Calendar className="w-4 h-4" />
              Book Service
            </Link>

            <Link to="/cart" className="relative p-2 rounded-lg hover:bg-slate-50 transition-colors text-slate-600">
              <ShoppingCart className="w-5 h-5" />
              {cartCount > 0 && (
                <span className="absolute -top-0.5 -right-0.5 bg-indigo-600 text-white text-[10px] font-bold w-4.5 h-4.5 min-w-[18px] min-h-[18px] flex items-center justify-center rounded-full border border-white">
                  {cartCount}
                </span>
              )}
            </Link>

            <Link to={user ? '/profile' : '/login'} className="hidden md:flex p-2 rounded-lg hover:bg-slate-50 transition-colors text-slate-600">
              <User className="w-5 h-5" />
            </Link>

            <button
              onClick={() => setIsMenuOpen(!isMenuOpen)}
              className="lg:hidden p-2 rounded-lg hover:bg-slate-50 transition-colors text-slate-600"
            >
              {isMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile menu */}
      {isMenuOpen && (
        <div className="lg:hidden border-t border-slate-100 bg-white">
          <div className="container mx-auto px-4 py-3 space-y-1">
            <form onSubmit={handleSearch} className="relative mb-3">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                placeholder="Search..."
                className="input pl-9 py-2"
              />
            </form>
            {navLinks.map(link => (
              <NavLink
                key={link.path}
                to={link.path}
                onClick={() => setIsMenuOpen(false)}
                className={({ isActive }) =>
                  `block px-3 py-2.5 rounded-lg text-sm font-medium ${
                    isActive ? 'bg-indigo-50 text-indigo-600' : 'text-slate-700 hover:bg-slate-50'
                  }`
                }
              >
                {link.name}
              </NavLink>
            ))}
            <div className="pt-2 border-t border-slate-50">
              <Link to="/orders" onClick={() => setIsMenuOpen(false)} className="flex items-center gap-2.5 px-3 py-2.5 text-sm text-slate-600 hover:bg-slate-50 rounded-lg">
                <Truck className="w-4 h-4" /> My Orders
              </Link>
              <Link to={user ? '/profile' : '/login'} onClick={() => setIsMenuOpen(false)} className="flex items-center gap-2.5 px-3 py-2.5 text-sm text-slate-600 hover:bg-slate-50 rounded-lg">
                <User className="w-4 h-4" /> {user ? 'My Account' : 'Sign In'}
              </Link>
            </div>
          </div>
        </div>
      )}
    </header>
  )
}

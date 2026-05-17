import { Link } from 'react-router-dom'
import { Facebook, Instagram, Twitter, MapPin, Phone, Mail, Clock } from 'lucide-react'
import { useSiteSettings } from '../state/SiteSettingsContext.jsx'

export default function Footer() {
  const settings = useSiteSettings()
  return (
    <footer className="bg-slate-900 text-slate-400 pt-12 pb-6 font-sans">
      <div className="container mx-auto px-4 max-w-7xl">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8 mb-10">

          {/* Brand */}
          <div className="col-span-2 md:col-span-1">
            <h3 className="text-base font-bold text-white mb-2">{settings.name}</h3>
            <p className="text-sm leading-relaxed text-slate-500 mb-4">
              Tamil Nadu's trusted partner for pure water solutions — advanced purification technology with responsive local service.
            </p>
            <div className="flex gap-3">
              <a href="#" className="w-8 h-8 rounded-lg bg-slate-800 flex items-center justify-center hover:bg-indigo-600 transition-colors">
                <Facebook className="w-4 h-4" />
              </a>
              <a href="#" className="w-8 h-8 rounded-lg bg-slate-800 flex items-center justify-center hover:bg-indigo-600 transition-colors">
                <Instagram className="w-4 h-4" />
              </a>
              <a href="#" className="w-8 h-8 rounded-lg bg-slate-800 flex items-center justify-center hover:bg-indigo-600 transition-colors">
                <Twitter className="w-4 h-4" />
              </a>
            </div>
          </div>

          {/* Services */}
          <div>
            <h4 className="text-sm font-semibold text-white mb-3">Services</h4>
            <ul className="space-y-2 text-sm">
              <li><Link to="/bookings" className="hover:text-white transition-colors">Book Technician</Link></li>
              <li><Link to="/services" className="hover:text-white transition-colors">Care Plans</Link></li>
              <li><Link to="/contact" className="hover:text-white transition-colors">Request Callback</Link></li>
              <li><Link to="/faq" className="hover:text-white transition-colors">FAQs</Link></li>
            </ul>
          </div>

          {/* Products */}
          <div>
            <h4 className="text-sm font-semibold text-white mb-3">Products</h4>
            <ul className="space-y-2 text-sm">
              <li><Link to="/shop" className="hover:text-white transition-colors">All Products</Link></li>
              <li><Link to="/shop?category=Purifiers" className="hover:text-white transition-colors">Water Purifiers</Link></li>
              <li><Link to="/shop?category=Filters" className="hover:text-white transition-colors">Filters & Spares</Link></li>
              <li><Link to="/orders" className="hover:text-white transition-colors">My Orders</Link></li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h4 className="text-sm font-semibold text-white mb-3">Contact</h4>
            <ul className="space-y-3 text-sm">
              <li className="flex items-start gap-2">
                <MapPin className="w-4 h-4 mt-0.5 text-slate-600 flex-shrink-0" />
                <span>
                  {settings.addressLine1 && <>{settings.addressLine1}<br /></>}
                  {settings.addressLine2 && <>{settings.addressLine2}<br /></>}
                  {settings.locality}
                </span>
              </li>
              <li className="flex items-center gap-2">
                <Phone className="w-4 h-4 text-slate-600 flex-shrink-0" />
                <span>{settings.phonePrimary}</span>
              </li>
              <li className="flex items-center gap-2">
                <Mail className="w-4 h-4 text-slate-600 flex-shrink-0" />
                <span className="truncate">{settings.emailPrimary}</span>
              </li>
              <li className="flex items-center gap-2">
                <Clock className="w-4 h-4 text-slate-600 flex-shrink-0" />
                <span>Mon–Sat, 9 AM – 8 PM</span>
              </li>
            </ul>
          </div>
        </div>

        <div className="border-t border-slate-800 pt-6 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-slate-600">
          <p>© {new Date().getFullYear()} {settings.name}. All rights reserved.</p>
          <div className="flex gap-5">
            <Link to="/terms" className="hover:text-slate-300 transition-colors">Terms of Service</Link>
            <Link to="/privacy" className="hover:text-slate-300 transition-colors">Privacy Policy</Link>
          </div>
        </div>
      </div>
    </footer>
  )
}

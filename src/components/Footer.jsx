import { Link } from 'react-router-dom'
import { Facebook, Instagram, Twitter, MapPin, Phone, Mail, Clock } from 'lucide-react'
import { COMPANY } from '../config/company.js'

export default function Footer() {
  return (
    <footer className="bg-slate-950 text-slate-300 pt-16 pb-8 font-sans">
      <div className="container mx-auto px-4 max-w-7xl">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8 mb-12">
          {/* Brand Column */}
          <div className="space-y-4">
            <h3 className="text-xl font-bold text-white tracking-tight">{COMPANY.name}</h3>
            <p className="text-sm leading-relaxed text-slate-400">
              Tamil Nadu's trusted partner for pure water solutions. We combine advanced purification technology with responsive local service.
            </p>
            <div className="flex gap-4 pt-2">
              <a href="#" className="hover:text-white transition-colors"><Facebook className="w-5 h-5" /></a>
              <a href="#" className="hover:text-white transition-colors"><Instagram className="w-5 h-5" /></a>
              <a href="#" className="hover:text-white transition-colors"><Twitter className="w-5 h-5" /></a>
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="text-white font-semibold mb-4">Shop</h4>
            <ul className="space-y-2 text-sm">
              <li><Link to="/shop?category=Purifiers" className="hover:text-white transition-colors">Water Purifiers</Link></li>
              <li><Link to="/shop?category=Filters" className="hover:text-white transition-colors">Filters & Spares</Link></li>
              <li><Link to="/shop?category=Commercial" className="hover:text-white transition-colors">Commercial RO</Link></li>
              <li><Link to="/shop?category=Services" className="hover:text-white transition-colors">Service Plans</Link></li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h4 className="text-white font-semibold mb-4">Support</h4>
            <ul className="space-y-2 text-sm">
              <li><Link to="/track" className="hover:text-white transition-colors">Track Your Order</Link></li>
              <li><Link to="/orders" className="hover:text-white transition-colors">My Orders</Link></li>
              <li><Link to="/bookings" className="hover:text-white transition-colors">Book a Service</Link></li>
              <li><Link to="/profile" className="hover:text-white transition-colors">My Account</Link></li>
              <li><Link to="/faq" className="hover:text-white transition-colors">FAQs</Link></li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h4 className="text-white font-semibold mb-4">Contact Us</h4>
            <ul className="space-y-3 text-sm">
              <li className="flex items-start gap-3">
                <MapPin className="w-4 h-4 mt-0.5 text-slate-500" />
                <span>{COMPANY.addressLine1}<br />{COMPANY.addressLine2}<br />{COMPANY.addressLine3}</span>
              </li>
              <li className="flex items-center gap-3">
                <Phone className="w-4 h-4 text-slate-500" />
                <span>{COMPANY.phonePrimary}</span>
              </li>
              <li className="flex items-center gap-3">
                <Mail className="w-4 h-4 text-slate-500" />
                <span>{COMPANY.emailPrimary}</span>
              </li>
              <li className="text-slate-400">GSTIN: {COMPANY.gstin}</li>
              <li className="flex items-center gap-3">
                <Clock className="w-4 h-4 text-slate-500" />
                <span>Mon - Sat: 9:00 AM - 8:00 PM</span>
              </li>
            </ul>
          </div>
        </div>

        <div className="border-t border-slate-900 pt-8 flex flex-col md:flex-row justify-between items-center gap-4 text-sm text-slate-500">
          <p>&copy; {new Date().getFullYear()} {COMPANY.name}. All rights reserved.</p>
          <div className="flex gap-6">
            <Link to="/terms" className="hover:text-white transition-colors">Terms of Service</Link>
            <Link to="/privacy" className="hover:text-white transition-colors">Privacy Policy</Link>
          </div>
        </div>
      </div>
    </footer>
  )
}

import { Link } from 'react-router-dom'
import { getProductImage, getServiceImage } from '../utils/imageUtils.js'
import { ArrowRight, ShieldCheck, Clock, Award, Calendar, Wrench, Droplets, BadgeCheck, Zap } from 'lucide-react'
import { formatCurrency } from '../utils/format.js'
import ProductCard from '../components/ProductCard.jsx'
import useProducts from '../hooks/useProducts.js'
import useRecommendations from '../hooks/useRecommendations.js'
import useAnnouncements from '../hooks/useAnnouncements.js'
import useServices from '../hooks/useServices.js'

const features = [
  { icon: Calendar, title: 'Quick Booking', desc: 'Schedule a certified technician visit in under 2 minutes.' },
  { icon: Wrench,   title: 'Expert Service', desc: 'Trained local professionals for all makes and models.' },
  { icon: Droplets, title: 'Water Testing', desc: 'Free TDS and water quality assessment with every visit.' },
  { icon: ShieldCheck, title: '1-Year Warranty', desc: 'All service work backed by our quality guarantee.' },
]

const highlights = [
  { icon: ShieldCheck, title: 'Maintenance & Servicing', desc: 'Routine filter changes, cleaning, and preventive care.' },
  { icon: Award,       title: 'Installation Support',   desc: 'Professional installation for new systems and upgrades.' },
  { icon: BadgeCheck,  title: 'AMC Care Plans',         desc: 'Annual plans with 4 visits, genuine parts, and warranty.' },
]

const amcBenefits = [
  { icon: ShieldCheck, text: '4 Scheduled Service Visits / Year' },
  { icon: Droplets,    text: 'Genuine OEM Filter Replacements' },
  { icon: Clock,       text: '24-Hour Emergency Support Line' },
  { icon: Award,       text: 'Extended Hardware Warranty' },
]

export default function Home() {
  const { items: products } = useProducts()
  const { items: services } = useServices()
  const { title, reason, items: recommendedItems } = useRecommendations()
  const { items: announcements } = useAnnouncements()

  return (
    <div className="bg-white">

      {/* ── Announcement banner ─────────────────────────────── */}
      {announcements.length > 0 && (
        <div className="bg-indigo-600 text-white text-sm text-center py-2.5 px-4 font-medium">
          <span className="font-semibold mr-2">{announcements[0].title}:</span>
          {announcements[0].message}
        </div>
      )}

      {/* ── Hero ────────────────────────────────────────────── */}
      <section className="bg-white border-b border-slate-100">
        <div className="container mx-auto px-4 max-w-7xl py-16 lg:py-24">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            <div>
              <span className="badge badge-primary mb-5">
                Official Portal · Gobichettipalayam
              </span>
              <h1 className="text-4xl lg:text-5xl font-bold text-slate-900 leading-tight mb-5">
                Pure Water for Your Home,<br />
                <span className="text-indigo-600">Expert Care for Your Purifier.</span>
              </h1>
              <p className="text-slate-500 text-lg leading-relaxed mb-8 max-w-lg">
                Book certified technician visits, explore AMC care plans, and shop genuine water purification systems — all in one place.
              </p>
              <div className="flex flex-wrap gap-3">
                <Link to="/bookings" className="btn-primary px-6 py-3 text-base">
                  <Calendar className="w-4 h-4" />
                  Book a Service Visit
                </Link>
                <Link to="/shop" className="btn-secondary px-6 py-3 text-base">
                  Browse Products
                  <ArrowRight className="w-4 h-4" />
                </Link>
              </div>
              <div className="flex items-center gap-6 mt-8 pt-8 border-t border-slate-100">
                <div className="text-center">
                  <div className="text-2xl font-bold text-slate-900">500+</div>
                  <div className="text-xs text-slate-400 font-medium">Happy Customers</div>
                </div>
                <div className="h-8 w-px bg-slate-100" />
                <div className="text-center">
                  <div className="text-2xl font-bold text-slate-900">100%</div>
                  <div className="text-xs text-slate-400 font-medium">Genuine Parts</div>
                </div>
                <div className="h-8 w-px bg-slate-100" />
                <div className="text-center">
                  <div className="text-2xl font-bold text-slate-900">24hr</div>
                  <div className="text-xs text-slate-400 font-medium">Response Time</div>
                </div>
              </div>
            </div>
            <div className="hidden lg:block">
              <div className="relative rounded-2xl overflow-hidden aspect-[4/3] bg-gradient-to-br from-slate-50 to-indigo-50 flex items-center justify-center">
                <img
                  src={encodeURI('/A1 PureFlow RO + UV.png')}
                  alt="A1 PureFlow RO Water Purifier"
                  onError={e => { e.currentTarget.onerror = null; e.currentTarget.src = encodeURI('/Purifiers Explore.png') }}
                  className="w-full h-full object-contain p-6"
                />
                <div className="absolute bottom-5 left-5 right-5 bg-white/95 backdrop-blur-sm rounded-xl p-4 flex items-center gap-3 shadow-lg">
                  <div className="w-9 h-9 bg-indigo-600 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Zap className="w-4 h-4 text-white" />
                  </div>
                  <div>
                    <div className="text-xs font-semibold text-slate-900">Free TDS Testing</div>
                    <div className="text-xs text-slate-500">Included with every service visit</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Feature strip ───────────────────────────────────── */}
      <section className="bg-slate-50 border-b border-slate-100">
        <div className="container mx-auto px-4 max-w-7xl py-10">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {features.map((f, i) => (
              <div key={i} className="flex items-start gap-3">
                <div className="w-9 h-9 rounded-lg bg-indigo-50 flex items-center justify-center flex-shrink-0">
                  <f.icon className="w-4.5 h-4.5 text-indigo-600" />
                </div>
                <div>
                  <div className="text-sm font-semibold text-slate-800">{f.title}</div>
                  <div className="text-xs text-slate-500 mt-0.5 leading-relaxed">{f.desc}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Service Booking Section ─────────────────────────── */}
      <section className="section">
        <div className="container mx-auto px-4 max-w-7xl">
          <div className="grid lg:grid-cols-2 gap-12 items-start">
            {/* Left — Info */}
            <div>
              <p className="section-label mb-3">Professional Services</p>
              <h2 className="text-3xl font-bold text-slate-900 mb-4">
                Expert Care for Your Water Purifier
              </h2>
              <p className="text-slate-500 leading-relaxed mb-8">
                Our certified technicians are trained on all major brands — Aquaguard, Kent, Pureit, and more. We service, repair, and install with genuine parts only.
              </p>
              <div className="space-y-5">
                {highlights.map(h => (
                  <div key={h.title} className="flex items-start gap-4">
                    <div className="w-9 h-9 rounded-lg bg-indigo-50 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <h.icon className="w-4 h-4 text-indigo-600" />
                    </div>
                    <div>
                      <div className="text-sm font-semibold text-slate-800">{h.title}</div>
                      <div className="text-sm text-slate-500 mt-0.5">{h.desc}</div>
                    </div>
                  </div>
                ))}
              </div>
              <Link to="/bookings" className="btn-primary mt-8 px-6 py-3 text-sm">
                Schedule a Visit
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>

            {/* Right — Quick booking links */}
            <div className="space-y-3 w-full">
              <div className="card p-5">
                <div className="flex items-center justify-between gap-4">
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-semibold text-slate-800 truncate sm:whitespace-normal">Technician Home Visit</div>
                    <div className="text-xs text-slate-500 mt-0.5">Same-day or next-day slots available</div>
                  </div>
                  <Link to="/bookings" className="btn-primary text-xs px-4 py-2 flex-shrink-0 whitespace-nowrap">
                    Book Now
                  </Link>
                </div>
              </div>
              <div className="card p-5">
                <div className="flex items-center justify-between gap-4">
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-semibold text-slate-800">Annual Maintenance Contract</div>
                    <div className="text-xs text-slate-500 mt-0.5">4 visits, genuine parts, extended warranty</div>
                  </div>
                  <Link to="/services" className="btn-secondary text-xs px-4 py-2 flex-shrink-0 whitespace-nowrap">
                    View Plans
                  </Link>
                </div>
              </div>
              <div className="card p-5">
                <div className="flex items-center justify-between gap-4">
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-semibold text-slate-800 truncate sm:whitespace-normal">Filter Replacement</div>
                    <div className="text-xs text-slate-500 mt-0.5">Genuine OEM filters with installation</div>
                  </div>
                  <Link to="/bookings" className="btn-secondary text-xs px-4 py-2 flex-shrink-0 whitespace-nowrap">
                    Schedule
                  </Link>
                </div>
              </div>
              <div className="card p-5">
                <div className="flex items-center justify-between gap-4">
                  <div className="min-w-0 flex-1">
                    <div className="text-sm font-semibold text-slate-800 truncate sm:whitespace-normal">New System Installation</div>
                    <div className="text-xs text-slate-500 mt-0.5">Professional install with demo & training</div>
                  </div>
                  <Link to="/bookings" className="btn-secondary text-xs px-4 py-2 flex-shrink-0 whitespace-nowrap">
                    Book
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ── Recommended Products ─────────────────────────────── */}
      {recommendedItems && recommendedItems.length > 0 && (
        <section className="section bg-slate-50 border-y border-slate-100">
          <div className="container mx-auto px-4 max-w-7xl">
            <div className="flex items-end justify-between mb-8">
              <div>
                <p className="section-label mb-2">Recommended</p>
                <h2 className="text-2xl font-bold text-slate-900">{title}</h2>
                {reason && <p className="text-sm text-slate-500 mt-1">{reason}</p>}
              </div>
              <Link to="/shop" className="text-sm font-semibold text-indigo-600 hover:text-indigo-700 flex items-center gap-1 flex-shrink-0 whitespace-nowrap ml-4">
                View all <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {recommendedItems.slice(0, 3).map(item => (
                <ProductCard key={item.id} product={item} />
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ── Services Showcase ────────────────────────────────── */}
      {services.length > 0 && (
        <section className="section">
          <div className="container mx-auto px-4 max-w-7xl">
            <div className="flex items-end justify-between mb-8">
              <div>
                <p className="section-label mb-2">Care & Protection</p>
                <h2 className="text-2xl font-bold text-slate-900">Service Plans</h2>
              </div>
              <Link to="/services" className="text-sm font-semibold text-indigo-600 hover:text-indigo-700 flex items-center gap-1 flex-shrink-0 whitespace-nowrap ml-4">
                See all <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {services.slice(0, 3).map(service => (
                <div key={service.id} className="card overflow-hidden flex flex-col">
                  <div className="relative aspect-video overflow-hidden bg-slate-100">
                    <img
                      src={getServiceImage(service)}
                      alt={service.name}
                      onError={(e) => { e.currentTarget.onerror = null; e.currentTarget.src = '/Services.png' }}
                      className="w-full h-full object-cover hover:scale-105 transition-transform duration-500"
                    />
                  </div>
                  <div className="p-5 flex flex-col flex-1">
                    <h3 className="font-semibold text-slate-900 mb-1">{service.name}</h3>
                    <p className="text-sm text-slate-500 mb-4 leading-relaxed line-clamp-2">{service.description}</p>
                    <div className="mt-auto flex items-center justify-between pt-4 border-t border-slate-50">
                      <div>
                        <div className="text-xs text-slate-400">Starting from</div>
                        <div className="text-lg font-bold text-slate-900">{formatCurrency(service.price)}</div>
                      </div>
                      <Link to="/bookings" className="btn-primary text-xs px-4 py-2">
                        Book Now
                      </Link>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ── AMC CTA Banner ───────────────────────────────────── */}
      <section className="section-sm bg-indigo-600">
        <div className="container mx-auto px-4 max-w-7xl">
          <div className="grid lg:grid-cols-2 gap-10 items-center py-6">
            <div>
              <span className="badge bg-white/20 text-white mb-4">Annual Protection Plan</span>
              <h2 className="text-2xl font-bold text-white mb-3">
                Protect Your Purifier All Year Long
              </h2>
              <p className="text-indigo-100 text-sm leading-relaxed mb-6">
                Our AMC plans are designed for Tamil Nadu's water conditions — proactive care, genuine parts, and priority technician support.
              </p>
              <Link to="/bookings" className="inline-flex items-center gap-2 bg-white text-indigo-600 font-semibold px-5 py-2.5 rounded-lg hover:bg-indigo-50 transition-colors text-sm">
                Activate My Plan <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {amcBenefits.map((b, i) => (
                <div key={i} className="flex items-start gap-3 bg-white/10 rounded-xl p-4">
                  <b.icon className="w-4 h-4 text-indigo-200 mt-0.5 flex-shrink-0" />
                  <span className="text-white text-sm font-medium leading-snug">{b.text}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

    </div>
  )
}

import { Link } from 'react-router-dom'
import { ArrowRight, ShieldCheck, Clock, Award, Phone, Calendar, Wrench, Droplets, BadgeCheck } from 'lucide-react'
import { useMemo } from 'react'
import ProductCard from '../components/ProductCard.jsx'
import useProducts from '../hooks/useProducts.js'
import useRecommendations from '../hooks/useRecommendations.js'
import useAnnouncements from '../hooks/useAnnouncements.js'
import useServices from '../hooks/useServices.js'

const features = [
  { icon: Calendar, title: 'Fast Slot Booking', desc: 'Choose a visit slot in minutes and get quick confirmation.' },
  { icon: Wrench, title: 'Certified Technicians', desc: 'Local experts for installation, repair, sanitization, and filter replacement.' },
  { icon: Droplets, title: 'Water Check Guidance', desc: 'Book home water quality checks before buying or servicing.' },
  { icon: Phone, title: 'Local Follow-Up', desc: 'Direct support in Tamil and English before and after the visit.' },
]

const bookingHighlights = [
  {
    icon: ShieldCheck,
    title: 'Maintenance Visits',
    desc: 'Routine servicing, filter changes, and preventive cleaning to keep purifier output consistent.',
  },
  {
    icon: Award,
    title: 'Installation Support',
    desc: 'Standard and express installation options for new systems, upgrades, and relocations.',
  },
  {
    icon: BadgeCheck,
    title: 'Health Check Appointments',
    desc: 'Deep clean, sanitization, and water-quality test bookings for homes, offices, and rental units.',
  },
]

const categoryImageByName = {
  Purifiers: '/Purifiers Explore.png',
  Filters: '/Filters.png',
  Services: '/Services.png',
  Commercial: '/Commercial.png',
  Accessories: '/Accessories.png',
}

export default function Home() {
  const { items: products } = useProducts()
  const { items: services } = useServices()
  const { title, reason, items: recommendedItems } = useRecommendations()
  const { items: announcements } = useAnnouncements()
  const categories = useMemo(
    () => [
      'All',
      ...new Set(
        products
          .map((product) => product.category)
          .filter(Boolean),
      ),
    ],
    [products],
  )

  return (
    <div className="flex flex-col gap-16 pb-20">
      {/* Announcement Strip */}
      {announcements.length > 0 && (
        <section className="container mx-auto px-4 pt-4 max-w-7xl">
          <div className="space-y-2">
            {announcements.slice(0, 2).map((item) => (
              <div
                key={item.id}
                className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-amber-900"
              >
                <p className="font-bold text-sm uppercase tracking-wide">{item.title}</p>
                <p className="text-sm">{item.message}</p>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Hero Section */}
      <section className="relative overflow-hidden bg-slate-900 py-16 lg:py-24">
        <div className="absolute inset-0 z-0 opacity-20 bg-[url('https://images.unsplash.com/photo-1548839140-29a749e1cf4d?auto=format&fit=crop&w=1600')] bg-cover bg-center" />
        <div className="absolute inset-0 bg-gradient-to-r from-slate-900 via-slate-900/90 to-transparent z-0" />

        <div className="container mx-auto px-4 relative z-10 max-w-7xl">
          <div className="max-w-2xl text-white">
            <span className="inline-block py-1 px-3 rounded-full bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 text-xs font-bold tracking-wide mb-6 uppercase">
              Service-First Water Support
            </span>
            <h1 className="text-4xl lg:text-6xl font-extrabold leading-tight mb-6 tracking-tight">
              Book purifier service, installation, and water checks <span className="text-indigo-400">TODAY!</span>
            </h1>

            <p className="text-lg text-slate-300 mb-8 leading-relaxed max-w-xl">
              Start with technician visits, annual care plans, and local support for Tamil Nadu water conditions. Product buying is still available, but service booking now leads the journey.
            </p>
            <div className="flex flex-wrap gap-4">
              <Link to="/bookings" className="bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-4 rounded-xl font-bold transition-all shadow-lg hover:shadow-indigo-500/30 flex items-center gap-2">
                Book Service Visit <ArrowRight className="w-5 h-5" />
              </Link>
              <Link to="/services" className="bg-white/10 hover:bg-white/20 text-white border border-white/10 px-8 py-4 rounded-xl font-bold transition-all backdrop-blur-sm">
                View Care Plans
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section className="container mx-auto px-4 -mt-24 relative z-20 max-w-7xl">
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 lg:gap-8">
          {features.map((f, i) => (
            <div key={i} className="bg-white p-6 rounded-2xl shadow-xl shadow-slate-200/50 border border-slate-100 flex flex-col items-center text-center hover:-translate-y-1 transition-transform">
              <div className="w-12 h-12 bg-indigo-50 rounded-full flex items-center justify-center text-indigo-600 mb-4">
                <f.icon className="w-6 h-6" />
              </div>
              <h3 className="font-bold text-slate-900 mb-1">{f.title}</h3>
              <p className="text-sm text-slate-500">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="container mx-auto px-4 max-w-7xl">
        <div className="grid grid-cols-1 lg:grid-cols-[1.15fr_0.85fr] gap-8 items-stretch">
          <div className="rounded-[2rem] bg-white border border-slate-100 shadow-xl shadow-slate-200/40 p-8 lg:p-10">
            <span className="inline-flex rounded-full bg-emerald-50 px-3 py-1 text-xs font-bold uppercase tracking-wide text-emerald-700">
              Main Journey
            </span>
            <h2 className="mt-4 text-3xl font-bold text-slate-900">Service booking comes first</h2>
            <p className="mt-3 max-w-2xl text-slate-600">
              Whether the customer needs installation, annual maintenance, emergency repair, or just a water-quality check, the site now encourages booking a technician first and shopping later only when needed.
            </p>
            <div className="mt-8 grid gap-4 md:grid-cols-3">
              {bookingHighlights.map((item) => (
                <div key={item.title} className="rounded-2xl border border-slate-100 bg-slate-50 p-5">
                  <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white text-indigo-600 shadow-sm">
                    <item.icon className="w-5 h-5" />
                  </div>
                  <h3 className="mt-4 font-bold text-slate-900">{item.title}</h3>
                  <p className="mt-2 text-sm leading-6 text-slate-600">{item.desc}</p>
                </div>
              ))}
            </div>
          </div>

          <div className="rounded-[2rem] bg-gradient-to-br from-indigo-600 via-indigo-700 to-slate-900 p-8 text-white shadow-2xl shadow-indigo-200/40">
            <span className="text-xs font-bold uppercase tracking-[0.2em] text-indigo-200">Quick Actions</span>
            <div className="mt-5 space-y-4">
              <Link to="/bookings" className="flex items-center justify-between rounded-2xl bg-white/10 px-5 py-4 font-semibold backdrop-blur-sm transition-colors hover:bg-white/20">
                Book a technician slot <ArrowRight className="w-4 h-4" />
              </Link>
              <Link to="/services" className="flex items-center justify-between rounded-2xl bg-white/10 px-5 py-4 font-semibold backdrop-blur-sm transition-colors hover:bg-white/20">
                Compare care plans <ArrowRight className="w-4 h-4" />
              </Link>
              <Link to="/shop" className="flex items-center justify-between rounded-2xl bg-black/15 px-5 py-4 font-semibold text-indigo-100 transition-colors hover:bg-black/25">
                Browse products second <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
            <div className="mt-8 rounded-2xl border border-white/10 bg-black/10 p-5 text-sm text-indigo-100">
              <p className="font-semibold text-white">Service booking ideas</p>
              <p className="mt-2">Offer “Free water test”, “Express installation”, “Deep clean & sanitization”, and “Filter replacement visit” as the first choices a visitor sees.</p>
            </div>
          </div>
        </div>
      </section>

      {services.length > 0 && (
        <section className="container mx-auto px-4 max-w-7xl">
          <div className="flex flex-col md:flex-row justify-between md:items-end gap-4 mb-8">
            <div>
              <span className="text-indigo-600 font-bold uppercase tracking-wider text-sm">Bookable Services</span>
              <h2 className="text-3xl font-bold text-slate-900 mt-1">Popular booking options</h2>
            </div>
            <Link to="/services" className="text-indigo-600 font-semibold hover:text-indigo-700 flex items-center gap-1">
              Explore all plans <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {services.slice(0, 3).map((service) => (
              <div key={service.id} className="overflow-hidden rounded-3xl border border-slate-100 bg-white shadow-sm">
                <div className="relative aspect-[16/10] overflow-hidden bg-slate-100">
                  <img
                    src={service.imageUrl || '/sample-service.jpg'}
                    alt={service.name}
                    onError={(event) => {
                      event.currentTarget.onerror = null
                      event.currentTarget.src = '/sample-service.jpg'
                    }}
                    className="h-full w-full object-cover transition-transform duration-700 hover:scale-105"
                  />
                  <div className="absolute inset-x-0 top-0 flex items-center justify-between p-4">
                    <span className="rounded-full bg-white/85 px-3 py-1 text-xs font-bold uppercase tracking-wide text-indigo-700 backdrop-blur-sm">
                      Service
                    </span>
                    <span className="rounded-full bg-slate-950/65 px-3 py-1 text-sm font-semibold text-white">
                      {service.duration}
                    </span>
                  </div>
                </div>
                <div className="p-6">
                  <h3 className="text-xl font-bold text-slate-900">{service.name}</h3>
                  <p className="mt-2 text-sm leading-6 text-slate-600">{service.description}</p>
                  <div className="mt-6 flex items-center justify-between">
                    <span className="text-lg font-bold text-slate-900">From Rs. {Number(service.price || 0).toLocaleString('en-IN')}</span>
                    <Link to="/bookings" className="font-semibold text-indigo-600 hover:text-indigo-700">
                      Book now
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Categories */}
      <section className="container mx-auto px-4 max-w-7xl">
        <div className="flex justify-between items-end mb-8">
          <div>
            <span className="text-indigo-600 font-bold uppercase tracking-wider text-sm">Secondary Journey</span>
            <h2 className="text-3xl font-bold text-slate-900 mt-1">Shop by product category</h2>
          </div>
          <Link to="/shop" className="text-indigo-600 font-semibold hover:text-indigo-700 hidden md:flex items-center gap-1">
            View All <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {categories.slice(1).map((cat) => (
            <Link to={`/shop?category=${cat}`} key={cat} className="group relative overflow-hidden rounded-2xl bg-slate-100 aspect-[4/3]">
              <div
                className="absolute inset-0 bg-cover bg-center transition-transform duration-500 group-hover:scale-110"
                style={{ backgroundImage: `url("${categoryImageByName[cat] || '/sample-product.jpg'}")` }}
              />
              <div className="absolute inset-0 bg-gradient-to-t from-slate-900/80 to-transparent flex items-end p-6">
                <div>
                  <h3 className="text-white font-bold text-lg group-hover:translate-x-2 transition-transform duration-300">{cat}</h3>
                  <p className="text-slate-300 text-sm opacity-0 group-hover:opacity-100 transition-opacity duration-300 transform translate-y-2 group-hover:translate-y-0">Explore Collection</p>
                </div>
              </div>
            </Link>
          ))}
        </div>
      </section>

      {/* Recommendations (Highlights) */}
      {recommendedItems && (
        <section className="bg-gradient-to-b from-indigo-50 to-white py-16">
          <div className="container mx-auto px-4 max-w-7xl">
            <div className="flex flex-col md:flex-row justify-between items-start md:items-end mb-10 gap-4">
              <div>
                <span className="bg-indigo-100 text-indigo-700 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide mb-3 inline-block">
                  picked for you
                </span>
                <h2 className="text-3xl font-bold text-slate-900 mb-2">{title}</h2>
                <p className="text-slate-600 max-w-xl">{reason}</p>
              </div>
              <Link to="/shop" className="text-indigo-600 font-bold hover:underline">
                Browse products
              </Link>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              {recommendedItems.map(item => (
                <ProductCard key={item.id} product={item} />
              ))}
            </div>
          </div>
        </section>
      )}


      {/* Best Sellers */}
      {products.length > 0 && (
        <section className="container mx-auto px-4 max-w-7xl">
          <div className="flex justify-between items-center mb-8">
            <h2 className="text-3xl font-bold text-slate-900">Product picks after service</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 md:gap-8">
            {products.slice(0, 3).map((product) => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        </section>
      )}

      {/* Services Banner */}
      <section className="container mx-auto px-4 max-w-7xl">
        <div className="bg-slate-900 rounded-3xl p-8 md:p-12 text-white relative overflow-hidden">
          <div className="absolute top-0 right-0 w-1/2 h-full bg-indigo-600/20 skew-x-12 transform origin-top-right scale-150" />
          <div className="relative z-10 grid md:grid-cols-2 gap-8 items-center">
            <div>
              <h2 className="text-3xl font-bold mb-4">Worry-free Annual Maintenance</h2>
              <p className="text-slate-300 mb-8 text-lg">
                Start with recurring service support, then upgrade or buy replacements only when your technician recommends them.
              </p>
              <Link to="/bookings" className="inline-flex bg-white text-slate-900 hover:bg-slate-100 px-6 py-3 rounded-lg font-bold transition-colors">
                View Service Plans
              </Link>
            </div>
            <div className="bg-white/5 p-6 rounded-2xl border border-white/10 backdrop-blur-sm">
              <div className="flex justify-between items-center mb-6 border-b border-white/10 pb-4">
                <span className="font-bold">What's Included</span>
                <span className="bg-green-500/20 text-green-300 text-xs px-2 py-1 rounded">Annual Plan</span>
              </div>
              <ul className="space-y-3">
                <li className="flex items-center gap-3">
                  <div className="bg-green-500 rounded-full p-0.5"><ArrowRight className="w-3 h-3 text-white" /></div>
                  <span className="text-slate-200">4 Scheduled Visits</span>
                </li>
                <li className="flex items-center gap-3">
                  <div className="bg-green-500 rounded-full p-0.5"><ArrowRight className="w-3 h-3 text-white" /></div>
                  <span className="text-slate-200">Genuine Filter Replacements</span>
                </li>
                <li className="flex items-center gap-3">
                  <div className="bg-green-500 rounded-full p-0.5"><ArrowRight className="w-3 h-3 text-white" /></div>
                  <span className="text-slate-200">Unlimited Breakdown Calls</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}

// Live Demo Update

// Demo Live Update 04/18/2026 16:00:27

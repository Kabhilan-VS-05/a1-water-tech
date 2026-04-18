import { Link } from 'react-router-dom'
import { ArrowRight, ShieldCheck, Truck, Clock, Award, Phone } from 'lucide-react'
import { products, categories } from '../data/products.js'
import ProductCard from '../components/ProductCard.jsx'
import useServices from '../hooks/useServices.js'
import useRecommendations from '../hooks/useRecommendations.js'
import useAnnouncements from '../hooks/useAnnouncements.js'

const features = [
  { icon: ShieldCheck, title: 'Genuine Parts', desc: '100% authentic filters & spares.' },
  { icon: Clock, title: '24h Installation', desc: 'Expert setup within a day.' },
  { icon: Award, title: 'Certified Techs', desc: 'Trained & verified professionals.' },
  { icon: Phone, title: 'Local Support', desc: 'Direct support in Tamil & English.' },
]

const categoryImageByName = {
  Purifiers: '/Purifiers Explore.png',
  Filters: '/Filters.png',
  Services: '/Services.png',
  Commercial: '/Commercial.png',
  Accessories: '/Accessories.png',
}

export default function Home() {
  useServices()
  const { title, reason, items: recommendedItems } = useRecommendations()
  const { items: announcements } = useAnnouncements()

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
              Trusted Since 2012
            </span>
            <h1 className="text-4xl lg:text-6xl font-extrabold leading-tight mb-6 tracking-tight">
              Pure Water for <span className="text-indigo-400">Healthier Living</span>
            </h1>
            <p className="text-lg text-slate-300 mb-8 leading-relaxed max-w-xl">
              Advanced RO purifiers, genuine filters, and reliable annual maintenance plans designed for Tamil Nadu's water conditions.
            </p>
            <div className="flex flex-wrap gap-4">
              <Link to="/shop" className="bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-4 rounded-xl font-bold transition-all shadow-lg hover:shadow-indigo-500/30 flex items-center gap-2">
                Shop Purifiers <ArrowRight className="w-5 h-5" />
              </Link>
              <Link to="/bookings" className="bg-white/10 hover:bg-white/20 text-white border border-white/10 px-8 py-4 rounded-xl font-bold transition-all backdrop-blur-sm">
                Book Free Water Test
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

      {/* Categories */}
      <section className="container mx-auto px-4 max-w-7xl">
        <div className="flex justify-between items-end mb-8">
          <div>
            <span className="text-indigo-600 font-bold uppercase tracking-wider text-sm">Our Range</span>
            <h2 className="text-3xl font-bold text-slate-900 mt-1">Shop by Category</h2>
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
                See All
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
      <section className="container mx-auto px-4 max-w-7xl">
        <div className="flex justify-between items-center mb-8">
          <h2 className="text-3xl font-bold text-slate-900">Best Sellers</h2>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6 md:gap-8">
          {products.slice(0, 3).map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      </section>

      {/* Services Banner */}
      <section className="container mx-auto px-4 max-w-7xl">
        <div className="bg-slate-900 rounded-3xl p-8 md:p-12 text-white relative overflow-hidden">
          <div className="absolute top-0 right-0 w-1/2 h-full bg-indigo-600/20 skew-x-12 transform origin-top-right scale-150" />
          <div className="relative z-10 grid md:grid-cols-2 gap-8 items-center">
            <div>
              <h2 className="text-3xl font-bold mb-4">Worry-free Annual Maintenance</h2>
              <p className="text-slate-300 mb-8 text-lg">
                Get year-round protection with quarterly service visits, free filter replacements, and priority emergency support.
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

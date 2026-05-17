import { Link } from 'react-router-dom'
import { Check, ArrowRight, Shield, AlertCircle } from 'lucide-react'
import { formatCurrency } from '../utils/format.js'
import useServices from '../hooks/useServices.js'
import { getServiceImage, handleImageError } from '../utils/imageUtils.js'

export default function Services() {
  const { items: servicePlans, loading, error } = useServices()

  return (
    <div className="page-bg">
      <div className="container mx-auto px-4 max-w-7xl py-8">

        {/* Header */}
        <div className="mb-8">
          <p className="section-label mb-2">Certified Care</p>
          <h1 className="text-2xl font-bold text-slate-900 mb-2">Maintenance & Protection Plans</h1>
          <p className="text-sm text-slate-500 max-w-xl">
            Keep your water purifier running at peak performance with professional care plans backed by certified technicians.
          </p>
        </div>

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            {[1, 2, 3].map(i => (
              <div key={i} className="card aspect-[4/5] animate-pulse bg-slate-100" />
            ))}
          </div>
        ) : error ? (
          <div className="card p-10 text-center">
            <AlertCircle className="w-8 h-8 text-red-400 mx-auto mb-3" />
            <h3 className="font-semibold text-slate-800 mb-1">Could not load services</h3>
            <p className="text-sm text-slate-500">{error}</p>
          </div>
        ) : servicePlans.length === 0 ? (
          <div className="card p-10 text-center text-sm text-slate-400">
            No service plans available. Please check back later.
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5 mb-10">
            {servicePlans.map(plan => (
              <div
                key={plan.id}
                className={`card flex flex-col overflow-hidden ${
                  plan.price > 4000 ? 'ring-2 ring-indigo-600' : ''
                }`}
              >
                {plan.price > 4000 && (
                  <div className="bg-indigo-600 text-white text-center text-xs font-bold py-1.5 tracking-wide">
                    MOST POPULAR
                  </div>
                )}
                <div className="relative aspect-video overflow-hidden bg-slate-100">
                  <img
                    src={getServiceImage(plan)}
                    alt={plan.name}
                    onError={e => handleImageError(e, 'service')}
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="p-5 flex flex-col flex-1">
                  <div className="flex items-start justify-between mb-3">
                    <div className="w-9 h-9 bg-indigo-50 rounded-lg flex items-center justify-center">
                      <Shield className="w-4 h-4 text-indigo-600" />
                    </div>
                  </div>
                  <h3 className="font-bold text-slate-900 mb-1">{plan.name}</h3>
                  <p className="text-sm text-slate-500 mb-4 leading-relaxed flex-1">{plan.description}</p>

                  <div className="mb-4">
                    <div className="text-xl font-bold text-slate-900">
                      {formatCurrency(plan.price)}
                      <span className="text-sm font-normal text-slate-400 ml-1">/{plan.duration}</span>
                    </div>
                    <div className="text-xs text-slate-400 mt-0.5">Inclusive of all taxes</div>
                  </div>

                  <ul className="space-y-2 mb-5">
                    {[
                      'Quarterly health check-ups',
                      'Priority 24hr installation',
                      'Genuine filter replacements',
                    ].map(item => (
                      <li key={item} className="flex items-center gap-2 text-sm text-slate-600">
                        <div className="w-4 h-4 bg-emerald-50 rounded-full flex items-center justify-center flex-shrink-0">
                          <Check className="w-2.5 h-2.5 text-emerald-600" />
                        </div>
                        {item}
                      </li>
                    ))}
                  </ul>

                  <Link
                    to="/bookings"
                    className={`flex items-center justify-center gap-2 py-2.5 rounded-lg font-semibold text-sm transition-colors ${
                      plan.price > 4000
                        ? 'bg-indigo-600 text-white hover:bg-indigo-700'
                        : 'bg-slate-900 text-white hover:bg-slate-800'
                    }`}
                    style={{ color: 'white' }}
                  >
                    Get Started <ArrowRight className="w-4 h-4" />
                  </Link>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* CTA */}
        <div className="card p-6 lg:p-8 flex flex-col lg:flex-row items-start lg:items-center gap-6 justify-between">
          <div>
            <h2 className="text-lg font-bold text-slate-900 mb-1">Need a one-time service visit?</h2>
            <p className="text-sm text-slate-500">
              Book a single technician visit for repairs, sanitization, water quality testing, or relocation.
            </p>
          </div>
          <div className="flex gap-3 flex-shrink-0">
            <Link to="/bookings" className="btn-primary px-5 py-2.5 text-sm">
              Book a Visit
            </Link>
            <Link to="/contact" className="btn-secondary px-5 py-2.5 text-sm">
              Contact Us
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}

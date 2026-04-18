import { Link } from 'react-router-dom'
import { servicePlans } from '../data/services.js'
import PageHeader from '../components/PageHeader.jsx'
import { Check, Calendar, ArrowRight, Shield } from 'lucide-react'
import { formatCurrency } from '../utils/format.js'

export default function Services() {
  return (
    <div className="container mx-auto px-4 py-12 max-w-7xl font-sans text-slate-900">
      <PageHeader
        eyebrow="Care Plans"
        title="Support that stays with you"
        subtitle="Ensure consistent purity with scheduled maintenance and certified technician visits."
      />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mt-12">
        {servicePlans.map((plan) => (
          <div
            key={plan.id}
            className={`flex flex-col bg-white rounded-3xl border p-8 shadow-sm transition-all hover:shadow-xl hover:-translate-y-1 ${plan.price > 4000 ? 'border-indigo-600 ring-4 ring-indigo-50' : 'border-slate-100'
              }`}
          >
            <div className="flex items-center justify-between mb-6">
              <div className="w-12 h-12 bg-indigo-50 rounded-2xl flex items-center justify-center text-indigo-600">
                <Shield className="w-6 h-6" />
              </div>
              {plan.price > 4000 && (
                <span className="bg-indigo-600 text-white text-[10px] uppercase font-extrabold px-3 py-1 rounded-full tracking-widest">
                  Most Popular
                </span>
              )}
            </div>

            <h3 className="text-2xl font-bold text-slate-900 mb-2">{plan.name}</h3>
            <p className="text-slate-500 text-sm mb-6 leading-relaxed grow">{plan.description}</p>

            <div className="mb-8">
              <div className="flex items-baseline gap-1">
                <span className="text-4xl font-extrabold text-slate-900">{formatCurrency(plan.price)}</span>
                <span className="text-slate-400 text-sm font-medium">/{plan.duration}</span>
              </div>
              <p className="text-xs text-slate-400 mt-1 uppercase font-bold tracking-wide">Inclusive of all taxes</p>
            </div>

            <ul className="space-y-4 mb-8">
              <li className="flex items-start gap-3 text-sm text-slate-700">
                <div className="mt-0.5 bg-green-50 text-green-600 rounded-full p-0.5"><Check className="w-3.5 h-3.5" /></div>
                <span>Quarterly health check-ups</span>
              </li>
              <li className="flex items-start gap-3 text-sm text-slate-700">
                <div className="mt-0.5 bg-green-50 text-green-600 rounded-full p-0.5"><Check className="w-3.5 h-3.5" /></div>
                <span>Priority installation within 24h</span>
              </li>
              <li className="flex items-start gap-3 text-sm text-slate-700">
                <div className="mt-0.5 bg-green-50 text-green-600 rounded-full p-0.5"><Check className="w-3.5 h-3.5" /></div>
                <span>Genuine filter replacements</span>
              </li>
            </ul>

            <Link
              to="/bookings"
              className={`w-full py-4 rounded-xl font-bold text-lg text-center transition-all flex items-center justify-center gap-2 ${plan.price > 4000
                  ? 'bg-indigo-600 text-white hover:bg-indigo-700 shadow-lg shadow-indigo-200'
                  : 'bg-slate-900 text-white hover:bg-slate-800'
                }`}
            >
              Get Started <ArrowRight className="w-5 h-5" />
            </Link>
          </div>
        ))}
      </div>

      <div className="mt-20 bg-slate-50 rounded-3xl p-8 lg:p-16 flex flex-col lg:flex-row items-center gap-12 border border-slate-100">
        <div className="lg:flex-1">
          <h2 className="text-3xl font-bold text-slate-900 mb-4">Request a local technician</h2>
          <p className="text-slate-600 text-lg mb-8 max-w-xl">
            Need a quick repair or a one-time water health test? Our certified experts are just a click away.
          </p>
          <div className="flex flex-wrap gap-4">
            <Link to="/bookings" className="bg-white border border-slate-200 px-8 py-4 rounded-xl font-bold text-slate-700 hover:bg-slate-100 transition-all flex items-center gap-2">
              <Calendar className="w-5 h-5 text-indigo-600" /> Book a Slot
            </Link>
            <Link to="/contact" className="text-indigo-600 font-bold px-4 py-4 hover:underline">
              Contact Support
            </Link>
          </div>
        </div>
        <div className="hidden lg:block lg:w-1/3">
          <div className="relative">
            <div className="absolute inset-0 bg-indigo-600 rounded-3xl translate-x-4 translate-y-4 -z-10" />
            <img
              src="https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=400"
              alt="Service Tech"
              onError={(event) => {
                event.currentTarget.onerror = null
                event.currentTarget.src = '/sample-service.jpg'
              }}
              className="rounded-3xl shadow-xl w-full"
            />
          </div>
        </div>
      </div>
    </div>
  )
}

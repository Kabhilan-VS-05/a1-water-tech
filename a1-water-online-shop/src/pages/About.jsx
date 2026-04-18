import PageHeader from '../components/PageHeader.jsx'
import { Rocket, Target, Heart, Award, ShieldCheck, Zap } from 'lucide-react'

const milestones = [
  { icon: Rocket, title: 'Reliability', desc: 'Certified technicians and genuine parts for long-lasting health.' },
  { icon: Target, title: 'Transparency', desc: 'Clear pricing, GST-compliant billing, and real-time service updates.' },
  { icon: Heart, title: 'Care', desc: 'Complimentary water testing and health-focused expert guidance.' },
]

export default function About() {
  return (
    <div className="container mx-auto px-4 py-12 max-w-6xl font-sans">
      <PageHeader
        eyebrow="Our Story"
        title="Built on service, trusted for water quality"
        subtitle="A1 Water Tech blends field expertise with a digital-first service experience to protect your family's health."
      />

      <div className="grid grid-cols-1 md:grid-cols-2 gap-12 mt-12 items-center">
        <div className="space-y-6">
          <div className="bg-white p-8 rounded-3xl border border-slate-100 shadow-sm">
            <h3 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
              <Award className="w-5 h-5 text-indigo-600" /> Who we are
            </h3>
            <p className="text-slate-600 leading-relaxed">
              A1 Water Tech delivers purifier sales, installation, and annual service plans across Tamil Nadu.
              Founded in 2012, we have grown from a local service shop to a technology-driven water solution provider,
              serving over 50,000 happy families.
            </p>
          </div>

          <div className="bg-white p-8 rounded-3xl border border-slate-100 shadow-sm">
            <h3 className="text-xl font-bold text-slate-900 mb-3 flex items-center gap-2">
              <Zap className="w-5 h-5 text-indigo-600" /> Our Focus
            </h3>
            <p className="text-slate-600 leading-relaxed">
              We focus on real-time service scheduling, accurate GST billing, and smart product recommendations.
              Our goal is to make clean, mineral-rich water accessible to everyone, regardless of their location.
            </p>
          </div>
        </div>

        <div className="relative aspect-square rounded-3xl overflow-hidden shadow-2xl">
          <img
            src="/sample-service.jpg"
            alt="Our Technician"
            onError={(event) => {
              event.currentTarget.onerror = null
              event.currentTarget.src = '/sample-service.jpg'
            }}
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-indigo-900/10 mix-blend-multiply" />
          <div className="absolute bottom-6 left-6 right-6 bg-white/90 backdrop-blur-md p-6 rounded-2xl border border-white/20 shadow-lg">
            <p className="text-indigo-900 font-bold text-lg mb-1">Guaranteed Service</p>
            <p className="text-indigo-700 text-sm font-medium">Within 24 hours of your request.</p>
          </div>
        </div>
      </div>

      <div className="mt-20 bg-slate-900 rounded-3xl p-8 md:p-12 text-white overflow-hidden relative">
        <div className="absolute top-0 left-0 w-64 h-64 bg-indigo-500/10 rounded-full -translate-x-1/2 -translate-y-1/2 blur-3xl" />
        <div className="relative z-10">
          <h2 className="text-3xl font-bold text-center mb-12">Our Core Values</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {milestones.map((m, i) => (
              <div key={i} className="bg-white/5 border border-white/10 p-8 rounded-2xl backdrop-blur-sm hover:bg-white/10 transition-colors">
                <div className="w-12 h-12 bg-indigo-500/20 rounded-full flex items-center justify-center mb-6 text-indigo-400">
                  <m.icon className="w-6 h-6" />
                </div>
                <h4 className="text-xl font-bold mb-3">{m.title}</h4>
                <p className="text-slate-300 text-sm leading-relaxed">{m.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

import PageHeader from '../components/PageHeader.jsx'
import { Phone, Mail, MapPin, Send, MessageSquare, Clock, Loader2 } from 'lucide-react'
import { useState } from 'react'
import { useSiteSettings } from '../state/SiteSettingsContext.jsx'

export default function Contact() {
  const settings = useSiteSettings()
  const [loading, setLoading]     = useState(false)
  const [submitted, setSubmitted] = useState(false)
  const [error, setError]         = useState('')
  const [form, setForm] = useState({ name: '', phone: '', email: '', message: '' })

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const baseUrl = import.meta.env.VITE_API_BASE_URL
      if (!baseUrl) throw new Error('Missing VITE_API_BASE_URL')
      const res = await fetch(`${baseUrl}/feedback`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          customerName: form.name.trim(),
          phone: form.phone.trim(),
          email: form.email.trim(),
          message: form.message.trim(),
        }),
      })
      if (!res.ok) throw new Error(`Failed: ${res.status}`)
      setSubmitted(true)
      setForm({ name: '', phone: '', email: '', message: '' })
    } catch {
      setError('Unable to submit. Please try again in a moment.')
    } finally {
      setLoading(false)
    }
  }

  const contactInfo = [
    { icon: Phone, label: 'Phone', primary: settings.phonePrimary, secondary: settings.phoneSecondary },
    { icon: Mail,  label: 'Email', primary: settings.emailPrimary, secondary: settings.emailSecondary },
    { icon: MapPin, label: 'Address', primary: settings.addressLine1, secondary: `${settings.addressLine2 || ''} ${settings.addressLine3 || ''} ${settings.locality || ''}`.trim() },
  ]

  return (
    <div className="page-bg">
      <div className="container mx-auto px-4 max-w-5xl py-8">

        {/* Header */}
        <div className="mb-8">
          <p className="section-label mb-2">Contact Us</p>
          <h1 className="text-2xl font-bold text-slate-900 mb-2">Get in Touch</h1>
          <p className="text-sm text-slate-500">Our team is here to help with installation queries, service updates, and order support.</p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-5 gap-6">
          {/* Contact info */}
          <div className="lg:col-span-2 space-y-4">
            <div className="card p-5 space-y-5">
              {contactInfo.map(item => (
                item.primary ? (
                  <div key={item.label} className="flex items-start gap-3">
                    <div className="w-9 h-9 bg-indigo-50 rounded-lg flex items-center justify-center text-indigo-600 flex-shrink-0">
                      <item.icon className="w-4 h-4" />
                    </div>
                    <div>
                      <div className="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-0.5">{item.label}</div>
                      <div className="text-sm font-semibold text-slate-800">{item.primary}</div>
                      {item.secondary && <div className="text-xs text-slate-500 mt-0.5">{item.secondary}</div>}
                    </div>
                  </div>
                ) : null
              ))}

              {settings.gstin && (
                <div className="flex items-start gap-3 pt-3 border-t border-slate-50">
                  <div className="text-xs text-slate-400">
                    <span className="font-semibold">GSTIN:</span> {settings.gstin}
                  </div>
                </div>
              )}

              <div className="flex items-center gap-2 pt-3 border-t border-slate-50">
                <div className="w-2 h-2 rounded-full bg-emerald-500" />
                <div className="flex items-center gap-1.5 text-xs text-slate-600">
                  <Clock className="w-3.5 h-3.5 text-slate-400" />
                  Mon – Sat, 9:00 AM – 8:00 PM
                </div>
              </div>
            </div>
          </div>

          {/* Callback form */}
          <div className="lg:col-span-3">
            <div className="card p-6">
              {submitted ? (
                <div className="text-center py-10">
                  <div className="w-14 h-14 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center mx-auto mb-4">
                    <Send className="w-6 h-6" />
                  </div>
                  <h3 className="text-lg font-bold text-slate-900 mb-1">Request Submitted!</h3>
                  <p className="text-sm text-slate-500 mb-5">Our team will call you back within 60 minutes during business hours.</p>
                  <button
                    onClick={() => setSubmitted(false)}
                    className="btn-secondary text-sm"
                  >
                    Send another request
                  </button>
                </div>
              ) : (
                <>
                  <div className="flex items-center gap-2 mb-5">
                    <MessageSquare className="w-4 h-4 text-indigo-600" />
                    <h3 className="text-base font-bold text-slate-900">Request a Callback</h3>
                  </div>
                  <p className="text-sm text-slate-500 mb-5">Leave your details and we'll get back to you shortly.</p>

                  <form className="space-y-4" onSubmit={handleSubmit}>
                    {error && (
                      <div className="p-3 rounded-lg bg-red-50 border border-red-200 text-xs text-red-600">
                        {error}
                      </div>
                    )}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-xs font-semibold text-slate-600 mb-1.5">Full Name <span className="text-red-500">*</span></label>
                        <input
                          placeholder="Your name"
                          value={form.name}
                          onChange={e => setForm(p => ({ ...p, name: e.target.value }))}
                          required
                          className="input"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-semibold text-slate-600 mb-1.5">Phone Number <span className="text-red-500">*</span></label>
                        <input
                          placeholder="+91 98765 43210"
                          value={form.phone}
                          onChange={e => setForm(p => ({ ...p, phone: e.target.value }))}
                          required
                          className="input"
                        />
                      </div>
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-600 mb-1.5">Email Address</label>
                      <input
                        type="email"
                        placeholder="Optional"
                        value={form.email}
                        onChange={e => setForm(p => ({ ...p, email: e.target.value }))}
                        className="input"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-600 mb-1.5">Message <span className="text-red-500">*</span></label>
                      <textarea
                        rows={4}
                        placeholder="Describe your issue or requirement (e.g., RO not working, need annual service, etc.)"
                        value={form.message}
                        onChange={e => setForm(p => ({ ...p, message: e.target.value }))}
                        required
                        className="input resize-none"
                      />
                    </div>
                    <button
                      type="submit"
                      disabled={loading}
                      className="btn-primary w-full justify-center py-2.5 disabled:opacity-60 disabled:cursor-not-allowed"
                    >
                      {loading
                        ? <><Loader2 className="w-4 h-4 animate-spin" /> Sending...</>
                        : <><Send className="w-4 h-4" /> Send Request</>
                      }
                    </button>
                  </form>
                </>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

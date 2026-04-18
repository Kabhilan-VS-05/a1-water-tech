import PageHeader from '../components/PageHeader.jsx'
import { Phone, Mail, MapPin, Send, MessageSquare, Clock, Loader2 } from 'lucide-react'
import { useState } from 'react'
import { COMPANY } from '../config/company.js'
import { addDoc, collection, serverTimestamp } from 'firebase/firestore'
import { auth, db } from '../firebase.js'

export default function Contact() {
  const [loading, setLoading] = useState(false)
  const [submitted, setSubmitted] = useState(false)
  const [error, setError] = useState('')
  const [form, setForm] = useState({
    name: '',
    phone: '',
    email: '',
    message: '',
  })

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await addDoc(collection(db, 'feedback'), {
        customerName: form.name.trim(),
        phone: form.phone.trim(),
        email: form.email.trim(),
        message: form.message.trim(),
        source: 'website_contact',
        status: 'open',
        rating: 0,
        userId: auth.currentUser?.uid || '',
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      })
      setLoading(false)
      setSubmitted(true)
      setForm({
        name: '',
        phone: '',
        email: '',
        message: '',
      })
    } catch {
      setLoading(false)
      setError('Unable to submit now. Please try again in a minute.')
    }
  }

  return (
    <div className="container mx-auto px-4 py-12 max-w-6xl font-sans text-slate-900">
      <PageHeader
        eyebrow="Contact Us"
        title="Talk to our water experts"
        subtitle="Get installation help, service updates, and 24/7 order support."
      />

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-12 mt-8">
        {/* Contact Info */}
        <div className="lg:col-span-2 space-y-8">
          <div className="bg-white p-8 rounded-3xl border border-slate-100 shadow-sm space-y-8">
            <h3 className="text-xl font-bold text-slate-900 mb-2">Get in touch</h3>
            <p className="text-slate-500 text-sm leading-relaxed">
              We're here to help with everything from product choice to installation booking and maintenance scheduling.
            </p>

            <div className="space-y-6">
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center text-indigo-600 flex-shrink-0">
                  <Phone className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs font-bold text-slate-400 uppercase tracking-wide">Call Us</p>
                  <p className="font-bold text-slate-900">{COMPANY.phonePrimary}</p>
                  <p className="text-sm text-slate-600">{COMPANY.phoneSecondary}</p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center text-indigo-600 flex-shrink-0">
                  <Mail className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs font-bold text-slate-400 uppercase tracking-wide">Email Us</p>
                  <p className="font-bold text-slate-900">{COMPANY.emailPrimary}</p>
                  <p className="text-sm text-slate-600">{COMPANY.emailSecondary}</p>
                </div>
              </div>

              <div className="flex items-start gap-4">
                <div className="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center text-indigo-600 flex-shrink-0">
                  <MapPin className="w-5 h-5" />
                </div>
                <div>
                  <p className="text-xs font-bold text-slate-400 uppercase tracking-wide">Office</p>
                  <p className="font-bold text-slate-900">{COMPANY.addressLine1}</p>
                  <p className="text-sm text-slate-600">{COMPANY.addressLine2}</p>
                  <p className="text-sm text-slate-600">{COMPANY.addressLine3}</p>
                  <p className="text-xs text-slate-500 mt-1">GSTIN: {COMPANY.gstin}</p>
                </div>
              </div>
            </div>

            <div className="pt-8 border-t border-slate-100">
              <div className="flex items-center gap-2 text-green-600 bg-green-50 px-4 py-2 rounded-lg text-sm font-bold">
                <Clock className="w-4 h-4" /> Available Mon-Sat, 9 AM - 8 PM
              </div>
            </div>
          </div>
        </div>

        {/* Callback Form */}
        <div className="lg:col-span-3">
          <div className="bg-white p-8 md:p-10 rounded-3xl border border-slate-100 shadow-xl shadow-slate-200/50">
            {submitted ? (
              <div className="text-center py-12">
                <div className="w-20 h-20 bg-indigo-50 text-indigo-600 rounded-full flex items-center justify-center mx-auto mb-6">
                  <Send className="w-10 h-10" />
                </div>
                <h3 className="text-2xl font-bold text-slate-900 mb-2">Request Submitted!</h3>
                <p className="text-slate-500 mb-8">One of our water experts will call you back within 60 minutes.</p>
                <button
                  onClick={() => setSubmitted(false)}
                  className="text-indigo-600 font-bold hover:underline"
                >
                  Send another request
                </button>
              </div>
            ) : (
              <>
                <h3 className="text-xl font-bold text-slate-900 mb-1 flex items-center gap-2">
                  <MessageSquare className="w-5 h-5 text-indigo-600" /> Request a Callback
                </h3>
                <p className="text-slate-500 text-sm mb-8">Leave your details and we'll get back to you shortly.</p>

                <form className="space-y-4" onSubmit={handleSubmit}>
                  {error && (
                    <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                      {error}
                    </div>
                  )}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <input
                      placeholder="Full name"
                      value={form.name}
                      onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))}
                      required
                      className="w-full p-4 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                    />
                    <input
                      placeholder="Phone number"
                      value={form.phone}
                      onChange={(e) => setForm((prev) => ({ ...prev, phone: e.target.value }))}
                      required
                      className="w-full p-4 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                    />
                  </div>
                  <input
                    placeholder="Email address (Optional)"
                    type="email"
                    value={form.email}
                    onChange={(e) => setForm((prev) => ({ ...prev, email: e.target.value }))}
                    className="w-full p-4 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                  />
                  <textarea
                    rows="4"
                    placeholder="Tell us about your water needs (e.g., Hard water problem, RO service required)"
                    value={form.message}
                    onChange={(e) => setForm((prev) => ({ ...prev, message: e.target.value }))}
                    required
                    className="w-full p-4 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all resize-none"
                  />
                  <button
                    className="w-full py-4 bg-slate-900 hover:bg-slate-800 text-white rounded-xl font-bold text-lg shadow-xl shadow-slate-200 transition-all flex items-center justify-center gap-2 disabled:bg-slate-400"
                    type="submit"
                    disabled={loading}
                  >
                    {loading ? <Loader2 className="w-6 h-6 animate-spin" /> : <>Send Request <Send className="w-4 h-4" /></>}
                  </button>
                </form>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

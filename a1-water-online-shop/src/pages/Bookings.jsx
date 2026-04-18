import { useState } from 'react'
import { useAuth } from '../state/AuthContext.jsx'
import useAddresses from '../hooks/useAddresses.js'
import useBookings from '../hooks/useBookings.js'
import useServices from '../hooks/useServices.js'
import { formatCurrency } from '../utils/format.js'
import { Calendar as CalendarIcon, Clock, MapPin, CheckCircle, Loader2, Info, AlertCircle, Sparkles, ShieldCheck, Droplets, Wrench } from 'lucide-react'

const bookingIdeas = [
  {
    icon: Wrench,
    title: 'Popular booking idea',
    heading: 'Filter replacement and service visit',
    desc: 'Perfect for customers whose purifier flow has dropped or taste has changed after months of use.',
  },
  {
    icon: Droplets,
    title: 'Pre-purchase help',
    heading: 'Home water quality test',
    desc: 'Useful before buying a new purifier so the recommended system matches the source water.',
  },
  {
    icon: ShieldCheck,
    title: 'High-value care',
    heading: 'Deep clean and sanitization',
    desc: 'Great for annual maintenance, rented homes, offices, and periods after long non-use.',
  },
]

const bookingFeatures = [
  'Choose a visit type from live service data in AWS',
  'Book by address and preferred slot',
  'Keep a booking history with status updates',
  'Use service booking as the first step before product purchase',
]

export default function Bookings() {
  const { user } = useAuth()
  const { addresses } = useAddresses(user?.uid)
  const [bookingRefreshKey, setBookingRefreshKey] = useState(0)
  const { bookings, loading: bookingsLoading } = useBookings(user?.uid, bookingRefreshKey)
  const { items: services, loading: servicesLoading } = useServices()

  const [selectedService, setSelectedService] = useState('')
  const [selectedDate, setSelectedDate] = useState('')
  const [selectedTime, setSelectedTime] = useState('')
  const [selectedAddress, setSelectedAddress] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [success, setSuccess] = useState('')
  const [error, setError] = useState('')

  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'scheduled': return 'text-indigo-600 bg-indigo-50 border-indigo-200';
      case 'confirmed': return 'text-green-600 bg-green-50 border-green-200';
      case 'completed': return 'text-slate-600 bg-slate-50 border-slate-200';
      case 'cancelled': return 'text-red-600 bg-red-50 border-red-200';
      default: return 'text-amber-600 bg-amber-50 border-amber-200';
    }
  }

  const handleBook = async (e) => {
    e.preventDefault()
    if (!user || !selectedService || !selectedDate || !selectedTime || !selectedAddress) return

    setIsSubmitting(true)
    setError('')
    try {
      const baseUrl = import.meta.env.VITE_API_BASE_URL
      if (!baseUrl) {
        throw new Error('Missing VITE_API_BASE_URL')
      }

      const serviceDetails = services.find(s => s.id === selectedService)
      const addressDetails = addresses.find(a => a.id === selectedAddress)

      const response = await fetch(`${baseUrl}/bookings`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId: user.uid,
          serviceId: selectedService,
          serviceName: serviceDetails?.name || 'Service',
          date: selectedDate,
          time: selectedTime,
          addressId: selectedAddress,
          addressSnapshot: addressDetails || {},
        }),
      })

      if (!response.ok) {
        throw new Error(`Booking request failed: ${response.status}`)
      }

      setSuccess('Booking request submitted successfully!')
      setBookingRefreshKey((current) => current + 1)
      setSelectedService('')
      setSelectedDate('')
      setSelectedTime('')
      setSelectedAddress('')
      setTimeout(() => setSuccess(''), 3000)
    } catch (err) {
      console.error(err)
      setError('Booking request failed. Please try again.')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="container mx-auto px-4 py-8 lg:py-12 max-w-6xl font-sans">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end mb-8 gap-4">
        <div>
          <span className="inline-flex rounded-full bg-indigo-50 px-3 py-1 text-xs font-bold uppercase tracking-wide text-indigo-700 mb-4">
            Main Service Journey
          </span>
          <h1 className="text-3xl font-bold text-slate-900 mb-2">Book service before you buy</h1>
          <p className="text-slate-500 max-w-2xl">Schedule installation, repair, maintenance, or a water check visit first. Product buying stays available, but the website now prioritizes technician-led service support.</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-[1.25fr_0.75fr] gap-6 mb-8">
        <div className="rounded-3xl bg-slate-900 px-6 py-7 text-white">
          <div className="flex items-center gap-2 text-indigo-300 font-semibold text-sm">
            <Sparkles className="w-4 h-4" /> Service booking features
          </div>
          <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-3">
            {bookingFeatures.map((feature) => (
              <div key={feature} className="rounded-2xl bg-white/5 px-4 py-3 text-sm text-slate-200 border border-white/10">
                {feature}
              </div>
            ))}
          </div>
        </div>
        <div className="rounded-3xl border border-slate-100 bg-white px-6 py-7 shadow-sm">
          <p className="text-xs font-bold uppercase tracking-wide text-slate-500">Booking ideas</p>
          <p className="mt-3 text-sm leading-6 text-slate-600">
            Guide customers toward service-led actions like water testing, express installation, deep cleaning, and annual maintenance renewals.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-5 mb-8">
        {bookingIdeas.map((idea) => (
          <div key={idea.heading} className="rounded-3xl border border-slate-100 bg-white p-5 shadow-sm">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-indigo-50 text-indigo-600">
              <idea.icon className="w-5 h-5" />
            </div>
            <p className="mt-4 text-xs font-bold uppercase tracking-wide text-indigo-600">{idea.title}</p>
            <h2 className="mt-2 text-lg font-bold text-slate-900">{idea.heading}</h2>
            <p className="mt-2 text-sm leading-6 text-slate-600">{idea.desc}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Booking Form */}
        <div className="lg:col-span-1">
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-xl shadow-slate-200/50 sticky top-24">
            <h2 className="text-xl font-bold text-slate-900 mb-6 flex items-center gap-2">
              <CalendarIcon className="w-5 h-5 text-indigo-600" /> Book a Slot
            </h2>

            {success ? (
              <div className="bg-green-50 text-green-700 p-4 rounded-xl border border-green-200 flex items-center gap-3 mb-6 animate-bounce">
                <CheckCircle className="w-5 h-5" />
                <span className="font-medium">{success}</span>
              </div>
            ) : (
              <form onSubmit={handleBook} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">Service Type</label>
                  <select
                    required
                    value={selectedService}
                    onChange={(e) => setSelectedService(e.target.value)}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all disabled:opacity-50"
                    disabled={servicesLoading}
                  >
                    <option value="">Select Service...</option>
                    {services.map(s => (
                      <option key={s.id} value={s.id}>{s.name} - {formatCurrency(s.price)}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">Date</label>
                  <input
                    type="date"
                    required
                    value={selectedDate}
                    onChange={(e) => setSelectedDate(e.target.value)}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                    min={new Date().toISOString().split('T')[0]}
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">Time Slot</label>
                  <select
                    required
                    value={selectedTime}
                    onChange={(e) => setSelectedTime(e.target.value)}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                  >
                    <option value="">Select Time...</option>
                    <option value="09:00 - 11:00">09:00 AM - 11:00 AM</option>
                    <option value="11:00 - 13:00">11:00 AM - 01:00 PM</option>
                    <option value="14:00 - 16:00">02:00 PM - 04:00 PM</option>
                    <option value="16:00 - 18:00">04:00 PM - 06:00 PM</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">Address</label>
                  {addresses.length === 0 ? (
                    <div className="p-3 bg-slate-50 border border-dashed border-slate-300 rounded-lg text-sm text-slate-500 text-center">
                      No addresses found. <a href="/profile" className="text-indigo-600 font-bold hover:underline">Add one in Profile</a>
                    </div>
                  ) : (
                    <select
                      required
                      value={selectedAddress}
                      onChange={(e) => setSelectedAddress(e.target.value)}
                      className="w-full p-3 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
                    >
                      <option value="">Select Address...</option>
                      {addresses.map(a => (
                        <option key={a.id} value={a.id}>{a.label} - {a.city}</option>
                      ))}
                    </select>
                  )}
                </div>

                {error && (
                  <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 flex items-center gap-2">
                    <AlertCircle className="w-4 h-4" />
                    {error}
                  </div>
                )}

                <button
                  type="submit"
                  disabled={isSubmitting || !selectedService || !selectedAddress}
                  className="w-full py-3.5 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow-lg shadow-indigo-200 transition-all disabled:bg-indigo-400 disabled:cursor-not-allowed flex items-center justify-center gap-2 mt-4"
                >
                  {isSubmitting ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Confirm Booking'}
                </button>
              </form>
            )}
          </div>
        </div>

        {/* Previous Bookings List */}
        <div className="lg:col-span-2">
          <h2 className="text-xl font-bold text-slate-900 mb-6 px-1">Your Bookings</h2>

          {bookingsLoading ? (
            <div className="bg-white p-8 rounded-2xl shadow-sm text-center">
              <Loader2 className="w-8 h-8 animate-spin text-indigo-600 mx-auto mb-2" />
              <p className="text-slate-500">Loading bookings...</p>
            </div>
          ) : bookings.length === 0 ? (
            <div className="bg-white p-12 rounded-2xl border border-dashed border-slate-200 text-center">
              <div className="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mx-auto mb-4 text-slate-400">
                <CalendarIcon className="w-8 h-8" />
              </div>
              <h3 className="text-lg font-bold text-slate-900 mb-1">No bookings found</h3>
              <p className="text-slate-500">You haven't booked any services yet.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {bookings.map((booking) => (
                <div key={booking.id} className="bg-white border border-slate-100 rounded-2xl p-6 hover:shadow-md transition-shadow group relative">
                  <div className="flex justify-between items-start mb-4">
                    <div>
                      <h3 className="font-bold text-slate-900 text-lg">{booking.serviceName}</h3>
                      <p className="text-xs text-slate-400 font-mono mt-1">ID: {booking.id.slice(0, 8)}</p>
                    </div>
                    <span className={`px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wide border ${getStatusColor(booking.status)}`}>
                      {booking.status || 'Scheduled'}
                    </span>
                  </div>

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm mb-4">
                    <div className="flex items-center gap-3 text-slate-600">
                      <CalendarIcon className="w-4 h-4 text-indigo-500" />
                      <span>{new Date(booking.date).toLocaleDateString(undefined, { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</span>
                    </div>
                    <div className="flex items-center gap-3 text-slate-600">
                      <Clock className="w-4 h-4 text-indigo-500" />
                      <span>{booking.time}</span>
                    </div>
                    <div className="flex items-start gap-3 text-slate-600 sm:col-span-2">
                      <MapPin className="w-4 h-4 text-indigo-500 mt-0.5 flex-shrink-0" />
                      <span className="line-clamp-1">{booking.addressSnapshot?.address || 'Address details unavailable'}</span>
                    </div>
                  </div>

                  {(booking.status === 'pending' || booking.status === 'scheduled') && (
                    <div className="pt-4 border-t border-slate-100 flex items-center gap-2 text-xs text-amber-600 bg-amber-50/50 p-3 rounded-lg">
                      <Info className="w-4 h-4 flex-shrink-0" />
                      Waiting for confirmation. Our team will contact you shortly.
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

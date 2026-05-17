import { useState, useEffect } from 'react'
import { useAuth } from '../state/AuthContext.jsx'
import useAddresses from '../hooks/useAddresses.js'
import useBookings from '../hooks/useBookings.js'
import useServices from '../hooks/useServices.js'
import { formatCurrency } from '../utils/format.js'
import {
  Calendar, Clock, MapPin, CheckCircle,
  Loader2, Info, AlertCircle, Wrench,
  ChevronRight, ChevronLeft, LayoutList
} from 'lucide-react'

export default function Bookings() {
  const { user } = useAuth()
  const { addresses } = useAddresses(user?.uid)
  const [bookingRefreshKey, setBookingRefreshKey] = useState(0)
  const { bookings, loading: bookingsLoading } = useBookings(user?.uid, bookingRefreshKey)
  const { items: services, loading: servicesLoading } = useServices()

  const [activeTab, setActiveTab] = useState('book')
  const [step, setStep] = useState(1)

  const today = new Date()
  const localToday = new Date(today.getTime() - today.getTimezoneOffset() * 60000).toISOString().split('T')[0]

  const timeSlots = [
    { value: '09:00 - 11:00', label: '09:00 AM – 11:00 AM', hour: 11 },
    { value: '11:00 - 13:00', label: '11:00 AM – 01:00 PM', hour: 13 },
    { value: '14:00 - 16:00', label: '02:00 PM – 04:00 PM', hour: 16 },
    { value: '16:00 - 18:00', label: '04:00 PM – 06:00 PM', hour: 18 },
  ]

  const [selectedService, setSelectedService] = useState('')
  const [selectedDate, setSelectedDate] = useState(localToday)
  const [selectedTime, setSelectedTime] = useState('')
  const [selectedAddress, setSelectedAddress] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState('')
  const [cancelingId, setCancelingId] = useState(null)
  const [slotAvailability, setSlotAvailability] = useState({})
  const [checkingAvailability, setCheckingAvailability] = useState(false)

  useEffect(() => {
    let active = true
    async function checkSlots() {
      if (!selectedDate) return
      setCheckingAvailability(true)
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        const res = await fetch(`${baseUrl}/bookings/availability?date=${selectedDate}`)
        if (res.ok && active) {
          const data = await res.json()
          const counts = {}
          data.items?.forEach(item => { counts[item.time] = parseInt(item.count || 0) })
          setSlotAvailability(counts)
        }
      } catch (err) {
        console.error(err)
      } finally {
        if (active) setCheckingAvailability(false)
      }
    }
    checkSlots()
    return () => { active = false }
  }, [selectedDate])

  const availableSlots = selectedDate === localToday
    ? timeSlots.filter(s => today.getHours() < s.hour)
    : timeSlots

  useEffect(() => {
    if (availableSlots.length > 0 && !availableSlots.find(s => s.label === selectedTime)) {
      setSelectedTime('')
    }
  }, [selectedDate, availableSlots, selectedTime])

  const getStatusBadge = (status) => {
    switch (status?.toLowerCase()) {
      case 'confirmed':  return 'badge-success'
      case 'completed':  return 'badge-neutral'
      case 'cancelled':
      case 'rejected':
      case 'expired':    return 'badge-error'
      default:           return 'badge-warning'
    }
  }

  const isExpired = (b) => {
    if (['completed', 'cancelled', 'rejected'].includes(b.status)) return false
    try {
      const endHour = parseInt(b.time.split('-')[1].trim().split(':')[0])
      const d = new Date(b.date)
      d.setHours(endHour, 0, 0, 0)
      return d < new Date()
    } catch {
      const d = new Date(b.date)
      d.setHours(23, 59, 59, 999)
      return d < new Date()
    }
  }

  const handleBook = async () => {
    if (!user || !selectedService || !selectedDate || !selectedTime || !selectedAddress) return
    setIsSubmitting(true)
    setError('')
    try {
      const baseUrl = import.meta.env.VITE_API_BASE_URL
      if (!baseUrl) throw new Error('Missing API URL')
      const svc  = services.find(s => s.id === selectedService)
      const addr = addresses.find(a => a.id === selectedAddress)
      const res = await fetch(`${baseUrl}/bookings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userId: user.uid,
          serviceId: selectedService,
          serviceName: svc?.name || 'Service',
          date: selectedDate,
          time: selectedTime,
          addressId: selectedAddress,
          addressSnapshot: addr || {},
        }),
      })
      if (!res.ok) throw new Error(`Failed: ${res.status}`)
      setBookingRefreshKey(k => k + 1)
      setStep(4)
    } catch (err) {
      console.error(err)
      setError('Booking failed. Please try again.')
    } finally {
      setIsSubmitting(false)
    }
  }

  const nextStep = () => {
    if (step === 1 && !selectedService) return
    if (step === 2 && (!selectedDate || !selectedTime)) return
    if (step === 3 && !selectedAddress) return
    if (step === 3) { handleBook(); return }
    setStep(s => s + 1)
  }

  const resetBooking = () => {
    setStep(1); setSelectedService(''); setSelectedDate(localToday)
    setSelectedTime(''); setSelectedAddress(''); setError('')
    setActiveTab('history')
  }

  const handleCancel = async (booking) => {
    if (!window.confirm('Cancel this booking?')) return
    setCancelingId(booking.id)
    try {
      const baseUrl = import.meta.env.VITE_API_BASE_URL
      const res = await fetch(`${baseUrl}/bookings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'cancel',
          bookingId: booking.id,
          status: 'cancelled',
        }),
      })
      if (res.ok) setBookingRefreshKey(k => k + 1)
      else alert('Could not cancel. Please try again.')
    } catch (err) {
      console.error(err)
    } finally {
      setCancelingId(null)
    }
  }

  const steps = [
    { num: 1, label: 'Service' },
    { num: 2, label: 'Date & Time' },
    { num: 3, label: 'Location' },
  ]

  return (
    <div className="page-bg">
      <div className="container mx-auto px-4 max-w-4xl py-8">

        {/* Page heading */}
        <div className="mb-6">
          <h1 className="text-2xl font-bold text-slate-900">Service Booking</h1>
          <p className="text-sm text-slate-500 mt-1">Schedule a certified technician visit at your convenience</p>
        </div>

        {/* Tabs */}
        <div className="flex gap-1 mb-6 bg-slate-100 p-1 rounded-lg w-fit">
          <button
            onClick={() => setActiveTab('book')}
            className={`flex items-center gap-2 px-5 py-2 rounded-md text-sm font-semibold transition-all ${
              activeTab === 'book'
                ? 'bg-white text-slate-900 shadow-sm'
                : 'text-slate-500 hover:text-slate-700'
            }`}
          >
            <Calendar className="w-4 h-4" /> Book Visit
          </button>
          <button
            onClick={() => setActiveTab('history')}
            className={`flex items-center gap-2 px-5 py-2 rounded-md text-sm font-semibold transition-all ${
              activeTab === 'history'
                ? 'bg-white text-slate-900 shadow-sm'
                : 'text-slate-500 hover:text-slate-700'
            }`}
          >
            <LayoutList className="w-4 h-4" /> My Bookings
          </button>
        </div>

        {/* ── BOOK TAB ── */}
        {activeTab === 'book' && (
          <div>
            {step < 4 && (
              /* Stepper */
              <div className="flex items-center gap-0 mb-6">
                {steps.map((s, i) => (
                  <div key={s.num} className="flex items-center flex-1">
                    <div className="flex flex-col items-center gap-1">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold border-2 transition-all ${
                        step > s.num  ? 'bg-indigo-600 border-indigo-600 text-white'
                        : step === s.num ? 'border-indigo-600 text-indigo-600 bg-white'
                        : 'border-slate-200 text-slate-400 bg-white'
                      }`}>
                        {step > s.num ? <CheckCircle className="w-4 h-4" /> : s.num}
                      </div>
                      <span className={`text-[10px] font-semibold uppercase tracking-wide ${
                        step >= s.num ? 'text-slate-700' : 'text-slate-400'
                      }`}>{s.label}</span>
                    </div>
                    {i < steps.length - 1 && (
                      <div className="flex-1 h-px bg-slate-200 mb-4 mx-2">
                        <div className={`h-full bg-indigo-600 transition-all duration-500 ${step > s.num ? 'w-full' : 'w-0'}`} />
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}

            <div className="card overflow-hidden">
              {/* Step 1 — Select Service */}
              {step === 1 && (
                <div className="p-6">
                  <h2 className="text-lg font-bold text-slate-900 mb-1">Select a Service</h2>
                  <p className="text-sm text-slate-500 mb-5">What type of assistance do you need?</p>
                  {servicesLoading ? (
                    <div className="flex justify-center py-12">
                      <Loader2 className="w-8 h-8 animate-spin text-indigo-600" />
                    </div>
                  ) : (
                    <div className="grid sm:grid-cols-2 gap-3">
                      {services.map(s => (
                        <button
                          key={s.id}
                          onClick={() => setSelectedService(s.id)}
                          className={`text-left p-4 rounded-xl border-2 transition-all ${
                            selectedService === s.id
                              ? 'border-indigo-600 bg-indigo-50'
                              : 'border-slate-100 hover:border-slate-300 bg-white'
                          }`}
                        >
                          <div className="flex items-start justify-between mb-2">
                            <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${
                              selectedService === s.id ? 'bg-indigo-600 text-white' : 'bg-slate-100 text-slate-500'
                            }`}>
                              <Wrench className="w-4 h-4" />
                            </div>
                            {selectedService === s.id && (
                              <CheckCircle className="w-4 h-4 text-indigo-600" />
                            )}
                          </div>
                          <div className="font-semibold text-sm text-slate-800 mt-2">{s.name}</div>
                          <div className="text-indigo-600 font-bold text-sm mt-0.5">{formatCurrency(s.price)}</div>
                          {s.description && (
                            <div className="text-xs text-slate-400 mt-1 line-clamp-2">{s.description}</div>
                          )}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Step 2 — Date & Time */}
              {step === 2 && (
                <div className="p-6">
                  <h2 className="text-lg font-bold text-slate-900 mb-1">Select Date & Time</h2>
                  <p className="text-sm text-slate-500 mb-5">When should our technician visit?</p>

                  <div className="mb-5">
                    <label className="block text-xs font-semibold text-slate-600 mb-1.5 uppercase tracking-wide">Visit Date</label>
                    <input
                      type="date"
                      value={selectedDate}
                      onChange={e => setSelectedDate(e.target.value)}
                      min={localToday}
                      className="input w-full sm:w-64 py-2.5"
                    />
                  </div>

                  <div>
                    <div className="flex items-center gap-2 mb-2">
                      <label className="text-xs font-semibold text-slate-600 uppercase tracking-wide">Available Slots</label>
                      {checkingAvailability && (
                        <Loader2 className="w-3 h-3 animate-spin text-indigo-600" />
                      )}
                    </div>
                    {availableSlots.length === 0 ? (
                      <div className="p-5 rounded-xl bg-amber-50 border border-amber-100 text-sm text-amber-700 flex items-center gap-3">
                        <Clock className="w-5 h-5 flex-shrink-0" />
                        No slots available for today. Please select a future date.
                      </div>
                    ) : (
                      <div className="grid grid-cols-2 gap-2">
                        {availableSlots.map(slot => {
                          const count = slotAvailability[slot.label] || 0
                          const full = count >= 3
                          return (
                            <button
                              key={slot.label}
                              disabled={full || checkingAvailability}
                              onClick={() => setSelectedTime(slot.label)}
                              className={`p-3.5 rounded-xl border text-sm font-semibold transition-all ${
                                full ? 'bg-slate-50 border-slate-100 text-slate-300 cursor-not-allowed'
                                : selectedTime === slot.label ? 'border-indigo-600 bg-indigo-600 text-white'
                                : 'border-slate-200 bg-white text-slate-700 hover:border-indigo-300'
                              }`}
                            >
                              <div>{slot.label}</div>
                              {full
                                ? <div className="text-[10px] font-normal text-red-400 mt-0.5">Full</div>
                                : count > 0
                                ? <div className="text-[10px] font-normal text-emerald-500 mt-0.5">{3 - count} slots left</div>
                                : null
                              }
                            </button>
                          )
                        })}
                      </div>
                    )}
                  </div>
                </div>
              )}

              {/* Step 3 — Address */}
              {step === 3 && (
                <div className="p-6">
                  <h2 className="text-lg font-bold text-slate-900 mb-1">Service Location</h2>
                  <p className="text-sm text-slate-500 mb-5">Where should the technician come?</p>

                  {addresses.length === 0 ? (
                    <div className="p-8 border-2 border-dashed border-slate-200 rounded-xl text-center">
                      <MapPin className="w-8 h-8 text-slate-300 mx-auto mb-3" />
                      <p className="font-semibold text-slate-700 mb-1">No saved addresses</p>
                      <p className="text-sm text-slate-400 mb-4">Add an address to your profile first.</p>
                      <a href="/profile" className="btn-primary text-sm">Go to Profile</a>
                    </div>
                  ) : (
                    <div className="space-y-2">
                      {addresses.map(a => (
                        <button
                          key={a.id}
                          onClick={() => setSelectedAddress(a.id)}
                          className={`w-full text-left p-4 rounded-xl border-2 transition-all ${
                            selectedAddress === a.id
                              ? 'border-indigo-600 bg-indigo-50'
                              : 'border-slate-100 hover:border-slate-300 bg-white'
                          }`}
                        >
                          <div className="flex items-start gap-3">
                            <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 mt-0.5 ${
                              selectedAddress === a.id ? 'bg-indigo-600 text-white' : 'bg-slate-100 text-slate-400'
                            }`}>
                              <MapPin className="w-4 h-4" />
                            </div>
                            <div className="min-w-0">
                              <div className="flex items-center gap-2 mb-0.5">
                                <span className="text-sm font-semibold text-slate-800">{a.label || a.name}</span>
                                {selectedAddress === a.id && <CheckCircle className="w-3.5 h-3.5 text-indigo-600" />}
                              </div>
                              <p className="text-sm text-slate-500 truncate">{a.address || a.line1}</p>
                              <p className="text-xs text-slate-400 mt-0.5">{a.city}, {a.pincode}</p>
                            </div>
                          </div>
                        </button>
                      ))}
                    </div>
                  )}

                  {error && (
                    <div className="mt-4 p-3 rounded-lg bg-red-50 border border-red-200 flex items-center gap-2 text-sm text-red-600">
                      <AlertCircle className="w-4 h-4 flex-shrink-0" /> {error}
                    </div>
                  )}
                </div>
              )}

              {/* Step 4 — Success */}
              {step === 4 && (
                <div className="p-10 text-center">
                  <div className="w-16 h-16 bg-emerald-50 rounded-full flex items-center justify-center mx-auto mb-5 border-4 border-white shadow">
                    <CheckCircle className="w-8 h-8 text-emerald-500" />
                  </div>
                  <h2 className="text-2xl font-bold text-slate-900 mb-2">Booking Confirmed!</h2>
                  <p className="text-slate-500 mb-6 max-w-sm mx-auto text-sm leading-relaxed">
                    Your appointment has been submitted. We'll send technician details via SMS 1 hour before the visit.
                  </p>
                  <button onClick={resetBooking} className="btn-primary px-6 py-2.5">
                    View My Bookings <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
              )}

              {/* Navigation footer */}
              {step < 4 && (
                <div className="px-6 py-4 bg-slate-50 border-t border-slate-100 flex items-center justify-between">
                  {step > 1 ? (
                    <button
                      onClick={() => setStep(s => s - 1)}
                      disabled={isSubmitting}
                      className="btn-secondary text-sm px-4 py-2"
                    >
                      <ChevronLeft className="w-4 h-4" /> Back
                    </button>
                  ) : <div />}
                  <button
                    onClick={nextStep}
                    disabled={
                      isSubmitting ||
                      (step === 1 && !selectedService) ||
                      (step === 2 && (!selectedDate || !selectedTime)) ||
                      (step === 3 && !selectedAddress)
                    }
                    className="btn-primary px-6 py-2.5 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isSubmitting ? (
                      <><Loader2 className="w-4 h-4 animate-spin" /> Submitting...</>
                    ) : step === 3 ? (
                      'Confirm Booking'
                    ) : (
                      <>Continue <ChevronRight className="w-4 h-4" /></>
                    )}
                  </button>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ── HISTORY TAB ── */}
        {activeTab === 'history' && (
          <div>
            {bookingsLoading ? (
              <div className="card p-12 flex flex-col items-center">
                <Loader2 className="w-8 h-8 animate-spin text-indigo-600 mb-3" />
                <p className="text-sm text-slate-400">Loading your bookings...</p>
              </div>
            ) : bookings.length === 0 ? (
              <div className="card p-12 text-center">
                <Calendar className="w-10 h-10 text-slate-300 mx-auto mb-3" />
                <h3 className="font-semibold text-slate-800 mb-1">No bookings yet</h3>
                <p className="text-sm text-slate-500 mb-5">Schedule your first service visit now.</p>
                <button onClick={() => setActiveTab('book')} className="btn-primary text-sm px-5 py-2.5">
                  Book a Service
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                {bookings.map(booking => {
                  const expired = isExpired(booking)
                  const status  = expired ? 'expired' : (booking.status || 'scheduled')
                  return (
                    <div key={booking.id} className={`card p-5 ${expired ? 'opacity-60' : ''}`}>
                      <div className="flex items-start justify-between gap-4 mb-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-slate-100 rounded-lg flex items-center justify-center flex-shrink-0">
                            <Wrench className="w-5 h-5 text-slate-500" />
                          </div>
                          <div>
                            <h3 className={`font-semibold text-slate-900 ${expired ? 'line-through text-slate-400' : ''}`}>
                              {booking.serviceName}
                            </h3>
                            <p className="text-xs text-slate-400 mt-0.5">ID: {booking.id.slice(0, 8).toUpperCase()}</p>
                          </div>
                        </div>
                        <span className={`badge ${getStatusBadge(status)} capitalize flex-shrink-0`}>
                          {status}
                        </span>
                      </div>

                      <div className="grid grid-cols-3 gap-2 sm:gap-3 mb-4">
                        {[
                          { label: 'Date', value: new Date(booking.date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' }) },
                          { label: 'Time', value: booking.time },
                          { label: 'Location', value: booking.addressSnapshot?.city || 'N/A' },
                        ].map(info => (
                          <div key={info.label} className="bg-slate-50 rounded-lg p-2 sm:p-3 min-w-0">
                            <div className="text-[10px] font-semibold text-slate-400 uppercase tracking-wide mb-1">{info.label}</div>
                            <div className="text-sm font-semibold text-slate-700 truncate">{info.value}</div>
                          </div>
                        ))}
                      </div>

                      {expired ? (
                        <div className="flex items-center gap-2 text-xs text-amber-600 bg-amber-50 p-3 rounded-lg border border-amber-100">
                          <AlertCircle className="w-4 h-4 flex-shrink-0" />
                          This appointment window has passed.
                        </div>
                      ) : (status === 'pending' || status === 'scheduled') && (
                        <div className="flex items-center justify-between gap-3 pt-3 border-t border-slate-50">
                          <div className="flex items-center gap-2 text-xs text-slate-500">
                            <Info className="w-3.5 h-3.5" /> Awaiting technician assignment
                          </div>
                          <button
                            disabled={cancelingId === booking.id}
                            onClick={() => handleCancel(booking)}
                            className="text-xs font-semibold text-red-500 hover:text-red-700 disabled:opacity-50 flex items-center gap-1"
                          >
                            {cancelingId === booking.id && <Loader2 className="w-3 h-3 animate-spin" />}
                            Cancel
                          </button>
                        </div>
                      )}
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}

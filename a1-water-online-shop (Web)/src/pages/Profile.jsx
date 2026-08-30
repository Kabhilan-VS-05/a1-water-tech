import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../state/AuthContext.jsx'
import useAddresses from '../hooks/useAddresses.js'
import {
  User, MapPin, Mail, Phone, LogOut, Plus, Trash2, Edit2,
  ShieldCheck, Box, LayoutList, ChevronRight, Loader2, AlertCircle, CheckCircle, FileText
} from 'lucide-react'

const emptyAddressForm = {
  label: '',
  name: '',
  phone: '',
  email: '',
  city: '',
  pincode: '',
  address: '',
}

export default function Profile() {
  const { user, signOut } = useAuth()
  const [addressRefreshKey, setAddressRefreshKey] = useState(0)
  const { addresses, loading: addressLoading } = useAddresses(user?.uid, user?.email, addressRefreshKey)
  const [editingId, setEditingId] = useState('')
  const [showAddressForm, setShowAddressForm] = useState(false)
  const [addressStatus, setAddressStatus] = useState('')
  const [addressError, setAddressError] = useState('')
  const [addressForm, setAddressForm] = useState(emptyAddressForm)
  const [isDeleting, setIsDeleting] = useState(null)

  const handleAddressSave = async (event) => {
    event.preventDefault()
    if (!user) return

    try {
      setAddressError('')
      const baseUrl = import.meta.env.VITE_API_BASE_URL
      if (!baseUrl) throw new Error('Missing VITE_API_BASE_URL')

      const payload = { userId: user.uid, ...addressForm }

      if (editingId) {
        const response = await fetch(`${baseUrl}/addresses/${editingId}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        })
        if (!response.ok) throw new Error('Failed to update')
        setEditingId('')
        setAddressStatus('Address updated successfully.')
      } else {
        const response = await fetch(`${baseUrl}/addresses`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        })
        if (!response.ok) throw new Error('Failed to save')
        setAddressStatus('Address added successfully.')
      }

      setAddressRefreshKey((current) => current + 1)
      setAddressForm(emptyAddressForm)
      setShowAddressForm(false)
      setTimeout(() => setAddressStatus(''), 3000)
    } catch {
      setAddressError('Service unavailable. Please try again later.')
    }
  }

  const handleEdit = (address) => {
    setEditingId(address.id)
    setAddressForm({
      label: address.label || '',
      name: address.name || '',
      phone: address.phone || '',
      email: address.email || '',
      city: address.city || '',
      pincode: address.pincode || '',
      address: address.address || '',
    })
    setShowAddressForm(true)
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const handleDelete = async (addressId) => {
    if (!user || !window.confirm('Delete this address?')) return
    setIsDeleting(addressId)
    try {
      const baseUrl = import.meta.env.VITE_API_BASE_URL
      const response = await fetch(`${baseUrl}/addresses/${encodeURIComponent(addressId)}?userId=${encodeURIComponent(user.uid)}`, { method: 'DELETE' })
      if (!response.ok) throw new Error('Delete failed')
      setAddressRefreshKey((current) => current + 1)
    } catch {
      setAddressError('Could not delete address.')
    } finally {
      setIsDeleting(null)
    }
  }

  return (
    <div className="page-bg">
      <div className="container mx-auto px-4 max-w-6xl py-8">
        
        {/* Header Section */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-8 gap-4 border-b border-slate-100 pb-6">
          <div>
            <p className="section-label mb-1">Personal Account</p>
            <h1 className="text-2xl font-bold text-slate-900">My Profile</h1>
            <p className="text-sm text-slate-500 mt-1">Manage your saved delivery locations and account services.</p>
          </div>
          <button
            onClick={signOut}
            className="btn-secondary text-sm px-4 py-2 border-rose-200 text-rose-600 hover:bg-rose-50 hover:border-rose-300 hover:text-rose-700 flex items-center gap-2"
          >
            <LogOut className="w-4 h-4" /> Sign Out
          </button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          
          {/* Left Column - User Info Panel */}
          <div className="lg:col-span-4 space-y-6">
            
            {/* User details card */}
            <div className="card p-6 relative overflow-hidden bg-white">
              <div className="flex items-center gap-4 mb-6">
                <div className="w-14 h-14 bg-indigo-50 text-indigo-600 rounded-xl flex items-center justify-center flex-shrink-0">
                  <User className="w-6 h-6" />
                </div>
                <div className="min-w-0">
                  <div className="text-sm text-slate-400 font-semibold uppercase tracking-wider">Authorized User</div>
                  <h3 className="text-base font-bold text-slate-800 truncate mt-0.5">
                    {user?.displayName && user.displayName !== user.email
                      ? user.displayName
                      : user?.email
                      ? user.email.split('@')[0]
                      : 'Customer Account'}
                  </h3>
                  <p className="text-xs text-slate-500 truncate mt-0.5">{user?.email}</p>
                </div>
              </div>

              {/* Navigation links inside profile */}
              <div className="space-y-2">
                <Link to="/orders" className="flex items-center justify-between p-3.5 bg-slate-50 rounded-xl hover:bg-indigo-50 hover:text-indigo-600 transition-colors group">
                  <div className="flex items-center gap-2.5">
                    <Box className="w-4.5 h-4.5 text-slate-400 group-hover:text-indigo-600" />
                    <span className="text-sm font-semibold text-slate-700 group-hover:text-indigo-600">Order History</span>
                  </div>
                  <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-indigo-600" />
                </Link>
                <Link to="/quotations" className="flex items-center justify-between p-3.5 bg-slate-50 rounded-xl hover:bg-indigo-50 hover:text-indigo-600 transition-colors group">
                  <div className="flex items-center gap-2.5">
                    <FileText className="w-4.5 h-4.5 text-slate-400 group-hover:text-indigo-600" />
                    <span className="text-sm font-semibold text-slate-700 group-hover:text-indigo-600">My Quotations</span>
                  </div>
                  <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-indigo-600" />
                </Link>
                <Link to="/bookings" className="flex items-center justify-between p-3.5 bg-slate-50 rounded-xl hover:bg-indigo-50 hover:text-indigo-600 transition-colors group">
                  <div className="flex items-center gap-2.5">
                    <LayoutList className="w-4.5 h-4.5 text-slate-400 group-hover:text-indigo-600" />
                    <span className="text-sm font-semibold text-slate-700 group-hover:text-indigo-600">Service Bookings</span>
                  </div>
                  <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-indigo-600" />
                </Link>
              </div>
            </div>

            {/* Smart maintenance care plan banner */}
            <div 
              style={{ backgroundColor: '#4f46e5', color: '#ffffff' }}
              className="p-6 rounded-[14px] shadow-lg shadow-indigo-100 hover:shadow-indigo-200 transition-all duration-200 hover:-translate-y-0.5"
            >
              <div className="w-10 h-10 bg-white/15 rounded-lg flex items-center justify-center mb-4">
                <ShieldCheck className="w-5 h-5 text-indigo-200" />
              </div>
              <h3 className="font-bold text-lg mb-2" style={{ color: '#ffffff' }}>Smart Maintenance</h3>
              <p className="text-sm leading-relaxed mb-5" style={{ color: '#e0e7ff' }}>
                Protect your water purifier with AMC plans designed for Gobichettipalayam's water levels. Proactive filter replacements, free servicing visits, and priority assistance.
              </p>
              <Link 
                to="/bookings" 
                style={{ color: '#4f46e5', backgroundColor: '#ffffff' }}
                className="inline-flex w-full items-center justify-center font-bold px-4 py-2.5 rounded-lg hover:bg-indigo-50 transition-colors text-sm shadow-sm"
              >
                Schedule Service Visit
              </Link>
            </div>

          </div>

          {/* Right Column - Address Management & Active Operations */}
          <div className="lg:col-span-8 space-y-6">
            
            {/* Status alerts */}
            {addressStatus && (
              <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-100 text-sm text-emerald-700 flex items-center gap-2">
                <CheckCircle className="w-4.5 h-4.5 text-emerald-600 flex-shrink-0" />
                {addressStatus}
              </div>
            )}
            
            {addressError && (
              <div className="p-4 rounded-xl bg-rose-50 border border-rose-100 text-sm text-rose-700 flex items-center gap-2">
                <AlertCircle className="w-4.5 h-4.5 text-rose-600 flex-shrink-0" />
                {addressError}
              </div>
            )}

            {/* Main addresses list panel */}
            <div className="card p-6 bg-white">
              <div className="flex items-center justify-between gap-4 mb-6 pb-4 border-b border-slate-50">
                <div>
                  <h2 className="text-base font-bold text-slate-800 flex items-center gap-2">
                    <MapPin className="w-4.5 h-4.5 text-indigo-600" /> Saved Locations
                  </h2>
                  <p className="text-xs text-slate-400 mt-0.5">Shipping and service booking destinations.</p>
                </div>
                {!showAddressForm && (
                  <button
                    onClick={() => { setShowAddressForm(true); setEditingId(''); setAddressForm(emptyAddressForm) }}
                    className="btn-primary text-xs px-3.5 py-2"
                  >
                    <Plus className="w-3.5 h-3.5" /> Add Location
                  </button>
                )}
              </div>

              {/* Dynamic location form */}
              {showAddressForm && (
                <div className="mb-6 p-5 bg-slate-50 rounded-xl border border-slate-200/60 animate-in fade-in duration-200">
                  <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-4">
                    {editingId ? 'Modify Saved Address' : 'Register New Address'}
                  </div>
                  
                  <form onSubmit={handleAddressSave} className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div className="sm:col-span-2">
                      <label className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1.5 ml-0.5">Address Label</label>
                      <input
                        required
                        placeholder="e.g. Home, Office, Parent's House"
                        value={addressForm.label}
                        onChange={(e) => setAddressForm({ ...addressForm, label: e.target.value })}
                        className="input py-2"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1.5 ml-0.5">Recipient Full Name</label>
                      <input
                        required
                        placeholder="John Doe"
                        value={addressForm.name}
                        onChange={(e) => setAddressForm({ ...addressForm, name: e.target.value })}
                        className="input py-2"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1.5 ml-0.5">Contact Number</label>
                      <input
                        required
                        placeholder="10-digit phone"
                        value={addressForm.phone}
                        onChange={(e) => setAddressForm({ ...addressForm, phone: e.target.value })}
                        className="input py-2"
                      />
                    </div>
                    <div className="sm:col-span-2">
                      <label className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1.5 ml-0.5">Email Address</label>
                      <input
                        required
                        type="email"
                        placeholder="name@example.com"
                        value={addressForm.email}
                        onChange={(e) => setAddressForm({ ...addressForm, email: e.target.value })}
                        className="input py-2"
                      />
                    </div>
                    <div className="sm:col-span-2">
                      <label className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1.5 ml-0.5">Detailed Address Info</label>
                      <textarea
                        required
                        rows="2"
                        placeholder="Door number, building, locality name"
                        value={addressForm.address}
                        onChange={(e) => setAddressForm({ ...addressForm, address: e.target.value })}
                        className="input py-2 resize-none"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1.5 ml-0.5">City</label>
                      <input
                        required
                        placeholder="e.g. Gobichettipalayam"
                        value={addressForm.city}
                        onChange={(e) => setAddressForm({ ...addressForm, city: e.target.value })}
                        className="input py-2"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1.5 ml-0.5">Pincode</label>
                      <input
                        required
                        placeholder="638452"
                        value={addressForm.pincode}
                        onChange={(e) => setAddressForm({ ...addressForm, pincode: e.target.value })}
                        className="input py-2"
                      />
                    </div>
                    <div className="sm:col-span-2 flex justify-end gap-2.5 pt-2">
                      <button
                        type="button"
                        onClick={() => { setShowAddressForm(false); setEditingId('') }}
                        className="btn-secondary text-xs px-4 py-2"
                      >
                        Cancel
                      </button>
                      <button
                        type="submit"
                        className="btn-primary text-xs px-5 py-2"
                      >
                        Save Address
                      </button>
                    </div>
                  </form>
                </div>
              )}

              {/* Saved Addresses list */}
              {addressLoading ? (
                <div className="flex flex-col items-center justify-center py-12">
                  <Loader2 className="w-6 h-6 animate-spin text-indigo-600 mb-2" />
                  <span className="text-xs text-slate-400 font-semibold tracking-wider uppercase">Loading Locations...</span>
                </div>
              ) : addresses.length === 0 ? (
                <div className="text-center py-10 rounded-xl bg-slate-50 border-2 border-dashed border-slate-200/70">
                  <MapPin className="w-8 h-8 text-slate-300 mx-auto mb-3" />
                  <h3 className="font-semibold text-slate-800 text-sm mb-0.5">No stored addresses</h3>
                  <p className="text-xs text-slate-500 mb-4">Please add a location to easily request technician visits.</p>
                  <button
                    onClick={() => { setShowAddressForm(true); setEditingId(''); setAddressForm(emptyAddressForm) }}
                    className="btn-primary text-xs px-4 py-2"
                  >
                    Add Address Location
                  </button>
                </div>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {addresses.map(addr => (
                    <div key={addr.id} className="p-4 rounded-xl border border-slate-100 bg-slate-50/50 flex flex-col justify-between group hover:border-indigo-100 transition-colors">
                      <div>
                        <div className="flex justify-between items-center mb-3">
                          <span className="badge badge-primary text-[10px] uppercase font-semibold">
                            {addr.label || 'Destination'}
                          </span>
                          <div className="flex gap-1.5 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button
                              onClick={() => handleEdit(addr)}
                              className="p-1.5 rounded bg-white hover:bg-indigo-50 text-indigo-600 shadow-sm border border-slate-100 transition-colors"
                              title="Edit Location"
                            >
                              <Edit2 className="w-3.5 h-3.5" />
                            </button>
                            <button
                              disabled={isDeleting === addr.id}
                              onClick={() => handleDelete(addr.id)}
                              className="p-1.5 rounded bg-white hover:bg-rose-50 text-rose-600 shadow-sm border border-slate-100 transition-colors disabled:opacity-50"
                              title="Delete Location"
                            >
                              {isDeleting === addr.id
                                ? <Loader2 className="w-3.5 h-3.5 animate-spin" />
                                : <Trash2 className="w-3.5 h-3.5" />
                              }
                            </button>
                          </div>
                        </div>
                        <h4 className="font-bold text-slate-800 text-sm leading-snug">{addr.name}</h4>
                        <p className="text-xs text-slate-500 mt-1 leading-relaxed">
                          {addr.address}, {addr.city} – {addr.pincode}
                        </p>
                      </div>

                      <div className="mt-4 pt-3 border-t border-slate-100/60 flex flex-wrap gap-x-4 gap-y-1 text-[11px] text-slate-400 font-medium">
                        <span className="flex items-center gap-1"><Phone className="w-3 h-3 text-indigo-500" /> {addr.phone}</span>
                        <span className="flex items-center gap-1 truncate max-w-[150px]"><Mail className="w-3 h-3 text-indigo-500" /> {addr.email}</span>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Account Info Security Note */}
            <div className="card p-5 bg-indigo-50/50 border-indigo-100/80 flex items-start gap-3">
              <ShieldCheck className="w-5 h-5 text-indigo-600 flex-shrink-0 mt-0.5" />
              <div>
                <h4 className="text-xs font-bold text-slate-800 uppercase tracking-wide mb-0.5">Secure Customer Data</h4>
                <p className="text-xs text-slate-500 leading-relaxed">
                  Your address details and service tickets are stored securely to assign local field engineers efficiently. We never share customer data.
                </p>
              </div>
            </div>

          </div>

        </div>

      </div>
    </div>
  )
}

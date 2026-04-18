import { useState } from 'react'
import { Link } from 'react-router-dom'
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore'
import { useAuth } from '../state/AuthContext.jsx'
import useAddresses from '../hooks/useAddresses.js'
import { db } from '../firebase.js'
import { User, MapPin, Mail, Phone, Settings, LogOut, Plus, Trash2, Edit2, Check, X } from 'lucide-react'

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
  const { addresses, loading: addressLoading } = useAddresses(user?.uid)
  const [editingId, setEditingId] = useState('')
  const [showAddressForm, setShowAddressForm] = useState(false)
  const [addressStatus, setAddressStatus] = useState('')
  const [addressForm, setAddressForm] = useState(emptyAddressForm)

  const handleAddressSave = async (event) => {
    event.preventDefault()
    if (!user) return

    if (editingId) {
      await updateDoc(doc(db, 'users', user.uid, 'addresses', editingId), {
        ...addressForm,
        updatedAt: serverTimestamp(),
      })
      setEditingId('')
      setAddressStatus('Address updated.')
    } else {
      await addDoc(collection(db, 'users', user.uid, 'addresses'), {
        ...addressForm,
        createdAt: serverTimestamp(),
      })
      setAddressStatus('Address saved.')
    }

    setAddressForm(emptyAddressForm)
    setShowAddressForm(false)
    setTimeout(() => setAddressStatus(''), 2500)
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
  }

  const handleDelete = async (addressId) => {
    if (!user) return
    await deleteDoc(doc(db, 'users', user.uid, 'addresses', addressId))
    if (editingId === addressId) {
      setEditingId('')
      setAddressForm(emptyAddressForm)
      setShowAddressForm(false)
    }
  }

  return (
    <div className="container mx-auto px-4 py-8 lg:py-12 max-w-5xl font-sans">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end mb-8 gap-4">
        <div>
          <h1 className="text-3xl font-bold text-slate-900 mb-2">My Account</h1>
          <p className="text-slate-500">Manage your profile, addresses, and account settings.</p>
        </div>
        <button
          onClick={signOut}
          className="flex items-center gap-2 px-4 py-2 bg-red-50 text-red-600 rounded-lg font-semibold hover:bg-red-100 transition-colors"
        >
          <LogOut className="w-4 h-4" /> Sign Out
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Sidebar Actions */}
        <div className="lg:col-span-1 space-y-4">
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm">
            <div className="flex items-center gap-4 mb-6">
              <div className="w-16 h-16 bg-indigo-50 rounded-full flex items-center justify-center text-indigo-600">
                <User className="w-8 h-8" />
              </div>
              <div>
                <p className="font-bold text-slate-900 truncate max-w-[150px]">{user?.displayName || 'User'}</p>
                <p className="text-sm text-slate-500 truncate max-w-[150px]">{user?.email}</p>
              </div>
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-xl text-slate-700">
                <User className="w-4 h-4 text-slate-400" />
                <span className="text-sm font-medium">Account Status: <span className="text-green-600 font-bold ml-1">Active</span></span>
              </div>
              <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-xl text-slate-700">
                <Settings className="w-4 h-4 text-slate-400" />
                <span className="text-sm font-medium">Preferences</span>
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-indigo-600 to-indigo-700 p-6 rounded-2xl text-white shadow-lg shadow-indigo-200">
            <h3 className="font-bold text-lg mb-2">Need a checkup?</h3>
            <p className="text-indigo-100 text-sm mb-4">Book a service slot for your purifier maintenance.</p>
            <Link to="/bookings" className="block w-full py-2.5 bg-white text-indigo-600 text-center rounded-lg font-bold text-sm hover:bg-indigo-50 transition-colors">
              Book Service Now
            </Link>
          </div>
        </div>

        {/* Main Content Areas */}
        <div className="lg:col-span-2 space-y-8">
          {/* Address Management */}
          <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
              <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                <MapPin className="w-5 h-5 text-indigo-600" /> Saved Addresses
              </h2>
              {!showAddressForm && (
                <button
                  onClick={() => { setShowAddressForm(true); setEditingId(''); setAddressForm(emptyAddressForm) }}
                  className="text-sm font-bold text-indigo-600 hover:bg-indigo-50 px-3 py-1.5 rounded-lg transition-colors flex items-center gap-1"
                >
                  <Plus className="w-4 h-4" /> Add New
                </button>
              )}
            </div>

            {showAddressForm && (
              <div className="p-6 bg-slate-50 border-b border-slate-100 animate-accordion-down">
                <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wide mb-4">{editingId ? 'Edit Address' : 'Add New Address'}</h3>
                <form onSubmit={handleAddressSave} className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <input
                    required
                    placeholder="Label (Home/Office)"
                    value={addressForm.label}
                    onChange={(e) => setAddressForm({ ...addressForm, label: e.target.value })}
                    className="p-3 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none"
                  />
                  <input
                    required
                    placeholder="Full Name"
                    value={addressForm.name}
                    onChange={(e) => setAddressForm({ ...addressForm, name: e.target.value })}
                    className="p-3 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none"
                  />
                  <input
                    required
                    placeholder="Phone Number"
                    value={addressForm.phone}
                    onChange={(e) => setAddressForm({ ...addressForm, phone: e.target.value })}
                    className="p-3 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none"
                  />
                  <input
                    required
                    placeholder="Email"
                    value={addressForm.email}
                    onChange={(e) => setAddressForm({ ...addressForm, email: e.target.value })}
                    className="p-3 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none"
                  />
                  <input
                    required
                    placeholder="City"
                    value={addressForm.city}
                    onChange={(e) => setAddressForm({ ...addressForm, city: e.target.value })}
                    className="p-3 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none"
                  />
                  <input
                    placeholder="Pincode"
                    value={addressForm.pincode}
                    onChange={(e) => setAddressForm({ ...addressForm, pincode: e.target.value })}
                    className="p-3 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none"
                  />
                  <textarea
                    required
                    rows="3"
                    placeholder="Full Address"
                    value={addressForm.address}
                    onChange={(e) => setAddressForm({ ...addressForm, address: e.target.value })}
                    className="md:col-span-2 p-3 bg-white border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none resize-none"
                  />
                  <div className="md:col-span-2 flex gap-3 pt-2">
                    <button type="submit" className="bg-indigo-600 text-white px-6 py-2 rounded-lg font-bold text-sm shadow-md hover:bg-indigo-700 transition-colors">Save Address</button>
                    <button type="button" onClick={() => setShowAddressForm(false)} className="bg-white border border-slate-200 text-slate-600 px-6 py-2 rounded-lg font-bold text-sm hover:bg-slate-50 transition-colors">Cancel</button>
                  </div>
                </form>
              </div>
            )}

            <div className="p-6">
              {addressLoading ? (
                <p className="text-slate-500 text-sm">Loading stored addresses...</p>
              ) : addresses.length === 0 ? (
                <div className="text-center py-8">
                  <div className="w-12 h-12 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-3 text-slate-400">
                    <MapPin className="w-6 h-6" />
                  </div>
                  <p className="text-slate-500 text-sm">No addresses saved yet.</p>
                </div>
              ) : (
                <div className="grid gap-4">
                  {addresses.map((addr) => (
                    <div key={addr.id} className="border border-slate-100 rounded-xl p-4 hover:border-indigo-100 hover:bg-indigo-50/30 transition-colors group relative">
                      <div className="flex justify-between items-start mb-2">
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-slate-900">{addr.label || 'Details'}</span>
                          {addr.createdAt && <span className="text-[10px] bg-slate-100 text-slate-500 px-2 py-0.5 rounded-full">New</span>}
                        </div>
                        <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <button onClick={() => handleEdit(addr)} className="text-indigo-600 hover:bg-indigo-50 p-1.5 rounded-md transition-colors" title="Edit">
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button onClick={() => handleDelete(addr.id)} className="text-red-500 hover:bg-red-50 p-1.5 rounded-md transition-colors" title="Delete">
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                      <p className="text-sm font-semibold text-slate-800 mb-1">{addr.name}</p>
                      <p className="text-sm text-slate-500 mb-1">{addr.address}, {addr.city} {addr.pincode}</p>
                      <p className="text-xs text-slate-400 flex items-center gap-2 mt-2">
                        <Phone className="w-3 h-3" /> {addr.phone}
                        <span className="w-1 h-1 bg-slate-300 rounded-full" />
                        <Mail className="w-3 h-3" /> {addr.email}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

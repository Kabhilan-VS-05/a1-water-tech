import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  addDoc,
  collection,
  serverTimestamp,
  setDoc,
  doc,
} from 'firebase/firestore'
import { db } from '../firebase.js'
import { useAuth } from '../state/AuthContext.jsx'
import useAddresses from '../hooks/useAddresses.js'
import { useCart } from '../state/CartContext.jsx'
import { createOrderId, formatCurrency } from '../utils/format.js'
import { MapPin, User, Mail, Smartphone, CreditCard, Truck, Check, Loader2 } from 'lucide-react'

export default function Checkout() {
  const { items, subtotal, clearCart } = useCart()
  const { user } = useAuth()
  const { addresses } = useAddresses(user?.uid)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState(null)
  const navigate = useNavigate()

  const [orderId, setOrderId] = useState('')
  const [addressMode, setAddressMode] = useState('saved')
  const [selectedAddress, setSelectedAddress] = useState('')
  const selectedAddressData = useMemo(
    () => addresses.find((addr) => addr.id === selectedAddress),
    [addresses, selectedAddress],
  )
  const [customerForm, setCustomerForm] = useState({
    fullName: '',
    phone: '',
    email: '',
    city: '',
    address: '',
  })

  const hasSavedAddresses = addresses.length > 0

  useEffect(() => {
    if (addressMode === 'saved' && !hasSavedAddresses) {
      setAddressMode('new')
    }
  }, [addressMode, hasSavedAddresses])

  useEffect(() => {
    if (addressMode === 'saved' && hasSavedAddresses && !selectedAddress) {
      setSelectedAddress(addresses[0].id)
    }
  }, [addressMode, hasSavedAddresses, selectedAddress, addresses])

  useEffect(() => {
    if (addressMode === 'saved' && selectedAddressData) {
      setCustomerForm({
        fullName: selectedAddressData.name || '',
        phone: selectedAddressData.phone || '',
        email: selectedAddressData.email || '',
        city: selectedAddressData.city || '',
        address: selectedAddressData.address || '',
      })
    }
  }, [addressMode, selectedAddressData])

  const handleSubmit = async (event) => {
    event.preventDefault()
    if (items.length === 0) return
    setIsSubmitting(true)
    setError(null)

    try {
      const formData = new FormData(event.currentTarget)
      const raw = Object.fromEntries(formData.entries())
      const addressData =
        addressMode === 'new'
          ? {
            name: raw.fullName,
            phone: raw.phone,
            email: raw.email,
            city: raw.city,
            address: raw.address,
            label: raw.addressLabel || 'Home',
          }
          : addresses.find((addr) => addr.id === selectedAddress)

      if (addressMode === 'new' && user) {
        const addressRef = doc(
          collection(db, 'users', user.uid, 'addresses'),
        )
        await setDoc(addressRef, {
          ...addressData,
          createdAt: serverTimestamp(),
        })
        raw.savedAddressId = addressRef.id
      } else if (addressMode === 'saved') {
        raw.savedAddressId = selectedAddress
      }

      const customer = {
        fullName: raw.fullName || customerForm.fullName || addressData?.name || '',
        phone: raw.phone || customerForm.phone || addressData?.phone || '',
        email: raw.email || customerForm.email || addressData?.email || '',
        city: raw.city || customerForm.city || addressData?.city || '',
        invoiceType: raw.invoiceType,
        paymentMethod: raw.paymentMethod,
      }

      const addressSnapshot = {
        label: raw.addressLabel || addressData?.label || '',
        address: raw.address || customerForm.address || addressData?.address || '',
        city: raw.city || customerForm.city || addressData?.city || '',
        pincode: addressData?.pincode || '',
        name: customer.fullName,
        phone: customer.phone,
        email: customer.email,
      }

      const id = createOrderId()

      if (user) {
        await addDoc(collection(db, 'orders'), {
          orderId: id,
          userId: user.uid,
          customer,
          addressId: raw.savedAddressId || '',
          address: addressSnapshot,
          items: items.map((item) => ({
            productId: item.id,
            name: item.name,
            qty: item.qty,
            unitPrice: item.price,
            image: item.imageUrl || '',
            category: item.category || 'Product',
          })),
          billing: { gstRate: 0.18, gstAmount: subtotal * 0.18 },
          subtotal,
          total: subtotal * 1.18,
          createdAt: serverTimestamp(),
          status: 'pending',
        })
      }

      clearCart()
      navigate(`/order-confirmation/${id}`)
    } catch (err) {
      console.error(err)
      setError('Failed to place order. Please try again.')
      setIsSubmitting(false)
    }
  }

  if (items.length === 0 && !isSubmitting) {
    return <div className="text-center py-20 text-slate-500 font-sans">Your cart is empty.</div>
  }

  return (
    <div className="container mx-auto px-4 py-8 lg:py-12 max-w-7xl font-sans text-slate-900">
      <h1 className="text-3xl font-bold text-slate-900 mb-8">Checkout</h1>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2">
          <form onSubmit={handleSubmit} className="space-y-8">
            {/* Contact & Delivery */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
              <h2 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
                <MapPin className="w-5 h-5 text-indigo-600" /> Delivery Address
              </h2>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
                <label className={`cursor-pointer p-4 rounded-xl border-2 transition-all ${addressMode === 'saved' ? 'border-indigo-600 bg-indigo-50/50' : 'border-slate-100 hover:border-slate-300'}`}>
                  <div className="flex items-center gap-3">
                    <input
                      type="radio"
                      name="addressMode"
                      checked={addressMode === 'saved'}
                      onChange={() => setAddressMode('saved')}
                      disabled={!hasSavedAddresses}
                      className="w-4 h-4 text-indigo-600 focus:ring-indigo-500"
                    />
                    <span className={!hasSavedAddresses ? 'text-slate-400' : 'font-medium text-slate-900'}>Use Saved Address</span>
                  </div>
                </label>
                <label className={`cursor-pointer p-4 rounded-xl border-2 transition-all ${addressMode === 'new' ? 'border-indigo-600 bg-indigo-50/50' : 'border-slate-100 hover:border-slate-300'}`}>
                  <div className="flex items-center gap-3">
                    <input
                      type="radio"
                      name="addressMode"
                      checked={addressMode === 'new'}
                      onChange={() => setAddressMode('new')}
                      className="w-4 h-4 text-indigo-600 focus:ring-indigo-500"
                    />
                    <span className="font-medium text-slate-900">Add New Address</span>
                  </div>
                </label>
              </div>

              {addressMode === 'saved' ? (
                <div className="space-y-4">
                  <select
                    required
                    value={selectedAddress}
                    onChange={(e) => setSelectedAddress(e.target.value)}
                    className="w-full p-3 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                  >
                    <option value="">Select a saved address...</option>
                    {addresses.map((addr) => (
                      <option key={addr.id} value={addr.id}>
                        {addr.label || 'Home'} - {addr.address}, {addr.city}
                      </option>
                    ))}
                  </select>

                  {selectedAddressData && (
                    <div className="bg-slate-50 p-4 rounded-xl border border-dashed border-slate-300 text-sm text-slate-600">
                      <p className="font-bold text-slate-900 mb-1">{selectedAddressData.name}</p>
                      <p>{selectedAddressData.address}</p>
                      <p>{selectedAddressData.city} {selectedAddressData.pincode}</p>
                      <p className="mt-2 text-slate-500">Phone: {selectedAddressData.phone}</p>
                    </div>
                  )}
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="md:col-span-2">
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">Full Name</label>
                    <div className="relative">
                      <input name="fullName" required className="w-full p-3 pl-10 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="John Doe" value={customerForm.fullName} onChange={(e) => setCustomerForm({ ...customerForm, fullName: e.target.value })} />
                      <User className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">Phone</label>
                    <div className="relative">
                      <input name="phone" required className="w-full p-3 pl-10 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="9876543210" value={customerForm.phone} onChange={(e) => setCustomerForm({ ...customerForm, phone: e.target.value })} />
                      <Smartphone className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                    </div>
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">Email</label>
                    <div className="relative">
                      <input name="email" type="email" required className="w-full p-3 pl-10 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="john@example.com" value={customerForm.email} onChange={(e) => setCustomerForm({ ...customerForm, email: e.target.value })} />
                      <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                    </div>
                  </div>
                  <div className="md:col-span-2">
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">Address</label>
                    <textarea name="address" required rows="2" className="w-full p-3 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none resize-none" placeholder="Flat No, Street, Area" value={customerForm.address} onChange={(e) => setCustomerForm({ ...customerForm, address: e.target.value })} />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">City</label>
                    <input name="city" required className="w-full p-3 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="Chennai" value={customerForm.city} onChange={(e) => setCustomerForm({ ...customerForm, city: e.target.value })} />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">Address Label</label>
                    <input name="addressLabel" className="w-full p-3 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none" placeholder="Home / Office" />
                  </div>
                </div>
              )}
            </div>

            {/* Payment */}
            <div className="bg-white p-6 rounded-2xl shadow-sm border border-slate-100">
              <h2 className="text-lg font-bold text-slate-900 mb-4 flex items-center gap-2">
                <CreditCard className="w-5 h-5 text-indigo-600" /> Payment & Billing
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">Invoice Type</label>
                  <select name="invoiceType" required className="w-full p-3 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
                    <option value="GST Invoice">GST Invoice (18%)</option>
                    <option value="Standard Invoice">Standard Invoice</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-500 uppercase tracking-wide mb-1">Payment Method</label>
                  <select name="paymentMethod" required className="w-full p-3 bg-slate-50 border border-slate-200 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 outline-none">
                    <option value="UPI">UPI / QR Code</option>
                    <option value="Card">Credit / Debit Card</option>
                    <option value="Netbanking">Netbanking</option>
                    <option value="EMI">EMI</option>
                  </select>
                </div>
              </div>
            </div>

            {error && (
              <div className="bg-red-50 text-red-600 p-4 rounded-xl text-sm font-medium border border-red-100">
                {error}
              </div>
            )}

            <button type="submit" disabled={items.length === 0 || isSubmitting} className="hidden lg:flex w-full bg-slate-900 hover:bg-slate-800 text-white py-4 rounded-xl font-bold text-lg shadow-xl shadow-slate-200 transition-all justify-center items-center gap-2 disabled:bg-slate-400 disabled:cursor-not-allowed">
              {isSubmitting ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" /> Processing Order...
                </>
              ) : (
                'Place Order'
              )}
            </button>
          </form>
        </div>

        {/* Order Summary Sidebar */}
        <div className="lg:col-span-1">
          <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-lg sticky top-24 space-y-6">
            <h3 className="font-bold text-slate-900 text-lg">Order Summary</h3>
            <div className="space-y-4 max-h-96 overflow-y-auto pr-2 custom-scrollbar">
              {items.map((item) => (
                <div key={item.id} className="flex gap-4 items-start">
                  <div className="w-16 h-16 bg-slate-50 rounded-lg border border-slate-100 flex-shrink-0 overflow-hidden">
                    <img
                      src={item.imageUrl || '/sample-product.jpg'}
                      alt={item.name}
                      onError={(event) => {
                        event.currentTarget.onerror = null
                        event.currentTarget.src = '/sample-product.jpg'
                      }}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-bold text-slate-900 truncate">{item.name}</p>
                    <p className="text-xs text-slate-500">Qty: {item.qty}</p>
                    <p className="text-sm font-medium text-slate-700 mt-1">{formatCurrency(item.price * item.qty)}</p>
                  </div>
                </div>
              ))}
            </div>

            <div className="border-t border-slate-100 pt-4 space-y-3">
              <div className="flex justify-between text-sm text-slate-600">
                <span>Subtotal</span>
                <span className="font-medium text-slate-900">{formatCurrency(subtotal)}</span>
              </div>
              <div className="flex justify-between text-sm text-slate-600">
                <span>GST (18%)</span>
                <span className="font-medium text-slate-900">{formatCurrency(subtotal * 0.18)}</span>
              </div>
              <div className="flex justify-between text-sm text-slate-600">
                <span>Delivery</span>
                <span className="text-green-600 font-medium">Free</span>
              </div>
              <div className="flex justify-between text-lg font-bold text-slate-900 pt-2 border-t border-slate-100">
                <span>Total Pay</span>
                <span>{formatCurrency(subtotal * 1.18)}</span>
              </div>
            </div>

            <button type="submit" disabled={items.length === 0 || isSubmitting} className="lg:hidden w-full bg-slate-900 hover:bg-slate-800 text-white py-4 rounded-xl font-bold text-lg shadow-xl shadow-slate-200 transition-all justify-center items-center gap-2 disabled:bg-slate-400 disabled:cursor-not-allowed">
              {isSubmitting ? (
                <>
                  <Loader2 className="w-5 h-5 animate-spin" /> Processing...
                </>
              ) : (
                'Place Order'
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

import { useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../state/AuthContext.jsx'
import useAddresses from '../hooks/useAddresses.js'
import { useCart } from '../state/CartContext.jsx'
import { useSiteSettings } from '../state/SiteSettingsContext.jsx'
import { createOrderId, formatCurrency } from '../utils/format.js'
import { MapPin, User, Mail, Smartphone, CreditCard, Truck, Check, Loader2, ChevronRight, ShieldCheck, AlertCircle } from 'lucide-react'

export default function Checkout() {
  const { items, subtotal, clearCart } = useCart()
  const { user } = useAuth()
  const settings = useSiteSettings()
  const { addresses } = useAddresses(user?.uid)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState(null)
  const navigate = useNavigate()

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
    pincode: '',
  })
  
  const hasSavedAddresses = addresses.length > 0
  const appliedGstRate = settings.gstEnabled ? settings.gstRate : 0
  const gstAmount = subtotal * appliedGstRate
  const totalAmount = subtotal + gstAmount
  const gstLabel =
    appliedGstRate > 0
      ? `GST (${(appliedGstRate * 100).toFixed(2)}%)`
      : 'GST'

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
        pincode: selectedAddressData.pincode || '',
      })
    }
  }, [addressMode, selectedAddressData])

  const handleSubmit = async (event) => {
    event.preventDefault()
    if (items.length === 0 || !user) return
    setIsSubmitting(true)
    setError(null)

    try {
      const baseUrl = import.meta.env.VITE_API_BASE_URL
      if (!baseUrl) {
        throw new Error('Missing VITE_API_BASE_URL')
      }

      const formData = new FormData(event.currentTarget)
      const raw = Object.fromEntries(formData.entries())
      
      let addressData =
        addressMode === 'new'
          ? {
              name: raw.fullName,
              phone: raw.phone,
              email: raw.email,
              city: raw.city,
              address: raw.address,
              label: raw.addressLabel || 'Home',
              pincode: raw.pincode || '',
            }
          : addresses.find((addr) => addr.id === selectedAddress)

      let savedAddressId = ''

      if (addressMode === 'new' && user) {
        const addressResponse = await fetch(`${baseUrl}/addresses`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            userId: user.uid,
            label: addressData?.label || 'Home',
            name: addressData?.name || '',
            phone: addressData?.phone || '',
            email: addressData?.email || '',
            city: addressData?.city || '',
            pincode: addressData?.pincode || '',
            address: addressData?.address || '',
          }),
        })

        if (!addressResponse.ok) {
          throw new Error(`Address save during checkout failed: ${addressResponse.status}`)
        }

        const addressPayload = await addressResponse.json()
        addressData = addressPayload.item || addressData
        savedAddressId = addressPayload.item?.id || ''
      } else if (addressMode === 'saved') {
        savedAddressId = selectedAddress
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

      const orderResponse = await fetch(`${baseUrl}/orders`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          orderId: id,
          userId: user.uid,
          customer,
          addressId: savedAddressId,
          address: addressSnapshot,
          items: items.map((item) => ({
            productId: item.id,
            name: item.name,
            qty: item.qty,
            unitPrice: item.price,
            image: item.imageUrl || '',
            category: item.category || 'Product',
          })),
          billing: { gstRate: appliedGstRate, gstAmount },
          subtotal,
          total: totalAmount,
        }),
      })

      if (!orderResponse.ok) {
        throw new Error(`Order request failed: ${orderResponse.status}`)
      }

      sessionStorage.setItem('lastOrder', JSON.stringify({
        id,
        items: items.map((item) => ({
          name: item.name,
          qty: item.qty,
          price: item.price,
          imageUrl: item.imageUrl || '',
        })),
        address: addressSnapshot,
        total: totalAmount,
        subtotal,
        gstAmount,
      }))

      clearCart()
      navigate(`/order-confirmation/${id}`)
    } catch (err) {
      console.error(err)
      setError('Failed to place order. Please try again.')
      setIsSubmitting(false)
    }
  }

  if (items.length === 0 && !isSubmitting) {
    return (
      <div className="flex flex-col items-center justify-center py-32 bg-white rounded-[3rem] border border-slate-100 shadow-sm mx-4 mt-8">
        <div className="w-20 h-20 bg-slate-50 rounded-full flex items-center justify-center text-slate-300 mb-6">
          <CreditCard className="w-10 h-10" />
        </div>
        <h2 className="text-2xl font-bold text-slate-900 mb-2">Your cart is empty</h2>
        <p className="text-slate-500 mb-8">Add some products to your cart before checking out.</p>
        <button onClick={() => navigate('/shop')} className="px-8 py-3 bg-indigo-600 text-white font-bold rounded-xl shadow-lg shadow-indigo-100">
          Browse Shop
        </button>
      </div>
    )
  }

  return (
    <div className="container mx-auto px-4 py-12 max-w-7xl font-sans text-slate-900 bg-slate-50 min-h-screen">
      <div className="flex items-center gap-3 mb-8">
        <div className="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center text-white shadow-lg shadow-indigo-200">
          <ShieldCheck className="w-6 h-6" />
        </div>
        <div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tight">Secure Checkout</h1>
          <p className="text-slate-500 text-sm font-medium">Complete your order details below</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-10">
        <div className="lg:col-span-8">
          <form id="checkout-form" onSubmit={handleSubmit} className="space-y-8">
            {/* Delivery Address */}
            <div className="bg-white p-8 rounded-[2rem] shadow-sm border border-slate-200/60 overflow-hidden relative">
              <div className="flex items-center justify-between mb-8">
                <h2 className="text-xl font-extrabold text-slate-900 flex items-center gap-3">
                  <MapPin className="w-6 h-6 text-indigo-600" /> Delivery Details
                </h2>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-5 mb-8">
                <div 
                  onClick={() => hasSavedAddresses && setAddressMode('saved')}
                  className={`cursor-pointer p-5 rounded-2xl border-2 transition-all duration-300 ${addressMode === 'saved' ? 'border-indigo-600 bg-indigo-50/30' : 'border-slate-100 bg-white hover:border-slate-300'} ${!hasSavedAddresses ? 'opacity-50 cursor-not-allowed' : ''}`}
                >
                  <div className="flex items-center gap-4">
                    <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${addressMode === 'saved' ? 'border-indigo-600' : 'border-slate-300'}`}>
                      {addressMode === 'saved' && <div className="w-2.5 h-2.5 bg-indigo-600 rounded-full" />}
                    </div>
                    <span className="font-bold text-slate-900">Saved Address</span>
                  </div>
                </div>
                <div 
                  onClick={() => setAddressMode('new')}
                  className={`cursor-pointer p-5 rounded-2xl border-2 transition-all duration-300 ${addressMode === 'new' ? 'border-indigo-600 bg-indigo-50/30' : 'border-slate-100 bg-white hover:border-slate-300'}`}
                >
                  <div className="flex items-center gap-4">
                    <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${addressMode === 'new' ? 'border-indigo-600' : 'border-slate-300'}`}>
                      {addressMode === 'new' && <div className="w-2.5 h-2.5 bg-indigo-600 rounded-full" />}
                    </div>
                    <span className="font-bold text-slate-900">Add New Address</span>
                  </div>
                </div>
              </div>

              {addressMode === 'saved' ? (
                <div className="space-y-5 animate-in fade-in slide-in-from-top-2">
                  <div className="relative">
                    <select
                      required
                      value={selectedAddress}
                      onChange={(e) => setSelectedAddress(e.target.value)}
                      className="w-full p-4 bg-slate-50 border border-slate-200 rounded-2xl text-base font-medium focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 outline-none transition-all appearance-none"
                    >
                      <option value="">Select a saved address...</option>
                      {addresses.map((addr) => (
                        <option key={addr.id} value={addr.id}>
                          {addr.label || 'Home'} - {addr.address}, {addr.city}
                        </option>
                      ))}
                    </select>
                    <div className="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none">
                      <ChevronRight className="w-5 h-5 text-slate-400 rotate-90" />
                    </div>
                  </div>

                  {selectedAddressData && (
                    <div className="bg-indigo-600/5 p-6 rounded-2xl border border-indigo-100 flex items-start gap-4 shadow-inner">
                      <div className="w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center text-white flex-shrink-0">
                        <MapPin className="w-5 h-5" />
                      </div>
                      <div className="flex-1">
                        <p className="font-extrabold text-slate-900 text-lg mb-1">{selectedAddressData.name}</p>
                        <p className="text-slate-600 font-medium">{selectedAddressData.address}</p>
                        <p className="text-slate-600 font-medium">{selectedAddressData.city} {selectedAddressData.pincode}</p>
                        <div className="mt-3 inline-flex items-center gap-2 px-3 py-1 bg-white rounded-lg border border-indigo-100 text-xs font-bold text-indigo-600">
                          📞 {selectedAddressData.phone}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 animate-in fade-in slide-in-from-top-2">
                  <div className="md:col-span-2">
                    <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Full Name</label>
                    <div className="relative">
                      <input name="fullName" required className="w-full p-4 pl-12 bg-slate-50 border border-slate-200 rounded-2xl text-sm font-bold focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-600 outline-none transition-all" placeholder="Enter recipient's name" value={customerForm.fullName} onChange={(e) => setCustomerForm({ ...customerForm, fullName: e.target.value })} />
                      <User className="w-5 h-5 text-slate-400 absolute left-4 top-4" />
                    </div>
                  </div>
                  <div>
                    <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Phone Number</label>
                    <div className="relative">
                      <input name="phone" required className="w-full p-4 pl-12 bg-slate-50 border border-slate-200 rounded-2xl text-sm font-bold focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-600 outline-none transition-all" placeholder="9876543210" value={customerForm.phone} onChange={(e) => setCustomerForm({ ...customerForm, phone: e.target.value })} />
                      <Smartphone className="w-5 h-5 text-slate-400 absolute left-4 top-4" />
                    </div>
                  </div>
                  <div>
                    <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Email Address</label>
                    <div className="relative">
                      <input name="email" type="email" required className="w-full p-4 pl-12 bg-slate-50 border border-slate-200 rounded-2xl text-sm font-bold focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-600 outline-none transition-all" placeholder="john@example.com" value={customerForm.email} onChange={(e) => setCustomerForm({ ...customerForm, email: e.target.value })} />
                      <Mail className="w-5 h-5 text-slate-400 absolute left-4 top-4" />
                    </div>
                  </div>
                  <div className="md:col-span-2">
                    <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Complete Address</label>
                    <textarea name="address" required rows="2" className="w-full p-4 bg-slate-50 border border-slate-200 rounded-2xl text-sm font-bold focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-600 outline-none transition-all resize-none" placeholder="House/Flat No, Building, Street, Area" value={customerForm.address} onChange={(e) => setCustomerForm({ ...customerForm, address: e.target.value })} />
                  </div>
                  <div>
                    <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">City</label>
                    <input name="city" required className="w-full p-4 bg-slate-50 border border-slate-200 rounded-2xl text-sm font-bold focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-600 outline-none transition-all" placeholder="Chennai" value={customerForm.city} onChange={(e) => setCustomerForm({ ...customerForm, city: e.target.value })} />
                  </div>
                  <div>
                    <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Pincode</label>
                    <input name="pincode" required className="w-full p-4 bg-slate-50 border border-slate-200 rounded-2xl text-sm font-bold focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-600 outline-none transition-all" placeholder="600001" value={customerForm.pincode} onChange={(e) => setCustomerForm({ ...customerForm, pincode: e.target.value })} />
                  </div>
                </div>
              )}
            </div>

            {/* Payment & Billing */}
            <div className="bg-white p-8 rounded-[2.5rem] shadow-sm border border-slate-200/60">
              <h2 className="text-xl font-extrabold text-slate-900 mb-8 flex items-center gap-3">
                <CreditCard className="w-6 h-6 text-indigo-600" /> Payment & Billing
              </h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Invoice Type</label>
                  <div className="relative">
                    <select name="invoiceType" required className="w-full p-4 bg-slate-50 border border-slate-200 rounded-2xl text-sm font-bold focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-600 outline-none transition-all appearance-none">
                      <option value="GST Invoice">{appliedGstRate > 0 ? `GST Invoice (${(appliedGstRate * 100).toFixed(0)}%)` : 'GST Invoice'}</option>
                      <option value="Standard Invoice">Standard Invoice</option>
                    </select>
                    <ChevronRight className="w-4 h-4 text-slate-400 absolute right-4 top-5 rotate-90" />
                  </div>
                </div>
                <div>
                  <label className="block text-[10px] font-black text-slate-400 uppercase tracking-widest mb-2 ml-1">Payment Method</label>
                  <div className="relative">
                    <select name="paymentMethod" required className="w-full p-4 bg-slate-50 border border-slate-200 rounded-2xl text-sm font-bold focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-600 outline-none transition-all appearance-none">
                      <option value="UPI">UPI / QR Code</option>
                      <option value="Card">Credit / Debit Card</option>
                      <option value="Netbanking">Netbanking</option>
                      <option value="EMI">EMI / Pay Later</option>
                    </select>
                    <ChevronRight className="w-4 h-4 text-slate-400 absolute right-4 top-5 rotate-90" />
                  </div>
                </div>
              </div>
            </div>

            {error && (
              <div className="bg-rose-50 text-rose-600 p-5 rounded-2xl text-sm font-bold border border-rose-100 flex items-center gap-3">
                <AlertCircle className="w-5 h-5 flex-shrink-0" /> {error}
              </div>
            )}

            <button type="submit" disabled={items.length === 0 || isSubmitting} className="hidden lg:flex w-full bg-slate-900 hover:bg-slate-800 text-white py-5 rounded-[2rem] font-black text-xl shadow-xl shadow-slate-200 transition-all justify-center items-center gap-3 disabled:bg-slate-300 disabled:cursor-not-allowed transform active:scale-[0.98]">
              {isSubmitting ? (
                <>
                  <Loader2 className="w-6 h-6 animate-spin" /> Finalizing Order...
                </>
              ) : (
                <>Place Order <ChevronRight className="w-6 h-6" /></>
              )}
            </button>
          </form>
        </div>

        {/* Order Summary Sidebar */}
        <div className="lg:col-span-4">
          <div className="bg-white p-8 rounded-[2.5rem] border border-slate-200/60 shadow-xl shadow-slate-200/50 sticky top-28 space-y-8">
            <div className="flex items-center justify-between">
              <h3 className="font-black text-slate-900 text-lg uppercase tracking-tight">Order Summary</h3>
              <span className="bg-indigo-50 text-indigo-600 text-[10px] font-black px-3 py-1 rounded-full uppercase">{items.length} Items</span>
            </div>
            
            <div className="space-y-6 max-h-[300px] overflow-y-auto pr-2 custom-scrollbar">
              {items.map((item) => (
                <div key={item.id} className="flex gap-4 items-center">
                  <div className="w-16 h-16 bg-slate-50 rounded-2xl border border-slate-100 flex-shrink-0 overflow-hidden shadow-sm">
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
                    <div className="flex items-center justify-between mt-1">
                      <p className="text-[11px] text-slate-400 font-bold uppercase tracking-widest">Qty: {item.qty}</p>
                      <p className="text-sm font-black text-slate-700">{formatCurrency(item.price * item.qty)}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div className="border-t border-slate-100 pt-6 space-y-4">
              <div className="flex justify-between text-sm">
                <span className="font-bold text-slate-400 uppercase tracking-widest text-[10px]">Subtotal</span>
                <span className="font-black text-slate-900">{formatCurrency(subtotal)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="font-bold text-slate-400 uppercase tracking-widest text-[10px]">{gstLabel}</span>
                <span className="font-black text-slate-900">{formatCurrency(gstAmount)}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="font-bold text-slate-400 uppercase tracking-widest text-[10px]">Delivery Fee</span>
                <span className="text-emerald-600 font-black uppercase text-xs">Free</span>
              </div>
              <div className="pt-6 border-t border-slate-100 flex justify-between items-end">
                <div>
                  <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Total Payable</p>
                  <p className="text-3xl font-black text-indigo-600 leading-none">{formatCurrency(totalAmount)}</p>
                </div>
              </div>
            </div>

            <div className="bg-slate-50 p-4 rounded-2xl border border-slate-100 flex items-center gap-3">
              <Truck className="w-5 h-5 text-indigo-500" />
              <p className="text-[11px] font-bold text-slate-600 leading-tight">Delivery within <span className="text-indigo-600">2-3 business days</span> after order confirmation.</p>
            </div>

            <button form="checkout-form" type="submit" disabled={items.length === 0 || isSubmitting} className="lg:hidden w-full bg-slate-900 hover:bg-slate-800 text-white py-5 rounded-[2rem] font-black text-lg shadow-xl shadow-slate-200 transition-all justify-center items-center gap-3 disabled:bg-slate-300 transform active:scale-[0.98]">
              {isSubmitting ? (
                <>
                  <Loader2 className="w-6 h-6 animate-spin" /> Placing...
                </>
              ) : (
                <>Place Order <ChevronRight className="w-6 h-6" /></>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

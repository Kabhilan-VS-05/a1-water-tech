import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import {
    CheckCircle,
    ShoppingBag,
    ArrowRight,
    Package,
    MapPin,
    CreditCard,
    Clock,
    Truck,
    ChevronRight,
    Printer,
    Copy,
    Check
} from 'lucide-react'

export default function OrderSuccess() {
    const { id } = useParams()
    const navigate = useNavigate()
    const [copied, setCopied] = useState(false)
    const [orderDetails, setOrderDetails] = useState(null)

    useEffect(() => {
        window.scrollTo(0, 0)
        // Try to get order details from sessionStorage
        const savedOrder = sessionStorage.getItem('lastOrder')
        if (savedOrder) {
            try {
                setOrderDetails(JSON.parse(savedOrder))
            } catch {
                setOrderDetails(null)
            }
        }
    }, [])

    const copyOrderId = () => {
        navigator.clipboard.writeText(id)
        setCopied(true)
        setTimeout(() => setCopied(false), 2000)
    }

    // Status steps
    const statusSteps = [
        { icon: CheckCircle, label: 'Order Placed', color: 'bg-green-500', active: true },
        { icon: Package, label: 'Processing', color: 'bg-slate-300', active: false },
        { icon: Truck, label: 'Shipped', color: 'bg-slate-300', active: false },
        { icon: MapPin, label: 'Delivered', color: 'bg-slate-300', active: false },
    ]

    return (
        <div className="min-h-screen bg-slate-50 py-8 px-4 font-sans">
            <div className="max-w-4xl mx-auto">
                {/* Success Header */}
                <div className="bg-gradient-to-br from-green-500 to-emerald-600 rounded-3xl p-8 mb-6 text-white shadow-xl shadow-green-200">
                    <div className="flex items-start justify-between">
                        <div className="flex items-center gap-4">
                            <div className="w-16 h-16 bg-white/20 rounded-2xl flex items-center justify-center">
                                <CheckCircle className="w-8 h-8 text-white" />
                            </div>
                            <div>
                                <h1 className="text-2xl md:text-3xl font-bold mb-1">Order Confirmed!</h1>
                                <p className="text-green-100">Thank you for your purchase</p>
                            </div>
                        </div>
                        <div className="hidden md:flex items-center gap-2 bg-white/10 px-4 py-2 rounded-xl">
                            <Clock className="w-4 h-4" />
                            <span className="text-sm">{new Date().toLocaleDateString('en-IN')}</span>
                        </div>
                    </div>
                </div>

                {/* Order Progress Tracker */}
                <div className="bg-white rounded-2xl p-6 mb-6 shadow-sm border border-slate-200">
                    <h2 className="text-lg font-bold text-slate-900 mb-6">Order Status</h2>
                    <div className="flex items-center justify-between relative">
                        {/* Progress Line */}
                        <div className="absolute top-6 left-0 right-0 h-1 bg-slate-200 rounded-full mx-8">
                            <div className="h-full w-0 bg-green-500 rounded-full transition-all duration-500" />
                        </div>

                        {statusSteps.map((step, index) => (
                            <div key={step.label} className="flex flex-col items-center relative z-10">
                                <div className={`w-12 h-12 rounded-full flex items-center justify-center mb-2 transition-all ${
                                    step.active ? step.color : 'bg-slate-100'
                                }`}>
                                    <step.icon className={`w-5 h-5 ${step.active ? 'text-white' : 'text-slate-400'}`} />
                                </div>
                                <span className={`text-xs font-medium ${step.active ? 'text-green-600' : 'text-slate-400'}`}>
                                    {step.label}
                                </span>
                            </div>
                        ))}
                    </div>
                </div>

                <div className="grid md:grid-cols-3 gap-6">
                    {/* Left Column - Order Details */}
                    <div className="md:col-span-2 space-y-6">
                        {/* Order ID Section */}
                        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200">
                            <div className="flex items-center justify-between mb-4">
                                <h3 className="text-lg font-bold text-slate-900">Order Details</h3>
                                <button
                                    onClick={copyOrderId}
                                    className="flex items-center gap-2 text-sm text-indigo-600 hover:text-indigo-700 font-medium"
                                >
                                    {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                                    {copied ? 'Copied!' : 'Copy ID'}
                                </button>
                            </div>
                            <div className="grid sm:grid-cols-2 gap-4">
                                <div className="bg-indigo-50 rounded-xl p-4 border border-indigo-100">
                                    <p className="text-xs text-indigo-600 font-semibold uppercase tracking-wide mb-1">Order ID</p>
                                    <p className="text-lg font-mono font-bold text-indigo-900 break-all">{id}</p>
                                </div>
                                <div className="bg-amber-50 rounded-xl p-4 border border-amber-100">
                                    <p className="text-xs text-amber-600 font-semibold uppercase tracking-wide mb-1">Estimated Delivery</p>
                                    <p className="text-lg font-bold text-amber-900">
                                        {new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toLocaleDateString('en-IN', {
                                            day: 'numeric',
                                            month: 'short',
                                            year: 'numeric'
                                        })}
                                    </p>
                                </div>
                            </div>
                        </div>

                        {/* Order Items (if available) */}
                        {orderDetails?.items && orderDetails.items.length > 0 && (
                            <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200">
                                <h3 className="text-lg font-bold text-slate-900 mb-4">Items Ordered</h3>
                                <div className="space-y-4">
                                    {orderDetails.items.map((item, idx) => (
                                        <div key={idx} className="flex items-center gap-4 p-4 bg-slate-50 rounded-xl">
                                            <div className="w-16 h-16 bg-white rounded-lg flex items-center justify-center text-2xl">
                                                {item.imageUrl ? (
                                                    <img src={item.imageUrl} alt={item.name} className="w-full h-full object-cover rounded-lg" />
                                                ) : (
                                                    <Package className="w-6 h-6 text-slate-400" />
                                                )}
                                            </div>
                                            <div className="flex-1">
                                                <p className="font-semibold text-slate-900">{item.name}</p>
                                                <p className="text-sm text-slate-500">Qty: {item.qty}</p>
                                            </div>
                                            <p className="font-bold text-slate-900">₹{item.price * item.qty}</p>
                                        </div>
                                    ))}
                                </div>
                                <div className="mt-4 pt-4 border-t border-slate-200 flex items-center justify-between">
                                    <span className="text-slate-600">Total Amount</span>
                                    <span className="text-2xl font-bold text-slate-900">₹{orderDetails.total}</span>
                                </div>
                            </div>
                        )}

                        {/* Delivery Address */}
                        {orderDetails?.address && (
                            <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200">
                                <div className="flex items-center gap-3 mb-4">
                                    <div className="w-10 h-10 bg-blue-100 rounded-xl flex items-center justify-center">
                                        <MapPin className="w-5 h-5 text-blue-600" />
                                    </div>
                                    <h3 className="text-lg font-bold text-slate-900">Delivery Address</h3>
                                </div>
                                <div className="bg-blue-50 rounded-xl p-4 border border-blue-100">
                                    <p className="font-semibold text-slate-900">{orderDetails.address.name}</p>
                                    <p className="text-slate-600 mt-1">{orderDetails.address.line1}</p>
                                    {orderDetails.address.line2 && <p className="text-slate-600">{orderDetails.address.line2}</p>}
                                    <p className="text-slate-600">{orderDetails.address.city}, {orderDetails.address.state} - {orderDetails.address.pincode}</p>
                                    <p className="text-slate-500 text-sm mt-2">📞 {orderDetails.address.phone}</p>
                                </div>
                            </div>
                        )}

                        {/* Payment Info */}
                        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200">
                            <div className="flex items-center gap-3 mb-4">
                                <div className="w-10 h-10 bg-purple-100 rounded-xl flex items-center justify-center">
                                    <CreditCard className="w-5 h-5 text-purple-600" />
                                </div>
                                <h3 className="text-lg font-bold text-slate-900">Payment Information</h3>
                            </div>
                            <div className="flex items-center justify-between p-4 bg-purple-50 rounded-xl border border-purple-100">
                                <div>
                                    <p className="font-semibold text-slate-900">Payment Status</p>
                                    <p className="text-sm text-slate-600">Cash on Delivery / Online</p>
                                </div>
                                <span className="px-4 py-2 bg-green-100 text-green-700 rounded-full text-sm font-bold">
                                    PAID
                                </span>
                            </div>
                        </div>
                    </div>

                    {/* Right Column - Actions */}
                    <div className="space-y-6">
                        {/* Quick Actions */}
                        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-200">
                            <h3 className="text-lg font-bold text-slate-900 mb-4">Quick Actions</h3>
                            <div className="space-y-3">
                                <button
                                    onClick={() => navigate('/orders')}
                                    className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3.5 rounded-xl shadow-lg shadow-indigo-200 transition-all flex items-center justify-center gap-2"
                                >
                                    <ShoppingBag className="w-5 h-5" />
                                    View My Orders
                                </button>
                                <button
                                    onClick={() => window.print()}
                                    className="w-full bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold py-3.5 rounded-xl transition-all flex items-center justify-center gap-2"
                                >
                                    <Printer className="w-5 h-5" />
                                    Print Receipt
                                </button>
                            </div>
                        </div>

                        {/* Continue Shopping Card */}
                        <Link
                            to="/shop"
                            className="block bg-gradient-to-br from-slate-800 to-slate-900 rounded-2xl p-6 text-white hover:from-slate-700 hover:to-slate-800 transition-all group"
                        >
                            <div className="flex items-center justify-between mb-3">
                                <ShoppingBag className="w-8 h-8" />
                                <ChevronRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
                            </div>
                            <h3 className="font-bold text-lg mb-1">Continue Shopping</h3>
                            <p className="text-slate-400 text-sm">Explore more products</p>
                        </Link>

                        {/* Need Help */}
                        <div className="bg-amber-50 rounded-2xl p-6 border border-amber-100">
                            <h3 className="font-bold text-amber-900 mb-2">Need Help?</h3>
                            <p className="text-sm text-amber-700 mb-4">
                                Contact us if you have any questions about your order.
                            </p>
                            <Link
                                to="/contact"
                                className="text-sm font-semibold text-amber-600 hover:text-amber-700 flex items-center gap-1"
                            >
                                Contact Support <ArrowRight className="w-4 h-4" />
                            </Link>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

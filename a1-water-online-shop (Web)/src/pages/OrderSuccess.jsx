import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useAuth } from '../state/AuthContext.jsx'
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
    Check,
    ShieldCheck
} from 'lucide-react'
import { formatCurrency } from '../utils/format'
import { getProductImage, handleImageError } from '../utils/imageUtils.js'

export default function OrderSuccess() {
    const { id } = useParams()
    const { user } = useAuth()
    const navigate = useNavigate()
    const [copied, setCopied] = useState(false)
    const [orderDetails, setOrderDetails] = useState(null)

    useEffect(() => {
        window.scrollTo(0, 0)
        
        let active = true;
        const fetchOrder = async () => {
            if (!user?.uid || !id) return;
            try {
                const baseUrl = import.meta.env.VITE_API_BASE_URL;
                if (!baseUrl) return;
                
                const res = await fetch(
                    `${baseUrl}/orders/track?userId=${encodeURIComponent(user.uid)}&orderId=${encodeURIComponent(id)}`
                );
                
                if (res.ok && active) {
                    const data = await res.json();
                    if (data.item) {
                        setOrderDetails(data.item);
                        // Save to session storage as fallback
                        sessionStorage.setItem('lastOrder', JSON.stringify(data.item));
                    }
                }
            } catch (err) {
                console.error("Failed to fetch order:", err);
            }
        };

        // Try to load from session storage instantly for immediate UI feedback
        const savedOrder = sessionStorage.getItem('lastOrder');
        if (savedOrder) {
            try {
                const parsed = JSON.parse(savedOrder);
                if (parsed.orderId === id || parsed.id === id) {
                    setOrderDetails(parsed);
                }
            } catch {
                // Ignore parse error
            }
        }

        // Fetch immediately to ensure we have the absolute latest status
        fetchOrder();

        // Start 5-second polling loop for live status tracking
        const interval = setInterval(fetchOrder, 5000);

        return () => {
            active = false;
            clearInterval(interval);
        };
    }, [id, user?.uid])

    const copyOrderId = () => {
        navigator.clipboard.writeText(id)
        setCopied(true)
        setTimeout(() => setCopied(false), 2000)
    }

    const orderStatus = orderDetails?.status?.toLowerCase() || 'pending'
    let currentStep = 1; 
    if (orderStatus === 'confirmed' || orderStatus === 'shipped') currentStep = 2;
    if (orderStatus === 'completed' || orderStatus === 'delivered') currentStep = 3;

    const statusSteps = orderStatus === 'rejected' ? [
        { icon: CheckCircle, label: 'Order Placed', color: 'bg-emerald-500', active: true },
        { icon: CheckCircle, label: 'Admin Approval', color: 'bg-emerald-500', active: true },
        { icon: Package, label: 'Rejected', color: 'bg-rose-500', active: true },
    ] : [
        { icon: CheckCircle, label: 'Order Placed', color: 'bg-emerald-500', active: true },
        { icon: Package, label: 'Admin Approval', color: currentStep >= 1 ? 'bg-emerald-500' : 'bg-slate-200', active: currentStep >= 1 },
        { icon: Check, label: 'Confirmed', color: currentStep >= 2 ? 'bg-emerald-500' : 'bg-slate-200', active: currentStep >= 2 },
        { icon: MapPin, label: 'Delivered', color: currentStep >= 3 ? 'bg-emerald-500' : 'bg-slate-200', active: currentStep >= 3 },
    ]

    const generateReceipt = () => {
        const items = orderDetails?.items || [];
        const subtotal = orderDetails?.subtotal || 0;
        const gstAmount = orderDetails?.gstAmount || 0;
        const total = orderDetails?.total || 0;
        const orderId = id || 'N/A';
        const date = new Date().toLocaleDateString('en-IN');
        const address = orderDetails?.address || {};

        const receiptHtml = `
          <!DOCTYPE html>
          <html>
          <head>
            <title>Receipt - ${orderId}</title>
            <style>
              @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap');
              body { font-family: 'Inter', sans-serif; margin: 0; padding: 40px; color: #1e293b; line-height: 1.5; }
              .receipt-box { max-width: 600px; margin: 0 auto; border: 1px solid #e2e8f0; padding: 40px; border-radius: 12px; }
              .header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #f1f5f9; padding-bottom: 20px; }
              .header h1 { margin: 0; color: #4f46e5; font-size: 24px; font-weight: 800; }
              .header p { margin: 5px 0; color: #64748b; font-size: 12px; font-weight: 600; }
              .meta { display: flex; justify-content: space-between; margin-bottom: 30px; font-size: 13px; }
              .meta-item b { display: block; color: #94a3b8; text-transform: uppercase; font-size: 10px; margin-bottom: 4px; letter-spacing: 0.05em; }
              .table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
              .table th { text-align: left; padding: 12px 0; border-bottom: 2px solid #f1f5f9; font-size: 11px; color: #94a3b8; text-transform: uppercase; }
              .table td { padding: 16px 0; border-bottom: 1px solid #f8fafc; font-size: 14px; }
              .summary { margin-left: auto; width: 200px; }
              .summary-row { display: flex; justify-content: space-between; padding: 6px 0; font-size: 13px; color: #64748b; }
              .summary-row.total { border-top: 2px solid #f1f5f9; margin-top: 10px; padding-top: 12px; color: #0f172a; font-weight: 800; font-size: 16px; }
              .footer { text-align: center; margin-top: 40px; font-size: 12px; color: #94a3b8; }
            </style>
          </head>
          <body>
            <div class="receipt-box">
              <div class="header">
                <h1>A1 WATER TECH</h1>
                <p>Order Receipt / Proof of Purchase</p>
              </div>
              <div class="meta">
                <div class="meta-item"><b>Order ID</b>#${orderId}</div>
                <div class="meta-item" style="text-align: right;"><b>Date</b>${date}</div>
              </div>
              <div class="meta">
                <div class="meta-item"><b>Billed To</b>${address.name || 'Customer'}<br>${address.city || ''}</div>
                <div class="meta-item" style="text-align: right;"><b>Status</b>Success</div>
              </div>
              <table class="table">
                <thead><tr><th>Item</th><th style="text-align: center;">Qty</th><th style="text-align: right;">Price</th></tr></thead>
                <tbody>
                  ${items.map(item => `
                    <tr>
                      <td style="font-weight: 600;">${item.name}</td>
                      <td style="text-align: center;">${item.qty}</td>
                      <td style="text-align: right;">₹${(item.price * item.qty).toFixed(2)}</td>
                    </tr>
                  `).join('')}
                </tbody>
              </table>
              <div class="summary">
                <div class="summary-row"><span>Subtotal</span><span>₹${subtotal.toFixed(2)}</span></div>
                <div class="summary-row"><span>GST</span><span>₹${gstAmount.toFixed(2)}</span></div>
                <div class="summary-row.total"><span>Total</span><span>₹${total.toFixed(2)}</span></div>
              </div>
              <div class="footer">
                <p>Thank you for shopping with A1 Water Tech!</p>
              </div>
            </div>
          </body>
          </html>
        `;

        const iframe = document.createElement('iframe');
        iframe.style.position = 'absolute';
        iframe.style.width = '0px';
        iframe.style.height = '0px';
        iframe.style.border = 'none';
        document.body.appendChild(iframe);

        const doc = iframe.contentWindow.document;
        doc.open();
        doc.write(receiptHtml);
        doc.close();

        // Print once images/fonts load, or fallback to short delay
        setTimeout(() => {
            iframe.contentWindow.focus();
            iframe.contentWindow.print();
            
            // Cleanup iframe after print dialog closes
            setTimeout(() => {
                document.body.removeChild(iframe);
            }, 1000);
        }, 500);
    }

    return (
        <div className="min-h-screen bg-slate-50 py-12 px-4 font-sans">
            <div className="max-w-4xl mx-auto">
                {/* Success Header */}
                <div className="bg-white rounded-[3rem] p-10 mb-8 shadow-xl shadow-slate-200/50 border border-slate-100 relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-50 rounded-full -mr-32 -mt-32 z-0" />
                    <div className="relative z-10 flex flex-col items-center text-center">
                        <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center mb-6 shadow-inner border-4 border-white">
                            <CheckCircle className="w-10 h-10 text-emerald-600" />
                        </div>
                        <h1 className="text-4xl font-black text-slate-900 mb-3 tracking-tight">
                            {orderStatus === 'rejected' ? 'Order Rejected' : 'Order Placed Successfully!'}
                        </h1>
                        <p className="text-slate-500 text-lg font-medium max-w-md">
                            Thank you for your purchase. Your order has been received and is being processed.
                        </p>
                        <div className="mt-8 flex items-center gap-4 bg-slate-50 px-6 py-3 rounded-2xl border border-slate-100">
                            <Clock className="w-5 h-5 text-indigo-500" />
                            <span className="text-sm font-bold text-slate-700">Estimated Delivery: 2-3 Business Days</span>
                        </div>
                    </div>
                </div>

                {/* Order Progress Tracker */}
                <div className="bg-white rounded-[2.5rem] p-8 mb-8 shadow-sm border border-slate-200/60">
                    <h2 className="text-xs font-black text-slate-400 uppercase tracking-widest mb-8 text-center">Tracking Status</h2>
                    <div className="flex items-center justify-between relative px-4 sm:px-10">
                        {/* Progress Line */}
                        <div className="absolute top-6 left-0 right-0 h-1 bg-slate-100 rounded-full mx-12 sm:mx-20">
                            <div className="h-full w-1/3 bg-emerald-500 rounded-full transition-all duration-700" />
                        </div>

                        {statusSteps.map((step, index) => (
                            <div key={step.label} className="flex flex-col items-center relative z-10">
                                <div className={`w-12 h-12 rounded-2xl flex items-center justify-center mb-3 transition-all duration-500 shadow-sm ${
                                    step.active ? step.color + ' text-white scale-110 shadow-lg' : 'bg-white text-slate-300 border border-slate-100'
                                }`}>
                                    <step.icon className={`w-6 h-6`} />
                                </div>
                                <span className={`text-[10px] font-black uppercase tracking-widest ${step.active ? 'text-slate-900' : 'text-slate-400'}`}>
                                    {step.label}
                                </span>
                            </div>
                        ))}
                    </div>
                </div>

                <div className="grid md:grid-cols-12 gap-8">
                    {/* Left Column - Order Details */}
                    <div className="md:col-span-8 space-y-8">
                        {/* Order ID Section */}
                        <div className="bg-white rounded-[2rem] p-8 shadow-sm border border-slate-200/60">
                            <div className="flex items-center justify-between mb-6">
                                <h3 className="text-lg font-black text-slate-900 uppercase tracking-tight">Order Identification</h3>
                                <button
                                    onClick={copyOrderId}
                                    className="flex items-center gap-2 px-4 py-2 bg-indigo-50 text-indigo-600 hover:bg-indigo-100 rounded-xl text-xs font-black uppercase tracking-widest transition-all"
                                >
                                    {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                                    {copied ? 'Copied' : 'Copy ID'}
                                </button>
                            </div>
                            <div className="bg-slate-50 rounded-2xl p-6 border border-slate-100">
                                <p className="text-[10px] text-slate-400 font-black uppercase tracking-widest mb-2">Reference Number</p>
                                <p className="text-xl font-mono font-black text-slate-900 break-all tracking-tighter">{id}</p>
                            </div>
                        </div>

                        {/* Order Items */}
                        {orderDetails?.items && orderDetails.items.length > 0 && (
                            <div className="bg-white rounded-[2rem] p-8 shadow-sm border border-slate-200/60">
                                <h3 className="text-lg font-black text-slate-900 uppercase tracking-tight mb-6">Items Summary</h3>
                                <div className="space-y-4">
                                    {orderDetails.items.map((item, idx) => (
                                        <div key={idx} className="flex items-center gap-5 p-5 bg-slate-50/50 rounded-2xl border border-slate-100">
                                            <div className="w-16 h-16 bg-white rounded-xl flex items-center justify-center shadow-sm overflow-hidden">
                                                <img
                                                    src={getProductImage(item)}
                                                    alt={item.name}
                                                    onError={(e) => handleImageError(e, item.category?.toLowerCase().includes('service') ? 'service' : 'product')}
                                                    className="w-full h-full object-cover"
                                                />
                                            </div>
                                            <div className="flex-1">
                                                <p className="font-bold text-slate-900">{item.name}</p>
                                                <p className="text-xs text-slate-400 font-black uppercase tracking-widest mt-1">Quantity: {item.qty}</p>
                                            </div>
                                            <p className="font-black text-slate-900 text-lg">{formatCurrency(item.price * item.qty)}</p>
                                        </div>
                                    ))}
                                </div>
                                <div className="mt-8 pt-8 border-t border-slate-100 flex items-center justify-between">
                                    <div>
                                        <p className="text-[10px] text-slate-400 font-black uppercase tracking-widest mb-1">Total Payable</p>
                                        <span className="text-3xl font-black text-indigo-600">{formatCurrency(orderDetails.total)}</span>
                                    </div>
                                    <div className="text-right">
                                        <p className="text-[10px] text-slate-400 font-black uppercase tracking-widest mb-1">Payment Method</p>
                                        <span className="text-sm font-bold text-slate-700">{orderDetails.paymentMethod || 'Online Payment'}</span>
                                    </div>
                                </div>
                            </div>
                        )}

                        {/* Delivery Address */}
                        {orderDetails?.address && (
                            <div className="bg-white rounded-[2rem] p-8 shadow-sm border border-slate-200/60">
                                <div className="flex items-center gap-4 mb-6">
                                    <div className="w-12 h-12 bg-indigo-50 rounded-2xl flex items-center justify-center text-indigo-600 shadow-sm">
                                        <MapPin className="w-6 h-6" />
                                    </div>
                                    <h3 className="text-lg font-black text-slate-900 uppercase tracking-tight">Shipping Location</h3>
                                </div>
                                <div className="bg-indigo-600/5 rounded-2xl p-6 border border-indigo-100">
                                    <p className="font-black text-slate-900 text-lg mb-2">{orderDetails.address.name}</p>
                                    <p className="text-slate-600 font-medium leading-relaxed">{orderDetails.address.address || orderDetails.address.line1}</p>
                                    <p className="text-slate-600 font-medium leading-relaxed">{orderDetails.address.city}, {orderDetails.address.state || ''} - {orderDetails.address.pincode}</p>
                                    <div className="mt-4 inline-flex items-center gap-2 px-4 py-2 bg-white rounded-xl border border-indigo-100 text-xs font-black text-indigo-600 shadow-sm">
                                        📞 {orderDetails.address.phone}
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>

                    {/* Right Column - Actions */}
                    <div className="md:col-span-4 space-y-6">
                        {/* Quick Actions */}
                        <div className="bg-slate-900 rounded-[2rem] p-8 text-white shadow-xl shadow-slate-300">
                            <h3 className="text-sm font-black uppercase tracking-widest text-slate-400 mb-6">Actions</h3>
                            <div className="space-y-4">
                                <button
                                    onClick={() => navigate('/orders')}
                                    className="w-full bg-white text-slate-900 font-black py-4 rounded-2xl shadow-lg transition-all flex items-center justify-center gap-3 hover:-translate-y-1 active:scale-[0.98]"
                                >
                                    <ShoppingBag className="w-5 h-5" />
                                    Order History
                                </button>
                                <button
                                    onClick={generateReceipt}
                                    disabled={!orderDetails}
                                    className={`w-full font-black py-4 rounded-2xl transition-all flex items-center justify-center gap-3 ${
                                        orderDetails 
                                            ? 'bg-slate-800 text-white hover:bg-slate-700' 
                                            : 'bg-slate-800/50 text-white/50 cursor-not-allowed'
                                    }`}
                                >
                                    <Printer className="w-5 h-5" />
                                    {orderDetails ? 'Print Receipt' : 'Loading Invoice...'}
                                </button>
                            </div>
                        </div>

                        {/* Continue Shopping Card */}
                        <Link
                            to="/shop"
                            className="block bg-indigo-600 rounded-[2rem] p-8 text-white hover:bg-indigo-700 transition-all group shadow-xl shadow-indigo-100"
                        >
                            <div className="flex items-center justify-between mb-4">
                                <div className="w-12 h-12 bg-white/20 rounded-2xl flex items-center justify-center">
                                    <ShoppingBag className="w-6 h-6 text-white" />
                                </div>
                                <ChevronRight className="w-6 h-6 group-hover:translate-x-1 transition-transform" />
                            </div>
                            <h3 className="font-black text-xl mb-1 tracking-tight">Keep Shopping</h3>
                            <p className="text-indigo-100 text-sm font-medium">Discover more hydration solutions</p>
                        </Link>

                        {/* Security Badge */}
                        <div className="bg-emerald-50 rounded-[2rem] p-8 border border-emerald-100 flex flex-col items-center text-center">
                            <ShieldCheck className="w-12 h-12 text-emerald-600 mb-4" />
                            <h3 className="font-black text-emerald-900 uppercase tracking-tight text-sm mb-2">Secure Purchase</h3>
                            <p className="text-emerald-700/70 text-xs font-bold leading-relaxed">
                                Your transaction is protected by industry-standard encryption and security protocols.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

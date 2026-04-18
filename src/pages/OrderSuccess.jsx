import { useEffect } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { CheckCircle, ShoppingBag, ArrowRight } from 'lucide-react'

export default function OrderSuccess() {
    const { id } = useParams()
    const navigate = useNavigate()

    useEffect(() => {
        window.scrollTo(0, 0)
    }, [])

    return (
        <div className="container mx-auto px-4 py-20 min-h-[60vh] flex flex-col items-center justify-center font-sans text-center">
            <div className="bg-white p-8 md:p-12 rounded-3xl shadow-xl shadow-indigo-100 border border-indigo-50 max-w-lg w-full">
                <div className="w-20 h-20 bg-green-100 text-green-600 rounded-full flex items-center justify-center mx-auto mb-6 animate-bounce">
                    <CheckCircle className="w-10 h-10" />
                </div>

                <h1 className="text-3xl font-bold text-slate-900 mb-2">Order Confirmed!</h1>
                <p className="text-slate-500 mb-6">Thank you for your purchase. We've received your order and will begin processing it right away.</p>

                <div className="bg-slate-50 rounded-xl p-4 mb-8 border border-slate-100">
                    <p className="text-xs text-slate-400 uppercase font-bold tracking-wide mb-1">Order ID</p>
                    <p className="text-lg font-mono font-bold text-slate-800 tracking-wider">{id}</p>
                </div>

                <div className="flex flex-col gap-3">
                    <button
                        onClick={() => navigate('/orders')}
                        className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3.5 rounded-xl shadow-lg shadow-indigo-200 transition-all flex items-center justify-center gap-2"
                    >
                        <ShoppingBag className="w-5 h-5" /> View My Orders
                    </button>
                    <Link
                        to="/shop"
                        className="w-full bg-white hover:bg-slate-50 text-slate-700 font-bold py-3.5 rounded-xl border border-slate-200 transition-all flex items-center justify-center gap-2"
                    >
                        Continue Shopping <ArrowRight className="w-4 h-4" />
                    </Link>
                </div>
            </div>
        </div>
    )
}

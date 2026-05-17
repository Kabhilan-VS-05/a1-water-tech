import { useState, useEffect } from 'react'
import { Routes, Route } from 'react-router-dom'
import Header from './components/Header.jsx'
import Footer from './components/Footer.jsx'
import ToastStack from './components/ToastStack.jsx'
import NotificationListener from './components/NotificationListener.jsx'
import ScrollToTop from './components/ScrollToTop.jsx'
import Home from './pages/Home.jsx'
import Shop from './pages/Shop.jsx'
import ProductDetail from './pages/ProductDetail.jsx'
import Cart from './pages/Cart.jsx'
import Checkout from './pages/Checkout.jsx'
import NotFound from './pages/NotFound.jsx'
import Login from './pages/Login.jsx'
import RequireAuth from './routes/RequireAuth.jsx'
import Profile from './pages/Profile.jsx'
import Orders from './pages/Orders.jsx'
import TrackOrder from './pages/TrackOrder.jsx'
import Bookings from './pages/Bookings.jsx'
import Services from './pages/Services.jsx'
import OrderSuccess from './pages/OrderSuccess.jsx'
import FAQ from './pages/FAQ.jsx'
import Contact from './pages/Contact.jsx'
import TermsOfService from './pages/TermsOfService.jsx'
import PrivacyPolicy from './pages/PrivacyPolicy.jsx'
import { Droplet } from 'lucide-react'

function App() {
  const [loading, setLoading] = useState(true)
  const [fade, setFade] = useState(false)

  useEffect(() => {
    // Elegant boot loader that guarantees all styles, scripts, and fonts are ready.
    const handleLoad = () => {
      // Small graceful buffer so elements layout cleanly before showing
      setTimeout(() => {
        setFade(true)
        setTimeout(() => {
          setLoading(false)
        }, 500) // matches transition duration
      }, 1000)
    }

    if (document.readyState === 'complete') {
      handleLoad()
    } else {
      window.addEventListener('load', handleLoad)
      return () => window.removeEventListener('load', handleLoad)
    }
  }, [])

  return (
    <>
      {/* ── Global Visual Preloader ────────────────────────────── */}
      {loading && (
        <div
          className={`fixed inset-0 z-[9999] flex flex-col items-center justify-center bg-white transition-opacity duration-500 ease-out ${
            fade ? 'opacity-0 pointer-events-none' : 'opacity-100'
          }`}
        >
          <div className="flex flex-col items-center max-w-xs text-center px-4">
            
            {/* Spinning/pulsating branding badge */}
            <div className="relative flex items-center justify-center w-20 h-20 mb-6">
              {/* Outer pulsing ring */}
              <div className="absolute inset-0 rounded-full border-2 border-indigo-100 animate-ping opacity-75" />
              {/* Spinning primary gradient track */}
              <div className="absolute inset-0 rounded-full border-[3px] border-slate-100 border-t-indigo-600 animate-spin" />
              {/* Centered brand water droplet icon */}
              <div className="w-12 h-12 rounded-full bg-indigo-50 flex items-center justify-center relative">
                <Droplet className="w-6 h-6 text-indigo-600 animate-bounce" />
              </div>
            </div>

            {/* Premium preloader brand typography */}
            <h2 className="text-xl font-extrabold text-slate-900 tracking-tight">A1 WATER TECH</h2>
            <p className="text-[11px] font-black text-indigo-600 tracking-[0.2em] uppercase mt-1">Water Solutions</p>
            
            {/* Soft status hint */}
            <div className="mt-8 flex items-center gap-2 bg-slate-50 px-4 py-2 rounded-full border border-slate-100 shadow-sm">
              <span className="w-1.5 h-1.5 rounded-full bg-indigo-600 animate-pulse" />
              <span className="text-[11px] font-semibold text-slate-500">Purifying your experience...</span>
            </div>

          </div>
        </div>
      )}

      {/* ── Main Application Content ──────────────────────────── */}
      <div className="min-h-screen flex flex-col font-sans bg-white text-slate-700">
        <Header />
        <ScrollToTop />
        <ToastStack />
        <NotificationListener />
        <main className="flex-1">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/shop" element={<Shop />} />
            <Route path="/shop/:id" element={<ProductDetail />} />
            <Route
              path="/cart"
              element={
                <RequireAuth>
                  <Cart />
                </RequireAuth>
              }
            />
            <Route
              path="/checkout"
              element={
                <RequireAuth>
                  <Checkout />
                </RequireAuth>
              }
            />
            <Route
              path="/order-confirmation/:id"
              element={
                <RequireAuth>
                  <OrderSuccess />
                </RequireAuth>
              }
            />
            <Route path="/login" element={<Login />} />
            <Route
              path="/profile"
              element={
                <RequireAuth>
                  <Profile />
                </RequireAuth>
              }
            />
            <Route
              path="/orders"
              element={
                <RequireAuth>
                  <Orders />
                </RequireAuth>
              }
            />
            <Route
              path="/track"
              element={
                <RequireAuth>
                  <TrackOrder />
                </RequireAuth>
              }
            />
            <Route
              path="/bookings"
              element={
                <RequireAuth>
                  <Bookings />
                </RequireAuth>
              }
            />
            <Route path="/services" element={<Services />} />
            <Route path="/faq" element={<FAQ />} />
            <Route path="/contact" element={<Contact />} />
            <Route path="/terms" element={<TermsOfService />} />
            <Route path="/privacy" element={<PrivacyPolicy />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </main>
        <Footer />
      </div>
    </>
  )
}

export default App

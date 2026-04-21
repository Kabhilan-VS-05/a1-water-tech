import { Link } from 'react-router-dom'
import { AlertTriangle, Home } from 'lucide-react'

export default function NotFound() {
  return (
    <div className="min-h-[60vh] flex flex-col items-center justify-center p-8 font-sans text-center">
      <div className="w-24 h-24 bg-amber-50 text-amber-500 rounded-full flex items-center justify-center mb-6 animate-pulse">
        <AlertTriangle className="w-12 h-12" />
      </div>
      <h1 className="text-4xl font-extrabold text-slate-900 mb-2 tracking-tight">404</h1>
      <h2 className="text-2xl font-bold text-slate-700 mb-4">Page Not Found</h2>
      <p className="text-slate-500 max-w-sm mx-auto mb-8">
        The page you are looking for might have been removed, had its name changed, or is temporarily unavailable.
      </p>
      <Link
        to="/"
        className="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3 px-8 rounded-xl shadow-lg shadow-indigo-200 transition-all hover:-translate-y-1"
      >
        <Home className="w-5 h-5" /> Go Back Home
      </Link>
    </div>
  )
}

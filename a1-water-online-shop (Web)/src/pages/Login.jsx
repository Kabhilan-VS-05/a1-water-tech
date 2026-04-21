import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../state/AuthContext.jsx'
import { confirmSignUpWithCognito, resendConfirmationCode } from '../cognito.js'
import { Mail, Lock, ArrowRight, Loader2, AlertCircle, ShieldCheck } from 'lucide-react'

export default function Login() {
  const { signIn, signUp } = useAuth()
  const [mode, setMode] = useState('login')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [code, setCode] = useState('')
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [loading, setLoading] = useState(false)

  const navigate = useNavigate()
  const location = useLocation()

  const handleSubmit = async (event) => {
    event.preventDefault()
    setError('')
    setNotice('')
    setLoading(true)
    try {
      if (mode === 'confirm') {
        await confirmSignUpWithCognito(email, code.trim())
        setMode('login')
        setCode('')
        setNotice('Account verified. Sign in now.')
      } else if (mode === 'login') {
        await signIn(email, password)
        const next = location.state?.from || '/shop'
        navigate(next, { replace: true })
      } else {
        const result = await signUp(email, password)
        if (result?.confirmed) {
          await signIn(email, password)
          const next = location.state?.from || '/shop'
          navigate(next, { replace: true })
        } else {
          setMode('confirm')
          setNotice('Account created. Enter the verification code from your email.')
        }
      }
    } catch (err) {
      if (err?.code === 'UserNotConfirmedException') {
        setMode('confirm')
        setNotice('Your account is not verified yet. Enter the code from your email.')
      } else {
        setError(err.message || 'Authentication failed. Please check your credentials.')
      }
    } finally {
      setLoading(false)
    }
  }

  const handleResendCode = async () => {
    if (!email) {
      setError('Enter your email first so we know where to send the code.')
      return
    }

    setError('')
    setNotice('')
    setLoading(true)

    try {
      await resendConfirmationCode(email)
      setNotice('A new verification code was sent to your email.')
    } catch (err) {
      setError(err.message || 'Unable to resend the verification code right now.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-[80vh] flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8 font-sans bg-slate-50">
      <div className="max-w-md w-full space-y-8 bg-white p-8 md:p-10 rounded-3xl shadow-xl shadow-slate-200 border border-slate-100">
        <div className="text-center">
          <h2 className="text-3xl font-extrabold text-slate-900 tracking-tight">
            {mode === 'login'
              ? 'Welcome Back'
              : mode === 'signup'
                ? 'Create Account'
                : 'Verify Email'}
          </h2>
          <p className="mt-2 text-sm text-slate-500">
            {mode === 'login'
              ? 'Sign in to access your orders and bookings.'
              : mode === 'signup'
                ? 'Join A1 Water Tech for exclusive services.'
                : 'Enter the verification code that Cognito sent to your email.'}
          </p>
        </div>

        {/* Tabs */}
        <div className="flex p-1 bg-slate-100 rounded-xl">
          <button
            type="button"
            onClick={() => setMode('login')}
            className={`flex-1 py-2.5 text-sm font-bold rounded-lg transition-all ${mode === 'login'
                ? 'bg-white text-indigo-600 shadow-sm'
                : 'text-slate-500 hover:text-slate-700'
              }`}
          >
            Log In
          </button>
          <button
            type="button"
            onClick={() => setMode('signup')}
            className={`flex-1 py-2.5 text-sm font-bold rounded-lg transition-all ${mode === 'signup'
                ? 'bg-white text-indigo-600 shadow-sm'
                : 'text-slate-500 hover:text-slate-700'
              }`}
          >
            Sign Up
          </button>
        </div>

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="space-y-4">
            <div>
              <label htmlFor="email" className="sr-only">Email address</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Mail className="h-5 w-5 text-slate-400" />
                </div>
                <input
                  id="email"
                  name="email"
                  type="email"
                  autoComplete="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="appearance-none relative block w-full pl-10 pr-3 py-3 border border-slate-200 placeholder-slate-400 text-slate-900 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm transition-shadow"
                  placeholder="Email address"
                />
              </div>
            </div>

            {mode === 'confirm' ? (
              <div>
                <label htmlFor="code" className="sr-only">Verification code</label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <ShieldCheck className="h-5 w-5 text-slate-400" />
                  </div>
                  <input
                    id="code"
                    name="code"
                    type="text"
                    required
                    value={code}
                    onChange={(e) => setCode(e.target.value)}
                    className="appearance-none relative block w-full pl-10 pr-3 py-3 border border-slate-200 placeholder-slate-400 text-slate-900 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm transition-shadow"
                    placeholder="Verification code"
                  />
                </div>
              </div>
            ) : (
              <div>
                <label htmlFor="password" className="sr-only">Password</label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Lock className="h-5 w-5 text-slate-400" />
                  </div>
                  <input
                    id="password"
                    name="password"
                    type="password"
                    autoComplete="current-password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="appearance-none relative block w-full pl-10 pr-3 py-3 border border-slate-200 placeholder-slate-400 text-slate-900 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm transition-shadow"
                    placeholder="Password"
                  />
                </div>
              </div>
            )}
          </div>

          {notice && (
            <div className="rounded-lg bg-indigo-50 p-4 border border-indigo-100">
              <p className="text-sm text-indigo-700 font-medium">{notice}</p>
            </div>
          )}

          {error && (
            <div className="rounded-lg bg-red-50 p-4 border border-red-100 flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0 mt-0.5" />
              <p className="text-sm text-red-700 font-medium">{error}</p>
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="group relative w-full flex justify-center py-3 px-4 border border-transparent text-sm font-bold rounded-xl text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 shadow-lg shadow-indigo-200 transition-all disabled:bg-indigo-400 disabled:cursor-not-allowed"
          >
            {loading ? (
              <Loader2 className="w-5 h-5 animate-spin" />
            ) : (
              <div className="flex items-center gap-2">
                {mode === 'login'
                  ? 'Sign In'
                  : mode === 'signup'
                    ? 'Create Account'
                    : 'Verify Code'} <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              </div>
            )}
          </button>

          {mode === 'confirm' && (
            <button
              type="button"
              onClick={handleResendCode}
              disabled={loading}
              className="w-full text-sm font-bold text-indigo-600 hover:text-indigo-700 disabled:text-indigo-300"
            >
              Resend verification code
            </button>
          )}
        </form>

        <div className="mt-6 text-center">
          <p className="text-xs text-slate-400">
            By continuing, you agree to our Terms of Service and Privacy Policy.
          </p>
        </div>
      </div>
    </div>
  )
}

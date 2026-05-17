import { useToast } from '../state/ToastContext.jsx'
import { CheckCircle, AlertCircle, X } from 'lucide-react'

export default function ToastStack() {
  const { toasts, removeToast } = useToast()

  return (
    <div className="fixed bottom-5 right-5 z-50 flex flex-col gap-2 max-w-sm w-full pointer-events-none">
      {toasts.map(toast => (
        <div
          key={toast.id}
          className={`pointer-events-auto flex items-start gap-3 px-4 py-3 rounded-xl border shadow-lg text-sm font-medium transition-all ${
            toast.type === 'error'
              ? 'bg-white border-red-200 text-red-700'
              : 'bg-slate-900 border-slate-800 text-white'
          }`}
        >
          <div className="flex-shrink-0 mt-0.5">
            {toast.type === 'error'
              ? <AlertCircle className="w-4 h-4 text-red-500" />
              : <CheckCircle className="w-4 h-4 text-emerald-400" />
            }
          </div>
          <span className="flex-1 leading-relaxed">{toast.message}</span>
          <button
            onClick={() => removeToast(toast.id)}
            className="flex-shrink-0 opacity-50 hover:opacity-100 transition-opacity mt-0.5"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      ))}
    </div>
  )
}

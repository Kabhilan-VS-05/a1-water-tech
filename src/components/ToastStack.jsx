import { useToast } from '../state/ToastContext.jsx'
import { Info, CheckCircle, AlertOctagon, X } from 'lucide-react'

export default function ToastStack() {
  const { toasts, removeToast } = useToast()

  return (
    <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-3 font-sans max-w-sm w-full pointer-events-none">
      {toasts.map((toast) => (
        <div
          key={toast.id}
          className={`pointer-events-auto flex items-start gap-3 p-4 rounded-xl shadow-lg border animate-accordion-up transition-all transform ${toast.type === 'error'
              ? 'bg-red-50 text-red-800 border-red-100'
              : 'bg-slate-900 text-white border-slate-700'
            }`}
        >
          <div className="flex-shrink-0 mt-0.5">
            {toast.type === 'error' ? <AlertOctagon className="w-5 h-5" /> : <CheckCircle className="w-5 h-5 text-green-400" />}
          </div>
          <div className="flex-1 text-sm font-medium leading-relaxed">
            {toast.message}
          </div>
          <button
            onClick={() => removeToast(toast.id)}
            className="opacity-60 hover:opacity-100 transition-opacity"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      ))}
    </div>
  )
}

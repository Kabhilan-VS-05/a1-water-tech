export default function PageHeader({ eyebrow, title, subtitle, actions }) {
  return (
    <div className="mb-6 pb-6 border-b border-slate-100">
      {eyebrow && (
        <p className="section-label mb-2">{eyebrow}</p>
      )}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">{title}</h1>
          {subtitle && <p className="text-sm text-slate-500 mt-1">{subtitle}</p>}
        </div>
        {actions && (
          <div className="flex flex-wrap items-center gap-3">{actions}</div>
        )}
      </div>
    </div>
  )
}

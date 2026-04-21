export default function PageHeader({ eyebrow, title, subtitle, actions }) {
  return (
    <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-6 mb-12 border-b border-slate-100 pb-8 font-sans">
      <div className="max-w-2xl">
        {eyebrow && (
          <span className="inline-block py-1 px-3 rounded-full bg-indigo-50 text-indigo-600 text-[10px] font-bold tracking-wider uppercase mb-3">
            {eyebrow}
          </span>
        )}
        <h1 className="text-3xl md:text-4xl font-extrabold text-slate-900 tracking-tight mb-2">
          {title}
        </h1>
        {subtitle && <p className="text-lg text-slate-500 leading-relaxed">{subtitle}</p>}
      </div>
      {actions && <div className="flex flex-wrap gap-3 w-full md:w-auto">{actions}</div>}
    </div>
  )
}

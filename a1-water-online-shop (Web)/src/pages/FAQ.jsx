import { faqs } from '../data/services.js'
import PageHeader from '../components/PageHeader.jsx'
import { Plus, Minus, Search } from 'lucide-react'
import { useState } from 'react'

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState(null)
  const [search, setSearch] = useState('')

  const filteredFaqs = faqs.filter(f =>
    f.q.toLowerCase().includes(search.toLowerCase()) ||
    f.a.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="container mx-auto px-4 py-12 max-w-4xl font-sans text-slate-900">
      <PageHeader
        eyebrow="Support"
        title="Answers to common questions"
        subtitle="Everything you need to know about our products, billing, and annual service plans."
      />

      <div className="mb-12 relative">
        <input
          type="text"
          placeholder="Search FAQs..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full p-4 pl-12 bg-white border border-slate-200 rounded-2xl shadow-sm focus:ring-2 focus:ring-indigo-500 outline-none transition-all"
        />
        <Search className="w-5 h-5 text-slate-400 absolute left-4 top-4.5" />
      </div>

      <div className="space-y-4">
        {filteredFaqs.length > 0 ? (
          filteredFaqs.map((item, index) => (
            <div
              key={index}
              className="bg-white border border-slate-100 rounded-2xl shadow-sm overflow-hidden transition-all"
            >
              <button
                onClick={() => setOpenIndex(openIndex === index ? null : index)}
                className="w-full p-6 text-left flex justify-between items-center hover:bg-slate-50 transition-colors"
                aria-expanded={openIndex === index}
              >
                <span className="font-bold text-slate-800 pr-4">{item.q}</span>
                <div className={`p-1 rounded-full bg-slate-100 text-slate-600 transition-transform duration-300 ${openIndex === index ? 'rotate-180' : ''}`}>
                  {openIndex === index ? <Minus className="w-4 h-4" /> : <Plus className="w-4 h-4" />}
                </div>
              </button>

              <div
                className={`transition-all duration-300 ease-in-out ${openIndex === index ? 'max-h-96 opacity-100 p-6 pt-0 border-t border-slate-50' : 'max-h-0 opacity-0 overflow-hidden'
                  }`}
              >
                <p className="text-slate-600 leading-relaxed text-sm">
                  {item.a}
                </p>
              </div>
            </div>
          ))
        ) : (
          <div className="text-center py-12 text-slate-500 font-medium">
            No matching questions found. Try a different keyword.
          </div>
        )}
      </div>

      <div className="mt-16 bg-slate-900 rounded-3xl p-8 md:p-12 text-center text-white">
        <h3 className="text-2xl font-bold mb-2">Still have questions?</h3>
        <p className="text-slate-400 mb-8">Can't find the answer you're looking for? Please chat with our friendly team.</p>
        <a href="/contact" className="inline-flex bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-3 px-8 rounded-xl transition-all shadow-lg shadow-indigo-500/20">
          Get in Touch
        </a>
      </div>
    </div>
  )
}

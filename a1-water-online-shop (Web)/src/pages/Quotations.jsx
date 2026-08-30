import { useState, useMemo } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../state/AuthContext.jsx'
import useQuotations from '../hooks/useQuotations.js'
import useAddresses from '../hooks/useAddresses.js'
import { formatCurrency } from '../utils/format.js'
import {
  FileText, Clock, CheckCircle, AlertCircle, ChevronRight,
  RefreshCcw, Loader2, Download, XCircle, Search, Phone
} from 'lucide-react'

const formatDate = (value) => {
  if (!value) return 'Pending'
  if (value?.toDate) return value.toDate().toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
  return new Date(value).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
}

const getStatusBadge = (status) => {
  switch (status?.toLowerCase()) {
    case 'accepted':  return 'badge-success'
    case 'sent':      return 'badge-primary'
    case 'rejected':  return 'badge-error'
    case 'expired':   return 'badge-warning'
    default:          return 'badge-secondary'
  }
}

const getStatusIcon = (status) => {
  switch (status?.toLowerCase()) {
    case 'accepted':  return <CheckCircle className="w-3 h-3" />
    case 'rejected':  return <XCircle className="w-3 h-3" />
    case 'sent':      return <FileText className="w-3 h-3" />
    default:          return <Clock className="w-3 h-3" />
  }
}

export default function Quotations() {
  const { user } = useAuth()
  const [refreshKey, setRefreshKey] = useState(0)
  const { addresses } = useAddresses(user?.uid, refreshKey)
  const [customPhone, setCustomPhone] = useState('')
  const [searchQuery, setSearchQuery] = useState('')

  // Discovered phone from address book or user
  const discoveredPhone = useMemo(() => {
    if (customPhone.trim()) return customPhone.trim()
    const firstAddrPhone = addresses?.find(a => a.phone && a.phone.trim())?.phone
    return firstAddrPhone || user?.phoneNumber || ''
  }, [customPhone, addresses, user])

  const email = user?.email || ''
  const { quotations, loading, updateStatus } = useQuotations(user?.uid, discoveredPhone, email, refreshKey)
  const [updatingId, setUpdatingId] = useState(null)

  const handleStatusUpdate = async (e, id, status) => {
    e.stopPropagation()
    try {
      setUpdatingId(id)
      await updateStatus(id, status)
    } catch (err) {
      alert(err.message || 'Failed to update quotation')
    } finally {
      setUpdatingId(null)
    }
  }

  const generateQuotationPdf = (e, q) => {
    e.stopPropagation()
    const w = window.open('', '_blank')
    if (!w) { alert('Please allow popups to view the quotation.'); return }

    const items     = q.items || []
    const subtotal  = q.subtotal || 0
    const gstAmount = q.gstAmount || 0
    const total     = q.total || 0
    const qNumber   = q.quotationNumber || q.id.slice(0, 8).toUpperCase()
    const date      = formatDate(q.createdAt)
    const validDate = formatDate(q.validUntil)

    w.document.write(`<!DOCTYPE html>
<html>
<head>
  <title>Quotation #${qNumber}</title>
  <meta charset="UTF-8">
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: 'Inter', sans-serif; color: #1e293b; background: #fff; padding: 48px; font-size: 14px; line-height: 1.5; }
    .wrap { max-width: 720px; margin: 0 auto; }

    /* Header */
    .inv-header { display: flex; justify-content: space-between; align-items: flex-start; padding-bottom: 28px; border-bottom: 1px solid #e2e8f0; margin-bottom: 28px; }
    .brand-name { font-size: 20px; font-weight: 800; color: #4f46e5; letter-spacing: -0.02em; }
    .brand-sub { font-size: 12px; color: #94a3b8; margin-top: 3px; }
    .inv-meta { text-align: right; }
    .inv-title { font-size: 22px; font-weight: 800; color: #0f172a; margin-bottom: 8px; }
    .inv-detail { font-size: 12px; color: #64748b; margin-top: 4px; }
    .inv-detail strong { color: #1e293b; }

    /* Billing grid */
    .billing { display: grid; grid-template-columns: 1fr; gap: 28px; margin-bottom: 28px; }
    .billing-box { background: #f8fafc; border-radius: 8px; padding: 16px; border: 1px solid #e2e8f0; }
    .billing-label { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; color: #94a3b8; margin-bottom: 10px; }
    .billing-name { font-size: 15px; font-weight: 700; color: #0f172a; margin-bottom: 4px; }
    .billing-line { font-size: 13px; color: #475569; }

    /* Table */
    table { width: 100%; border-collapse: collapse; margin-bottom: 28px; }
    thead th { background: #f1f5f9; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; color: #64748b; padding: 10px 12px; text-align: left; }
    tbody td { padding: 12px; border-bottom: 1px solid #f1f5f9; font-size: 13px; color: #334155; }
    tbody tr:last-child td { border-bottom: none; }
    .item-name { font-weight: 600; color: #0f172a; }

    /* Summary */
    .summary { display: flex; justify-content: flex-end; margin-bottom: 32px; }
    .summary-table { width: 240px; }
    .sum-row { display: flex; justify-content: space-between; padding: 6px 0; font-size: 13px; color: #64748b; }
    .sum-row.total { border-top: 2px solid #e2e8f0; margin-top: 10px; padding-top: 12px; font-weight: 800; font-size: 16px; color: #0f172a; }

    /* Footer */
    .notes-box { background: #f8fafc; padding: 16px; border-radius: 8px; margin-bottom: 32px; border-left: 3px solid #4f46e5; }
    .notes-title { font-size: 11px; font-weight: 700; color: #4f46e5; text-transform: uppercase; margin-bottom: 4px; }
    .notes-content { font-size: 13px; color: #475569; }

    .inv-footer { border-top: 1px solid #e2e8f0; padding-top: 20px; text-align: center; color: #64748b; font-size: 12px; }
    
    .print-btn { margin-top: 32px; display: inline-block; background: #4f46e5; color: #fff; border: none; padding: 10px 20px; border-radius: 6px; font-weight: 700; cursor: pointer; font-size: 13px; }
    @media print { .print-btn { display: none; } body { padding: 24px; } }
  </style>
</head>
<body>
<div class="wrap">
  <div class="inv-header">
    <div>
      <div class="brand-name">A1 WATER TECH</div>
      <div class="brand-sub">Premium Water Purification Systems</div>
      <div class="brand-sub" style="margin-top:2px;">GSTIN: 33AAAAA0000A1Z5 &nbsp;|&nbsp; +91 87783 08119</div>
    </div>
    <div class="inv-meta">
      <div class="inv-title">QUOTATION</div>
      <div class="inv-detail">Quotation No: <strong>#${qNumber}</strong></div>
      <div class="inv-detail">Date: <strong>${date}</strong></div>
      <div class="inv-detail">Valid Until: <strong>${validDate}</strong></div>
    </div>
  </div>

  <div class="billing">
    <div class="billing-box">
      <div class="billing-label">Prepared For</div>
      <div class="billing-name">${q.customerName || 'Customer'}</div>
      ${q.customerPhone ? `<div class="billing-line">${q.customerPhone}</div>` : ''}
      ${q.customerAddress ? `<div class="billing-line">${q.customerAddress}</div>` : ''}
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th>Item Description</th>
        <th style="text-align:right">Qty</th>
        <th style="text-align:right">Price</th>
        <th style="text-align:right">Total</th>
      </tr>
    </thead>
    <tbody>
      ${items.map(item => `
        <tr>
          <td>
            <div class="item-name">${item.name || item.description || 'Service/Product'}</div>
          </td>
          <td style="text-align:right">${item.quantity || item.qty || 1}</td>
          <td style="text-align:right">₹${(item.unitPrice || item.price || 0).toFixed(2)}</td>
          <td style="text-align:right; font-weight:600; color:#0f172a;">₹${((item.quantity || item.qty || 1) * (item.unitPrice || item.price || 0)).toFixed(2)}</td>
        </tr>
      `).join('')}
    </tbody>
  </table>

  <div class="summary">
    <div class="summary-table">
      <div class="sum-row">
        <span>Subtotal</span>
        <span style="color:#0f172a; font-weight:500;">₹${subtotal.toFixed(2)}</span>
      </div>
      ${gstAmount > 0 ? `
      <div class="sum-row">
        <span>GST</span>
        <span style="color:#0f172a; font-weight:500;">₹${gstAmount.toFixed(2)}</span>
      </div>` : ''}
      <div class="sum-row total">
        <span>Total Amount</span>
        <span>₹${total.toFixed(2)}</span>
      </div>
    </div>
  </div>

  ${q.notes ? `
  <div class="notes-box">
    <div class="notes-title">Notes & Terms</div>
    <div class="notes-content">${q.notes}</div>
  </div>
  ` : ''}

  <div class="inv-footer">
    <p>This is a computer-generated quotation and does not require a physical signature.</p>
    <button class="print-btn" onclick="window.print()">Print Quotation</button>
  </div>
</div>
</body>
</html>`)
    w.document.close()
  }

  const filteredQuotations = useMemo(() => {
    if (!searchQuery.trim()) return quotations
    const q = searchQuery.toLowerCase().trim()
    return quotations.filter(item => 
      (item.quotationNumber || '').toLowerCase().includes(q) ||
      (item.customerName || '').toLowerCase().includes(q) ||
      (item.customerPhone || '').includes(q)
    )
  }, [quotations, searchQuery])

  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
            My Quotations
          </h1>
          <p className="text-slate-500 mt-1">
            View and download quotations from A1 Water Tech.
          </p>
        </div>
        <button
          onClick={() => setRefreshKey(k => k + 1)}
          disabled={loading}
          className="inline-flex items-center justify-center gap-2 px-4 py-2 bg-white border border-slate-200 text-slate-700 font-medium rounded-lg hover:bg-slate-50 hover:text-slate-900 transition-colors focus:ring-2 focus:ring-slate-200 disabled:opacity-50"
        >
          <RefreshCcw className={"w-4 h-4 " + (loading ? 'animate-spin' : '')} />
          Refresh
        </button>
      </div>

      {/* Phone / Number Lookup Bar */}
      <div className="bg-white p-4 rounded-xl border border-slate-200/80 shadow-sm mb-6 flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            placeholder="Filter by Quotation # or Name..."
            className="w-full pl-9 pr-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
          />
        </div>
        <div className="relative sm:w-64">
          <Phone className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="tel"
            value={customPhone}
            onChange={e => setCustomPhone(e.target.value)}
            placeholder="Phone (e.g. 9876543210)"
            className="w-full pl-9 pr-3 py-2 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
          />
        </div>
      </div>

      {/* Main Content */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        {loading && filteredQuotations.length === 0 ? (
          <div className="py-24 text-center">
            <Loader2 className="w-8 h-8 text-indigo-600 animate-spin mx-auto mb-4" />
            <p className="text-slate-500 font-medium animate-pulse">Loading your quotations...</p>
          </div>
        ) : filteredQuotations.length === 0 ? (
          <div className="py-24 px-6 text-center">
            <div className="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center mx-auto mb-4">
              <FileText className="w-8 h-8 text-slate-400" />
            </div>
            <h3 className="text-lg font-bold text-slate-900 mb-2">No quotations found</h3>
            <p className="text-slate-500 mb-6 max-w-sm mx-auto">
              {customPhone ? `No quotations found for phone ${customPhone}.` : "You don't have any quotations linked to your account yet."}
            </p>
            <Link
              to="/shop"
              className="inline-flex items-center gap-2 px-6 py-2.5 bg-indigo-600 text-white font-semibold rounded-lg hover:bg-indigo-700 transition-all shadow-sm"
            >
              Browse Products
            </Link>
          </div>
        ) : (
          <div className="divide-y divide-slate-100">
            {filteredQuotations.map(q => (
              <div 
                key={q.id}
                className="p-4 sm:p-6 hover:bg-slate-50/50 transition-colors flex flex-col sm:flex-row sm:items-center justify-between gap-4"
              >
                <div className="flex items-start gap-4">
                  <div className="w-12 h-12 bg-indigo-50 rounded-xl flex items-center justify-center shrink-0">
                    <FileText className="w-6 h-6 text-indigo-600" />
                  </div>
                  <div>
                    <div className="flex items-center gap-3 mb-1">
                      <h3 className="font-bold text-slate-900 text-lg">
                        {q.quotationNumber || `#${q.id.slice(0, 8).toUpperCase()}`}
                      </h3>
                      <span className={`badge ${getStatusBadge(q.status)} gap-1`}>
                        {getStatusIcon(q.status)}
                        {q.status?.charAt(0).toUpperCase() + q.status?.slice(1) || 'Draft'}
                      </span>
                    </div>
                    <div className="flex flex-wrap items-center gap-x-4 gap-y-2 text-sm text-slate-500">
                      <div className="flex items-center gap-1.5">
                        <Clock className="w-4 h-4" />
                        Date: {formatDate(q.createdAt)}
                      </div>
                      <div className="flex items-center gap-1.5 text-orange-600 font-medium">
                        <AlertCircle className="w-4 h-4" />
                        Valid Until: {formatDate(q.validUntil)}
                      </div>
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center justify-between sm:justify-end gap-3 sm:w-auto w-full border-t sm:border-t-0 border-slate-100 pt-4 sm:pt-0 flex-wrap">
                  <div className="text-left sm:text-right w-full sm:w-auto mb-2 sm:mb-0 sm:mr-4">
                    <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">Total</p>
                    <p className="text-lg font-bold text-slate-900">{formatCurrency(q.total || 0)}</p>
                  </div>
                  
                  {q.status === 'sent' && (
                    <div className="flex gap-2">
                      <button
                        onClick={(e) => handleStatusUpdate(e, q.id, 'accepted')}
                        disabled={updatingId === q.id}
                        className="inline-flex items-center gap-1.5 px-3 py-2 bg-emerald-50 text-emerald-700 hover:bg-emerald-100 font-semibold rounded-lg transition-colors disabled:opacity-50"
                      >
                        {updatingId === q.id ? <Loader2 className="w-4 h-4 animate-spin" /> : <CheckCircle className="w-4 h-4" />}
                        Accept
                      </button>
                      <button
                        onClick={(e) => handleStatusUpdate(e, q.id, 'rejected')}
                        disabled={updatingId === q.id}
                        className="inline-flex items-center gap-1.5 px-3 py-2 bg-rose-50 text-rose-700 hover:bg-rose-100 font-semibold rounded-lg transition-colors disabled:opacity-50"
                      >
                        <XCircle className="w-4 h-4" />
                        Reject
                      </button>
                    </div>
                  )}

                  <button
                    onClick={(e) => generateQuotationPdf(e, q)}
                    className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 hover:text-indigo-800 font-semibold rounded-lg transition-colors"
                  >
                    <Download className="w-4 h-4" />
                    Download
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

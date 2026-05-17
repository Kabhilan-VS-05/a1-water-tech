import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../state/AuthContext.jsx'
import useOrders from '../hooks/useOrders.js'
import useProducts from '../hooks/useProducts.js'
import { formatCurrency } from '../utils/format.js'
import {
  Box, Calendar, Clock, CheckCircle, Truck, AlertCircle,
  RefreshCcw, Loader2, FileText, XCircle, ChevronRight,
  MapPin, CreditCard, ShoppingBag
} from 'lucide-react'

const formatDate = (value) => {
  if (!value) return 'Pending'
  if (value?.toDate) return value.toDate().toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
  return new Date(value).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
}

const getStatusBadge = (status) => {
  switch (status?.toLowerCase()) {
    case 'delivered':  return 'badge-success'
    case 'confirmed':  return 'badge-primary'
    case 'shipped':    return 'badge-primary'
    case 'cancelled':
    case 'rejected':   return 'badge-error'
    default:           return 'badge-warning'
  }
}

const getStatusIcon = (status) => {
  switch (status?.toLowerCase()) {
    case 'delivered':  return <CheckCircle className="w-3 h-3" />
    case 'confirmed':  return <CheckCircle className="w-3 h-3" />
    case 'cancelled':
    case 'rejected':   return <AlertCircle className="w-3 h-3" />
    case 'shipped':    return <Truck className="w-3 h-3" />
    default:           return <Clock className="w-3 h-3" />
  }
}

export default function Orders() {
  const { user } = useAuth()
  const [refreshKey, setRefreshKey] = useState(0)
  const { orders, loading } = useOrders(user?.uid, refreshKey)
  const { items: products } = useProducts()
  const [cancelingId, setCancelingId] = useState(null)

  const productById = Object.fromEntries(products.map(p => [p.id, p]))

  const handleCancelOrder = async (e, order) => {
    e.stopPropagation()
    if (!window.confirm('Cancel this order?')) return
    setCancelingId(order.id)
    try {
      const baseUrl = import.meta.env.VITE_API_BASE_URL
      const res = await fetch(`${baseUrl}/orders/${order.id}/status`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: 'cancelled' }),
      })
      if (res.ok) setRefreshKey(k => k + 1)
      else alert('Could not cancel order. It may already be processed.')
    } catch (err) {
      console.error(err)
    } finally {
      setCancelingId(null)
    }
  }

  const generateInvoice = (e, order) => {
    e.stopPropagation()
    const w = window.open('', '_blank')
    if (!w) { alert('Please allow popups to view the invoice.'); return }

    const items     = order.items || []
    const subtotal  = order.subtotal || 0
    const gstAmount = order.billing?.gstAmount || 0
    const total     = order.total || 0
    const orderId   = order.orderId || order.id.slice(0, 8).toUpperCase()
    const date      = formatDate(order.createdAt)
    const customer  = order.customer || {}
    const address   = order.address  || {}

    w.document.write(`<!DOCTYPE html>
<html>
<head>
  <title>Invoice #${orderId}</title>
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
    .inv-title { font-size: 22px; font-weight: 800; color: #0f172a; }
    .inv-detail { font-size: 12px; color: #64748b; margin-top: 4px; }
    .inv-detail strong { color: #1e293b; }

    /* Billing grid */
    .billing { display: grid; grid-template-columns: 1fr 1fr; gap: 28px; margin-bottom: 28px; }
    .billing-box { background: #f8fafc; border-radius: 8px; padding: 16px; }
    .billing-label { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.08em; color: #94a3b8; margin-bottom: 10px; }
    .billing-name { font-size: 15px; font-weight: 700; color: #0f172a; margin-bottom: 4px; }
    .billing-line { font-size: 13px; color: #475569; }

    /* Table */
    table { width: 100%; border-collapse: collapse; margin-bottom: 28px; }
    thead th { background: #f1f5f9; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.06em; color: #64748b; padding: 10px 12px; text-align: left; }
    tbody td { padding: 12px; border-bottom: 1px solid #f1f5f9; font-size: 13px; color: #334155; }
    tbody tr:last-child td { border-bottom: none; }
    .item-name { font-weight: 600; color: #0f172a; }
    .item-hsn { font-size: 11px; color: #94a3b8; margin-top: 2px; }

    /* Summary */
    .summary { display: flex; justify-content: flex-end; margin-bottom: 32px; }
    .summary-table { width: 240px; }
    .sum-row { display: flex; justify-content: space-between; padding: 6px 0; font-size: 13px; color: #64748b; }
    .sum-row.total { border-top: 2px solid #e2e8f0; margin-top: 10px; padding-top: 12px; font-weight: 800; font-size: 16px; color: #0f172a; }
    .free { color: #10b981; font-weight: 600; }

    /* Footer */
    .inv-footer { border-top: 1px solid #e2e8f0; padding-top: 20px; display: flex; justify-content: space-between; align-items: flex-end; }
    .sig { text-align: center; }
    .sig-line { border-top: 1px solid #cbd5e1; width: 160px; margin-bottom: 6px; }
    .sig-text { font-size: 11px; font-weight: 600; color: #94a3b8; text-transform: uppercase; letter-spacing: 0.06em; }
    .disclaimer { font-size: 11px; color: #94a3b8; max-width: 300px; }

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
      <div class="inv-title">TAX INVOICE</div>
      <div class="inv-detail">Invoice No: <strong>#${orderId}</strong></div>
      <div class="inv-detail">Date: <strong>${date}</strong></div>
    </div>
  </div>

  <div class="billing">
    <div class="billing-box">
      <div class="billing-label">Sold By</div>
      <div class="billing-name">A1 Water Tech</div>
      <div class="billing-line">Gobichettipalayam</div>
      <div class="billing-line">Tamil Nadu, India</div>
    </div>
    <div class="billing-box">
      <div class="billing-label">Billed To</div>
      <div class="billing-name">${customer.fullName || 'Customer'}</div>
      <div class="billing-line">${address.address || ''}</div>
      <div class="billing-line">${address.city || ''} ${address.pincode || ''}</div>
      <div class="billing-line">Phone: ${customer.phone || 'N/A'}</div>
    </div>
  </div>

  <table>
    <thead>
      <tr>
        <th>Item Description</th>
        <th style="text-align:center">Qty</th>
        <th style="text-align:right">Unit Price</th>
        <th style="text-align:right">Amount</th>
      </tr>
    </thead>
    <tbody>
      ${items.map(item => `
        <tr>
          <td>
            <div class="item-name">${item.name || 'Product'}</div>
            <div class="item-hsn">HSN/SAC: 842121</div>
          </td>
          <td style="text-align:center">${item.qty}</td>
          <td style="text-align:right">₹${(item.unitPrice ?? 0).toFixed(2)}</td>
          <td style="text-align:right;font-weight:600">₹${((item.unitPrice ?? 0) * item.qty).toFixed(2)}</td>
        </tr>
      `).join('')}
    </tbody>
  </table>

  <div class="summary">
    <div class="summary-table">
      <div class="sum-row"><span>Subtotal</span><span>₹${subtotal.toFixed(2)}</span></div>
      <div class="sum-row"><span>GST (18%)</span><span>₹${gstAmount.toFixed(2)}</span></div>
      <div class="sum-row"><span>Shipping</span><span class="free">FREE</span></div>
      <div class="sum-row total"><span>Total</span><span>₹${total.toFixed(2)}</span></div>
    </div>
  </div>

  <div class="inv-footer">
    <div class="disclaimer">This is a computer-generated invoice. No physical signature required.</div>
    <div class="sig">
      <div class="sig-line"></div>
      <div class="sig-text">Authorized Signatory</div>
      <div style="font-size:10px;color:#cbd5e1;margin-top:2px;">For A1 Water Tech</div>
    </div>
  </div>

  <button class="print-btn" onclick="window.print()">Print Invoice</button>
</div>
</body>
</html>`)
    w.document.close()
  }

  return (
    <div className="page-bg">
      <div className="container mx-auto px-4 max-w-4xl py-8">

        {/* Header row */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold text-slate-900">My Orders</h1>
            <p className="text-sm text-slate-500 mt-0.5">Track and manage your purchases</p>
          </div>
          {orders.length > 0 && (
            <span className="badge badge-neutral">
              <Box className="w-3 h-3" /> {orders.length} {orders.length === 1 ? 'order' : 'orders'}
            </span>
          )}
        </div>

        {/* States */}
        {loading ? (
          <div className="space-y-3">
            {[1, 2, 3].map(i => (
              <div key={i} className="card h-32 animate-pulse bg-slate-100" />
            ))}
          </div>
        ) : orders.length === 0 ? (
          <div className="card p-12 text-center">
            <ShoppingBag className="w-10 h-10 text-slate-300 mx-auto mb-3" />
            <h3 className="font-semibold text-slate-800 mb-1">No orders yet</h3>
            <p className="text-sm text-slate-500 mb-5">Browse our catalog and place your first order.</p>
            <Link to="/shop" className="btn-primary text-sm px-5 py-2.5">
              Browse Products
            </Link>
          </div>
        ) : (
          <div className="space-y-4">
            {orders.map(order => {
              const isPending = order.status === 'pending'
              return (
                <div
                  key={order.id}
                  className="card overflow-hidden cursor-pointer hover:border-indigo-200 transition-colors"
                  onClick={() => {
                    sessionStorage.setItem('lastOrder', JSON.stringify(order))
                    window.location.href = `/order-confirmation/${order.orderId || order.id}`
                  }}
                >
                  {/* Order header */}
                  <div className="p-5 border-b border-slate-50 flex flex-col sm:flex-row sm:items-center gap-3 justify-between">
                    <div>
                      <div className="flex items-center gap-2.5 mb-1.5">
                        <span className="font-bold text-slate-900 text-sm">#{order.orderId || order.id.slice(0, 8).toUpperCase()}</span>
                        <span className={`badge ${getStatusBadge(order.status)} flex items-center gap-1`}>
                          {getStatusIcon(order.status)} {order.status || 'processing'}
                        </span>
                      </div>
                      <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-slate-400">
                        <span className="flex items-center gap-1">
                          <Calendar className="w-3 h-3" /> {formatDate(order.createdAt)}
                        </span>
                        <span className="flex items-center gap-1">
                          <CreditCard className="w-3 h-3" /> {order.customer?.paymentMethod || 'Online'}
                        </span>
                        <span className="flex items-center gap-1">
                          <MapPin className="w-3 h-3" /> {order.address?.city || 'N/A'}
                        </span>
                      </div>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <div className="text-xs text-slate-400 mb-0.5">Order Total</div>
                      <div className="text-lg font-bold text-indigo-600">{formatCurrency(order.total || 0)}</div>
                    </div>
                  </div>

                  {/* Order items */}
                  <div className="p-5 space-y-4">
                    {(order.items || []).map((item, idx) => {
                      const product = productById[item.productId || item.id]
                      return (
                        <div key={idx} className="flex items-center gap-3">
                          <div className="w-12 h-12 rounded-lg overflow-hidden bg-slate-100 border border-slate-100 flex-shrink-0">
                            <img
                              src={item.image || product?.imageUrl || '/sample-product.jpg'}
                              alt={item.name}
                              onError={e => { e.currentTarget.onerror = null; e.currentTarget.src = '/sample-product.jpg' }}
                              className="w-full h-full object-cover"
                            />
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="text-sm font-semibold text-slate-800 truncate">{item.name || product?.name || 'Product'}</div>
                            <div className="text-xs text-slate-400 mt-0.5">Qty: {item.qty} × {formatCurrency(item.unitPrice ?? 0)}</div>
                          </div>
                          <div className="text-sm font-bold text-slate-700 flex-shrink-0">
                            {formatCurrency((item.unitPrice ?? 0) * (item.qty ?? 1))}
                          </div>
                        </div>
                      )
                    })}
                  </div>

                  {/* Footer actions */}
                  <div className="px-5 py-3 bg-slate-50 border-t border-slate-50 flex items-center justify-between gap-3" onClick={e => e.stopPropagation()}>
                    <div className="flex items-center gap-4">
                      <button
                        onClick={e => generateInvoice(e, order)}
                        className="flex items-center gap-1.5 text-xs font-semibold text-slate-500 hover:text-indigo-600 transition-colors"
                      >
                        <FileText className="w-3.5 h-3.5" /> Invoice
                      </button>
                      <Link
                        to="/shop"
                        className="flex items-center gap-1.5 text-xs font-semibold text-slate-500 hover:text-indigo-600 transition-colors"
                        onClick={e => e.stopPropagation()}
                      >
                        <RefreshCcw className="w-3.5 h-3.5" /> Reorder
                      </Link>
                      {isPending && (
                        <button
                          disabled={cancelingId === order.id}
                          onClick={e => handleCancelOrder(e, order)}
                          className="flex items-center gap-1.5 text-xs font-semibold text-red-400 hover:text-red-600 transition-colors disabled:opacity-50"
                        >
                          {cancelingId === order.id
                            ? <Loader2 className="w-3.5 h-3.5 animate-spin" />
                            : <XCircle className="w-3.5 h-3.5" />
                          }
                          Cancel
                        </button>
                      )}
                    </div>
                    <div className="flex items-center gap-1 text-xs font-semibold text-slate-500 hover:text-indigo-600 transition-colors cursor-pointer"
                      onClick={() => window.location.href = '/track'}>
                      <Truck className="w-3.5 h-3.5" /> Track <ChevronRight className="w-3 h-3" />
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}

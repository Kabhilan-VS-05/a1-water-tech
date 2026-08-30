import { useState, useMemo } from 'react'
import { Link } from 'react-router-dom'
import {
  Bell,
  CheckCheck,
  Trash2,
  ShoppingBag,
  Calendar,
  FileText,
  Info,
  ExternalLink,
  CheckCircle,
  Filter,
  Sparkles
} from 'lucide-react'
import { useNotifications } from '../state/NotificationContext.jsx'
import PageHeader from '../components/PageHeader.jsx'

export default function Notifications() {
  const {
    notifications,
    unreadCount,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    clearAllNotifications
  } = useNotifications()

  const [activeFilter, setActiveFilter] = useState('all')

  const filteredNotifications = useMemo(() => {
    return notifications.filter(item => {
      if (activeFilter === 'unread') return !item.read
      if (activeFilter === 'order') return item.type === 'order'
      if (activeFilter === 'booking') return item.type === 'booking'
      if (activeFilter === 'quotation') return item.type === 'quotation'
      return true
    })
  }, [notifications, activeFilter])

  const counts = useMemo(() => ({
    all: notifications.length,
    unread: unreadCount,
    order: notifications.filter(n => n.type === 'order').length,
    booking: notifications.filter(n => n.type === 'booking').length,
    quotation: notifications.filter(n => n.type === 'quotation').length
  }), [notifications, unreadCount])

  const formatTime = (isoString) => {
    if (!isoString) return ''
    const date = new Date(isoString)
    const now = new Date()
    const diffSeconds = Math.floor((now - date) / 1000)

    if (diffSeconds < 60) return 'Just now'
    if (diffSeconds < 3600) return `${Math.floor(diffSeconds / 60)}m ago`
    if (diffSeconds < 86400) return `${Math.floor(diffSeconds / 3600)}h ago`
    if (diffSeconds < 172800) return 'Yesterday'
    
    return date.toLocaleDateString('en-IN', {
      day: 'numeric',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const getTypeStyle = (type) => {
    switch (type) {
      case 'order':
        return {
          icon: ShoppingBag,
          color: 'text-indigo-600 bg-indigo-50 border-indigo-100',
          badge: 'Order'
        }
      case 'booking':
        return {
          icon: Calendar,
          color: 'text-emerald-600 bg-emerald-50 border-emerald-100',
          badge: 'Service'
        }
      case 'quotation':
        return {
          icon: FileText,
          color: 'text-amber-600 bg-amber-50 border-amber-100',
          badge: 'Quotation'
        }
      default:
        return {
          icon: Info,
          color: 'text-slate-600 bg-slate-100 border-slate-200',
          badge: 'Notice'
        }
    }
  }

  return (
    <div className="bg-slate-50/50 min-h-screen pb-16">
      <PageHeader
        title="Notification Center"
        subtitle="Stay updated with order tracking, booking confirmations, and quotation alerts from the last 30 days."
      />

      <div className="container mx-auto max-w-5xl px-4 py-8">
        {/* Top Control Bar */}
        <div className="bg-white rounded-2xl border border-slate-200/80 p-4 mb-6 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
          
          {/* Filter Tabs */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-2 md:pb-0 scrollbar-none">
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider mr-2 hidden sm:inline-flex items-center gap-1">
              <Filter className="w-3.5 h-3.5" /> Filter:
            </span>
            
            {[
              { id: 'all', label: 'All', count: counts.all },
              { id: 'unread', label: 'Unread', count: counts.unread },
              { id: 'order', label: 'Orders', count: counts.order },
              { id: 'booking', label: 'Bookings', count: counts.booking },
              { id: 'quotation', label: 'Quotations', count: counts.quotation }
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveFilter(tab.id)}
                className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 whitespace-nowrap ${
                  activeFilter === tab.id
                    ? 'bg-slate-900 text-white shadow-sm'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200/70 hover:text-slate-900'
                }`}
              >
                {tab.label}
                {tab.count > 0 && (
                  <span
                    className={`text-[10px] font-bold px-1.5 py-0.2 rounded-full ${
                      activeFilter === tab.id
                        ? 'bg-white/20 text-white'
                        : tab.id === 'unread'
                        ? 'bg-rose-100 text-rose-700'
                        : 'bg-slate-200 text-slate-700'
                    }`}
                  >
                    {tab.count}
                  </span>
                )}
              </button>
            ))}
          </div>

          {/* Action Buttons */}
          <div className="flex items-center gap-2 self-end md:self-auto">
            {unreadCount > 0 && (
              <button
                onClick={markAllAsRead}
                className="btn-secondary text-xs py-1.5 px-3 flex items-center gap-1.5 text-indigo-600 hover:bg-indigo-50 border-indigo-200"
              >
                <CheckCheck className="w-3.5 h-3.5" />
                Mark all read
              </button>
            )}

            {notifications.length > 0 && (
              <button
                onClick={clearAllNotifications}
                className="btn-secondary text-xs py-1.5 px-3 flex items-center gap-1.5 text-slate-600 hover:text-rose-600 hover:bg-rose-50 border-slate-200"
              >
                <Trash2 className="w-3.5 h-3.5" />
                Clear All
              </button>
            )}
          </div>
        </div>

        {/* Notifications List */}
        {filteredNotifications.length > 0 ? (
          <div className="space-y-3">
            {filteredNotifications.map(item => {
              const style = getTypeStyle(item.type)
              const IconComponent = style.icon

              return (
                <div
                  key={item.id}
                  className={`relative group bg-white rounded-2xl border transition-all p-5 shadow-sm hover:shadow-md ${
                    !item.read
                      ? 'border-indigo-200 bg-indigo-50/20'
                      : 'border-slate-200/80 hover:border-slate-300'
                  }`}
                >
                  <div className="flex items-start gap-4">
                    {/* Type Icon */}
                    <div className={`p-3 rounded-xl border flex-shrink-0 ${style.color}`}>
                      <IconComponent className="w-5 h-5" />
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0 pr-8">
                      <div className="flex items-center gap-2 flex-wrap mb-1">
                        <h4 className={`text-sm font-bold ${!item.read ? 'text-slate-900' : 'text-slate-800'}`}>
                          {item.title}
                        </h4>
                        
                        <span className={`text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-md border ${style.color}`}>
                          {style.badge}
                        </span>

                        {!item.read && (
                          <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse" title="Unread" />
                        )}

                        <span className="text-xs text-slate-400 font-medium ml-auto">
                          {formatTime(item.createdAt)}
                        </span>
                      </div>

                      <p className="text-xs text-slate-600 leading-relaxed">
                        {item.body}
                      </p>

                      {/* Card Action footer */}
                      <div className="mt-3.5 flex items-center gap-3">
                        {item.link && (
                          <Link
                            to={item.link}
                            onClick={() => markAsRead(item.id)}
                            className="inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-600 hover:text-indigo-700 hover:underline"
                          >
                            View details
                            <ExternalLink className="w-3 h-3" />
                          </Link>
                        )}

                        {!item.read && (
                          <button
                            onClick={() => markAsRead(item.id)}
                            className="inline-flex items-center gap-1 text-[11px] font-medium text-slate-400 hover:text-slate-700"
                          >
                            <CheckCircle className="w-3 h-3" />
                            Mark read
                          </button>
                        )}
                      </div>
                    </div>

                    {/* Delete button on right */}
                    <button
                      onClick={() => deleteNotification(item.id)}
                      className="absolute top-4 right-4 text-slate-300 hover:text-rose-500 opacity-0 group-hover:opacity-100 transition-opacity p-1.5 rounded-lg hover:bg-slate-100"
                      title="Delete notification"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              )
            })}
          </div>
        ) : (
          /* Empty State */
          <div className="bg-white rounded-3xl border border-slate-200/80 p-12 text-center shadow-sm max-w-md mx-auto my-8">
            <div className="w-16 h-16 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center mx-auto mb-4 border border-indigo-100">
              <Bell className="w-8 h-8" />
            </div>
            <h3 className="text-lg font-bold text-slate-900 mb-1">No Notifications Found</h3>
            <p className="text-xs text-slate-500 mb-6 leading-relaxed">
              {activeFilter === 'unread'
                ? "You're all caught up! There are no unread notifications at this time."
                : "You don't have any saved notifications from the last 30 days."
              }
            </p>
            <Link to="/shop" className="btn-primary text-xs px-5 py-2.5 inline-flex items-center gap-2">
              <Sparkles className="w-4 h-4" />
              Explore Water Shop
            </Link>
          </div>
        )}
      </div>
    </div>
  )
}

import { createContext, useContext, useState, useEffect, useMemo } from 'react'
import { useToast } from './ToastContext.jsx'

const NotificationContext = createContext(null)
const STORAGE_KEY = 'a1_notifications_store_v1'
const THIRTY_DAYS_MS = 30 * 24 * 60 * 60 * 1000

// Helper to remove notifications older than 30 days (1 month)
function purgeOldNotifications(list) {
  if (!Array.isArray(list)) return []
  const now = Date.now()
  return list.filter(item => {
    if (!item.createdAt) return false
    const itemTime = new Date(item.createdAt).getTime()
    return now - itemTime <= THIRTY_DAYS_MS
  })
}

export function NotificationProvider({ children }) {
  const { showToast } = useToast()
  const [notifications, setNotifications] = useState(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY)
      if (!saved) return []
      const parsed = JSON.parse(saved)
      return purgeOldNotifications(parsed)
    } catch (e) {
      console.error('Failed to parse notifications storage:', e)
      return []
    }
  })

  // Sync to localStorage & purge on state change
  useEffect(() => {
    try {
      const purged = purgeOldNotifications(notifications)
      localStorage.setItem(STORAGE_KEY, JSON.stringify(purged))
    } catch (e) {
      console.error('Failed to save notifications storage:', e)
    }
  }, [notifications])

  const unreadCount = useMemo(() => {
    return notifications.filter(n => !n.read).length
  }, [notifications])

  // Batch notification trigger to avoid toast spamming
  const addNotificationsBatch = (newItems) => {
    if (!Array.isArray(newItems) || newItems.length === 0) return

    const nowIso = new Date().toISOString()
    const formattedNewItems = newItems.map(item => ({
      id: item.id || `notif_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      title: item.title || 'Notification',
      body: item.body || '',
      type: item.type || 'system', // 'order' | 'booking' | 'quotation' | 'system'
      link: item.link || '/notifications',
      read: false,
      createdAt: item.createdAt || nowIso
    }))

    setNotifications(prev => {
      // Prevent duplicates by checking ID or title+body combination
      const existingIds = new Set(prev.map(n => n.id))
      const uniqueNew = formattedNewItems.filter(n => !existingIds.has(n.id))
      if (uniqueNew.length === 0) return prev
      return purgeOldNotifications([...uniqueNew, ...prev])
    })

    // Handle Toasts and Windows Native Notifications intelligently
    const count = newItems.length

    // Windows Native OS Notification
    if ('Notification' in window && Notification.permission === 'granted') {
      try {
        if (count === 1) {
          new Notification(newItems[0].title, { body: newItems[0].body })
        } else if (count === 2) {
          new Notification(newItems[0].title, { body: newItems[0].body })
          new Notification(newItems[1].title, { body: newItems[1].body })
        } else {
          new Notification('A1 Water Tech Updates', {
            body: `You have ${count} new updates available in your account.`
          })
        }
      } catch (err) {
        console.warn('Native notification failed:', err)
      }
    }

    // On-screen Toasts: Show 1 summary toast if count >= 3 to prevent screen spamming
    if (count >= 3) {
      showToast(`You have ${count} new notifications. Click Bell icon to view.`, 'info')
    } else {
      newItems.forEach(item => {
        showToast(item.body, item.type === 'error' ? 'error' : 'success')
      })
    }
  }

  const markAsRead = (id) => {
    setNotifications(prev =>
      prev.map(n => (n.id === id ? { ...n, read: true } : n))
    )
  }

  const markAllAsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...n, read: true })))
  }

  const deleteNotification = (id) => {
    setNotifications(prev => prev.filter(n => n.id !== id))
  }

  const clearAllNotifications = () => {
    setNotifications([])
  }

  const value = useMemo(() => ({
    notifications,
    unreadCount,
    addNotificationsBatch,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    clearAllNotifications
  }), [notifications, unreadCount])

  return (
    <NotificationContext.Provider value={value}>
      {children}
    </NotificationContext.Provider>
  )
}

export function useNotifications() {
  const context = useContext(NotificationContext)
  if (!context) {
    throw new Error('useNotifications must be used within NotificationProvider')
  }
  return context
}

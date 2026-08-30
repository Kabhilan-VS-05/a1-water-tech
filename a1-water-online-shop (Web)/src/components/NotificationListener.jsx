import { useEffect } from 'react'
import { useAuth } from '../state/AuthContext.jsx'
import { useNotifications } from '../state/NotificationContext.jsx'

export default function NotificationListener() {
  const { user } = useAuth()
  const { addNotificationsBatch } = useNotifications()

  useEffect(() => {
    // Request native Windows/browser notification permissions if not asked yet
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission()
    }
  }, [])

  useEffect(() => {
    if (!user) return

    let active = true

    const checkStatus = async () => {
      if (!active) return
      
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) return

        const batchItems = []

        // 1. Fetch Orders
        const ordersRes = await fetch(`${baseUrl}/orders?userId=${encodeURIComponent(user.uid)}`)
        if (ordersRes.ok && active) {
          const data = await ordersRes.json()
          const orders = data.items || []
          
          const notifiedOrders = JSON.parse(localStorage.getItem('notifiedOrders') || '{}')
          let updated = false

          orders.forEach(order => {
            if (order.status === 'confirmed' || order.status === 'rejected') {
              if (notifiedOrders[order.id] !== order.status) {
                if (Object.keys(notifiedOrders).length > 0) {
                  batchItems.push({
                    id: `order_${order.id}_${order.status}`,
                    title: 'Order Status Update',
                    body: `Order #${order.orderId || order.id.slice(0,8)} is now ${order.status}!`,
                    type: 'order',
                    link: '/orders'
                  })
                }
                notifiedOrders[order.id] = order.status
                updated = true
              }
            } else if (order.status === 'pending') {
              if (!notifiedOrders[order.id]) {
                notifiedOrders[order.id] = 'pending'
                updated = true
              }
            }
          })
          if (updated) localStorage.setItem('notifiedOrders', JSON.stringify(notifiedOrders))
        }

        // 2. Fetch Bookings
        const bookingsRes = await fetch(`${baseUrl}/bookings?userId=${encodeURIComponent(user.uid)}`)
        if (bookingsRes.ok && active) {
          const data = await bookingsRes.json()
          const bookings = data.items || []
          
          const notifiedBookings = JSON.parse(localStorage.getItem('notifiedBookings') || '{}')
          let updated = false

          bookings.forEach(booking => {
            if (booking.status === 'confirmed' || booking.status === 'rejected') {
              if (notifiedBookings[booking.id] !== booking.status) {
                if (Object.keys(notifiedBookings).length > 0) {
                  batchItems.push({
                    id: `booking_${booking.id}_${booking.status}`,
                    title: 'Service Booking Update',
                    body: `Booking for ${booking.serviceName} has been ${booking.status}!`,
                    type: 'booking',
                    link: '/bookings'
                  })
                }
                notifiedBookings[booking.id] = booking.status
                updated = true
              }
            } else if (booking.status === 'pending') {
              if (!notifiedBookings[booking.id]) {
                notifiedBookings[booking.id] = 'pending'
                updated = true
              }
            }
          })
          if (updated) localStorage.setItem('notifiedBookings', JSON.stringify(notifiedBookings))
        }

        // 3. Fetch Quotations
        const phoneParam = user.phoneNumber ? `&phone=${encodeURIComponent(user.phoneNumber)}` : ''
        const emailParam = user.email ? `&email=${encodeURIComponent(user.email)}` : ''
        const quotationsRes = await fetch(`${baseUrl}/quotations?userId=${encodeURIComponent(user.uid)}${phoneParam}${emailParam}`)
        if (quotationsRes.ok && active) {
          const data = await quotationsRes.json()
          const quotations = data.items || []
          
          const notifiedQuotations = JSON.parse(localStorage.getItem('notifiedQuotations') || '{}')
          let updated = false

          quotations.forEach(q => {
            if (!notifiedQuotations[q.id]) {
              if (Object.keys(notifiedQuotations).length > 0) {
                batchItems.push({
                  id: `quotation_new_${q.id}`,
                  title: 'New Quotation Received',
                  body: `You received a new quotation #${q.quotationNumber || q.id.slice(0,8)}.`,
                  type: 'quotation',
                  link: '/quotations'
                })
              }
              notifiedQuotations[q.id] = q.status
              updated = true
            } else if (notifiedQuotations[q.id] !== q.status) {
              if (Object.keys(notifiedQuotations).length > 0) {
                batchItems.push({
                  id: `quotation_${q.id}_${q.status}`,
                  title: 'Quotation Status Update',
                  body: `Quotation #${q.quotationNumber || q.id.slice(0,8)} is now ${q.status}.`,
                  type: 'quotation',
                  link: '/quotations'
                })
              }
              notifiedQuotations[q.id] = q.status
              updated = true
            }
          })
          if (updated) localStorage.setItem('notifiedQuotations', JSON.stringify(notifiedQuotations))
        }

        // Dispatch batch to Context if there are new items
        if (batchItems.length > 0 && active) {
          addNotificationsBatch(batchItems)
        }

      } catch (err) {
        console.error('Notification check failed:', err)
      }
    }

    // Check immediately
    checkStatus()
    
    // Poll every 30 seconds
    const interval = setInterval(checkStatus, 30000)

    return () => {
      active = false
      clearInterval(interval)
    }
  }, [user, addNotificationsBatch])

  return null
}

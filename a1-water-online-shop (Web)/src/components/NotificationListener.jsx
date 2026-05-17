import { useEffect } from 'react'
import { useAuth } from '../state/AuthContext.jsx'
import { useToast } from '../state/ToastContext.jsx'

export default function NotificationListener() {
  const { user } = useAuth()
  const { showToast } = useToast()

  useEffect(() => {
    // Request native notification permissions
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission()
    }
  }, [])

  useEffect(() => {
    if (!user) return

    let active = true
    const triggerNotification = (title, body, type) => {
      showToast(body, type)
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification(title, { body })
      }
    }

    const checkStatus = async () => {
      if (!active) return
      
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) return

        // Fetch Orders
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
                  triggerNotification(
                    'Order Update', 
                    `Order #${order.orderId || order.id.slice(0,8)} has been ${order.status}!`, 
                    order.status === 'rejected' ? 'error' : 'success'
                  )
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

        // Fetch Bookings
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
                  triggerNotification(
                    'Service Booking Update', 
                    `Your booking for ${booking.serviceName} has been ${booking.status}!`, 
                    booking.status === 'rejected' ? 'error' : 'success'
                  )
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

      } catch (err) {
        console.error('Notification check failed', err)
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
  }, [user, showToast])

  return null
}

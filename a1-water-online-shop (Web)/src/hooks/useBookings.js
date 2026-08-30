import { useEffect, useState } from 'react'

const getMillis = (value) => {
  if (!value) return 0
  if (typeof value?.toMillis === 'function') return value.toMillis()
  if (typeof value?.toDate === 'function') return value.toDate().getTime()
  const parsed = new Date(value).getTime()
  return Number.isFinite(parsed) ? parsed : 0
}

export default function useBookings(userId, emailOrRefreshKey = 0, refreshKey = 0) {
  const [bookings, setBookings] = useState([])
  const [loading, setLoading] = useState(true)

  const email = typeof emailOrRefreshKey === 'string' ? emailOrRefreshKey : ''
  const actualRefreshKey = typeof emailOrRefreshKey === 'number' ? emailOrRefreshKey : refreshKey

  useEffect(() => {
    if (!userId && !email) {
      setBookings([])
      setLoading(false)
      return
    }

    let active = true

    async function loadBookings() {
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) {
          throw new Error('Missing VITE_API_BASE_URL')
        }

        const params = new URLSearchParams()
        if (userId) params.set('userId', userId)
        if (email) params.set('email', email)

        const response = await fetch(`${baseUrl}/bookings?${params.toString()}`)

        if (!response.ok) {
          throw new Error(`Bookings request failed: ${response.status}`)
        }

        const data = await response.json()
        const next = Array.isArray(data.items) ? data.items : []
        next.sort((a, b) => getMillis(b.createdAt) - getMillis(a.createdAt))
        if (active) {
          setBookings(next)
          setLoading(false)
        }
      } catch {
        if (active) {
          setBookings([])
          setLoading(false)
        }
      }
    }
    loadBookings()

    const interval = setInterval(loadBookings, 5000)

    return () => {
      active = false
      clearInterval(interval)
    }
  }, [actualRefreshKey, userId, email])

  return { bookings, loading }
}

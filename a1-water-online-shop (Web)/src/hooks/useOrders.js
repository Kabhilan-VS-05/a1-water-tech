import { useEffect, useState } from 'react'

const getMillis = (value) => {
  if (!value) return 0
  if (typeof value?.toMillis === 'function') return value.toMillis()
  if (typeof value?.toDate === 'function') return value.toDate().getTime()
  const parsed = new Date(value).getTime()
  return Number.isFinite(parsed) ? parsed : 0
}

export default function useOrders(userId, refreshKey = 0) {
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!userId) {
      setOrders([])
      setLoading(false)
      return
    }

    let active = true

    async function loadOrders() {
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) {
          throw new Error('Missing VITE_API_BASE_URL')
        }

        const response = await fetch(
          `${baseUrl}/orders?userId=${encodeURIComponent(userId)}`,
        )

        if (!response.ok) {
          throw new Error(`Orders request failed: ${response.status}`)
        }

        const data = await response.json()
        const next = Array.isArray(data.items) ? data.items : []
        next.sort((a, b) => getMillis(b.createdAt) - getMillis(a.createdAt))
        if (active) {
          setOrders(next)
          setLoading(false)
        }
      } catch {
        if (active) {
          setOrders([])
          setLoading(false)
        }
      }
    }
    loadOrders()

    const interval = setInterval(loadOrders, 5000)

    return () => {
      active = false
      clearInterval(interval)
    }
  }, [userId, refreshKey])

  return { orders, loading }
}

import { useEffect, useState } from 'react'

const getMillis = (value) => {
  if (!value) return 0
  if (typeof value?.toMillis === 'function') return value.toMillis()
  if (typeof value?.toDate === 'function') return value.toDate().getTime()
  const parsed = new Date(value).getTime()
  return Number.isFinite(parsed) ? parsed : 0
}

export default function useAnnouncements() {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let active = true

    async function loadAnnouncements() {
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) {
          throw new Error('Missing VITE_API_BASE_URL')
        }

        const response = await fetch(`${baseUrl}/announcements`)
        if (!response.ok) {
          throw new Error(`Announcements request failed: ${response.status}`)
        }

        const data = await response.json()
        const next = Array.isArray(data.items) ? data.items : []

        next.sort((a, b) => {
          if (a.isPinned !== b.isPinned) return a.isPinned ? -1 : 1
          return getMillis(b.createdAt) - getMillis(a.createdAt)
        })

        if (active) {
          setItems(next)
          setLoading(false)
        }
      } catch {
        if (active) {
          setItems([])
          setLoading(false)
        }
      }
    }

    loadAnnouncements()

    return () => {
      active = false
    }
  }, [])

  return { items, loading }
}

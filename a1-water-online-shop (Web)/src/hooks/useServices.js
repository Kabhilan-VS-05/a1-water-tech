import { useEffect, useState } from 'react'

export default function useServices() {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let active = true

    async function loadServices() {
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) {
          throw new Error('Missing VITE_API_BASE_URL')
        }

        const response = await fetch(`${baseUrl}/services`)
        if (!response.ok) {
          throw new Error(`Services request failed: ${response.status}`)
        }

        const data = await response.json()
        if (active) {
          setItems(Array.isArray(data.items) ? data.items : [])
          setLoading(false)
        }
      } catch {
        if (active) {
          setItems([])
          setLoading(false)
        }
      }
    }

    loadServices()

    return () => {
      active = false
    }
  }, [])

  return { items, loading }
}

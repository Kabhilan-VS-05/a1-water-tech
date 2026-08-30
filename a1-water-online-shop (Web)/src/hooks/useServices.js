import { useState, useEffect } from 'react'

let memoryServicesCache = null

export default function useServices() {
  const [items, setItems] = useState(() => {
    if (memoryServicesCache) return memoryServicesCache
    try {
      const stored = sessionStorage.getItem('a1_services_cache')
      if (stored) return JSON.parse(stored)
    } catch (e) {
      // ignore
    }
    return []
  })
  const [loading, setLoading] = useState(() => items.length === 0)
  const [error, setError] = useState(null)

  useEffect(() => {
    let active = true

    async function loadServices() {
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL || '/api'
        const response = await fetch(`${baseUrl}/services`)
        if (!response.ok) {
          throw new Error(`Services request failed: ${response.status}`)
        }

        const data = await response.json()
        const fetchedItems = Array.isArray(data.items) ? data.items : []

        if (active) {
          memoryServicesCache = fetchedItems
          try {
            sessionStorage.setItem('a1_services_cache', JSON.stringify(fetchedItems))
          } catch (e) {
            // ignore
          }
          setItems(fetchedItems)
          setLoading(false)
        }
      } catch (err) {
        if (active) {
          setError(err.message)
          if (items.length === 0) setItems([])
          setLoading(false)
        }
      }
    }

    loadServices()

    return () => {
      active = false
    }
  }, [])

  return { items, loading, error }
}

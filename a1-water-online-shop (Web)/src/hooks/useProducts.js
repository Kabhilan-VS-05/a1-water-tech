import { useState, useEffect } from 'react'

let memoryProductsCache = null

export default function useProducts() {
  const [items, setItems] = useState(() => {
    if (memoryProductsCache) return memoryProductsCache
    try {
      const stored = sessionStorage.getItem('a1_products_cache')
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

    async function loadProducts() {
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL || '/api'
        const response = await fetch(`${baseUrl}/products`)
        if (!response.ok) {
          throw new Error(`Products request failed: ${response.status}`)
        }

        const data = await response.json()
        const fetchedItems = Array.isArray(data.items) ? data.items : []
        
        if (active) {
          memoryProductsCache = fetchedItems
          try {
            sessionStorage.setItem('a1_products_cache', JSON.stringify(fetchedItems))
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

    loadProducts()

    return () => {
      active = false
    }
  }, [])

  return { items, loading, error }
}

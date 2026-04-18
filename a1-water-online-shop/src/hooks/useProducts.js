import { useEffect, useState } from 'react'

export default function useProducts() {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let active = true

    async function loadProducts() {
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) {
          throw new Error('Missing VITE_API_BASE_URL')
        }

        const response = await fetch(`${baseUrl}/products`)
        if (!response.ok) {
          throw new Error(`Products request failed: ${response.status}`)
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

    loadProducts()

    return () => {
      active = false
    }
  }, [])

  return { items, loading }
}

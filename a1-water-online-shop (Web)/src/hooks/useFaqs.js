import { useEffect, useState } from 'react'

export default function useFaqs() {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    let active = true

    async function loadFaqs() {
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) {
          throw new Error('Missing VITE_API_BASE_URL')
        }

        const response = await fetch(`${baseUrl}/faqs`)
        if (!response.ok) {
          throw new Error(`FAQs request failed: ${response.status}`)
        }

        const data = await response.json()
        if (active) {
          setItems(Array.isArray(data.items) ? data.items : [])
          setLoading(false)
        }
      } catch (err) {
        if (active) {
          setError(err.message)
          setItems([])
          setLoading(false)
        }
      }
    }

    loadFaqs()

    return () => {
      active = false
    }
  }, [])

  return { items, loading, error }
}

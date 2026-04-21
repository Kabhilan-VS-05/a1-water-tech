import { useEffect, useState } from 'react'

export default function useAddresses(userId, refreshKey = 0) {
  const [addresses, setAddresses] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!userId) {
      setAddresses([])
      setLoading(false)
      return
    }

    let active = true

    async function loadAddresses() {
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) {
          throw new Error('Missing VITE_API_BASE_URL')
        }

        const response = await fetch(
          `${baseUrl}/addresses?userId=${encodeURIComponent(userId)}`,
        )

        if (!response.ok) {
          throw new Error(`Addresses request failed: ${response.status}`)
        }

        const data = await response.json()
        if (active) {
          setAddresses(Array.isArray(data.items) ? data.items : [])
          setLoading(false)
        }
      } catch {
        if (active) {
          setAddresses([])
          setLoading(false)
        }
      }
    }

    loadAddresses()

    return () => {
      active = false
    }
  }, [refreshKey, userId])

  return { addresses, loading }
}

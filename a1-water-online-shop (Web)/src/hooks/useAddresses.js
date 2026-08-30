import { useEffect, useState } from 'react'

export default function useAddresses(userId, emailOrRefreshKey = 0, refreshKey = 0) {
  const [addresses, setAddresses] = useState([])
  const [loading, setLoading] = useState(true)

  const email = typeof emailOrRefreshKey === 'string' ? emailOrRefreshKey : ''
  const actualRefreshKey = typeof emailOrRefreshKey === 'number' ? emailOrRefreshKey : refreshKey

  useEffect(() => {
    if (!userId && !email) {
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

        const params = new URLSearchParams()
        if (userId) params.set('userId', userId)
        if (email) params.set('email', email)

        const response = await fetch(`${baseUrl}/addresses?${params.toString()}`)

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
  }, [actualRefreshKey, userId, email])

  return { addresses, loading }
}

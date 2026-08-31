import { useState, useEffect } from 'react'

export default function useQuotations(userId, phone, email, refreshKey = 0) {
  const [quotations, setQuotations] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    let mounted = true

    const fetchQuotations = async () => {
      if (!userId && !phone && !email) {
        setQuotations([])
        setLoading(false)
        return
      }

      try {
        setLoading(true)
        setError(null)
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) throw new Error('Missing VITE_API_BASE_URL')

        const params = new URLSearchParams()
        if (userId) params.set('userId', userId)
        if (phone) params.set('phone', phone)
        if (email) params.set('email', email)

        const url = `${baseUrl}/quotations?${params.toString()}`
        const response = await fetch(url)
        if (!response.ok) throw new Error('Failed to fetch quotations')

        const data = await response.json()
        if (mounted) {
          setQuotations(data.items || [])
        }
      } catch (err) {
        if (mounted) {
          setError(err.message)
          console.error('Error fetching quotations:', err)
        }
      } finally {
        if (mounted) setLoading(false)
      }
    }

    fetchQuotations()

    return () => {
      mounted = false
    }
  }, [userId, phone, email, refreshKey])

  const updateStatus = async (quotationId, status) => {
    try {
      const baseUrl = import.meta.env.VITE_API_BASE_URL
      if (!baseUrl) throw new Error('Missing VITE_API_BASE_URL')

      const response = await fetch(`${baseUrl}/quotations/${quotationId}/status`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, phone, email, status }),
      })

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.message || 'Failed to update quotation status')
      }

      setQuotations((prev) =>
        prev.map((q) => (q.id === quotationId ? { ...q, status } : q))
      )
      
      return true
    } catch (err) {
      console.error('Error updating quotation status:', err)
      throw err
    }
  }

  return { quotations, loading, error, updateStatus }
}

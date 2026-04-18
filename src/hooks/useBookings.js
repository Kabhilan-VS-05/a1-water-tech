import { useEffect, useState } from 'react'
import { collection, onSnapshot, query, where } from 'firebase/firestore'
import { db } from '../firebase.js'

const getMillis = (value) => {
  if (!value) return 0
  if (typeof value?.toMillis === 'function') return value.toMillis()
  if (typeof value?.toDate === 'function') return value.toDate().getTime()
  const parsed = new Date(value).getTime()
  return Number.isFinite(parsed) ? parsed : 0
}

export default function useBookings(userId) {
  const [bookings, setBookings] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!userId) {
      setBookings([])
      setLoading(false)
      return
    }

    const ref = query(
      collection(db, 'bookings'),
      where('userId', '==', userId),
    )

    const unsub = onSnapshot(
      ref,
      (snapshot) => {
        const next = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }))
        next.sort((a, b) => getMillis(b.createdAt) - getMillis(a.createdAt))
        setBookings(next)
        setLoading(false)
      },
      () => {
        setBookings([])
        setLoading(false)
      },
    )

    return () => unsub()
  }, [userId])

  return { bookings, loading }
}

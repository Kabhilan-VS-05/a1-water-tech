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

export default function useOrders(userId) {
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!userId) {
      setOrders([])
      setLoading(false)
      return
    }

    const ref = query(
      collection(db, 'orders'),
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
        setOrders(next)
        setLoading(false)
      },
      () => {
        setOrders([])
        setLoading(false)
      },
    )

    return () => unsub()
  }, [userId])

  return { orders, loading }
}

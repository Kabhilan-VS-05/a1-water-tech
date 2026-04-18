import { useEffect, useState } from 'react'
import { collection, onSnapshot, orderBy, query } from 'firebase/firestore'
import { db } from '../firebase.js'

export default function useAddresses(userId) {
  const [addresses, setAddresses] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!userId) {
      setAddresses([])
      setLoading(false)
      return
    }

    const ref = query(
      collection(db, 'users', userId, 'addresses'),
      orderBy('createdAt', 'desc'),
    )

    const unsub = onSnapshot(
      ref,
      (snapshot) => {
        const next = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }))
        setAddresses(next)
        setLoading(false)
      },
      () => {
        setAddresses([])
        setLoading(false)
      },
    )

    return () => unsub()
  }, [userId])

  return { addresses, loading }
}

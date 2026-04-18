import { useEffect, useState } from 'react'
import { collection, onSnapshot } from 'firebase/firestore'
import { db } from '../firebase.js'
import { servicePlans as fallbackServices } from '../data/services.js'

export default function useServices() {
  const [items, setItems] = useState(fallbackServices)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const ref = collection(db, 'services')
    const unsub = onSnapshot(
      ref,
      (snapshot) => {
        const next = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }))
        setItems(next.length ? next : fallbackServices)
        setLoading(false)
      },
      () => {
        setItems(fallbackServices)
        setLoading(false)
      },
    )

    return () => unsub()
  }, [])

  return { items, loading }
}

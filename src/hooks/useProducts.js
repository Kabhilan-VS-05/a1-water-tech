import { useEffect, useState } from 'react'
import { collection, onSnapshot } from 'firebase/firestore'
import { db } from '../firebase.js'
import { products as fallbackProducts } from '../data/products.js'

export default function useProducts() {
  const [items, setItems] = useState(fallbackProducts)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const ref = collection(db, 'products')
    const unsub = onSnapshot(
      ref,
      (snapshot) => {
        const next = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }))
        setItems(next.length ? next : fallbackProducts)
        setLoading(false)
      },
      () => {
        setItems(fallbackProducts)
        setLoading(false)
      },
    )
    return () => unsub()
  }, [])

  return { items, loading }
}

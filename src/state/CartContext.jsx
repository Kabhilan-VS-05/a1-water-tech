import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  onSnapshot,
  setDoc,
  updateDoc,
  writeBatch
} from 'firebase/firestore'
import { db } from '../firebase.js'
import { useAuth } from './AuthContext.jsx'
import useProducts from '../hooks/useProducts.js'

const CartContext = createContext(null)

const loadLocalCart = () => {
  try {
    const raw = localStorage.getItem('a1-cart')
    return raw ? JSON.parse(raw) : []
  } catch {
    return []
  }
}

const persistLocalCart = (items) => {
  try {
    localStorage.setItem('a1-cart', JSON.stringify(items))
  } catch {
    // ignore write failures
  }
}

export function CartProvider({ children }) {
  const { user } = useAuth()
  const { items: allProducts } = useProducts()
  const [cartItems, setCartItems] = useState(loadLocalCart)
  const [loading, setLoading] = useState(true)

  // Sync with Firestore when user logs in
  useEffect(() => {
    if (!user) {
      setCartItems(loadLocalCart())
      setLoading(false)
      return
    }

    // Merge local cart to firestore on first login if needed
    const local = loadLocalCart()
    if (local.length > 0) {
      const batch = writeBatch(db)
      local.forEach((item) => {
        const ref = doc(db, 'users', user.uid, 'cart', item.id)
        batch.set(ref, { qty: item.qty }, { merge: true })
      })
      batch.commit().then(() => {
        localStorage.removeItem('a1-cart')
      })
    }

    const ref = collection(db, 'users', user.uid, 'cart')
    const unsub = onSnapshot(ref, (snapshot) => {
      const next = snapshot.docs.map((entry) => ({
        id: entry.id,
        qty: entry.data().qty || 1,
      }))
      setCartItems(next)
      setLoading(false)
    })

    return () => unsub()
  }, [user])

  const addItem = async (id, qty = 1) => {
    if (user) {
      const ref = doc(db, 'users', user.uid, 'cart', id)
      // We don't need to read expected qty here if we just increment in a transaction or use logic
      // But for simplicity in this structure:
      const existing = cartItems.find((item) => item.id === id)
      const nextQty = existing ? existing.qty + qty : qty
      return setDoc(ref, { qty: nextQty }, { merge: true })
    }

    setCartItems((prev) => {
      const existing = prev.find((item) => item.id === id)
      const next = existing
        ? prev.map((item) =>
          item.id === id ? { ...item, qty: item.qty + qty } : item,
        )
        : [...prev, { id, qty }]
      persistLocalCart(next)
      return next
    })
  }

  const updateItem = (id, qty) => {
    if (user) {
      const ref = doc(db, 'users', user.uid, 'cart', id)
      if (qty <= 0) return deleteDoc(ref)
      return updateDoc(ref, { qty })
    }

    setCartItems((prev) => {
      const next = prev
        .map((item) => (item.id === id ? { ...item, qty } : item))
        .filter((item) => item.qty > 0)
      persistLocalCart(next)
      return next
    })
  }

  const removeItem = (id) => {
    if (user) {
      const ref = doc(db, 'users', user.uid, 'cart', id)
      return deleteDoc(ref)
    }

    setCartItems((prev) => {
      const next = prev.filter((item) => item.id !== id)
      persistLocalCart(next)
      return next
    })
  }

  const clearCart = () => {
    if (user) {
      // Deleting mostly relies on batching for efficiency if many items
      cartItems.forEach((item) => {
        const ref = doc(db, 'users', user.uid, 'cart', item.id)
        deleteDoc(ref)
      })
      return
    }
    setCartItems([])
    persistLocalCart([])
  }

  // Hydrate items with product details from the `allProducts` (from useProducts hook)
  const detailedItems = useMemo(() => {
    if (!allProducts || allProducts.length === 0) return []
    return cartItems
      .map((item) => {
        const product = allProducts.find((entry) => entry.id === item.id)
        return product ? { ...product, qty: item.qty } : null
      })
      .filter(Boolean)
  }, [cartItems, allProducts])

  const subtotal = detailedItems.reduce(
    (sum, item) => sum + (item.price || 0) * item.qty,
    0,
  )

  const value = {
    items: detailedItems,
    addItem,
    updateItem,
    removeItem,
    clearCart,
    subtotal,
    loading,
    count: detailedItems.reduce((acc, item) => acc + item.qty, 0)
  }

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>
}

export function useCart() {
  const context = useContext(CartContext)
  if (!context) {
    throw new Error('useCart must be used within CartProvider')
  }
  return context
}


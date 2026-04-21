import { createContext, useContext, useEffect, useMemo, useState } from 'react'
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
  const remoteUserId = user?.uid?.trim() || ''

  const getBaseUrl = () => {
    const baseUrl = import.meta.env.VITE_API_BASE_URL
    if (!baseUrl) {
      throw new Error('Missing VITE_API_BASE_URL')
    }
    return baseUrl
  }

  const fetchRemoteCart = async (userId) => {
    const response = await fetch(
      `${getBaseUrl()}/cart?userId=${encodeURIComponent(userId)}`,
    )

    if (!response.ok) {
      throw new Error(`Cart request failed: ${response.status}`)
    }

    const data = await response.json()
    return Array.isArray(data.items) ? data.items : []
  }

  const putRemoteCartItem = async (userId, productId, qty) => {
    const response = await fetch(
      `${getBaseUrl()}/cart/${encodeURIComponent(productId)}`,
      {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userId,
          qty,
        }),
      },
    )

    if (!response.ok) {
      throw new Error(`Cart update failed: ${response.status}`)
    }
  }

  const deleteRemoteCartItem = async (userId, productId) => {
    const response = await fetch(
      `${getBaseUrl()}/cart/${encodeURIComponent(productId)}?userId=${encodeURIComponent(userId)}`,
      {
        method: 'DELETE',
      },
    )

    if (!response.ok) {
      throw new Error(`Cart delete failed: ${response.status}`)
    }
  }

  const clearRemoteCart = async (userId) => {
    const response = await fetch(
      `${getBaseUrl()}/cart?userId=${encodeURIComponent(userId)}`,
      {
        method: 'DELETE',
      },
    )

    if (!response.ok) {
      throw new Error(`Cart clear failed: ${response.status}`)
    }
  }

  useEffect(() => {
    if (!remoteUserId) {
      setCartItems(loadLocalCart())
      setLoading(false)
      return
    }

    let active = true

    async function syncRemoteCart() {
      try {
        setLoading(true)

        const local = loadLocalCart()
        if (local.length > 0) {
          await Promise.all(
            local.map((item) => putRemoteCartItem(remoteUserId, item.id, item.qty)),
          )
          localStorage.removeItem('a1-cart')
        }

        const next = await fetchRemoteCart(remoteUserId)
        if (active) {
          setCartItems(next)
          setLoading(false)
        }
      } catch {
        if (active) {
          setCartItems([])
          setLoading(false)
        }
      }
    }

    syncRemoteCart()

    return () => {
      active = false
    }
  }, [remoteUserId])

  const addItem = async (id, qty = 1) => {
    if (remoteUserId) {
      const existing = cartItems.find((item) => item.id === id)
      const nextQty = existing ? existing.qty + qty : qty
      await putRemoteCartItem(remoteUserId, id, nextQty)
      setCartItems((prev) => {
        const found = prev.find((item) => item.id === id)
        return found
          ? prev.map((item) => (item.id === id ? { ...item, qty: nextQty } : item))
          : [...prev, { id, qty: nextQty }]
      })
      return
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
    if (remoteUserId) {
      if (qty <= 0) {
        return removeItem(id)
      }

      return putRemoteCartItem(remoteUserId, id, qty).then(() => {
        setCartItems((prev) =>
          prev.map((item) => (item.id === id ? { ...item, qty } : item)),
        )
      })
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
    if (remoteUserId) {
      return deleteRemoteCartItem(remoteUserId, id).then(() => {
        setCartItems((prev) => prev.filter((item) => item.id !== id))
      })
    }

    setCartItems((prev) => {
      const next = prev.filter((item) => item.id !== id)
      persistLocalCart(next)
      return next
    })
  }

  const clearCart = () => {
    if (remoteUserId) {
      return clearRemoteCart(remoteUserId).then(() => {
        setCartItems([])
      })
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

import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import {
  getCurrentSession,
  signInWithCognito,
  signOutFromCognito,
  signUpWithCognito,
  forgotPassword as forgotPasswordCognito,
  confirmPassword as confirmPasswordCognito,
} from '../cognito.js'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let active = true

    getCurrentSession()
      .then((currentUser) => {
        if (!active) return
        setUser(currentUser)
        setLoading(false)
      })
      .catch(() => {
        if (!active) return
        setUser(null)
        setLoading(false)
      })

    return () => {
      active = false
    }
  }, [])

  const signIn = async (email, password) => {
    const nextUser = await signInWithCognito(email, password)
    setUser(nextUser)
    return nextUser
  }

  const signUp = async (email, password) => {
    return signUpWithCognito(email, password)
  }

  const signOut = async () => {
    await signOutFromCognito()
    setUser(null)
  }

  const forgotPassword = async (email) => {
    return forgotPasswordCognito(email)
  }

  const confirmPassword = async (email, code, newPassword) => {
    return confirmPasswordCognito(email, code, newPassword)
  }

  const value = useMemo(
    () => ({ user, loading, signIn, signUp, signOut, forgotPassword, confirmPassword }),
    [user, loading],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}

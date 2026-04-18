import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

const firebaseConfig = {
  apiKey: 'AIzaSyC5p0AdhibTTSqcGz7wkNg28L_beZsrdzs',
  authDomain: 'a1-water-tech.firebaseapp.com',
  projectId: 'a1-water-tech',
  storageBucket: 'a1-water-tech.firebasestorage.app',
  messagingSenderId: '381202778843',
  appId: '1:381202778843:web:208932db64720b33fd9afe',
  measurementId: 'G-23CVQN7P78',
}

const app = initializeApp(firebaseConfig)

if (typeof window !== 'undefined') {
  import('firebase/analytics')
    .then(({ getAnalytics, isSupported }) =>
      isSupported().then((supported) => {
        if (supported) getAnalytics(app)
      }),
    )
    .catch(() => {})
}

export const auth = getAuth(app)
export const db = getFirestore(app)

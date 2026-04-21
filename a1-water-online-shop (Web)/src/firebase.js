import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'
import { getFirestore } from 'firebase/firestore'

const firestoreDatabaseId = 'default'

const firebaseConfig = {
  apiKey: 'AIzaSyA_fT0vzvOarMOHp2nhNcA3F4Kno9oXDOM',
  authDomain: 'a1-tech-water.firebaseapp.com',
  projectId: 'a1-tech-water',
  storageBucket: 'a1-tech-water.firebasestorage.app',
  messagingSenderId: '384158666499',
  appId: '1:384158666499:web:5d5a74aaabf9e3574fe336',
  measurementId: 'G-ZZQSK3ESH8',
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
export const db = getFirestore(app, firestoreDatabaseId)

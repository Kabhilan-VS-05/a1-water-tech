import path from 'node:path'
import { fileURLToPath } from 'node:url'
import fs from 'node:fs/promises'
import admin from 'firebase-admin'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const rootDir = path.resolve(__dirname, '..')

const serviceAccountPath = path.join(
  rootDir,
  'a1-water-tech-firebase-adminsdk-fbsvc-2c1c94ffea.json',
)

async function readJson(filePath) {
  const raw = await fs.readFile(filePath, 'utf8')
  return JSON.parse(raw)
}

async function initAdmin() {
  const serviceAccount = await readJson(serviceAccountPath)
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    })
  }
  return admin.firestore()
}

async function deleteQuery(db, q, label) {
  const snap = await q.get()
  if (snap.empty) return 0

  const writer = db.bulkWriter()
  let deleted = 0

  for (const doc of snap.docs) {
    writer.delete(doc.ref)
    deleted += 1
  }

  await writer.close()
  console.log(`${label}: deleted ${deleted}`)
  return deleted
}

async function deleteCollectionAll(db, collectionPath, label) {
  // Loop pages so we can handle large collections.
  let total = 0
  while (true) {
    const q = db.collection(collectionPath).orderBy('__name__').limit(500)
    const snap = await q.get()
    if (snap.empty) break

    const writer = db.bulkWriter()
    for (const doc of snap.docs) writer.delete(doc.ref)
    await writer.close()

    total += snap.size
    console.log(`${label}: deleted ${total} so far`)
  }
  return total
}

async function deleteUserSubcollectionAll(db, subcollectionName, label) {
  // Iterate all users, and delete users/{uid}/{subcollectionName} documents.
  let deletedTotal = 0
  let last = null

  while (true) {
    let q = db.collection('users').orderBy('__name__').limit(200)
    if (last) q = q.startAfter(last)
    const usersSnap = await q.get()
    if (usersSnap.empty) break

    for (const userDoc of usersSnap.docs) {
      const uid = userDoc.id
      const base = db.collection('users').doc(uid).collection(subcollectionName)

      while (true) {
        const subSnap = await base.orderBy('__name__').limit(500).get()
        if (subSnap.empty) break

        const writer = db.bulkWriter()
        for (const doc of subSnap.docs) writer.delete(doc.ref)
        await writer.close()

        deletedTotal += subSnap.size
      }
    }

    last = usersSnap.docs[usersSnap.docs.length - 1]
    console.log(`${label}: deleted ${deletedTotal} so far`)
  }

  return deletedTotal
}

async function main() {
  const db = await initAdmin()

  console.log('Purging global collections...')
  const ordersDeleted = await deleteCollectionAll(db, 'orders', 'orders')
  const bookingsDeleted = await deleteCollectionAll(db, 'bookings', 'bookings')

  console.log('Purging user subcollections (legacy duplicates)...')
  const userOrdersDeleted = await deleteUserSubcollectionAll(
    db,
    'orders',
    'users/*/orders',
  )
  const userBookingsDeleted = await deleteUserSubcollectionAll(
    db,
    'bookings',
    'users/*/bookings',
  )

  console.log('Done.')
  console.log(
    JSON.stringify(
      {
        global: { ordersDeleted, bookingsDeleted },
        userSubcollections: { userOrdersDeleted, userBookingsDeleted },
      },
      null,
      2,
    ),
  )
}

main().catch((err) => {
  console.error('Purge failed:', err)
  process.exit(1)
})


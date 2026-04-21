import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import admin from 'firebase-admin'
import { getFirestore } from 'firebase-admin/firestore'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

async function readJson(filePath) {
  const raw = await fs.readFile(filePath, 'utf8')
  return JSON.parse(raw)
}

async function initAdmin(serviceAccountPath) {
  const serviceAccount = await readJson(serviceAccountPath)
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    })
  }
  return getFirestore('default')
}

async function deleteUserSubcollectionAll(db, subcollectionName) {
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
    console.log(`${subcollectionName}: deleted ${deletedTotal} so far`)
  }

  return deletedTotal
}

async function main() {
  const serviceAccountArgIndex = process.argv.indexOf('--serviceAccount')
  const serviceAccountArg =
    serviceAccountArgIndex >= 0 ? process.argv[serviceAccountArgIndex + 1] : ''
  const serviceAccountPath = path.resolve(
    __dirname,
    '..',
    serviceAccountArg || 'a1-tech-water-firebase-adminsdk-fbsvc-7272ff5ab2.json',
  )
  const db = await initAdmin(serviceAccountPath)

  console.log('Deleting legacy duplicates under users/*/orders and users/*/bookings ...')
  const orders = await deleteUserSubcollectionAll(db, 'orders')
  const bookings = await deleteUserSubcollectionAll(db, 'bookings')

  console.log('Done.')
  console.log(JSON.stringify({ userOrdersDeleted: orders, userBookingsDeleted: bookings }, null, 2))
}

main().catch((err) => {
  console.error('Failed:', err)
  process.exit(1)
})

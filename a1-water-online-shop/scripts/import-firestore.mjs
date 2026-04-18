import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import admin from 'firebase-admin'
import { getFirestore } from 'firebase-admin/firestore'
import { readServiceAccount } from './firebase-admin-config.mjs'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const rootDir = path.resolve(__dirname, '..')
const firestoreDatabaseId = 'default'

const productsPath = path.join(rootDir, 'products.firestore.json')
const servicesPath = path.join(rootDir, 'services.firestore.json')

async function readJson(filePath) {
  const raw = await fs.readFile(filePath, 'utf8')
  return JSON.parse(raw)
}

async function upsertCollection(db, collectionName, records) {
  const entries = Object.entries(records)
  const batchSize = 400
  let index = 0

  while (index < entries.length) {
    const batch = db.batch()
    const chunk = entries.slice(index, index + batchSize)
    for (const [docId, data] of chunk) {
      const ref = db.collection(collectionName).doc(docId)
      batch.set(ref, data, { merge: true })
    }
    await batch.commit()
    index += batchSize
  }

  return entries.length
}

function normalizeProduct(docId, data) {
  const name = typeof data.name === 'string' ? data.name : docId
  const features = Array.isArray(data.features) ? data.features : []
  return {
    ...data,
    name,
    type: 'product',
    isActive: data.isActive ?? true,
    schemaVersion: 2,
    imageUrl: data.imageUrl || '/sample-product.jpg',
    features,
    searchKeywords: [
      ...new Set(
        `${name} ${data.category || ''}`
          .toLowerCase()
          .split(/\s+/)
          .filter(Boolean),
      ),
    ],
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: data.createdAt ?? admin.firestore.FieldValue.serverTimestamp(),
  }
}

function normalizeService(docId, data) {
  const name = typeof data.name === 'string' ? data.name : docId
  return {
    ...data,
    name,
    type: 'service',
    isActive: data.isActive ?? true,
    schemaVersion: 2,
    imageUrl: data.imageUrl || '/sample-service.jpg',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: data.createdAt ?? admin.firestore.FieldValue.serverTimestamp(),
  }
}

async function main() {
  const serviceAccount = await readServiceAccount(rootDir)
  const productSeed = await readJson(productsPath)
  const serviceSeed = await readJson(servicesPath)

  const products = Object.fromEntries(
    Object.entries(productSeed).map(([docId, data]) => [
      docId,
      normalizeProduct(docId, data),
    ]),
  )
  const services = Object.fromEntries(
    Object.entries(serviceSeed).map(([docId, data]) => [
      docId,
      normalizeService(docId, data),
    ]),
  )

  let app = admin.apps[0]
  if (!app) {
    app = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    })
  }

  const db = getFirestore(app, firestoreDatabaseId)
  const productCount = await upsertCollection(db, 'products', products)
  const serviceCount = await upsertCollection(db, 'services', services)

  console.log(`Imported products: ${productCount}`)
  console.log(`Imported services: ${serviceCount}`)
}

main().catch((error) => {
  console.error('Import failed:', error)
  process.exit(1)
})

import fs from 'node:fs/promises'
import path from 'node:path'
import crypto from 'node:crypto'
import { fileURLToPath } from 'node:url'
import admin from 'firebase-admin'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const rootDir = path.resolve(__dirname, '..')

const serviceAccountPath = path.join(
  rootDir,
  'a1-water-tech-firebase-adminsdk-fbsvc-2c1c94ffea.json',
)
const publicDir = path.join(rootDir, 'public')
const productsPath = path.join(rootDir, 'products.firestore.json')
const servicesPath = path.join(rootDir, 'services.firestore.json')
const outputPath = path.join(rootDir, 'storage.upload-map.json')

const PRODUCT_IMAGES = {
  'a1-pureflow-rouv': 'A1 PureFlow RO + UV.png',
  'a1-aquashield-ro': 'A1 AquaShield RO.png',
  'a1-mineral-plus': 'A1 Mineral+ Cartridge.png',
  'a1-sediment-guard': 'A1 Sediment Guard.png',
  'a1-servicecare-annual': 'ServiceCare Annual.png',
  'a1-commercial-ro-50': 'A1 Commercial RO 50L.png',
  'a1-uv-compact': 'UV Compact.png',
  'a1-smart-dispenser': 'Smart Water Dispenser.png',
  'a1-copper-guard-pro': 'A1 Copper Guard Pro.png',
  'a1-ro-membrane-kit': 'A1 RO Membrane Kit.png',
}

const SERVICE_IMAGES = {
  'install-standard': 'Services.png',
  'service-annual': 'ServiceCare Annual.png',
  'service-premium': 'Services.png',
  'service-emergency-visit': 'Services.png',
}

const EXTRA_IMAGES = {
  'brand/logo': 'a1-logo.jpeg',
  'products/sample': 'sample-product.jpg',
  'services/sample': 'sample-service.jpg',
  'categories/purifiers': 'Purifiers Explore.png',
  'categories/filters': 'Filters.png',
  'categories/services': 'Services.png',
  'categories/commercial': 'Commercial.png',
  'categories/accessories': 'Accessories.png',
}

async function readJson(filePath) {
  const raw = await fs.readFile(filePath, 'utf8')
  return JSON.parse(raw)
}

async function writeJson(filePath, value) {
  await fs.writeFile(filePath, JSON.stringify(value, null, 2))
}

function extToContentType(filename) {
  const ext = path.extname(filename).toLowerCase()
  if (ext === '.png') return 'image/png'
  if (ext === '.jpg' || ext === '.jpeg') return 'image/jpeg'
  if (ext === '.svg') return 'image/svg+xml'
  if (ext === '.webp') return 'image/webp'
  return 'application/octet-stream'
}

async function uploadWithToken(bucket, localFilePath, destination) {
  const token = crypto.randomUUID()
  await bucket.upload(localFilePath, {
    destination,
    metadata: {
      cacheControl: 'public,max-age=31536000',
      contentType: extToContentType(localFilePath),
      metadata: {
        firebaseStorageDownloadTokens: token,
      },
    },
  })

  const encoded = encodeURIComponent(destination)
  return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encoded}?alt=media&token=${token}`
}

async function resolveBucket(serviceAccount) {
  const adminStorage = admin.storage()
  const candidates = [
    process.env.FIREBASE_STORAGE_BUCKET,
    `${serviceAccount.project_id}.firebasestorage.app`,
    `${serviceAccount.project_id}.appspot.com`,
  ].filter(Boolean)

  for (const bucketName of candidates) {
    try {
      const bucket = adminStorage.bucket(bucketName)
      const [exists] = await bucket.exists()
      if (exists) return bucket
    } catch {
      // Try next candidate.
    }
  }

  throw new Error(
    [
      'No Firebase Storage bucket found for this project.',
      `Checked: ${candidates.join(', ')}`,
      'Create/enable Cloud Storage in Firebase Console first.',
      'If bucket creation fails with billing error, enable billing on the project and retry.',
    ].join(' '),
  )
}

async function uploadMappedFiles(bucket, mapping, folderPrefix) {
  const result = {}
  for (const [key, fileName] of Object.entries(mapping)) {
    const localFilePath = path.join(publicDir, fileName)
    const destination = `${folderPrefix}/${key}/${fileName}`
    try {
      await fs.access(localFilePath)
    } catch {
      throw new Error(`Missing image file: ${localFilePath}`)
    }
    const url = await uploadWithToken(bucket, localFilePath, destination)
    result[key] = { fileName, path: destination, url }
  }
  return result
}

async function main() {
  const serviceAccount = await readJson(serviceAccountPath)
  const products = await readJson(productsPath)
  const services = await readJson(servicesPath)

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    })
  }

  const bucket = await resolveBucket(serviceAccount)

  const uploadedProducts = await uploadMappedFiles(
    bucket,
    PRODUCT_IMAGES,
    'website/products',
  )
  const uploadedServices = await uploadMappedFiles(
    bucket,
    SERVICE_IMAGES,
    'website/services',
  )
  const uploadedExtras = await uploadMappedFiles(bucket, EXTRA_IMAGES, 'website')

  for (const [docId, uploaded] of Object.entries(uploadedProducts)) {
    if (products[docId]) {
      products[docId].imageUrl = uploaded.url
    }
  }

  for (const [docId, uploaded] of Object.entries(uploadedServices)) {
    if (services[docId]) {
      services[docId].imageUrl = uploaded.url
    }
  }

  await writeJson(productsPath, products)
  await writeJson(servicesPath, services)
  await writeJson(outputPath, {
    bucket: bucket.name,
    uploadedAt: new Date().toISOString(),
    products: uploadedProducts,
    services: uploadedServices,
    extras: uploadedExtras,
  })

  console.log(`Storage bucket: ${bucket.name}`)
  console.log(`Uploaded product images: ${Object.keys(uploadedProducts).length}`)
  console.log(`Uploaded service images: ${Object.keys(uploadedServices).length}`)
  console.log(`Uploaded extra images: ${Object.keys(uploadedExtras).length}`)
  console.log(`Updated: ${path.relative(rootDir, productsPath)}`)
  console.log(`Updated: ${path.relative(rootDir, servicesPath)}`)
  console.log(`Wrote map: ${path.relative(rootDir, outputPath)}`)
}

main().catch((error) => {
  console.error('Image upload failed:', error)
  process.exit(1)
})

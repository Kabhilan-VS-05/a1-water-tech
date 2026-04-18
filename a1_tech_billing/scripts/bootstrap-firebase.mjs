import crypto from 'node:crypto'
import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import admin from 'firebase-admin'
import { getFirestore } from 'firebase-admin/firestore'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

function parseArgs(argv) {
  const args = {}
  for (let i = 2; i < argv.length; i += 1) {
    const key = argv[i]
    const next = argv[i + 1]
    if (!key.startsWith('--')) continue
    args[key.slice(2)] = next && !next.startsWith('--') ? next : true
  }
  return args
}

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
  return {
    auth: admin.auth(),
    db: getFirestore('default'),
  }
}

function generatePassword() {
  return crypto.randomBytes(18).toString('base64url')
}

async function ensureAdminUser({ auth, db, email, createIfMissing }) {
  let user
  let created = false
  let temporaryPassword = ''

  try {
    user = await auth.getUserByEmail(email)
  } catch (error) {
    if (error?.code !== 'auth/user-not-found') {
      throw error
    }
    if (!createIfMissing) {
      return { user: null, created, temporaryPassword }
    }

    temporaryPassword = generatePassword()
    user = await auth.createUser({
      email,
      password: temporaryPassword,
      emailVerified: true,
      displayName: 'A1 Water Tech Admin',
    })
    created = true
  }

  await auth.setCustomUserClaims(user.uid, { admin: true })

  await db.collection('admins').doc(user.uid).set(
    {
      email,
      admin: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(created
        ? { createdAt: admin.firestore.FieldValue.serverTimestamp() }
        : {}),
    },
    { merge: true },
  )

  return { user, created, temporaryPassword }
}

async function ensureBillingSettings(db) {
  const billingRef = db.collection('app_settings').doc('billing')
  const billingSnap = await billingRef.get()

  await billingRef.set(
    {
      companyName: 'A1 Water Tech',
      supportPhone: '',
      invoicePrefix: 'BILL',
      gstRate: 0,
      gstEnabled: false,
      updatedBy: 'bootstrap-script',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(billingSnap.exists
        ? {}
        : { createdAt: admin.firestore.FieldValue.serverTimestamp() }),
    },
    { merge: true },
  )

  return { existed: billingSnap.exists }
}

async function ensureBusinessProfile(db) {
  const businessRef = db.collection('app_settings').doc('business')
  const businessSnap = await businessRef.get()

  await businessRef.set(
    {
      companyName: 'A1 Water Tech',
      supportPhone: '+91 8778308119',
      supportEmail: 'thinakarans12345@gmail.com',
      locality: 'Gobichettipalayam, Tamil Nadu',
      addressLine1: 'G.K.M Gowtham Complex, Opp. HP Bunk',
      addressLine2: 'Sathy-Athani Main Road, Kalipatti',
      addressLine3: 'Gobichettipalayam - 638505',
      gstin: '33CWHPH8901N1Z6',
      updatedBy: 'bootstrap-script',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(businessSnap.exists
        ? {}
        : { createdAt: admin.firestore.FieldValue.serverTimestamp() }),
    },
    { merge: true },
  )

  return { existed: businessSnap.exists }
}

async function main() {
  const args = parseArgs(process.argv)
  const serviceAccountPath = path.resolve(
    __dirname,
    '..',
    args.serviceAccount
      ? String(args.serviceAccount)
      : 'a1-tech-water-firebase-adminsdk-fbsvc-7272ff5ab2.json',
  )
  const adminEmail = args.email ? String(args.email) : 'admin@a1watertech.com'
  const createAdmin = args.createAdmin !== 'false'

  const { auth, db } = await initAdmin(serviceAccountPath)
  const businessResult = await ensureBusinessProfile(db)
  const billingResult = await ensureBillingSettings(db)
  const adminResult = await ensureAdminUser({
    auth,
    db,
    email: adminEmail,
    createIfMissing: createAdmin,
  })

  console.log(
    JSON.stringify(
      {
        projectId: 'a1-tech-water',
        businessProfileReady: true,
        businessProfilePreviouslyExisted: businessResult.existed,
        billingSettingsReady: true,
        billingSettingsPreviouslyExisted: billingResult.existed,
        adminEmail,
        adminUserReady: Boolean(adminResult.user),
        adminUserCreated: adminResult.created,
        adminUid: adminResult.user?.uid ?? '',
        temporaryPassword: adminResult.temporaryPassword || '',
      },
      null,
      2,
    ),
  )
}

main().catch((err) => {
  console.error('Failed:', err)
  process.exit(1)
})

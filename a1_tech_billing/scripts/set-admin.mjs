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

async function main() {
  const args = parseArgs(process.argv)

  const serviceAccountPath = path.resolve(
    __dirname,
    '..',
    args.serviceAccount
      ? String(args.serviceAccount)
      : 'a1-tech-water-firebase-adminsdk-fbsvc-7272ff5ab2.json',
  )

  const email = args.email ? String(args.email) : ''
  const uid = args.uid ? String(args.uid) : ''
  if (!email && !uid) {
    console.error('Usage: node set-admin.mjs --email admin@example.com')
    console.error('   or: node set-admin.mjs --uid <FIREBASE_UID>')
    console.error('Optional: --serviceAccount ../my-project-adminsdk.json')
    process.exit(2)
  }

  const { auth, db } = await initAdmin(serviceAccountPath)

  const user = uid ? await auth.getUser(uid) : await auth.getUserByEmail(email)
  await auth.setCustomUserClaims(user.uid, { admin: true })

  await db.collection('admins').doc(user.uid).set(
    {
      email: user.email || email || '',
      admin: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  )

  console.log(`Admin enabled for uid=${user.uid} email=${user.email || ''}`)
  console.log('Note: user must sign out/in (or refresh token) to pick up claims.')
}

main().catch((err) => {
  console.error('Failed:', err)
  process.exit(1)
})

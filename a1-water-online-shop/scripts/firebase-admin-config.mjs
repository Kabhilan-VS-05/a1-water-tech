import fs from 'node:fs/promises'
import path from 'node:path'

export async function findServiceAccountPath(rootDir) {
  const configuredPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
  if (configuredPath) {
    return path.resolve(rootDir, configuredPath)
  }

  const entries = await fs.readdir(rootDir, { withFileTypes: true })
  const matches = entries
    .filter(
      (entry) =>
        entry.isFile() &&
        /firebase-adminsdk-.*\.json$/i.test(entry.name),
    )
    .map((entry) => path.join(rootDir, entry.name))

  if (matches.length === 1) {
    return matches[0]
  }

  if (matches.length === 0) {
    throw new Error(
      [
        'No Firebase service account JSON was found in the project root.',
        'Add the file there or set FIREBASE_SERVICE_ACCOUNT_PATH.',
      ].join(' '),
    )
  }

  throw new Error(
    [
      'Multiple Firebase service account JSON files were found.',
      'Set FIREBASE_SERVICE_ACCOUNT_PATH to choose the correct one.',
    ].join(' '),
  )
}

export async function readServiceAccount(rootDir) {
  const serviceAccountPath = await findServiceAccountPath(rootDir)
  const raw = await fs.readFile(serviceAccountPath, 'utf8')
  return JSON.parse(raw)
}

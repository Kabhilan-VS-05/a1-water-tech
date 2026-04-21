import { Buffer } from 'buffer'

if (typeof globalThis.global === 'undefined') {
  globalThis.global = globalThis
}

if (typeof globalThis.process === 'undefined') {
  globalThis.process = { env: {} }
} else if (typeof globalThis.process.env === 'undefined') {
  globalThis.process.env = {}
}

if (typeof globalThis.Buffer === 'undefined') {
  globalThis.Buffer = Buffer
}

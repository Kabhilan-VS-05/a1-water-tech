import http from 'node:http'
import { handler } from './index.mjs'
import { normalizeRoute, recordMetrics, renderMetrics } from './metrics.mjs'

const port = Number(process.env.PORT || 3000)

function collectBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = []
    req.on('data', (chunk) => chunks.push(chunk))
    req.on('end', () => {
      if (chunks.length === 0) {
        resolve('')
        return
      }
      resolve(Buffer.concat(chunks).toString('utf8'))
    })
    req.on('error', reject)
  })
}

function toQueryStringParameters(url) {
  const params = {}
  for (const [key, value] of url.searchParams.entries()) {
    params[key] = value
  }
  return params
}

const server = http.createServer(async (req, res) => {
  const startedAt = process.hrtime.bigint()
  const url = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`)
  const method = req.method || 'GET'
  const route = normalizeRoute(url.pathname)

  if (route === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify({ ok: true }))
    return
  }

  if (route === '/metrics') {
    res.writeHead(200, { 'Content-Type': 'text/plain; version=0.0.4; charset=utf-8' })
    res.end(renderMetrics())
    return
  }

  try {
    const body = await collectBody(req)
    const result = await handler({
      rawPath: route,
      body,
      queryStringParameters: toQueryStringParameters(url),
      requestContext: {
        http: {
          method,
          path: route,
        },
      },
    })

    const statusCode = Number(result?.statusCode || 200)
    const responseBody = result?.body || ''
    const headers = result?.headers || { 'Content-Type': 'application/json' }

    res.writeHead(statusCode, headers)
    res.end(responseBody)

    const durationSeconds = Number(process.hrtime.bigint() - startedAt) / 1_000_000_000
    recordMetrics({
      method,
      route,
      statusCode,
      durationSeconds,
    })
  } catch (error) {
    console.error('Container request failed', error)
    res.writeHead(500, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify({ message: 'Internal Server Error' }))

    const durationSeconds = Number(process.hrtime.bigint() - startedAt) / 1_000_000_000
    recordMetrics({
      method,
      route,
      statusCode: 500,
      durationSeconds,
    })
  }
})

server.listen(port, () => {
  console.log(`A1 backend container is listening on port ${port}`)
})

const counters = new Map()
const durationBuckets = [0.1, 0.3, 0.5, 1, 2, 5]
const durationValues = new Map()
let totalDurationSum = 0
let totalDurationCount = 0

function sanitize(value) {
  return String(value || 'unknown').replace(/\\/g, '\\\\').replace(/"/g, '\\"')
}

function counterKey(method, route, statusCode) {
  return `${method}|${route}|${statusCode}`
}

function recordBucket(duration) {
  for (const bucket of durationBuckets) {
    if (duration <= bucket) {
      durationValues.set(bucket, (durationValues.get(bucket) || 0) + 1)
    }
  }
  durationValues.set('+Inf', (durationValues.get('+Inf') || 0) + 1)
}

export function normalizeRoute(path) {
  if (!path) return '/'
  return String(path).split('?')[0] || '/'
}

export function recordMetrics({ method, route, statusCode, durationSeconds }) {
  const key = counterKey(method, route, statusCode)
  counters.set(key, (counters.get(key) || 0) + 1)
  recordBucket(durationSeconds)
  totalDurationSum += durationSeconds
  totalDurationCount += 1
}

export function renderMetrics() {
  const lines = [
    '# HELP a1_backend_http_requests_total Total HTTP requests handled by the backend',
    '# TYPE a1_backend_http_requests_total counter',
  ]

  for (const [key, value] of counters.entries()) {
    const [method, route, statusCode] = key.split('|')
    lines.push(
      `a1_backend_http_requests_total{method="${sanitize(method)}",route="${sanitize(route)}",status_code="${sanitize(statusCode)}"} ${value}`,
    )
  }

  lines.push(
    '# HELP a1_backend_http_request_duration_seconds Backend request duration in seconds',
    '# TYPE a1_backend_http_request_duration_seconds histogram',
  )

  for (const bucket of durationBuckets) {
    lines.push(
      `a1_backend_http_request_duration_seconds_bucket{le="${bucket}"} ${durationValues.get(bucket) || 0}`,
    )
  }

  lines.push(
    `a1_backend_http_request_duration_seconds_bucket{le="+Inf"} ${durationValues.get('+Inf') || 0}`,
    `a1_backend_http_request_duration_seconds_sum ${totalDurationSum}`,
    `a1_backend_http_request_duration_seconds_count ${totalDurationCount}`,
  )

  return `${lines.join('\n')}\n`
}

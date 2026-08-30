import pg from 'pg';
import dotenv from 'dotenv';
import { handleAdminRoute } from './admin.mjs';

dotenv.config();

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

function getPool() {
  return pool;
}

function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
    body: JSON.stringify(body, (key, value) =>
      typeof value === 'bigint' ? value.toString() : value
    ),
  };
}

function parseJsonBody(body) {
  if (!body) return {};
  if (typeof body === 'string') return JSON.parse(body);
  return body;
}

function getQueryValue(event, key) {
  return event?.queryStringParameters?.[key] || '';
}

function getPathId(path, prefix) {
  const start = path.indexOf(prefix);
  if (start < 0) return '';
  const value = path.slice(start + prefix.length).split('/')[0];
  return decodeURIComponent(value || '');
}

async function testAllAdminEndpoints() {
  console.log('====================================================');
  console.log('  FLUTTER MOBILE ADMIN API INTEGRATION TEST (SUPABASE)');
  console.log('====================================================');

  const tests = [
    { name: '1. GET /admin/orders', path: '/admin/orders', method: 'GET' },
    { name: '2. GET /admin/bookings', path: '/admin/bookings', method: 'GET' },
    { name: '3. GET /admin/bills', path: '/admin/bills', method: 'GET' },
    { name: '4. GET /admin/quotations', path: '/admin/quotations', method: 'GET' },
    { name: '5. GET /admin/purchase-orders', path: '/admin/purchase-orders', method: 'GET' },
    { name: '6. GET /admin/users (Customers)', path: '/admin/users', method: 'GET' },
    { name: '7. GET /admin/catalog/products', path: '/admin/catalog/products', method: 'GET' },
    { name: '8. GET /admin/catalog/services', path: '/admin/catalog/services', method: 'GET' },
    { name: '9. GET /admin/metrics', path: '/admin/metrics', method: 'GET', query: { days: '30' } },
    { name: '10. GET /admin/settings/business', path: '/admin/settings/business', method: 'GET' },
    { name: '11. GET /admin/settings/billing', path: '/admin/settings/billing', method: 'GET' },
    { name: '12. GET /admin/feedback', path: '/admin/feedback', method: 'GET' },
  ];

  let passed = 0;
  let failed = 0;

  for (const t of tests) {
    try {
      const event = {
        path: t.path,
        rawPath: t.path,
        httpMethod: t.method,
        requestContext: {
          http: { method: t.method, path: t.path },
          authorizer: {
            claims: {
              sub: 'admin-test-sub',
              email: 'admin@a1watertech.in',
              name: 'Admin'
            }
          }
        },
        queryStringParameters: t.query || {},
        headers: {
          authorization: 'Bearer bypass-token-for-test'
        }
      };

      const res = await handleAdminRoute({
        method: t.method,
        path: t.path,
        event,
        getPool,
        response,
        parseJsonBody,
        getQueryValue,
        getPathId,
      });

      if (res && (res.statusCode === 200 || res.statusCode === 201)) {
        const parsed = JSON.parse(res.body);
        const count = Array.isArray(parsed.items) ? `${parsed.items.length} items` : (Array.isArray(parsed) ? `${parsed.length} items` : 'OK (object)');
        console.log(`✅ [PASS] ${t.name} -> Status: ${res.statusCode}, Data: ${count}`);
        passed++;
      } else {
        console.log(`❌ [FAIL] ${t.name} -> Status: ${res?.statusCode}, Body: ${res?.body}`);
        failed++;
      }
    } catch (err) {
      console.log(`❌ [ERROR] ${t.name} -> ${err.message}`);
      failed++;
    }
  }

  console.log('\n====================================================');
  console.log(`  SUMMARY: ${passed} PASSED / ${failed} FAILED`);
  console.log('====================================================');

  await pool.end();
}

testAllAdminEndpoints();

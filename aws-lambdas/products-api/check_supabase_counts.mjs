import pg from 'pg';

const { Pool } = pg;

const pool = new Pool({
  connectionString: 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function checkCounts() {
  const tables = ['products', 'services', 'business_settings', 'billing_settings', 'bookings', 'orders', 'quotations', 'customers', 'admins'];
  console.log('--- SUPABASE TABLE ROW COUNTS ---');
  for (const t of tables) {
    try {
      const res = await pool.query(`SELECT count(*) FROM "${t}"`);
      console.log(`${t}: ${res.rows[0].count} rows`);
    } catch (e) {
      console.log(`${t}: Error (${e.message})`);
    }
  }
  await pool.end();
}

checkCounts();

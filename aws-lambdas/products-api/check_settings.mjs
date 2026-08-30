import pg from 'pg';

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function checkSettings() {
  const bRes = await pool.query('SELECT * FROM business_settings');
  console.log('business_settings row:', bRes.rows);
  const billRes = await pool.query('SELECT * FROM billing_settings');
  console.log('billing_settings row:', billRes.rows);
  await pool.end();
}

checkSettings();

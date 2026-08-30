import pg from 'pg';

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function updateRemainingSchemas() {
  console.log('--- Adding remaining columns to customers and feedback tables ---');

  await pool.query(`
    ALTER TABLE customers
      ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'manual',
      ADD COLUMN IF NOT EXISTS total_visits INTEGER NOT NULL DEFAULT 0,
      ADD COLUMN IF NOT EXISTS total_spent NUMERIC(12, 2) NOT NULL DEFAULT 0;

    ALTER TABLE feedback
      ADD COLUMN IF NOT EXISTS order_id TEXT NOT NULL DEFAULT '',
      ADD COLUMN IF NOT EXISTS admin_response TEXT NOT NULL DEFAULT '',
      ADD COLUMN IF NOT EXISTS updated_by TEXT NOT NULL DEFAULT '',
      ADD COLUMN IF NOT EXISTS responded_by TEXT NOT NULL DEFAULT '',
      ADD COLUMN IF NOT EXISTS created_by TEXT NOT NULL DEFAULT '',
      ADD COLUMN IF NOT EXISTS responded_at TIMESTAMPTZ,
      ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMPTZ;
  `);

  console.log('✅ Columns added successfully.');
  await pool.end();
}

updateRemainingSchemas().catch(console.error);

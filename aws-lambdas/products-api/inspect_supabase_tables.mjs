import pg from 'pg';

const { Pool } = pg;

const pool = new Pool({
  connectionString: 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function inspect() {
  console.log('=== SUPABASE SCHEMA INSPECTION ===');
  const tableRes = await pool.query(`
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public'
    ORDER BY table_name;
  `);

  console.log('Tables found:', tableRes.rows.map(r => r.table_name));

  for (const row of tableRes.rows) {
    const table = row.table_name;
    const colRes = await pool.query(`
      SELECT column_name, data_type, column_default, is_nullable
      FROM information_schema.columns
      WHERE table_name = $1
      ORDER BY ordinal_position;
    `, [table]);

    const countRes = await pool.query(`SELECT count(*) FROM "${table}"`);
    console.log(`\nTable: "${table}" (${countRes.rows[0].count} rows)`);
    colRes.rows.forEach(col => {
      console.log(`  - ${col.column_name}: ${col.data_type} (default: ${col.column_default}, nullable: ${col.is_nullable})`);
    });
  }

  await pool.end();
}

inspect().catch(err => {
  console.error('Inspection error:', err);
});

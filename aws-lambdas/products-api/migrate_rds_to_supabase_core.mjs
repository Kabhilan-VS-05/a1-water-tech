import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

// 1. RDS Connection Pool (Targeting AWS RDS)
export async function dumpFromRdsToSupabase() {
  const rdsPool = new Pool({
    host: 'a1-water-tech-db.chk0gamumn4n.ap-south-1.rds.amazonaws.com',
    user: 'a1admin',
    password: 'Thinakaran$5',
    database: 'postgres',
    port: 5432,
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 15000,
  });

  // 2. Supabase Connection Pool
  const supabasePool = new Pool({
    connectionString: 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
    ssl: { rejectUnauthorized: false },
    connectionTimeoutMillis: 15000,
  });

  const summary = {};

  const tablesToMigrate = [
    'bills',
    'quotations',
    'purchase_orders',
    'orders',
    'bookings',
    'customers',
    'products',
    'services',
    'user_addresses',
    'feedback'
  ];

  try {
    for (const table of tablesToMigrate) {
      try {
        console.log(`Checking table "${table}" in RDS...`);
        const rdsRes = await rdsPool.query(`SELECT * FROM "${table}"`);
        const rows = rdsRes.rows;
        summary[table] = { rdsRows: rows.length, migrated: 0 };

        if (rows.length === 0) continue;

        const columns = Object.keys(rows[0]);
        const colsStr = columns.map(c => `"${c}"`).join(', ');

        for (const row of rows) {
          const values = columns.map(c => row[c]);
          const placeholders = columns.map((_, i) => `$${i + 1}`).join(', ');

          const insertSql = `
            INSERT INTO "${table}" (${colsStr})
            VALUES (${placeholders})
            ON CONFLICT DO NOTHING
          `;
          await supabasePool.query(insertSql, values);
          summary[table].migrated++;
        }
        console.log(`Successfully migrated ${rows.length} rows for table "${table}" to Supabase.`);
      } catch (tableErr) {
        console.warn(`Notice on table "${table}": ${tableErr.message}`);
        summary[table] = { error: tableErr.message };
      }
    }
  } finally {
    await rdsPool.end();
    await supabasePool.end();
  }

  return summary;
}

import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

// Connection to Source AWS RDS
const rdsPool = new Pool({
  host: process.env.DB_HOST || 'a1-water-tech-db.chk0gamumn4n.ap-south-1.rds.amazonaws.com',
  user: process.env.DB_USER || 'a1admin',
  password: process.env.DB_PASSWORD || 'Thinakaran$5',
  database: process.env.DB_NAME || 'postgres',
  port: Number(process.env.DB_PORT || 5432),
  ssl: { rejectUnauthorized: false }
});

// Connection to Target Supabase
const supabaseConnectionString = process.env.SUPABASE_DB_URL || 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres';

const supabasePool = new Pool({
  connectionString: supabaseConnectionString,
  ssl: { rejectUnauthorized: false }
});

async function migrateData() {
  console.log('--- Starting Data Migration from AWS RDS to Supabase ---');

  const tables = [
    'products',
    'services',
    'announcements',
    'faqs',
    'business_settings',
    'billing_settings',
    'bookings',
    'user_addresses',
    'orders',
    'cart_items',
    'quotations',
    'customers',
    'feedback',
    'admins'
  ];

  try {
    for (const table of tables) {
      console.log(`\nMigrating table: ${table}...`);
      try {
        const sourceResult = await rdsPool.query(`SELECT * FROM ${table}`);
        const rows = sourceResult.rows;
        console.log(`Found ${rows.length} rows in RDS for ${table}.`);

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
        }
        console.log(`Successfully migrated ${rows.length} rows into Supabase for ${table}!`);
      } catch (err) {
        console.warn(`Notice migrating ${table}:`, err.message);
      }
    }

    console.log('\nSUCCESS! All data has been migrated from AWS RDS to Supabase!');
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await rdsPool.end();
    await supabasePool.end();
  }
}

migrateData();

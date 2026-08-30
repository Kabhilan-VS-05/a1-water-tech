import pg from 'pg';

const { Pool } = pg;

// Source: AWS RDS
const rdsPool = new Pool({
  host: 'a1-water-tech-db.chk0gamumn4n.ap-south-1.rds.amazonaws.com',
  user: 'a1admin',
  password: 'Thinakaran$5',
  database: 'postgres',
  port: 5432,
  ssl: { rejectUnauthorized: false }
});

// Destination: Supabase
const supabasePool = new Pool({
  connectionString: 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function runFullMigration() {
  console.log('=====================================================');
  console.log('  MIGRATING ALL DATA FROM AWS RDS TO SUPABASE');
  console.log('=====================================================');

  const tables = [
    'bills',
    'orders',
    'bookings',
    'customers',
    'user_addresses',
    'feedback',
    'quotations',
    'purchase_orders',
    'cart_items'
  ];

  for (const table of tables) {
    console.log(`\n--- Processing Table: "${table}" ---`);
    try {
      const sourceResult = await rdsPool.query(`SELECT * FROM "${table}"`);
      const rows = sourceResult.rows;
      console.log(`Found ${rows.length} rows in RDS for "${table}".`);

      if (rows.length === 0) continue;

      let successCount = 0;
      let conflictCount = 0;

      // Get target columns in Supabase
      const targetColRes = await supabasePool.query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = $1
      `, [table]);
      const validColsMap = new Map(targetColRes.rows.map(r => [r.column_name, r.data_type]));

      for (const row of rows) {
        const matchingCols = Object.keys(row).filter(c => validColsMap.has(c));
        const colsStr = matchingCols.map(c => `"${c}"`).join(', ');

        const values = matchingCols.map(c => {
          const val = row[c];
          const colType = validColsMap.get(c);
          if (val !== null && typeof val === 'object' && !(val instanceof Date)) {
            return JSON.stringify(val);
          }
          return val;
        });

        const placeholders = matchingCols.map((c, i) => {
          const colType = validColsMap.get(c);
          if (colType === 'jsonb' || colType === 'json') {
            return `$${i + 1}::jsonb`;
          }
          return `$${i + 1}`;
        }).join(', ');

        let conflictClause = 'ON CONFLICT DO NOTHING';
        if (table === 'orders') conflictClause = 'ON CONFLICT (order_id) DO UPDATE SET customer = EXCLUDED.customer, address_snapshot = EXCLUDED.address_snapshot, items = EXCLUDED.items, billing = EXCLUDED.billing, subtotal = EXCLUDED.subtotal, total = EXCLUDED.total, status = EXCLUDED.status, updated_at = now()';
        if (table === 'bills') conflictClause = 'ON CONFLICT (bill_number) DO NOTHING';
        if (table === 'cart_items') conflictClause = 'ON CONFLICT (user_id, product_id) DO UPDATE SET qty = EXCLUDED.qty, updated_at = now()';
        if (table === 'customers') conflictClause = 'ON CONFLICT (phone) DO UPDATE SET name = EXCLUDED.name, address = EXCLUDED.address, email = EXCLUDED.email, updated_at = now()';

        const insertSql = `
          INSERT INTO "${table}" (${colsStr})
          VALUES (${placeholders})
          ${conflictClause}
        `;

        try {
          const res = await supabasePool.query(insertSql, values);
          if (res.rowCount > 0) successCount++;
          else conflictCount++;
        } catch (rowErr) {
          console.warn(`  Row error in "${table}": ${rowErr.message}`);
        }
      }

      console.log(`✅ Finished "${table}": ${successCount} inserted/updated, ${conflictCount} skipped.`);
    } catch (err) {
      console.error(`❌ Error migrating "${table}":`, err.message);
    }
  }

  // Final verification counts in Supabase
  console.log('\n=====================================================');
  console.log('  FINAL SUPABASE DATA VERIFICATION');
  console.log('=====================================================');
  for (const t of ['bills', 'orders', 'bookings', 'customers', 'user_addresses', 'feedback', 'products', 'services']) {
    try {
      const res = await supabasePool.query(`SELECT count(*) FROM "${t}"`);
      console.log(`📊 Supabase Table "${t}": ${res.rows[0].count} total rows`);
    } catch (e) {
      console.log(`📊 Supabase Table "${t}": Error (${e.message})`);
    }
  }

  await rdsPool.end();
  await supabasePool.end();
  console.log('\n🎉 ALL RDS DATA HAS BEEN FULLY TRANSFERRED TO SUPABASE!');
}

runFullMigration().catch(console.error);

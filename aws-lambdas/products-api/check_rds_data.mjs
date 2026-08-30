import pg from 'pg';

const rdsPool = new pg.Pool({
  host: 'a1-water-tech-db.chk0gamumn4n.ap-south-1.rds.amazonaws.com',
  user: 'a1admin',
  password: 'Thinakaran$5',
  database: 'postgres',
  port: 5432,
  ssl: { rejectUnauthorized: false },
  connectionTimeoutMillis: 10000,
});

async function checkRDS() {
  console.log('Testing RDS connection...');
  try {
    const res = await rdsPool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
    console.log('RDS Tables:', res.rows.map(r => r.table_name));

    for (const row of res.rows) {
      const t = row.table_name;
      try {
        const countRes = await rdsPool.query(`SELECT count(*) FROM "${t}"`);
        console.log(`RDS Table "${t}": ${countRes.rows[0].count} rows`);
      } catch (err) {
        console.log(`RDS Table "${t}": Error (${err.message})`);
      }
    }
  } catch (err) {
    console.error('RDS Connection Failed:', err.message);
  } finally {
    await rdsPool.end();
  }
}

checkRDS();

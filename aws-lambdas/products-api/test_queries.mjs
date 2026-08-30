import pg from 'pg';

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function testQueries() {
  console.log('--- Testing Address & Order queries ---');
  
  // Test address insert
  const addrRes = await pool.query(`
    INSERT INTO user_addresses (user_id, label, full_name, phone, email, city, pincode, address)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING *
  `, ['test-user-123', 'Home', 'Test User', '9876543210', 'test@example.com', 'Gobichettipalayam', '638505', 'Main Road']);
  console.log('Address inserted successfully:', addrRes.rows[0]);

  // Test address fetch
  const fetchAddr = await pool.query(`
    SELECT id::text as id, user_id as "userId", label, full_name as name, phone, email, city, pincode, address, created_at as "createdAt"
    FROM user_addresses
    WHERE user_id = $1 OR email ILIKE $2
    ORDER BY created_at DESC
  `, ['test-user-123', 'test@example.com']);
  console.log('Address fetch result count:', fetchAddr.rows.length);

  // Test orders fetch with email lookup
  const fetchOrd = await pool.query(`
    SELECT id::text as id, order_id as "orderId", user_id as "userId", customer, address_snapshot as address, total, status
    FROM orders
    WHERE user_id = $1 OR (customer->>'email' ILIKE $2 OR address_snapshot->>'email' ILIKE $2)
    ORDER BY created_at DESC
  `, ['some-new-id', 'kabhilan2905@gmail.com']);
  console.log('Orders found for kabhilan2905@gmail.com:', fetchOrd.rows.length);
  fetchOrd.rows.forEach(r => console.log('  -> Order:', r.orderId, 'User:', r.userId, 'Total:', r.total));

  // Clean up test address
  await pool.query('DELETE FROM user_addresses WHERE user_id = $1', ['test-user-123']);

  await pool.end();
}

testQueries().catch(console.error);

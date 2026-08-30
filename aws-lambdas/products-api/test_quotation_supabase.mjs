import pg from 'pg';

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function run() {
  const cols = await pool.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'quotations'");
  console.log('Quotation table columns in Supabase:');
  console.table(cols.rows);

  const users = await pool.query("SELECT id, name, phone, email FROM customers");
  console.log('Customers:');
  console.table(users.rows);

  const testQuotation = {
    quotation_number: 'QT-20260825-001',
    customer_id: '1784801147421',
    customer_name: 'thina',
    customer_phone: '8778308119',
    customer_address: 'Main Road, Chennai',
    items: JSON.stringify([
      { itemId: '1', name: 'Water Purifier 50L', price: 12000, quantity: 1, gstPercent: 18, gstAmount: 2160, total: 14160 }
    ]),
    subtotal: 12000,
    gst_amount: 2160,
    total: 14160,
    status: 'sent',
    valid_until: new Date(Date.now() + 15 * 86400000).toISOString(),
    notes: 'Test quotation for testing web app view'
  };

  // Test insert
  const insertRes = await pool.query(`
    INSERT INTO quotations (
      quotation_number, customer_id, customer_name, customer_phone,
      customer_address, items, subtotal, gst_amount, total,
      status, valid_until, notes, created_at, updated_at
    ) VALUES (
      $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, now(), now()
    ) RETURNING id, quotation_number, customer_name, total, status
  `, [
    testQuotation.quotation_number,
    testQuotation.customer_id,
    testQuotation.customer_name,
    testQuotation.customer_phone,
    testQuotation.customer_address,
    testQuotation.items,
    testQuotation.subtotal,
    testQuotation.gst_amount,
    testQuotation.total,
    testQuotation.status,
    testQuotation.valid_until,
    testQuotation.notes
  ]);

  console.log('Inserted test quotation:', insertRes.rows[0]);

  // Test public query like web app does
  const phone = '8778308119';
  const getRes = await pool.query(`
    SELECT id, quotation_number, customer_name, customer_phone, items, total, status, valid_until, created_at
    FROM quotations
    WHERE customer_phone LIKE $1 OR customer_id = $2
    ORDER BY created_at DESC
  `, [`%${phone}%`, '1784801147421']);

  console.log(`Fetched for phone ${phone}:`, getRes.rows);

  process.exit(0);
}

run().catch(console.error);

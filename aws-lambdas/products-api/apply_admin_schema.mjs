import pg from 'pg';

const pool = new pg.Pool({
  connectionString: 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
  ssl: { rejectUnauthorized: false }
});

async function applyAdminSchema() {
  console.log('=== APPLYING ADMIN & FLUTTER APP SCHEMA ADDITIONS ===');

  // 1. Orders table missing columns
  await pool.query(`
    ALTER TABLE orders
      ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMPTZ,
      ADD COLUMN IF NOT EXISTS bill_number TEXT NOT NULL DEFAULT '',
      ADD COLUMN IF NOT EXISTS bill_id TEXT NOT NULL DEFAULT '',
      ADD COLUMN IF NOT EXISTS billed_at TIMESTAMPTZ;
  `);
  console.log('Added missing columns to orders');

  // 2. Bookings table missing columns
  await pool.query(`
    ALTER TABLE bookings
      ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMPTZ;
  `);
  console.log('Added missing columns to bookings');

  // 3. Bills table
  await pool.query(`
    CREATE TABLE IF NOT EXISTS bills (
      id BIGSERIAL PRIMARY KEY,
      bill_number TEXT NOT NULL UNIQUE,
      source TEXT NOT NULL DEFAULT 'manual',
      source_order_doc_id TEXT NOT NULL DEFAULT '',
      source_order_id TEXT NOT NULL DEFAULT '',
      user_id TEXT NOT NULL DEFAULT '',
      customer JSONB NOT NULL DEFAULT '{}'::jsonb,
      items JSONB NOT NULL DEFAULT '[]'::jsonb,
      subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0,
      billing JSONB NOT NULL DEFAULT '{}'::jsonb,
      total NUMERIC(12, 2) NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'confirmed',
      generated_by TEXT NOT NULL DEFAULT '',
      updated_by TEXT NOT NULL DEFAULT '',
      company_name TEXT NOT NULL DEFAULT 'A1 Water Tech',
      support_phone TEXT NOT NULL DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      confirmed_at TIMESTAMPTZ,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    CREATE INDEX IF NOT EXISTS bills_created_at_idx ON bills (created_at DESC);
    CREATE INDEX IF NOT EXISTS bills_user_created_at_idx ON bills (user_id, created_at DESC);
  `);
  console.log('Created bills table');

  // 4. Admins table
  await pool.query(`
    CREATE TABLE IF NOT EXISTS admins (
      id BIGSERIAL PRIMARY KEY,
      cognito_sub TEXT NOT NULL DEFAULT '' UNIQUE,
      email TEXT NOT NULL UNIQUE,
      display_name TEXT NOT NULL DEFAULT '',
      is_active BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  `);
  console.log('Created admins table');

  // 5. Purchase Orders table
  await pool.query(`
    CREATE TABLE IF NOT EXISTS purchase_orders (
      id BIGSERIAL PRIMARY KEY,
      po_number TEXT NOT NULL UNIQUE,
      customer_id TEXT,
      customer_name TEXT NOT NULL,
      customer_phone TEXT,
      billing_address JSONB NOT NULL DEFAULT '{}'::jsonb,
      shipping_address JSONB NOT NULL DEFAULT '{}'::jsonb,
      items JSONB NOT NULL DEFAULT '[]'::jsonb,
      subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0,
      gst_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
      total NUMERIC(12, 2) NOT NULL DEFAULT 0,
      delivery_date TIMESTAMPTZ,
      payment_terms TEXT,
      notes TEXT,
      status TEXT NOT NULL DEFAULT 'draft',
      quotation_id TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    CREATE INDEX IF NOT EXISTS purchase_orders_created_at_idx ON purchase_orders (created_at DESC);
  `);
  console.log('Created purchase_orders table');

  // 6. Test GET /admin/orders query directly
  const testRes = await pool.query(`
    SELECT
      id::text as "docId",
      id::text as id,
      order_id as "orderId",
      user_id as "userId",
      jsonb_build_object(
        'fullName', coalesce(customer->>'fullName', customer->>'name', ''),
        'phone', coalesce(customer->>'phone', ''),
        'email', coalesce(customer->>'email', address_snapshot->>'email', ''),
        'city', coalesce(customer->>'city', address_snapshot->>'city', ''),
        'address', coalesce(customer->>'address', address_snapshot->>'address', ''),
        'invoiceType', coalesce(customer->>'invoiceType', 'GST Invoice'),
        'paymentMethod', coalesce(customer->>'paymentMethod', 'UPI'),
        'userId', user_id
      ) as customer,
      address_snapshot as address,
      items,
      subtotal,
      total,
      status,
      bill_number as "billNumber",
      bill_id as "billId",
      created_at as "createdAt",
      confirmed_at as "confirmedAt"
    FROM orders
    ORDER BY created_at DESC
  `);
  console.log(`\nDirect test query: Found ${testRes.rows.length} orders for Admin/Mobile app!`);
  testRes.rows.forEach(r => {
    console.log(`  -> Order #${r.id} (${r.orderId}): Customer=${r.customer.fullName} (${r.customer.phone}) | Status=${r.status} | Total=₹${r.total}`);
  });

  await pool.end();
}

applyAdminSchema().catch(console.error);

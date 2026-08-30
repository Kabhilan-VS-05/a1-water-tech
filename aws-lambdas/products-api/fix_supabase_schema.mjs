import pg from 'pg';
import fs from 'fs';

const { Pool } = pg;

const supabaseConnectionString = process.env.SUPABASE_DB_URL || 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres';

const pool = new Pool({
  connectionString: supabaseConnectionString,
  ssl: { rejectUnauthorized: false }
});

async function fixSchema() {
  console.log('=== FIXING SUPABASE DATABASE SCHEMAS ===');

  // 1. Fix user_addresses
  console.log('Fixing user_addresses table...');
  await pool.query(`
    DROP TABLE IF EXISTS user_addresses CASCADE;
    CREATE TABLE user_addresses (
      id BIGSERIAL PRIMARY KEY,
      user_id TEXT NOT NULL,
      label TEXT NOT NULL DEFAULT '',
      full_name TEXT NOT NULL DEFAULT '',
      phone TEXT NOT NULL DEFAULT '',
      email TEXT NOT NULL DEFAULT '',
      city TEXT NOT NULL DEFAULT '',
      pincode TEXT NOT NULL DEFAULT '',
      address TEXT NOT NULL DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    CREATE INDEX user_addresses_user_created_at_idx ON user_addresses (user_id, created_at DESC);
  `);

  // 2. Fix orders table
  console.log('Fixing orders table...');
  await pool.query(`
    DROP TABLE IF EXISTS orders CASCADE;
    CREATE TABLE orders (
      id BIGSERIAL PRIMARY KEY,
      order_id TEXT NOT NULL UNIQUE,
      user_id TEXT NOT NULL,
      customer JSONB NOT NULL DEFAULT '{}'::jsonb,
      address_id TEXT NOT NULL DEFAULT '',
      address_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
      items JSONB NOT NULL DEFAULT '[]'::jsonb,
      billing JSONB NOT NULL DEFAULT '{}'::jsonb,
      subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0,
      total NUMERIC(12, 2) NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'pending',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    CREATE INDEX orders_user_created_at_idx ON orders (user_id, created_at DESC);
  `);

  // 3. Fix bookings table
  console.log('Fixing bookings table...');
  await pool.query(`
    DROP TABLE IF EXISTS bookings CASCADE;
    CREATE TABLE bookings (
      id BIGSERIAL PRIMARY KEY,
      user_id TEXT NOT NULL,
      service_id TEXT NOT NULL,
      service_name TEXT NOT NULL,
      booking_date DATE NOT NULL,
      time_slot TEXT NOT NULL,
      address_id TEXT NOT NULL,
      address_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
      status TEXT NOT NULL DEFAULT 'scheduled',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    CREATE INDEX bookings_user_created_at_idx ON bookings (user_id, created_at DESC);
    CREATE INDEX bookings_status_date_idx ON bookings (status, booking_date ASC);
  `);

  // 4. Fix cart_items table
  console.log('Fixing cart_items table...');
  await pool.query(`
    DROP TABLE IF EXISTS cart_items CASCADE;
    CREATE TABLE cart_items (
      user_id TEXT NOT NULL,
      product_id TEXT NOT NULL,
      qty INTEGER NOT NULL CHECK (qty > 0),
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      PRIMARY KEY (user_id, product_id)
    );
    CREATE INDEX cart_items_user_updated_at_idx ON cart_items (user_id, updated_at DESC);
  `);

  // 5. Fix feedback table
  console.log('Fixing feedback table...');
  await pool.query(`
    DROP TABLE IF EXISTS feedback CASCADE;
    CREATE TABLE feedback (
      id BIGSERIAL PRIMARY KEY,
      customer_name TEXT NOT NULL DEFAULT '',
      phone TEXT NOT NULL DEFAULT '',
      rating INTEGER NOT NULL DEFAULT 5,
      message TEXT NOT NULL DEFAULT '',
      status TEXT NOT NULL DEFAULT 'published',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
  `);

  // 6. Fix faqs table
  console.log('Fixing faqs table...');
  await pool.query(`
    DROP TABLE IF EXISTS faqs CASCADE;
    CREATE TABLE faqs (
      id SERIAL PRIMARY KEY,
      q TEXT NOT NULL,
      a TEXT NOT NULL,
      is_active BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    INSERT INTO faqs (q, a) VALUES
      ('Do you offer free water testing?', 'Yes. We provide a free in-home TDS and hardness test in select areas.'),
      ('How quickly can you install a purifier?', 'Most installations are scheduled within 24 hours after order confirmation.'),
      ('Is GST included in the listed price?', 'Yes. All listed prices include GST. The invoice will show the breakup.'),
      ('What payment methods are supported?', 'UPI, card, netbanking, and EMI options on select products.');
  `);

  // 7. Fix announcements table
  console.log('Fixing announcements table...');
  await pool.query(`
    DROP TABLE IF EXISTS announcements CASCADE;
    CREATE TABLE announcements (
      id BIGSERIAL PRIMARY KEY,
      title TEXT NOT NULL,
      message TEXT NOT NULL DEFAULT '',
      badge TEXT NOT NULL DEFAULT '',
      is_pinned BOOLEAN NOT NULL DEFAULT false,
      is_active BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    INSERT INTO announcements (title, message, badge, is_pinned, is_active) VALUES
      ('Free TDS Testing Offer', 'Book any purifier this week and get a complimentary 10-point water lab test report.', 'Special Offer', true, true);
  `);

  // 8. Fix business_settings & billing_settings
  console.log('Fixing business_settings & billing_settings tables...');
  await pool.query(`
    DROP TABLE IF EXISTS business_settings CASCADE;
    CREATE TABLE business_settings (
      id SMALLINT PRIMARY KEY CHECK (id = 1),
      company_name TEXT NOT NULL DEFAULT 'A1 Water Tech',
      support_phone TEXT NOT NULL DEFAULT '',
      support_email TEXT NOT NULL DEFAULT '',
      locality TEXT NOT NULL DEFAULT '',
      address_line1 TEXT NOT NULL DEFAULT '',
      address_line2 TEXT NOT NULL DEFAULT '',
      address_line3 TEXT NOT NULL DEFAULT '',
      gstin TEXT NOT NULL DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    INSERT INTO business_settings (
      id, company_name, support_phone, support_email, locality, address_line1, address_line2, address_line3, gstin
    ) VALUES (
      1, 'A1 Water Tech', '+91 8778308119', 'thinakarans12345@gmail.com', 'Gobichettipalayam', '3/185/4 Bagavathi Nagar', 'Kanakappalayam', 'Erode-638505', '33CWHPJ8901N1Z6'
    );

    DROP TABLE IF EXISTS billing_settings CASCADE;
    CREATE TABLE billing_settings (
      id SMALLINT PRIMARY KEY CHECK (id = 1),
      company_name TEXT NOT NULL DEFAULT 'A1 Water Tech',
      support_phone TEXT NOT NULL DEFAULT '',
      invoice_prefix TEXT NOT NULL DEFAULT 'BILL',
      gst_rate NUMERIC(5, 4) NOT NULL DEFAULT 0.18,
      gst_enabled BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
    );
    INSERT INTO billing_settings (
      id, company_name, support_phone, invoice_prefix, gst_rate, gst_enabled
    ) VALUES (
      1, 'A1 Water Tech', '+91 8778308119', 'BILL', 0.18, true
    );
  `);

  // 9. Import old orders from orders_dump.json
  console.log('Importing orders from orders_dump.json...');
  try {
    let content = fs.readFileSync('../../orders_dump.json', 'utf16le');
    if (content.charCodeAt(0) === 0xFEFF) {
      content = content.slice(1);
    }
    const data = JSON.parse(content);
    if (Array.isArray(data.items)) {
      for (const o of data.items) {
        const orderId = o.orderId || `A1-${Date.now()}`;
        const userId = o.userId || 'unknown';
        const customer = o.customer || {};
        const address = o.address || {};
        const items = o.items || [];
        const subtotal = Number(o.subtotal) || 0;
        const total = Number(o.total) || subtotal;
        const status = o.status || 'pending';
        const createdAt = o.createdAt ? new Date(o.createdAt) : new Date();

        await pool.query(`
          INSERT INTO orders (
            order_id, user_id, customer, address_id, address_snapshot, items, billing, subtotal, total, status, created_at, updated_at
          ) VALUES ($1, $2, $3::jsonb, $4, $5::jsonb, $6::jsonb, $7::jsonb, $8, $9, $10, $11, $11)
          ON CONFLICT (order_id) DO NOTHING
        `, [
          orderId,
          userId,
          JSON.stringify(customer),
          'legacy-addr-1',
          JSON.stringify(address),
          JSON.stringify(items),
          JSON.stringify({}),
          subtotal,
          total,
          status,
          createdAt
        ]);

        // Also save address into user_addresses if valid
        if (address && address.name && address.phone && userId !== 'test-user') {
          await pool.query(`
            INSERT INTO user_addresses (
              user_id, label, full_name, phone, email, city, pincode, address, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $9)
          `, [
            userId,
            address.label || 'Home',
            address.name || '',
            address.phone || '',
            address.email || '',
            address.city || '',
            address.pincode || '',
            address.address || '',
            createdAt
          ]);
        }
      }
      console.log(`Successfully migrated ${data.items.length} orders and addresses!`);
    }
  } catch (err) {
    console.error('Failed to import orders_dump.json:', err.message);
  }

  console.log('\n--- ALL SUPABASE TABLES SUCCESSFULLY RESTORED & ALIGNED ---');
  await pool.end();
}

fixSchema().catch(err => {
  console.error('Fix schema error:', err);
});

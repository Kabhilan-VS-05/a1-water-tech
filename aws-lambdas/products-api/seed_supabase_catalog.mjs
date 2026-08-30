import pg from 'pg';
import fs from 'fs';
import path from 'path';

const { Pool } = pg;

const supabaseConnectionString = 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres';

const pool = new Pool({
  connectionString: supabaseConnectionString,
  ssl: { rejectUnauthorized: false }
});

async function seedData() {
  console.log('Seeding products, services, business settings, and billing settings into Supabase...');

  try {
    // 1. Seed Business Settings
    await pool.query(`
      INSERT INTO business_settings (id, name, phone_primary, phone_secondary, email, address, locality, gstin, working_hours)
      VALUES (1, 'A1 Water Tech', '+91 98765 43210', '+91 98765 43211', 'contact@a1watertech.in', '123 Water Works Road, Main Junction', 'Coimbatore', '33AAAAA0000A1Z5', 'Mon - Sat: 9:00 AM - 8:00 PM')
      ON CONFLICT (id) DO UPDATE SET
        name = excluded.name,
        phone_primary = excluded.phone_primary,
        email = excluded.email;
    `);

    // 2. Seed Billing Settings
    await pool.query(`
      INSERT INTO billing_settings (id, default_gst_percent, terms_and_conditions, bank_details, upi_id)
      VALUES (1, 18.00, '1. Payment terms: 100% against delivery.\n2. Goods once sold will not be taken back.\n3. Warranty covers manufacturing defects only.', 'Bank: HDFC Bank\nA/C: 50200012345678\nIFSC: HDFC0001234', 'a1watertech@upi')
      ON CONFLICT (id) DO UPDATE SET
        default_gst_percent = excluded.default_gst_percent;
    `);

    // 3. Seed Products from json
    const productsPath = 'd:/The Project/A1 Water Tech/a1-water-online-shop (Web)/products.firestore.json';
    if (fs.existsSync(productsPath)) {
      const productsData = JSON.parse(fs.readFileSync(productsPath, 'utf8'));
      for (const [id, item] of Object.entries(productsData)) {
        await pool.query(`
          INSERT INTO products (id, name, category, image_url, price, rating, tag, tds, warranty, description, features, recommendation)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
          ON CONFLICT (id) DO UPDATE SET
            name = excluded.name,
            price = excluded.price,
            image_url = excluded.image_url;
        `, [
          id,
          item.name || 'Product',
          item.category || 'Purifiers',
          item.imageUrl || '/a1-pureflow-ro-uv.png',
          item.price || 0,
          item.rating || 5.0,
          item.tag || '',
          item.tds || '',
          item.warranty || '1 year',
          item.description || '',
          item.features || [],
          item.recommendation || ''
        ]);
      }
      console.log('Successfully seeded Products into Supabase!');
    }

    // 4. Seed Services from json
    const servicesPath = 'd:/The Project/A1 Water Tech/a1-water-online-shop (Web)/services.firestore.json';
    if (fs.existsSync(servicesPath)) {
      const servicesData = JSON.parse(fs.readFileSync(servicesPath, 'utf8'));
      for (const [id, item] of Object.entries(servicesData)) {
        await pool.query(`
          INSERT INTO services (id, name, image_url, price, duration, description)
          VALUES ($1, $2, $3, $4, $5, $6)
          ON CONFLICT (id) DO UPDATE SET
            name = excluded.name,
            price = excluded.price,
            image_url = excluded.image_url;
        `, [
          id,
          item.name || 'Service',
          item.imageUrl || '/Services.png',
          item.price || 0,
          item.duration || 'Per Visit',
          item.description || ''
        ]);
      }
      console.log('Successfully seeded Services into Supabase!');
    }

    console.log('\nSUCCESS! Supabase is fully populated with all Products, Services, and Settings!');
  } catch (err) {
    console.error('Seeding error:', err);
  } finally {
    await pool.end();
  }
}

seedData();

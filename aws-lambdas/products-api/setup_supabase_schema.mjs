import pg from 'pg';

const { Pool } = pg;

const supabaseConnectionString = process.env.SUPABASE_DB_URL || 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres';

const pool = new Pool({
  connectionString: supabaseConnectionString,
  ssl: { rejectUnauthorized: false }
});

async function setupSchema() {
  console.log('Connecting to Supabase to verify & setup schema...');
  try {
    // 1. Products table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS products (
        id VARCHAR(255) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        category VARCHAR(255),
        image_url TEXT,
        price DECIMAL(10,2) DEFAULT 0.00,
        rating DECIMAL(3,2) DEFAULT 5.0,
        tag VARCHAR(255),
        tds VARCHAR(255),
        hsn VARCHAR(255),
        warranty VARCHAR(255),
        description TEXT,
        features TEXT[],
        recommendation TEXT,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 2. Services table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS services (
        id VARCHAR(255) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        image_url TEXT,
        price DECIMAL(10,2) DEFAULT 0.00,
        duration VARCHAR(255),
        hsn VARCHAR(255),
        description TEXT,
        features TEXT[],
        recommendation TEXT,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 3. Announcements table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS announcements (
        id VARCHAR(255) PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        content TEXT,
        type VARCHAR(50) DEFAULT 'info',
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 4. FAQs table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS faqs (
        id VARCHAR(255) PRIMARY KEY,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        category VARCHAR(255) DEFAULT 'General',
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 5. Business Settings
    await pool.query(`
      CREATE TABLE IF NOT EXISTS business_settings (
        id INT PRIMARY KEY DEFAULT 1,
        name VARCHAR(255),
        phone_primary VARCHAR(50),
        phone_secondary VARCHAR(50),
        email VARCHAR(255),
        address TEXT,
        locality VARCHAR(255),
        gstin VARCHAR(50),
        working_hours VARCHAR(255),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 6. Billing Settings
    await pool.query(`
      CREATE TABLE IF NOT EXISTS billing_settings (
        id INT PRIMARY KEY DEFAULT 1,
        default_gst_percent DECIMAL(5,2) DEFAULT 18.00,
        terms_and_conditions TEXT,
        bank_details TEXT,
        upi_id VARCHAR(255),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 7. Bookings table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS bookings (
        id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255),
        service_id VARCHAR(255),
        service_name VARCHAR(255),
        customer_name VARCHAR(255),
        customer_phone VARCHAR(50),
        customer_email VARCHAR(255),
        address TEXT,
        booking_date VARCHAR(50),
        time_slot VARCHAR(50),
        notes TEXT,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 8. User Addresses table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS user_addresses (
        id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL,
        name VARCHAR(255),
        phone VARCHAR(50),
        address_line TEXT,
        locality VARCHAR(255),
        city VARCHAR(255),
        pincode VARCHAR(20),
        is_default BOOLEAN DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 9. Orders table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS orders (
        id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255),
        customer JSONB,
        address_id VARCHAR(255),
        address_snapshot JSONB,
        items JSONB,
        billing JSONB,
        subtotal DECIMAL(10,2),
        total DECIMAL(10,2),
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 10. Cart Items table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS cart_items (
        id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255) NOT NULL,
        product_id VARCHAR(255) NOT NULL,
        quantity INT DEFAULT 1,
        item_data JSONB,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 11. Quotations table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS quotations (
        id BIGSERIAL PRIMARY KEY,
        quotation_number VARCHAR(255),
        customer_id VARCHAR(255),
        customer_name VARCHAR(255),
        customer_phone VARCHAR(50),
        customer_address TEXT,
        customer_gst VARCHAR(50),
        customer_email VARCHAR(255),
        items JSONB,
        subtotal DECIMAL(10,2),
        gst_amount DECIMAL(10,2),
        total DECIMAL(10,2),
        status VARCHAR(50) DEFAULT 'draft',
        valid_until TIMESTAMP WITH TIME ZONE,
        notes TEXT,
        other_charge_label VARCHAR(255),
        other_charge_amount DECIMAL(10,2),
        is_other_charge_taxable BOOLEAN DEFAULT false,
        other_charge_gst_percent DECIMAL(5,2),
        terms TEXT,
        is_rounded_off BOOLEAN DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 12. Customers table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS customers (
        id VARCHAR(255) PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(50),
        email VARCHAR(255),
        address TEXT,
        gstin VARCHAR(50),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 13. Feedback table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS feedback (
        id VARCHAR(255) PRIMARY KEY,
        user_id VARCHAR(255),
        user_name VARCHAR(255),
        rating INT DEFAULT 5,
        comments TEXT,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    // 14. Admins table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS admins (
        id VARCHAR(255) PRIMARY KEY,
        username VARCHAR(255) UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role VARCHAR(50) DEFAULT 'admin',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
      );
    `);

    console.log('Successfully created all 14 application tables on Supabase!');
  } catch (error) {
    console.error('Schema setup error:', error);
  } finally {
    await pool.end();
  }
}

setupSchema();

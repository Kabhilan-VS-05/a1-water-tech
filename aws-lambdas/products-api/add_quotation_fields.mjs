import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const { Pool } = pg;

const pool = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: process.env.DB_PORT,
  ssl: {
    rejectUnauthorized: false
  }
});

async function run() {
  try {
    console.log('Connecting to database...');
    console.log('Adding new columns to quotations table...');
    
    await pool.query(`
      ALTER TABLE quotations 
      ADD COLUMN IF NOT EXISTS other_charge_label VARCHAR(255),
      ADD COLUMN IF NOT EXISTS other_charge_amount DECIMAL(10,2),
      ADD COLUMN IF NOT EXISTS is_other_charge_taxable BOOLEAN DEFAULT false,
      ADD COLUMN IF NOT EXISTS other_charge_gst_percent DECIMAL(5,2),
      ADD COLUMN IF NOT EXISTS terms TEXT,
      ADD COLUMN IF NOT EXISTS is_rounded_off BOOLEAN DEFAULT false;
    `);
    
    console.log('Successfully added columns to quotations table!');
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await pool.end();
  }
}

run();

import pg from 'pg';
import fs from 'fs';

const envFile = fs.readFileSync('.env', 'utf8');
const env = {};
envFile.split('\n').forEach(line => {
    const match = line.match(/^([^=]+)=(.*)$/);
    if (match) env[match[1].trim()] = match[2].trim();
});

const pool = new pg.Pool({
    host: env.DB_HOST,
    port: Number(env.DB_PORT || 5432),
    database: env.DB_NAME || 'postgres',
    user: env.DB_USER,
    password: env.DB_PASSWORD,
    ssl: { rejectUnauthorized: false },
});

async function main() {
    try {
        console.log('Adding customer_gst column to quotations table...');
        await pool.query(`ALTER TABLE quotations ADD COLUMN IF NOT EXISTS customer_gst VARCHAR(50);`);
        console.log('Done.');
    } catch (e) {
        console.error(e);
    } finally {
        await pool.end();
    }
}

main();

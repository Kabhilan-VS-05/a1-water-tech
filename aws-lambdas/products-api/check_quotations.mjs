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
        const res = await pool.query(`SELECT COUNT(*) as total_bills FROM bills`);
        console.log('Total bills in cloud:', res.rows[0].total_bills);
        const res2 = await pool.query(`SELECT * FROM bills ORDER BY created_at DESC LIMIT 10`);
        console.log(JSON.stringify(res2.rows, null, 2));
    } catch (e) {
        console.error(e);
    } finally {
        await pool.end();
    }
}

main();

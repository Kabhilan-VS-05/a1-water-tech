import fs from 'fs';
import path from 'path';
import pg from 'pg';

const { Pool } = pg;

const publicDir = 'd:/The Project/A1 Water Tech/a1-water-online-shop (Web)/public';

const fileMap = {
  'A1 AquaShield RO.png': 'a1-aquashield-ro.png',
  'A1 Commercial RO 50L.png': 'a1-commercial-ro-50l.png',
  'A1 Copper Guard Pro.png': 'a1-copper-guard-pro.png',
  'A1 Mineral+ Cartridge.png': 'a1-mineral-plus-cartridge.png',
  'A1 PureFlow RO + UV.png': 'a1-pureflow-ro-uv.png',
  'A1 RO Membrane Kit.png': 'a1-ro-membrane-kit.png',
  'A1 Sediment Guard.png': 'a1-sediment-guard.png',
  'Purifiers Explore.png': 'purifiers-explore.png',
  'ServiceCare Annual.png': 'servicecare-annual.png',
  'Services.png': 'services.png',
  'Smart Water Dispenser.png': 'smart-water-dispenser.png',
  'UV Compact.png': 'uv-compact.png',
  'Accessories.png': 'accessories.png',
  'Commercial.png': 'commercial.png',
  'Filters.png': 'filters.png'
};

console.log('Copying public images to clean hyphenated filenames...');
for (const [oldName, newName] of Object.entries(fileMap)) {
  const oldPath = path.join(publicDir, oldName);
  const newPath = path.join(publicDir, newName);
  if (fs.existsSync(oldPath)) {
    fs.copyFileSync(oldPath, newPath);
    console.log(`Copied ${oldName} -> ${newName}`);
  }
}

// Update Supabase DB URLs to clean hyphenated filenames
const dbMap = {
  'A1 PureFlow RO + UV': '/a1-pureflow-ro-uv.png',
  'A1 AquaShield RO': '/a1-aquashield-ro.png',
  'A1 Mineral+ Cartridge': '/a1-mineral-plus-cartridge.png',
  'A1 Sediment Guard': '/a1-sediment-guard.png',
  'A1 ServiceCare Annual': '/servicecare-annual.png',
  'A1 Commercial RO 50L': '/a1-commercial-ro-50l.png',
  'A1 UV Compact': '/uv-compact.png',
  'A1 Smart Water Dispenser': '/smart-water-dispenser.png',
  'A1 Copper Guard Pro': '/a1-copper-guard-pro.png',
  'A1 RO Membrane Kit': '/a1-ro-membrane-kit.png',
  'A1 UnderSink Elite': '/a1-pureflow-ro-uv.png',
  'A1 Alkaline Max': '/a1-copper-guard-pro.png',
  'A1 Pre-Carbon Filter': '/filters.png'
};

const serviceDbMap = {
  'Standard Installation': '/services.png',
  'ServiceCare Annual': '/servicecare-annual.png',
  'ServiceCare Premium': '/services.png',
  'Emergency Visit': '/services.png',
  'Express Installation': '/services.png',
  'Filter Replacement Visit': '/servicecare-annual.png',
  'Deep Clean & Sanitization': '/services.png',
  'Home Water Quality Test': '/services.png'
};

async function updateDb() {
  const pool = new Pool({
    connectionString: 'postgresql://postgres.vbadwfrvhyfbfableeug:Thinakaran%245@aws-0-ap-northeast-2.pooler.supabase.com:6543/postgres',
    ssl: { rejectUnauthorized: false }
  });

  console.log('\nUpdating Supabase database image_url fields to clean static paths...');
  for (const [name, url] of Object.entries(dbMap)) {
    await pool.query('UPDATE products SET image_url = $1 WHERE name = $2', [url, name]);
  }

  for (const [name, url] of Object.entries(serviceDbMap)) {
    await pool.query('UPDATE services SET image_url = $1 WHERE name = $2', [url, name]);
  }

  console.log('Successfully updated all database image URLs in Supabase!');
  await pool.end();
}

updateDb();

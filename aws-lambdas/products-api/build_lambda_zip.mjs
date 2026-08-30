import fs from 'fs';
import path from 'path';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const archiver = require('../../a1-water-online-shop (Web)/node_modules/archiver');

const output = fs.createWriteStream('lambda-deploy-fixed.zip');
const archive = archiver('zip', { zlib: { level: 9 } });

output.on('close', function () {
  console.log(`Successfully created lambda-deploy-fixed.zip (${(archive.pointer() / 1024 / 1024).toFixed(2)} MB)`);
  fs.copyFileSync('lambda-deploy-fixed.zip', 'lambda-deploy.zip');
  fs.copyFileSync('lambda-deploy-fixed.zip', '../lambda-deploy.zip');
  fs.copyFileSync('lambda-deploy-fixed.zip', '../../lambda-clean.zip');
  console.log('Updated deployment packages.');
});

archive.on('error', function (err) {
  throw err;
});

archive.pipe(output);

// Append files
archive.file('index.mjs', { name: 'index.mjs' });
archive.file('admin.mjs', { name: 'admin.mjs' });
archive.file('package.json', { name: 'package.json' });

if (fs.existsSync('.env')) {
  archive.file('.env', { name: '.env' });
}

// Append node_modules
archive.directory('node_modules/', 'node_modules');

archive.finalize();

import fs from 'fs';
import { execSync } from 'child_process';

function getEntries(zipFile) {
  const output = execSync(`powershell -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem'); [System.IO.Compression.ZipFile]::OpenRead('${zipFile}').Entries.FullName"`).toString();
  return output.split('\r\n').filter(Boolean);
}

console.log('--- OLD ZIP (lambda-deploy-new.zip) ---');
const oldEntries = getEntries('lambda-deploy-new.zip');
console.log('Total entries:', oldEntries.length);
console.log('Top level files:', oldEntries.filter(e => !e.includes('/')));

console.log('\n--- NEW ZIP (lambda-deploy.zip) ---');
const newEntries = getEntries('lambda-deploy.zip');
console.log('Total entries:', newEntries.length);
console.log('Top level files:', newEntries.filter(e => !e.includes('/')));

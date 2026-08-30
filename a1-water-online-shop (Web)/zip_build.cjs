const fs = require('fs');
const archiver = require('archiver');

const output = fs.createWriteStream('amplify-deploy-fixed.zip');
const archive = archiver('zip', { zlib: { level: 9 } });

output.on('close', function() {
  console.log(archive.pointer() + ' total bytes');
  console.log('archiver has been finalized and the output file descriptor has closed.');
});

archive.on('error', function(err) {
  throw err;
});

archive.pipe(output);
archive.directory('dist/', false); // false means don't put it in a 'dist' subfolder
archive.finalize();

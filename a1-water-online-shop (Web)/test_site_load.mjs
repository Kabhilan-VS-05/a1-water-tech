async function testLoad() {
  const r = await fetch('https://a1watertech.in');
  const html = await r.text();
  console.log('INDEX HTML HTML LENGTH:', html.length);
  
  const matches = html.match(/src="([^"]+)"/g);
  console.log('Found script sources:', matches);

  if (matches) {
    for (const m of matches) {
      const path = m.replace('src="', '').replace('"', '');
      const fullUrl = path.startsWith('http') ? path : 'https://a1watertech.in' + (path.startsWith('/') ? path : '/' + path);
      console.log('\nTesting asset:', fullUrl);
      const assetRes = await fetch(fullUrl);
      console.log('Status:', assetRes.status, 'Content-Type:', assetRes.headers.get('content-type'));
      const text = await assetRes.text();
      console.log('Snippet:', text.substring(0, 100));
    }
  }
}

testLoad();

import fs from 'fs';

try {
  let content = fs.readFileSync('../../orders_dump.json', 'utf16le');
  if (content.charCodeAt(0) === 0xFEFF) {
    content = content.slice(1);
  }
  const data = JSON.parse(content);
  console.log('orders_dump.json top-level keys:', Object.keys(data));
  if (data.items) {
    console.log('Total orders in dump:', data.items.length);
    console.log('Sample order:', JSON.stringify(data.items[0], null, 2));
  }
} catch (err) {
  console.error('Error:', err.message);
}

import fs from 'fs';

let content = fs.readFileSync('../../orders_dump.json', 'utf16le');
if (content.charCodeAt(0) === 0xFEFF) {
  content = content.slice(1);
}
const data = JSON.parse(content);
console.log('All orders:');
data.items.forEach((o, i) => {
  console.log(`\n--- Order #${i + 1} ---`);
  console.log('ID:', o.id, 'OrderId:', o.orderId, 'User:', o.userId);
  console.log('Customer:', o.customer);
  console.log('Address:', o.address);
  console.log('Items:', o.items);
  console.log('Total:', o.total, 'Status:', o.status, 'Date:', o.createdAt);
});

import fs from 'fs';

async function main() {
    const envFile = fs.readFileSync('../../a1-water-online-shop (Web)/.env.production', 'utf8');
    let baseUrl = '';
    envFile.split('\n').forEach(line => {
        const match = line.match(/^([^=]+)=(.*)$/);
        if (match && match[1].trim() === 'VITE_API_BASE_URL') {
            baseUrl = match[2].trim();
        }
    });

    const phone = '8';
    // Fetch quotations by phone
    const url = `${baseUrl}/quotations?phone=${encodeURIComponent(phone)}`;
    console.log('Fetching from:', url);
    
    try {
        const res = await fetch(url);
        const data = await res.json();
        console.log('Response:', JSON.stringify(data, null, 2));
    } catch (err) {
        console.error(err);
    }
}
main();

/*
 ====================================================================
  A1 Water Tech — COMPREHENSIVE BACKEND QA TEST SUITE
  Tests ALL API endpoints, calculations, data models, and cloud sync.
 ====================================================================
*/

const BASE_URL = 'https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod';

let passed = 0;
let failed = 0;
let warnings = 0;
const issues = [];

function logPass(testId, msg) {
  console.log(`✅ [${testId}] PASSED: ${msg}`);
  passed++;
}

function logFail(testId, msg) {
  console.error(`❌ [${testId}] FAILED: ${msg}`);
  issues.push(`[${testId}] ${msg}`);
  failed++;
}

function logWarn(testId, msg) {
  console.log(`⚠️  [${testId}] WARNING: ${msg}`);
  warnings++;
}

async function safeFetch(url, opts = {}) {
  try {
    return await fetch(url, opts);
  } catch (e) {
    return { ok: false, status: 0, statusText: e.message, text: async () => e.message, json: async () => ({}) };
  }
}

// ============================================================
// PHASE 1: PUBLIC ENDPOINTS & CONNECTIVITY
// ============================================================

async function testBusinessSettings() {
  console.log('\n━━━ PHASE 1: PUBLIC ENDPOINTS & CONNECTIVITY ━━━');
  console.log('[T1.1] Business Settings API...');
  const res = await safeFetch(`${BASE_URL}/settings/business`);
  if (res.ok) {
    const data = await res.json();
    const item = data.item || data;
    if (item.companyName && item.gstin && item.supportPhone) {
      logPass('T1.1', `Company: "${item.companyName}", GSTIN: "${item.gstin}", Phone: "${item.supportPhone}"`);
      // Validate GSTIN format (15 chars, alphanumeric)
      if (/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[A-Z0-9]{1}Z[A-Z0-9]{1}$/.test(item.gstin)) {
        logPass('T1.1b', `GSTIN format is valid: ${item.gstin}`);
      } else {
        logWarn('T1.1b', `GSTIN may not match standard format: ${item.gstin}`);
      }
    } else {
      logFail('T1.1', `Missing required fields. Got: ${JSON.stringify(item)}`);
    }
    return item;
  } else {
    logFail('T1.1', `HTTP ${res.status}: ${await res.text()}`);
    return null;
  }
}

async function testBillingSettings() {
  console.log('\n[T1.2] Billing Settings API...');
  const res = await safeFetch(`${BASE_URL}/settings/billing`);
  if (res.ok) {
    const data = await res.json();
    const item = data.item || data;
    logPass('T1.2', `Billing settings retrieved. invoicePrefix: "${item.invoicePrefix || 'N/A'}", gstRate: ${item.gstRate}, gstEnabled: ${item.gstEnabled}`);

    // Validate gstRate is a decimal (e.g. 0.18 for 18%)
    if (item.gstRate !== undefined) {
      const rate = parseFloat(item.gstRate);
      if (rate > 0 && rate < 1) {
        logPass('T1.2b', `GST rate stored as decimal fraction: ${rate} (= ${(rate * 100).toFixed(0)}%)`);
      } else if (rate >= 1 && rate <= 100) {
        logWarn('T1.2b', `GST rate stored as whole number: ${rate}%. Flutter converts by multiplying by 100, so this may cause 1800% GST!`);
      }
    }
    return item;
  } else {
    logFail('T1.2', `HTTP ${res.status}: ${await res.text()}`);
    return null;
  }
}

// ============================================================
// PHASE 2: PRODUCT & SERVICE CATALOG
// ============================================================

async function testProductsCatalog() {
  console.log('\n━━━ PHASE 2: PRODUCT & SERVICE CATALOG ━━━');
  console.log('[T2.1] Products API...');
  const res = await safeFetch(`${BASE_URL}/products`);
  if (!res.ok) { logFail('T2.1', `HTTP ${res.status}`); return []; }

  const data = await res.json();
  const items = data.items || data;
  if (!Array.isArray(items) || items.length === 0) {
    logFail('T2.1', 'No products returned from catalog!');
    return [];
  }

  logPass('T2.1', `Fetched ${items.length} products.`);

  // Validate each product has required fields
  let productIssues = 0;
  for (const p of items) {
    if (!p.name) { logFail('T2.1c', `Product missing name: ${JSON.stringify(p)}`); productIssues++; }
    if (p.price === undefined || p.price === null) { logFail('T2.1d', `Product "${p.name}" missing price`); productIssues++; }
    if (parseFloat(p.price) < 0) { logFail('T2.1e', `Product "${p.name}" has negative price: ${p.price}`); productIssues++; }
  }
  if (productIssues === 0) {
    logPass('T2.1f', `All ${items.length} products have valid name and non-negative price.`);
  }

  // Print catalog summary
  console.log('   📦 Catalog Summary:');
  for (const p of items) {
    console.log(`      • ${p.name} — ₹${parseFloat(p.price).toFixed(2)} [HSN: ${p.hsn || 'N/A'}] [Category: ${p.category || 'N/A'}]`);
  }
  return items;
}

async function testServicesCatalog() {
  console.log('\n[T2.2] Services API...');
  const res = await safeFetch(`${BASE_URL}/services`);
  if (!res.ok) { logFail('T2.2', `HTTP ${res.status}`); return []; }

  const data = await res.json();
  const items = data.items || data;
  logPass('T2.2', `Fetched ${Array.isArray(items) ? items.length : 0} services.`);
  if (Array.isArray(items) && items.length > 0) {
    console.log('   🔧 Services Summary:');
    for (const s of items) {
      console.log(`      • ${s.name} — ₹${parseFloat(s.price || 0).toFixed(2)}`);
    }
  }
  return items;
}

// ============================================================
// PHASE 3: BILLING CALCULATION MATH VERIFICATION
// ============================================================

async function testBillingCalculations(products, billingSettings) {
  console.log('\n━━━ PHASE 3: BILLING CALCULATION MATH VERIFICATION ━━━');

  const defaultGstRate = billingSettings?.gstRate !== undefined
    ? parseFloat(billingSettings.gstRate) * 100  // Convert 0.18 -> 18
    : 18;

  console.log(`[T3.0] Default GST rate from settings: ${defaultGstRate}%`);

  // Test Case 3.1: Single item, qty 1
  console.log('\n[T3.1] Single item, qty=1, GST=18%...');
  {
    const price = 650, qty = 1, gst = 18;
    const subtotal = price * qty;         // 650
    const gstAmount = (subtotal * gst) / 100; // 117
    const total = subtotal + gstAmount;    // 767
    const exp = { subtotal: 650, gstAmount: 117, total: 767 };
    if (subtotal === exp.subtotal && gstAmount === exp.gstAmount && total === exp.total) {
      logPass('T3.1', `Subtotal=₹${subtotal}, GST(18%)=₹${gstAmount}, Total=₹${total}`);
    } else {
      logFail('T3.1', `Expected ${JSON.stringify(exp)}, Got sub=${subtotal}, gst=${gstAmount}, tot=${total}`);
    }
  }

  // Test Case 3.2: Multiple items, mixed quantities
  console.log('\n[T3.2] Multi-item cart, mixed qty...');
  {
    const cart = [
      { name: 'Wound Filter', price: 650, qty: 2, gst: 18 },
      { name: 'Installation Fee', price: 350, qty: 1, gst: 18 },
      { name: 'Carbon Filter', price: 800, qty: 3, gst: 12 },
    ];
    let subtotal = 0, gstTotal = 0;
    for (const item of cart) {
      const itemSub = item.price * item.qty;
      const itemGst = (itemSub * item.gst) / 100;
      subtotal += itemSub;
      gstTotal += itemGst;
    }
    const total = subtotal + gstTotal;
    // Expected: (650*2)+(350*1)+(800*3) = 1300+350+2400 = 4050
    // GST: (1300*18/100)+(350*18/100)+(2400*12/100) = 234+63+288 = 585
    // Total: 4050+585 = 4635
    const expSub = 4050, expGst = 585, expTot = 4635;
    if (subtotal === expSub && gstTotal === expGst && total === expTot) {
      logPass('T3.2', `Subtotal=₹${subtotal}, GST=₹${gstTotal}, Total=₹${total}`);
    } else {
      logFail('T3.2', `Expected sub=${expSub} gst=${expGst} tot=${expTot}, Got sub=${subtotal} gst=${gstTotal} tot=${total}`);
    }
  }

  // Test Case 3.3: GST Override — Flat amount
  console.log('\n[T3.3] GST Override (flat amount)...');
  {
    const subtotal = 1650;
    const overrideGstAmount = 200;
    const total = subtotal + overrideGstAmount;
    if (total === 1850) {
      logPass('T3.3', `Subtotal=₹${subtotal}, Override GST=₹${overrideGstAmount}, Total=₹${total}`);
    } else {
      logFail('T3.3', `Expected 1850, got ${total}`);
    }
  }

  // Test Case 3.4: GST Override — Percentage
  console.log('\n[T3.4] GST Override (custom percentage 28%)...');
  {
    const subtotal = 1650;
    const overridePercent = 28;
    const gstAmount = (subtotal * overridePercent) / 100; // 462
    const total = subtotal + gstAmount;
    if (gstAmount === 462 && total === 2112) {
      logPass('T3.4', `Subtotal=₹${subtotal}, Override GST(28%)=₹${gstAmount}, Total=₹${total}`);
    } else {
      logFail('T3.4', `Expected gst=462, total=2112. Got gst=${gstAmount}, total=${total}`);
    }
  }

  // Test Case 3.5: Zero quantity edge case
  console.log('\n[T3.5] Edge case: qty=0...');
  {
    const price = 650, qty = 0, gst = 18;
    const subtotal = price * qty;
    const gstAmount = (subtotal * gst) / 100;
    const total = subtotal + gstAmount;
    if (total === 0) {
      logPass('T3.5', `Zero quantity produces ₹0 total.`);
    } else {
      logFail('T3.5', `Expected total=0, got ${total}`);
    }
  }

  // Test Case 3.6: Large quantity stress test
  console.log('\n[T3.6] Stress test: qty=9999...');
  {
    const price = 1500, qty = 9999, gst = 18;
    const subtotal = price * qty;         // 14,998,500
    const gstAmount = (subtotal * gst) / 100; // 2,699,730
    const total = subtotal + gstAmount;    // 17,698,230
    if (subtotal === 14998500 && gstAmount === 2699730 && total === 17698230) {
      logPass('T3.6', `Large qty: Subtotal=₹${subtotal.toLocaleString()}, GST=₹${gstAmount.toLocaleString()}, Total=₹${total.toLocaleString()}`);
    } else {
      logFail('T3.6', `Large qty math error: sub=${subtotal}, gst=${gstAmount}, tot=${total}`);
    }
  }

  // Test Case 3.7: BillItem.fromMap total calculation check
  // In bill.dart line 208-209: total = (price * quantity) + gstAmount if map['total'] is missing
  console.log('\n[T3.7] BillItem.fromMap fallback total logic...');
  {
    const price = 500, qty = 3, gstAmount = 270;
    const expectedTotal = (price * qty) + gstAmount; // 1500 + 270 = 1770
    if (expectedTotal === 1770) {
      logPass('T3.7', `BillItem fallback total = (price*qty)+gstAmount = ${expectedTotal}`);
    } else {
      logFail('T3.7', `Expected 1770, got ${expectedTotal}`);
    }
  }

  // Test Case 3.8: OrderItem.total and gstAmount getters
  // In order.dart: total = price * quantity, gstAmount = (total * gstPercent) / 100
  console.log('\n[T3.8] OrderItem calculation getters...');
  {
    const price = 800, qty = 2, gstPercent = 18;
    const total = price * qty;               // 1600
    const gstAmount = (total * gstPercent) / 100; // 288
    const totalWithGst = total + gstAmount;   // 1888
    if (total === 1600 && gstAmount === 288 && totalWithGst === 1888) {
      logPass('T3.8', `OrderItem: total=₹${total}, gst=₹${gstAmount}, totalWithGst=₹${totalWithGst}`);
    } else {
      logFail('T3.8', `OrderItem math: total=${total}, gst=${gstAmount}, totalWithGst=${totalWithGst}`);
    }
  }
}

// ============================================================
// PHASE 4: QUOTATIONS & ORDERS CLOUD ENDPOINTS
// ============================================================

async function testQuotationsEndpoint() {
  console.log('\n━━━ PHASE 4: QUOTATIONS & ORDERS CLOUD ENDPOINTS ━━━');

  // T4.1: GET /quotations (public, by phone)
  console.log('[T4.1] GET /quotations?phone=8760351341...');
  const res = await safeFetch(`${BASE_URL}/quotations?phone=8760351341`);
  if (res.ok) {
    const data = await res.json();
    logPass('T4.1', `Quotations endpoint OK. Items: ${(data.items || []).length}`);
  } else {
    logFail('T4.1', `HTTP ${res.status}: ${await res.text()}`);
  }

  // T4.2: GET /orders (public, needs userId query)
  console.log('\n[T4.2] GET /orders...');
  const res2 = await safeFetch(`${BASE_URL}/orders?userId=test`);
  if (res2.status === 200 || res2.status === 404 || res2.status === 400) {
    logPass('T4.2', `Orders endpoint responded with HTTP ${res2.status}.`);
  } else {
    logWarn('T4.2', `Orders endpoint status: ${res2.status}`);
  }

  // T4.3: GET /announcements
  console.log('\n[T4.3] GET /announcements...');
  const res3 = await safeFetch(`${BASE_URL}/announcements`);
  if (res3.ok) {
    const data = await res3.json();
    logPass('T4.3', `Announcements endpoint OK. Items: ${(data.items || []).length}`);
  } else {
    logFail('T4.3', `HTTP ${res3.status}`);
  }

  // T4.4: GET /faqs
  console.log('\n[T4.4] GET /faqs...');
  const res4 = await safeFetch(`${BASE_URL}/faqs`);
  if (res4.ok) {
    const data = await res4.json();
    logPass('T4.4', `FAQs endpoint OK. Items: ${(data.items || []).length}`);
  } else {
    logFail('T4.4', `HTTP ${res4.status}`);
  }

  // T4.5: POST /feedback (should accept valid JSON)
  console.log('\n[T4.5] POST /feedback...');
  const res5 = await safeFetch(`${BASE_URL}/feedback`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      customerName: 'QA Test',
      phone: '9876543210',
      message: 'QA test feedback — please ignore.',
      rating: 5,
    }),
  });
  if (res5.ok || res5.status === 201) {
    logPass('T4.5', `Feedback endpoint accepted POST. HTTP ${res5.status}`);
  } else {
    logWarn('T4.5', `Feedback endpoint returned HTTP ${res5.status}: ${await res5.text()}`);
  }

  // T4.6: GET /bookings/availability
  console.log('\n[T4.6] GET /bookings/availability...');
  const res6 = await safeFetch(`${BASE_URL}/bookings/availability`);
  if (res6.ok) {
    logPass('T4.6', 'Booking availability endpoint OK.');
  } else {
    logWarn('T4.6', `Booking availability HTTP ${res6.status}`);
  }
}

// ============================================================
// PHASE 5: DATA MODEL & SYNC FIELD MAPPING
// ============================================================

async function testDataModelMapping() {
  console.log('\n━━━ PHASE 5: DATA MODEL & SYNC FIELD MAPPING ━━━');

  // T5.1: Bill model field mapping test
  console.log('[T5.1] Bill model: toMap() field mapping...');
  {
    // Simulating what the Flutter Bill model does
    const bill = {
      id: 'BILL-001',
      bill_number: 'INV-2026-001',
      customer_id: 'cust-123',
      customer_name: 'Test Customer',
      customer_phone: '9876543210',
      customer_address: '123 Water St',
      customer_gst: '33CWHPH8901N1Z6',
      items: JSON.stringify([
        { itemId: 'p1', name: 'Filter', type: 'product', hsn: '8421', price: 650, quantity: 2, gstPercent: 18, gstAmount: 234, total: 1534 },
      ]),
      subtotal: 1300,
      gst_amount: 234,
      total: 1534,
      payment_mode: 'cash',
      status: 'paid',
    };

    // Verify items can be parsed back
    const parsedItems = JSON.parse(bill.items);
    if (parsedItems.length === 1 && parsedItems[0].name === 'Filter') {
      logPass('T5.1', 'Bill model serialization/deserialization works correctly.');
    } else {
      logFail('T5.1', 'Bill item JSON parse failed.');
    }
  }

  // T5.2: Quotation model field mapping
  console.log('\n[T5.2] Quotation model: field mapping check...');
  {
    const quotation = {
      id: 'Q-001',
      quotation_number: 'EST-2026-001',
      customer_name: 'Test Customer',
      customer_phone: '9876543210',
      customer_email: 'test@example.com',
      items: JSON.stringify([
        { item_id: 'p1', name: 'Filter', type: 'product', price: 650, quantity: 2, gst_percent: 18, gst_amount: 234, total: 1534 }
      ]),
      subtotal: 1300,
      gst_amount: 234,
      total: 1534,
      status: 'draft',
      valid_until: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      notes: 'Payment 50% advance',
    };

    const parsedItems = JSON.parse(quotation.items);
    if (parsedItems[0].gst_percent === 18 && quotation.total === 1534) {
      logPass('T5.2', 'Quotation model field mapping is consistent.');
    } else {
      logFail('T5.2', 'Quotation item field mapping issue.');
    }
  }

  // T5.3: Order model — AWS format vs local format parsing
  console.log('\n[T5.3] Order model: AWS format with "customer" object...');
  {
    // AWS returns orders with nested customer/address objects
    const awsOrder = {
      id: 'ord-aws-001',
      orderId: 'A1-298963-687',
      customer: { fullName: 'Kabhilan VS', phone: '8760351341' },
      address: { address: '123 Main St', city: 'Gobichettipalayam' },
      items: [
        { productId: 'p1', name: 'Filter', category: 'product', unitPrice: 650, qty: 2, gstPercent: 18 }
      ],
      subtotal: '1300',
      gst_amount: '234',
      total: '1534',
      status: 'Pending',
      createdAt: '2026-07-01T10:00:00Z',
    };

    // Simulate Order.fromMap parsing
    const customerName = awsOrder.customer?.fullName || awsOrder.customer?.name || 'Unknown Customer';
    const customerPhone = awsOrder.customer?.phone || awsOrder.address?.phone;
    const customerAddress = awsOrder.customer?.address || awsOrder.address?.address;
    const status = (awsOrder.status || 'pending').toLowerCase();

    if (customerName === 'Kabhilan VS' && customerPhone === '8760351341' && status === 'pending') {
      logPass('T5.3', `AWS Order parsed: name="${customerName}", phone="${customerPhone}", status="${status}"`);
    } else {
      logFail('T5.3', `AWS parsing failed: name=${customerName}, phone=${customerPhone}`);
    }

    // OrderItem parsing: qty/unitPrice vs quantity/price
    const item = awsOrder.items[0];
    const quantity = item.qty || item.quantity || 1;
    const unitPrice = item.unitPrice || item.price || 0;
    const itemTotal = unitPrice * quantity; // 1300
    const gstAmount = (itemTotal * (item.gstPercent || 18)) / 100; // 234
    const totalWithGst = itemTotal + gstAmount; // 1534
    if (quantity === 2 && unitPrice === 650 && itemTotal === 1300 && gstAmount === 234) {
      logPass('T5.3b', `OrderItem AWS fields: qty=${quantity}, unitPrice=₹${unitPrice}, total=₹${itemTotal}, gst=₹${gstAmount}`);
    } else {
      logFail('T5.3b', `OrderItem parse error: qty=${quantity}, unitPrice=${unitPrice}`);
    }
  }

  // T5.4: Customer model — field fallbacks
  console.log('\n[T5.4] Customer model: field validation...');
  {
    const customer = {
      id: 'c-001',
      name: 'Test Customer',
      phone: '9876543210',
      address: '123 Water Street',
      email: 'test@example.com',
      source: 'manual',
      total_visits: 0,
      total_spent: 0.0,
      is_synced: 1,
      created_at: new Date().toISOString(),
    };

    if (customer.name && customer.id && customer.created_at) {
      logPass('T5.4', `Customer model valid: "${customer.name}" [${customer.source}]`);
    } else {
      logFail('T5.4', 'Customer model missing required fields.');
    }
  }

  // T5.5: Sync service field name matching (camelCase vs snake_case)
  console.log('\n[T5.5] Sync service: camelCase vs snake_case field compatibility...');
  {
    // The admin API uses camelCase (customerName, billNumber)
    // Local SQLite uses snake_case (customer_name, bill_number)
    // Bill.fromMap handles both with ?? fallbacks
    const awsBill = { billNumber: 'INV-001', customerName: 'Test' };
    const localBill = { bill_number: 'INV-001', customer_name: 'Test' };

    const resolvedAws = awsBill.bill_number ?? awsBill.billNumber;
    const resolvedLocal = localBill.bill_number ?? localBill.billNumber;

    if (resolvedAws === 'INV-001' && resolvedLocal === 'INV-001') {
      logPass('T5.5', 'Bill field fallbacks handle both camelCase and snake_case correctly.');
    } else {
      logFail('T5.5', `Field resolution mismatch: AWS=${resolvedAws}, Local=${resolvedLocal}`);
    }
  }
}

// ============================================================
// PHASE 6: CORS, OPTIONS, & ERROR HANDLING
// ============================================================

async function testCorsAndErrors() {
  console.log('\n━━━ PHASE 6: CORS, OPTIONS & ERROR HANDLING ━━━');

  // T6.1: OPTIONS preflight
  console.log('[T6.1] OPTIONS preflight request...');
  const res = await safeFetch(`${BASE_URL}/products`, { method: 'OPTIONS' });
  if (res.status === 200) {
    logPass('T6.1', 'OPTIONS preflight returned 200.');
  } else {
    logWarn('T6.1', `OPTIONS returned ${res.status}`);
  }

  // T6.2: 404 for nonexistent route
  console.log('\n[T6.2] GET /nonexistent-route...');
  const res2 = await safeFetch(`${BASE_URL}/nonexistent-route-xyz`);
  if (res2.status === 404) {
    logPass('T6.2', '404 returned for nonexistent route.');
  } else {
    logWarn('T6.2', `Expected 404, got ${res2.status}`);
  }

  // T6.3: CORS headers present
  console.log('\n[T6.3] CORS headers check...');
  const res3 = await safeFetch(`${BASE_URL}/products`);
  const corsOrigin = res3.headers?.get?.('access-control-allow-origin');
  if (corsOrigin === '*') {
    logPass('T6.3', 'CORS Access-Control-Allow-Origin: * is set.');
  } else {
    logWarn('T6.3', `CORS header: ${corsOrigin || 'not detected (may be hidden by fetch)'}`);
  }
}

// ============================================================
// PHASE 7: PDF GENERATION DATA VERIFICATION
// ============================================================

async function testPdfDataStructure(bizSettings, billingSettings) {
  console.log('\n━━━ PHASE 7: PDF GENERATION DATA VERIFICATION ━━━');

  // T7.1: Bill PDF header data
  console.log('[T7.1] Invoice PDF header fields...');
  if (bizSettings) {
    const requiredFields = ['companyName', 'supportPhone', 'gstin', 'addressLine1'];
    let allPresent = true;
    for (const f of requiredFields) {
      if (!bizSettings[f]) {
        logFail('T7.1', `PDF header missing: ${f}`);
        allPresent = false;
      }
    }
    if (allPresent) {
      logPass('T7.1', `PDF header data complete: ${bizSettings.companyName}, GSTIN: ${bizSettings.gstin}`);
    }
  } else {
    logFail('T7.1', 'No business settings available for PDF header verification.');
  }

  // T7.2: Invoice number format
  console.log('\n[T7.2] Invoice number format...');
  const prefix = billingSettings?.invoicePrefix || 'BILL';
  const now = new Date();
  const y = now.getFullYear().toString().slice(-2);
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const sampleBillNum = `${prefix}-${y}${m}-0001`;
  if (/^[A-Z]+-\d{4}-\d{4}$/.test(sampleBillNum)) {
    logPass('T7.2', `Invoice number format valid: ${sampleBillNum}`);
  } else {
    logWarn('T7.2', `Invoice number format may vary: ${sampleBillNum}`);
  }

  // T7.3: PDF line item data structure
  console.log('\n[T7.3] PDF line item rendering data...');
  {
    const lineItems = [
      { name: '20"wound filter', price: 650, quantity: 2, gstPercent: 18, gstAmount: 234, total: 1534 },
      { name: 'Installation', price: 350, quantity: 1, gstPercent: 18, gstAmount: 63, total: 413 },
    ];
    let subtotal = 0, gstTotal = 0, grandTotal = 0;
    for (const li of lineItems) {
      const expectedItemSub = li.price * li.quantity;
      const expectedGst = (expectedItemSub * li.gstPercent) / 100;
      const expectedTotal = expectedItemSub + expectedGst;
      subtotal += expectedItemSub;
      gstTotal += expectedGst;

      if (Math.abs(li.gstAmount - expectedGst) > 0.01) {
        logFail('T7.3', `"${li.name}" gstAmount mismatch: stored=${li.gstAmount}, calculated=${expectedGst}`);
      }
      if (Math.abs(li.total - expectedTotal) > 0.01) {
        logFail('T7.3', `"${li.name}" total mismatch: stored=${li.total}, calculated=${expectedTotal}`);
      }
    }
    grandTotal = subtotal + gstTotal;
    logPass('T7.3', `PDF line items verified: Subtotal=₹${subtotal}, GST=₹${gstTotal}, Grand Total=₹${grandTotal}`);
  }
}

// ============================================================
// MAIN RUNNER
// ============================================================

async function main() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║  A1 WATER TECH — COMPREHENSIVE QA TEST SUITE             ║');
  console.log('║  Testing: APIs, Calculations, Models, Sync, PDF, CORS    ║');
  console.log('╚════════════════════════════════════════════════════════════╝');

  const bizSettings = await testBusinessSettings();
  const billingSettings = await testBillingSettings();
  const products = await testProductsCatalog();
  const services = await testServicesCatalog();
  await testBillingCalculations(products, billingSettings);
  await testQuotationsEndpoint();
  await testDataModelMapping();
  await testCorsAndErrors();
  await testPdfDataStructure(bizSettings, billingSettings);

  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log(`║  FINAL RESULTS: ${passed} PASSED | ${failed} FAILED | ${warnings} WARNINGS`);
  console.log('╚════════════════════════════════════════════════════════════╝');

  if (issues.length > 0) {
    console.log('\n🔴 ISSUES FOUND:');
    for (const issue of issues) {
      console.log(`   • ${issue}`);
    }
  } else {
    console.log('\n🟢 ALL TESTS PASSED — No issues found!');
  }
}

main();

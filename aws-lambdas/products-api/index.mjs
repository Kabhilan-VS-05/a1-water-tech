import pg from 'pg'
import dotenv from 'dotenv'
import { handleAdminRoute } from './admin.mjs'

dotenv.config()

const { Pool } = pg

let pool

function getPool() {
  if (!pool) {
    if (process.env.DATABASE_URL) {
      pool = new Pool({
        connectionString: process.env.DATABASE_URL,
        ssl: { rejectUnauthorized: false },
        max: 10,
        idleTimeoutMillis: 10000,
        connectionTimeoutMillis: 10000,
      });
    } else {
      const user = process.env.DB_USER || 'postgres.vbadwfrvhyfbfableeug';
      const pass = process.env.DB_PASSWORD || '';
      const host = process.env.DB_HOST || 'aws-0-ap-northeast-2.pooler.supabase.com';
      const port = process.env.DB_PORT || 6543;
      const dbName = process.env.DB_NAME || 'postgres';

      const connectionString = `postgresql://${encodeURIComponent(user)}:${encodeURIComponent(pass)}@${host}:${port}/${dbName}`;

      pool = new Pool({
        connectionString,
        ssl: { rejectUnauthorized: false },
        max: 10,
        idleTimeoutMillis: 10000,
        connectionTimeoutMillis: 10000,
      });
    }
  }

  return pool
}

function safeQuery(promise) {
  return promise.catch(err => {
    console.error('Database query error:', err);
    return { rows: [] };
  });
}
function response(statusCode, body) {
  return {
    statusCode,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': '*',
      'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
      'access-control-allow-origin': '*',
      'access-control-allow-headers': '*',
      'access-control-allow-methods': 'GET,POST,PUT,DELETE,OPTIONS',
    },
    multiValueHeaders: {
      'Access-Control-Allow-Origin': ['*'],
      'Access-Control-Allow-Headers': ['*'],
      'Access-Control-Allow-Methods': ['GET,POST,PUT,DELETE,OPTIONS'],
      'Content-Type': ['application/json'],
    },
    isBase64Encoded: false,
    body: JSON.stringify(body, (key, value) =>
      typeof value === 'bigint' ? value.toString() : value
    ),
  }
}

function getPath(event) {
  return event?.rawPath || event?.path || event?.requestContext?.http?.path || '';
}

function getMethod(event) {
  return (event?.httpMethod || event?.requestContext?.http?.method || '').toUpperCase();
}

function parseJsonBody(body) {
  if (!body) return {}
  if (typeof body === 'string') return JSON.parse(body)
  return body
}

function getQueryValue(event, key) {
  return event?.queryStringParameters?.[key] || ''
}

function getPathId(path, prefix) {
  const start = path.indexOf(prefix)
  if (start < 0) return ''
  const value = path.slice(start + prefix.length).split('/')[0]
  return decodeURIComponent(value || '')
}

async function fetchProducts() {
  const result = await safeQuery(getPool().query(`
    select
      id,
      name,
      category,
      image_url as "imageUrl",
      price,
      rating,
      tag,
      tds,
      hsn,
      warranty,
      description,
      features,
      recommendation,
      is_active as "isActive"
    from products
    where is_active = true
    order by name asc
  `));

  return {
    items: result.rows,
  };
}

async function fetchServices() {
  const result = await safeQuery(getPool().query(`
    select
      id,
      name,
      image_url as "imageUrl",
      price,
      duration,
      hsn,
      description,
      is_active as "isActive"
    from services
    where is_active = true
    order by name asc
  `));

  return {
    items: result.rows,
  }
}

async function fetchAnnouncements() {
  const result = await safeQuery(getPool().query(`
    select
      id,
      title,
      message,
      is_active as "isActive",
      is_pinned as "isPinned",
      created_at as "createdAt"
    from announcements
    where is_active = true
    order by is_pinned desc, created_at desc
  `));

  return {
    items: result.rows,
  }
}

async function fetchFaqs() {
  const result = await safeQuery(getPool().query(`
    select
      id,
      q,
      a,
      is_active as "isActive",
      created_at as "createdAt"
    from faqs
    where is_active = true
    order by id asc
  `));

  return {
    items: result.rows,
  }
}

async function fetchBusinessSettings() {
  const result = await safeQuery(getPool().query(`
    select
      company_name as "companyName",
      support_phone as "supportPhone",
      support_email as "supportEmail",
      locality,
      address_line1 as "addressLine1",
      address_line2 as "addressLine2",
      address_line3 as "addressLine3",
      gstin
    from business_settings
    where id = 1
    limit 1
  `));

  return result.rows[0] || null
}

async function fetchBillingSettings() {
  const result = await safeQuery(getPool().query(`
    select
      company_name as "companyName",
      support_phone as "supportPhone",
      invoice_prefix as "invoicePrefix",
      gst_rate as "gstRate",
      gst_enabled as "gstEnabled"
    from billing_settings
    where id = 1
    limit 1
  `));

  return result.rows[0] || null
}

async function createFeedback(payload) {
  const customerName = String(payload?.customerName || '').trim()
  const phone = String(payload?.phone || '').trim()
  const email = String(payload?.email || '').trim()
  const message = String(payload?.message || '').trim()
  const userId = String(payload?.userId || '').trim()

  if (!customerName || !phone || !message) {
    return response(400, {
      message: 'customerName, phone, and message are required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      insert into feedback (
        customer_name,
        phone,
        email,
        message,
        source,
        status,
        rating,
        user_id
      )
      values ($1, $2, $3, $4, 'website_contact', 'open', 0, $5)
      returning id, created_at as "createdAt"
    `,
    [customerName, phone, email, message, userId],
  ));

  return response(201, {
    item: result.rows[0],
    ok: true,
  })
}

async function fetchBookings(userId, phone, email) {
  const normalizedUserId = String(userId || '').trim()
  const normalizedPhone = String(phone || '').trim()
  const normalizedEmail = String(email || '').trim()

  if (!normalizedUserId && !normalizedPhone && !normalizedEmail) {
    return response(400, {
      message: 'userId, phone, or email is required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      select
        id::text as id,
        user_id as "userId",
        service_id as "serviceId",
        service_name as "serviceName",
        booking_date::text as date,
        time_slot as time,
        address_id as "addressId",
        address_snapshot as "addressSnapshot",
        status,
        created_at as "createdAt"
      from bookings
      where (COALESCE($1, '') != '' AND user_id = $1)
         OR (COALESCE($2, '') != '' AND (address_snapshot->>'phone' ILIKE $2))
         OR (COALESCE($3, '') != '' AND (address_snapshot->>'email' ILIKE $3))
      order by created_at desc
    `,
    [normalizedUserId, normalizedPhone, normalizedEmail],
  ));

  return response(200, {
    items: result.rows,
  })
}

async function fetchBookedSlots(date) {
  const normalizedDate = String(date || '').trim()

  if (!normalizedDate) {
    return response(400, {
      message: 'date is required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      select time_slot as time, count(*) as count
      from bookings
      where booking_date = $1::date and status != 'cancelled' and status != 'rejected'
      group by time_slot
    `,
    [normalizedDate],
  ));

  return response(200, {
    items: result.rows,
  })
}

async function createBooking(payload) {
  const userId = String(payload?.userId || '').trim()
  const serviceId = String(payload?.serviceId || '').trim()
  const serviceName = String(payload?.serviceName || '').trim()
  const date = String(payload?.date || '').trim()
  const time = String(payload?.time || '').trim()
  const addressId = String(payload?.addressId || '').trim()
  const addressSnapshot = payload?.addressSnapshot ?? {}

  if (!userId || !serviceId || !serviceName || !date || !time || !addressId) {
    return response(400, {
      message: 'userId, serviceId, serviceName, date, time, and addressId are required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      insert into bookings (
        user_id,
        service_id,
        service_name,
        booking_date,
        time_slot,
        address_id,
        address_snapshot,
        status
      )
      values ($1, $2, $3, $4::date, $5, $6, $7::jsonb, 'scheduled')
      returning
        id::text as id,
        user_id as "userId",
        service_id as "serviceId",
        service_name as "serviceName",
        booking_date::text as date,
        time_slot as time,
        address_id as "addressId",
        address_snapshot as "addressSnapshot",
        status,
        created_at as "createdAt"
    `,
    [
      userId,
      serviceId,
      serviceName,
      date,
      time,
      addressId,
      JSON.stringify(addressSnapshot),
    ],
  ));

  return response(201, {
    item: result.rows[0],
    ok: true,
  })
}

async function updateBookingStatus(bookingId, payload) {
  const id = String(bookingId || '').trim()
  const status = String(payload?.status || '').trim()

  if (!id || !status) {
    return response(400, {
      message: 'booking id and status are required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      update bookings
      set
        status = $2,
        updated_at = now()
      where id = $1::bigint
      returning
        id::text as id,
        user_id as "userId",
        service_id as "serviceId",
        service_name as "serviceName",
        booking_date::text as date,
        time_slot as time,
        address_id as "addressId",
        address_snapshot as "addressSnapshot",
        status,
        created_at as "createdAt"
    `,
    [id, status],
  ));

  if (result.rowCount === 0) {
    return response(404, {
      message: 'Booking not found',
    })
  }

  return response(200, {
    item: result.rows[0],
    ok: true,
  })
}

async function fetchAddresses(userId, email, phone) {
  const normalizedUserId = String(userId || '').trim()
  const normalizedEmail = String(email || '').trim()
  const normalizedPhone = String(phone || '').trim()

  if (!normalizedUserId && !normalizedEmail && !normalizedPhone) {
    return response(400, {
      message: 'userId, email, or phone is required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      select
        id::text as id,
        user_id as "userId",
        label,
        full_name as name,
        phone,
        email,
        city,
        pincode,
        address,
        created_at as "createdAt",
        updated_at as "updatedAt"
      from user_addresses
      where (COALESCE($1, '') != '' AND user_id = $1)
         OR (COALESCE($2, '') != '' AND email ILIKE $2)
         OR (COALESCE($3, '') != '' AND phone ILIKE $3)
      order by created_at desc
    `,
    [normalizedUserId, normalizedEmail, normalizedPhone],
  ));

  return response(200, {
    items: result.rows,
  })
}

async function createAddress(payload) {
  const userId = String(payload?.userId || '').trim()
  const label = String(payload?.label || '').trim()
  const name = String(payload?.name || '').trim()
  const phone = String(payload?.phone || '').trim()
  const email = String(payload?.email || '').trim()
  const city = String(payload?.city || '').trim()
  const pincode = String(payload?.pincode || '').trim()
  const address = String(payload?.address || '').trim()

  if (!userId || !label || !name || !phone || !city || !address) {
    return response(400, {
      message: 'userId, label, name, phone, city, and address are required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      insert into user_addresses (
        user_id,
        label,
        full_name,
        phone,
        email,
        city,
        pincode,
        address
      )
      values ($1, $2, $3, $4, $5, $6, $7, $8)
      returning
        id::text as id,
        user_id as "userId",
        label,
        full_name as name,
        phone,
        email,
        city,
        pincode,
        address,
        created_at as "createdAt",
        updated_at as "updatedAt"
    `,
    [userId, label, name, phone, email, city, pincode, address],
  ));

  if (!result.rows || result.rows.length === 0) {
    return response(500, {
      message: 'Failed to create address in database',
      ok: false,
    })
  }

  return response(201, {
    item: result.rows[0],
    ok: true,
  })
}

async function updateAddress(addressId, payload) {
  const id = String(addressId || '').trim()
  const userId = String(payload?.userId || '').trim()
  const label = String(payload?.label || '').trim()
  const name = String(payload?.name || '').trim()
  const phone = String(payload?.phone || '').trim()
  const email = String(payload?.email || '').trim()
  const city = String(payload?.city || '').trim()
  const pincode = String(payload?.pincode || '').trim()
  const address = String(payload?.address || '').trim()

  if (!id || !userId || !label || !name || !phone || !email || !city || !address) {
    return response(400, {
      message: 'address id, userId, label, name, phone, email, city, and address are required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      update user_addresses
      set
        label = $3,
        full_name = $4,
        phone = $5,
        email = $6,
        city = $7,
        pincode = $8,
        address = $9,
        updated_at = now()
      where id = $1::bigint and user_id = $2
      returning
        id::text as id,
        user_id as "userId",
        label,
        full_name as name,
        phone,
        email,
        city,
        pincode,
        address,
        created_at as "createdAt",
        updated_at as "updatedAt"
    `,
    [id, userId, label, name, phone, email, city, pincode, address],
  ));

  if (result.rowCount === 0) {
    return response(404, {
      message: 'Address not found',
    })
  }

  return response(200, {
    item: result.rows[0],
    ok: true,
  })
}

async function deleteAddress(addressId, userId) {
  const id = String(addressId || '').trim()
  const normalizedUserId = String(userId || '').trim()

  if (!id || !normalizedUserId) {
    return response(400, {
      message: 'address id and userId are required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      delete from user_addresses
      where id = $1::bigint and user_id = $2
      returning id::text as id
    `,
    [id, normalizedUserId],
  ));

  if (result.rowCount === 0) {
    return response(404, {
      message: 'Address not found',
    })
  }

  return response(200, {
    ok: true,
    id: result.rows[0].id,
  })
}

async function fetchOrders(userId, email, phone) {
  const normalizedUserId = String(userId || '').trim()
  const normalizedEmail = String(email || '').trim()
  const normalizedPhone = String(phone || '').trim()

  if (!normalizedUserId && !normalizedEmail && !normalizedPhone) {
    return response(400, {
      message: 'userId, email, or phone is required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      select
        id::text as id,
        order_id as "orderId",
        user_id as "userId",
        customer,
        address_id as "addressId",
        address_snapshot as address,
        items,
        billing,
        subtotal,
        total,
        status,
        created_at as "createdAt",
        updated_at as "updatedAt"
      from orders
      where (COALESCE($1, '') != '' AND user_id = $1)
         OR (COALESCE($2, '') != '' AND (customer->>'email' ILIKE $2 OR address_snapshot->>'email' ILIKE $2))
         OR (COALESCE($3, '') != '' AND (customer->>'phone' ILIKE $3 OR address_snapshot->>'phone' ILIKE $3))
      order by created_at desc
    `,
    [normalizedUserId, normalizedEmail, normalizedPhone],
  ));

  return response(200, {
    items: result.rows,
  })
}

async function fetchTrackedOrder(userId, orderId) {
  const normalizedOrderId = String(orderId || '').trim()

  if (!normalizedOrderId) {
    return response(400, {
      message: 'orderId is required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      select
        id::text as id,
        order_id as "orderId",
        user_id as "userId",
        customer,
        address_id as "addressId",
        address_snapshot as address,
        items,
        billing,
        subtotal,
        total,
        status,
        created_at as "createdAt",
        updated_at as "updatedAt"
      from orders
      where order_id ILIKE $1
      limit 1
    `,
    [normalizedOrderId],
  ));

  if (result.rowCount === 0) {
    return response(404, {
      message: 'Order not found',
    })
  }

  return response(200, {
    item: result.rows[0],
  })
}

async function createOrder(payload) {
  const userId = String(payload?.userId || '').trim()
  const orderId = String(payload?.orderId || '').trim()
  const customer = payload?.customer ?? {}
  const addressId = String(payload?.addressId || '').trim()
  const address = payload?.address ?? {}
  const items = Array.isArray(payload?.items) ? payload.items : []
  const billing = payload?.billing ?? {}
  const subtotal = Number(payload?.subtotal ?? 0)
  const total = Number(payload?.total ?? 0)

  if (!userId || !orderId || items.length === 0) {
    return response(400, {
      message: 'userId, orderId, and at least one item are required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      insert into orders (
        order_id,
        user_id,
        customer,
        address_id,
        address_snapshot,
        items,
        billing,
        subtotal,
        total,
        status
      )
      values ($1, $2, $3::jsonb, $4, $5::jsonb, $6::jsonb, $7::jsonb, $8, $9, 'pending')
      returning
        id::text as id,
        order_id as "orderId",
        user_id as "userId",
        customer,
        address_id as "addressId",
        address_snapshot as address,
        items,
        billing,
        subtotal,
        total,
        status,
        created_at as "createdAt",
        updated_at as "updatedAt"
    `,
    [
      orderId,
      userId,
      JSON.stringify(customer),
      addressId,
      JSON.stringify(address),
      JSON.stringify(items),
      JSON.stringify(billing),
      subtotal,
      total,
    ],
  ));

  if (!result.rows || result.rows.length === 0) {
    return response(500, {
      message: 'Failed to create order in database',
      ok: false,
    })
  }

  return response(201, {
    item: result.rows[0],
    ok: true,
  })
}

async function fetchCart(userId) {
  const normalizedUserId = String(userId || '').trim()

  if (!normalizedUserId) {
    return response(400, {
      message: 'userId is required',
    })
  }

  const result = await safeQuery(getPool().query(
    `
      select
        product_id as id,
        qty
      from cart_items
      where user_id = $1
      order by updated_at desc
    `,
    [normalizedUserId],
  ));

  return response(200, {
    items: result.rows,
  })
}

async function upsertCartItem(productId, payload) {
  const normalizedProductId = String(productId || '').trim()
  const userId = String(payload?.userId || '').trim()
  const qty = Number(payload?.qty ?? 0)

  if (!normalizedProductId || !userId || !Number.isFinite(qty)) {
    return response(400, {
      message: 'productId, userId, and qty are required',
    })
  }

  if (qty <= 0) {
    return await deleteCartItem(normalizedProductId, userId)
  }

  const result = await safeQuery(getPool().query(
    `
      insert into cart_items (
        user_id,
        product_id,
        qty
      )
      values ($1, $2, $3)
      on conflict (user_id, product_id)
      do update set
        qty = excluded.qty,
        updated_at = now()
      returning
        product_id as id,
        qty
    `,
    [userId, normalizedProductId, qty],
  ));

  return response(200, {
    item: result.rows[0],
    ok: true,
  })
}

async function deleteCartItem(productId, userId) {
  const normalizedProductId = String(productId || '').trim()
  const normalizedUserId = String(userId || '').trim()

  if (!normalizedProductId || !normalizedUserId) {
    return response(400, {
      message: 'productId and userId are required',
    })
  }

  await safeQuery(getPool().query(
    `
      delete from cart_items
      where user_id = $1 and product_id = $2
    `,
    [normalizedUserId, normalizedProductId],
  ));

  return response(200, {
    ok: true,
    id: normalizedProductId,
  })
}

async function clearCart(userId) {
  const normalizedUserId = String(userId || '').trim()

  if (!normalizedUserId) {
    return response(400, {
      message: 'userId is required',
    })
  }

  await safeQuery(getPool().query(
    `
      delete from cart_items
      where user_id = $1
    `,
    [normalizedUserId],
  ));

  return response(200, {
    ok: true,
  })
}

async function fetchQuotations(userId, phone, email) {
  const normalizedUserId = String(userId || '').trim()
  const normalizedPhone = String(phone || '').trim().replace(/\D/g, '')
  const normalizedEmail = String(email || '').trim().toLowerCase()

  if (!normalizedUserId && !normalizedPhone && !normalizedEmail) {
    return response(400, {
      message: 'userId, phone, or email is required',
    })
  }

  const pool = getPool()
  const phonesSet = new Set()
  const emailsSet = new Set()

  if (normalizedPhone) {
    // Keep last 10 digits if longer (e.g. country code)
    const p = normalizedPhone.length >= 10 ? normalizedPhone.slice(-10) : normalizedPhone
    if (p) phonesSet.add(p)
  }

  if (normalizedEmail) {
    emailsSet.add(normalizedEmail)
  }

  // If userId is provided, look up saved addresses and prior orders to auto-discover customer phones and emails
  if (normalizedUserId) {
    try {
      const addrRes = await safeQuery(pool.query(
        'SELECT phone, email FROM user_addresses WHERE user_id = $1',
        [normalizedUserId]
      ))
      for (const row of addrRes.rows || []) {
        if (row.phone) {
          const digits = String(row.phone).replace(/\D/g, '')
          const p = digits.length >= 10 ? digits.slice(-10) : digits
          if (p) phonesSet.add(p)
        }
        if (row.email) {
          const em = String(row.email).trim().toLowerCase()
          if (em) emailsSet.add(em)
        }
      }

      const orderRes = await safeQuery(pool.query(
        `SELECT customer->>'phone' as phone, customer->>'email' as email, address_snapshot->>'phone' as addr_phone FROM orders WHERE user_id = $1 ORDER BY created_at DESC LIMIT 10`,
        [normalizedUserId]
      ))
      for (const row of orderRes.rows || []) {
        const orderPhone = row.phone || row.addr_phone
        if (orderPhone) {
          const digits = String(orderPhone).replace(/\D/g, '')
          const p = digits.length >= 10 ? digits.slice(-10) : digits
          if (p) phonesSet.add(p)
        }
        if (row.email) {
          const em = String(row.email).trim().toLowerCase()
          if (em) emailsSet.add(em)
        }
      }
    } catch (e) {
      console.error('Error discovering user contact info for quotations:', e)
    }
  }

  let conditions = []
  let params = []

  if (normalizedUserId) {
    params.push(normalizedUserId)
    conditions.push(`customer_id = $${params.length}`)
  }

  for (const ph of phonesSet) {
    params.push(`%${ph}%`)
    const paramIdx = params.length
    params.push(`cust-${ph}`)
    const custIdParamIdx = params.length
    conditions.push(`customer_phone LIKE $${paramIdx} OR customer_id = $${custIdParamIdx}`)
  }

  for (const em of emailsSet) {
    params.push(em)
    conditions.push(`LOWER(customer_email) = $${params.length}`)
  }

  if (conditions.length === 0) {
    return response(200, { items: [] })
  }

  const whereClause = conditions.join(' OR ')

  const result = await safeQuery(pool.query(
    `
      select
        id::text as id,
        quotation_number as "quotationNumber",
        customer_id as "customerId",
        customer_name as "customerName",
        customer_phone as "customerPhone",
        customer_address as "customerAddress",
        customer_email as "customerEmail",
        items,
        subtotal,
        gst_amount as "gstAmount",
        total,
        status,
        valid_until as "validUntil",
        notes,
        created_at as "createdAt",
        updated_at as "updatedAt",
        other_charge_label as "otherChargeLabel",
        other_charge_amount as "otherChargeAmount",
        is_other_charge_taxable as "isOtherChargeTaxable",
        other_charge_gst_percent as "otherChargeGstPercent",
        terms,
        is_rounded_off as "isRoundedOff"
      from quotations
      where ${whereClause}
      order by created_at desc
    `,
    params,
  ));

  return response(200, { items: result?.rows || [] })
}

async function updateQuotationStatus(id, data) {
  const { userId, phone, email, status } = data
  const normalizedUserId = String(userId || '').trim()

  if (!normalizedUserId) {
    return response(400, { message: 'userId is required' })
  }

  if (!status || !['accepted', 'rejected'].includes(status)) {
    return response(400, { message: 'Invalid status' })
  }

  const pool = getPool()

  const checkResult = await safeQuery(pool.query(
    'SELECT * FROM quotations WHERE id = $1',
    [id]
  ))

  if (checkResult.rows.length === 0) {
    return response(404, { message: 'Quotation not found' })
  }

  const quotation = checkResult.rows[0]

  // Authorization check
  let isAuthorized = (quotation.customer_id === normalizedUserId)

  if (!isAuthorized) {
    // Collect user's known phones and emails to verify ownership
    const phonesSet = new Set()
    const emailsSet = new Set()

    if (phone) {
      const digits = String(phone).replace(/\D/g, '')
      const p = digits.length >= 10 ? digits.slice(-10) : digits
      if (p) phonesSet.add(p)
    }
    if (email) {
      emailsSet.add(String(email).trim().toLowerCase())
    }

    try {
      const addrRes = await safeQuery(pool.query(
        'SELECT phone, email FROM user_addresses WHERE user_id = $1',
        [normalizedUserId]
      ))
      for (const row of addrRes.rows || []) {
        if (row.phone) {
          const digits = String(row.phone).replace(/\D/g, '')
          const p = digits.length >= 10 ? digits.slice(-10) : digits
          if (p) phonesSet.add(p)
        }
        if (row.email) {
          const em = String(row.email).trim().toLowerCase()
          if (em) emailsSet.add(em)
        }
      }

      const orderRes = await safeQuery(pool.query(
        `SELECT customer->>'phone' as phone, customer->>'email' as email, address_snapshot->>'phone' as addr_phone FROM orders WHERE user_id = $1 ORDER BY created_at DESC LIMIT 10`,
        [normalizedUserId]
      ))
      for (const row of orderRes.rows || []) {
        const orderPhone = row.phone || row.addr_phone
        if (orderPhone) {
          const digits = String(orderPhone).replace(/\D/g, '')
          const p = digits.length >= 10 ? digits.slice(-10) : digits
          if (p) phonesSet.add(p)
        }
        if (row.email) {
          const em = String(row.email).trim().toLowerCase()
          if (em) emailsSet.add(em)
        }
      }
    } catch (e) {
      console.error('Error discovering user contact info for updateQuotationStatus:', e)
    }

    // Check if quotation matches any of the discovered contact info
    if (quotation.customer_phone) {
      const qDigits = String(quotation.customer_phone).replace(/\D/g, '')
      const qp = qDigits.length >= 10 ? qDigits.slice(-10) : qDigits
      if (phonesSet.has(qp)) {
        isAuthorized = true
      }
    }
    
    if (!isAuthorized && quotation.customer_email) {
      const qem = String(quotation.customer_email).trim().toLowerCase()
      if (emailsSet.has(qem)) {
        isAuthorized = true
      }
    }
  }

  if (!isAuthorized) {
    return response(404, { message: 'Quotation not found or unauthorized' })
  }

  if (quotation.status === 'accepted') {
    return response(400, { message: 'Quotation is already accepted' })
  }

  if (status === 'accepted') {
    const today = new Date()
    const dateStr = today.toISOString().slice(2, 10).replace(/-/g, '')
    const rand = Math.floor(100 + Math.random() * 900)
    const orderId = `A1-${dateStr}-${rand}`

    const customerObj = {
      fullName: quotation.customer_name || '',
      phone: quotation.customer_phone || '',
      email: '', 
      city: '',
    }

    const addressObj = {
      name: quotation.customer_name || '',
      phone: quotation.customer_phone || '',
      address: quotation.customer_address || '',
      label: 'Quotation Address',
    }

    const billingObj = {
      gstRate: 0,
      gstAmount: quotation.gst_amount || 0,
    }

    await safeQuery(pool.query(
      `
      insert into orders (
        order_id,
        user_id,
        customer,
        address_id,
        address_snapshot,
        items,
        billing,
        subtotal,
        total,
        status,
        created_at,
        updated_at
      ) values ($1, $2, $3::jsonb, $4, $5::jsonb, $6::jsonb, $7::jsonb, $8, $9, $10, now(), now())
      `,
      [
        orderId,
        normalizedUserId,
        JSON.stringify(customerObj),
        -1,
        JSON.stringify(addressObj),
        typeof quotation.items === 'string' ? quotation.items : JSON.stringify(quotation.items),
        JSON.stringify(billingObj),
        quotation.subtotal,
        quotation.total,
        'confirmed'
      ]
    ))
  }

  await safeQuery(pool.query(
    'UPDATE quotations SET status = $1, updated_at = now() WHERE id = $2',
    [status, id]
  ))

  return response(200, { ok: true, status })
}

export const handler = async (event) => {
  const method = getMethod(event)
  const path = getPath(event)

  console.log(`Incoming request: ${method} ${path}`);

  if (method === 'OPTIONS') {
    return response(200, { ok: true })
  }

  try {
    const adminResponse = await handleAdminRoute({
      method,
      path,
      event,
      getPool,
      response,
      parseJsonBody,
      getQueryValue,
      getPathId,
    })

    if (adminResponse) {
      return adminResponse
    }

    if (method === 'GET' && path.endsWith('/products')) {
      return response(200, await fetchProducts())
    }

    if (method === 'GET' && path.endsWith('/services')) {
      return response(200, await fetchServices())
    }

    if (method === 'GET' && path.endsWith('/announcements')) {
      return response(200, await fetchAnnouncements())
    }

    if (method === 'GET' && path.endsWith('/faqs')) {
      return response(200, await fetchFaqs())
    }

    if (method === 'GET' && path.endsWith('/settings/business')) {
      return response(200, {
        item: await fetchBusinessSettings(),
      })
    }

    if (method === 'GET' && path.endsWith('/settings/billing')) {
      return response(200, {
        item: await fetchBillingSettings(),
      })
    }

    if (method === 'POST' && path.endsWith('/feedback')) {
      return await createFeedback(parseJsonBody(event?.body))
    }

    if (method === 'GET' && path.endsWith('/bookings')) {
      return await fetchBookings(
        getQueryValue(event, 'userId'),
        getQueryValue(event, 'phone'),
        getQueryValue(event, 'email')
      )
    }

    if (method === 'GET' && path.endsWith('/bookings/availability')) {
      return await fetchBookedSlots(getQueryValue(event, 'date'))
    }

    if (method === 'POST' && path.endsWith('/bookings')) {
      const body = parseJsonBody(event?.body)
      if (body?.action === 'cancel') {
        return await updateBookingStatus(body?.bookingId, { status: 'cancelled' })
      }
      return await createBooking(body)
    }

    if (method === 'PUT' && path.includes('/bookings/') && path.endsWith('/status')) {
      return await updateBookingStatus(
        getPathId(path, '/bookings/'),
        parseJsonBody(event?.body),
      )
    }

    if (method === 'GET' && path.endsWith('/addresses')) {
      return await fetchAddresses(
        getQueryValue(event, 'userId'),
        getQueryValue(event, 'email'),
        getQueryValue(event, 'phone')
      )
    }

    if (method === 'POST' && path.endsWith('/addresses')) {
      return await createAddress(parseJsonBody(event?.body))
    }

    if (method === 'PUT' && path.includes('/addresses/')) {
      return await updateAddress(
        getPathId(path, '/addresses/'),
        parseJsonBody(event?.body),
      )
    }

    if (method === 'DELETE' && path.includes('/addresses/')) {
      return await deleteAddress(
        getPathId(path, '/addresses/'),
        getQueryValue(event, 'userId'),
      )
    }

    if (method === 'GET' && path.endsWith('/orders/track')) {
      return await fetchTrackedOrder(
        getQueryValue(event, 'userId'),
        getQueryValue(event, 'orderId'),
      )
    }

    if (method === 'GET' && path.endsWith('/orders')) {
      return await fetchOrders(
        getQueryValue(event, 'userId'),
        getQueryValue(event, 'email'),
        getQueryValue(event, 'phone')
      )
    }

    if (method === 'POST' && path.endsWith('/orders')) {
      return await createOrder(parseJsonBody(event?.body))
    }

    if (method === 'GET' && path.endsWith('/quotations')) {
      return await fetchQuotations(
        getQueryValue(event, 'userId'),
        getQueryValue(event, 'phone'),
        getQueryValue(event, 'email')
      )
    }

    if (method === 'PUT' && path.includes('/quotations/') && path.endsWith('/status')) {
      return await updateQuotationStatus(
        getPathId(path, '/quotations/'),
        parseJsonBody(event?.body)
      )
    }

    if (method === 'GET' && path.endsWith('/cart')) {
      return await fetchCart(getQueryValue(event, 'userId'))
    }

    if (method === 'PUT' && path.includes('/cart/')) {
      return await upsertCartItem(
        getPathId(path, '/cart/'),
        parseJsonBody(event?.body),
      )
    }

    if (method === 'DELETE' && path.endsWith('/cart')) {
      return await clearCart(getQueryValue(event, 'userId'))
    }

    if (method === 'DELETE' && path.includes('/cart/')) {
      return await deleteCartItem(
        getPathId(path, '/cart/'),
        getQueryValue(event, 'userId'),
      )
    }

    return response(404, {
      message: 'Not Found',
      method,
      path,
    })
  } catch (error) {
    console.error(`Failed to fetch path ${path || 'unknown'}`, error)

    return response(500, {
      message: 'Failed to fetch data',
      error: error.message,
      stack: error.stack,
      method,
      path,
    })
  }
}

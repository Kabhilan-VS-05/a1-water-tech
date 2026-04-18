import { randomUUID } from 'node:crypto'

function toNumber(value, fallback = 0) {
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : fallback
}

function toText(value, fallback = '') {
  const text = String(value ?? '').trim()
  return text || fallback
}

function toBoolean(value) {
  return value === true
}

function slugify(value) {
  const slug = toText(value)
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
  return slug || randomUUID()
}

function startOfDay(value) {
  return new Date(value.getFullYear(), value.getMonth(), value.getDate())
}

function mapTopItems(rows) {
  const performance = new Map()
  for (const row of rows) {
    const items = Array.isArray(row.items) ? row.items : []
    for (const raw of items) {
      const item = raw && typeof raw === 'object' ? raw : {}
      const name = toText(item.name || item.productId, 'Item')
      const quantity = toNumber(item.qty ?? item.quantity, 1)
      const unitPrice = toNumber(item.price ?? item.unitPrice, 0)
      const current = performance.get(name) || { name, quantity: 0, revenue: 0 }
      current.quantity += quantity
      current.revenue += quantity * unitPrice
      performance.set(name, current)
    }
  }

  return [...performance.values()].sort((a, b) => {
    if (b.revenue !== a.revenue) return b.revenue - a.revenue
    return b.quantity - a.quantity
  })
}

function mapDailyRevenue(rows, days) {
  const today = new Date()
  const start = startOfDay(new Date(today.getFullYear(), today.getMonth(), today.getDate() - days))
  const end = startOfDay(today)
  const revenueMap = new Map()
  const billsMap = new Map()

  for (const row of rows) {
    const createdAt = row.createdAt ? new Date(row.createdAt) : today
    const dayKey = startOfDay(createdAt).toISOString()
    revenueMap.set(dayKey, (revenueMap.get(dayKey) || 0) + toNumber(row.total))
    billsMap.set(dayKey, (billsMap.get(dayKey) || 0) + 1)
  }

  const items = []
  let cursor = new Date(start)
  while (cursor <= end) {
    const key = cursor.toISOString()
    items.push({
      date: key,
      revenue: revenueMap.get(key) || 0,
      billsCount: billsMap.get(key) || 0,
    })
    cursor = new Date(cursor.getFullYear(), cursor.getMonth(), cursor.getDate() + 1)
  }

  return items
}

async function authorizeAdminSession(getPool, payload) {
  const cognitoSub = toText(payload?.cognitoSub || payload?.sub)
  const email = toText(payload?.email).toLowerCase()
  const displayName = toText(payload?.displayName || payload?.name || email, 'Admin')

  if (!email && !cognitoSub) {
    return { ok: false, code: 400, message: 'email or cognitoSub is required' }
  }

  const result = await getPool().query(
    `
      select
        id::text as id,
        cognito_sub as "cognitoSub",
        lower(email) as email,
        display_name as "displayName",
        is_active as "isActive"
      from admins
      where
        ($1 <> '' and lower(email) = $1)
        or ($2 <> '' and cognito_sub = $2)
      order by
        case when $2 <> '' and cognito_sub = $2 then 0 else 1 end,
        id asc
      limit 1
    `,
    [email, cognitoSub],
  )

  const admin = result.rows[0]
  if (!admin || admin.isActive !== true) {
    return { ok: false, code: 403, message: 'Access denied. This account is not an admin.' }
  }

  const shouldUpdate =
    (email && admin.email !== email) ||
    (cognitoSub && admin.cognitoSub !== cognitoSub) ||
    (displayName && admin.displayName !== displayName)

  if (shouldUpdate) {
    const updated = await getPool().query(
      `
        update admins
        set
          email = case when $2 = '' then email else $2 end,
          cognito_sub = case when $3 = '' then cognito_sub else $3 end,
          display_name = case when $4 = '' then display_name else $4 end,
          updated_at = now()
        where id = $1::bigint
        returning
          id::text as id,
          lower(email) as email,
          display_name as "displayName"
      `,
      [admin.id, email, cognitoSub, displayName],
    )

    return { ok: true, item: updated.rows[0] }
  }

  return {
    ok: true,
    item: {
      id: admin.id,
      email: admin.email,
      displayName: admin.displayName || displayName,
    },
  }
}

async function fetchAdminOrders(getPool) {
  const result = await getPool().query(`
    select
      id::text as "docId",
      id::text as id,
      order_id as "orderId",
      user_id as "userId",
      jsonb_build_object(
        'fullName', coalesce(customer->>'fullName', customer->>'name', ''),
        'phone', coalesce(customer->>'phone', ''),
        'city', coalesce(customer->>'city', address_snapshot->>'city', ''),
        'address', coalesce(customer->>'address', address_snapshot->>'address', ''),
        'invoiceType', coalesce(customer->>'invoiceType', 'GST Invoice'),
        'paymentMethod', coalesce(customer->>'paymentMethod', 'UPI')
      ) as customer,
      address_snapshot as address,
      items,
      subtotal,
      total,
      status,
      bill_number as "billNumber",
      bill_id as "billId",
      created_at as "createdAt",
      confirmed_at as "confirmedAt"
    from orders
    order by created_at desc
  `)

  return result.rows
}

async function updateAdminOrderStatus(getPool, orderDocId, payload) {
  const status = toText(payload?.status, 'pending')
  const result = await getPool().query(
    `
      update orders
      set
        status = $2,
        confirmed_at = case
          when $2 = 'confirmed' then coalesce(confirmed_at, now())
          else confirmed_at
        end,
        updated_at = now()
      where id = $1::bigint
      returning id::text as id
    `,
    [orderDocId, status],
  )

  return result.rowCount === 0 ? null : result.rows[0]
}

async function fetchAdminBookings(getPool) {
  const result = await getPool().query(`
    select
      id::text as "bookingId",
      id::text as id,
      user_id as "userId",
      coalesce(
        address_snapshot->>'name',
        address_snapshot->>'fullName',
        address_snapshot->>'label',
        ''
      ) as name,
      coalesce(address_snapshot->>'phone', '') as phone,
      coalesce(address_snapshot->>'email', '') as email,
      coalesce(address_snapshot->>'city', '') as city,
      coalesce(address_snapshot->>'address', '') as address,
      address_snapshot as "addressSnapshot",
      service_name as "serviceType",
      booking_date::text as date,
      time_slot as slot,
      status,
      created_at as "createdAt",
      confirmed_at as "confirmedAt"
    from bookings
    order by created_at desc
  `)

  return result.rows
}

async function updateAdminBookingStatus(getPool, bookingId, payload) {
  const status = toText(payload?.status, 'scheduled')
  const result = await getPool().query(
    `
      update bookings
      set
        status = $2,
        confirmed_at = case
          when $2 = 'confirmed' then coalesce(confirmed_at, now())
          else confirmed_at
        end,
        updated_at = now()
      where id = $1::bigint
      returning id::text as id
    `,
    [bookingId, status],
  )

  return result.rowCount === 0 ? null : result.rows[0]
}

async function fetchAdminFeedback(getPool) {
  const result = await getPool().query(`
    select
      id::text as "docId",
      id::text as id,
      customer_name as "customerName",
      phone,
      order_id as "orderId",
      message,
      rating,
      status,
      admin_response as "adminResponse",
      created_at as "createdAt"
    from feedback
    order by created_at desc
  `)

  return result.rows
}

async function updateAdminFeedbackStatus(getPool, feedbackId, payload) {
  const status = toText(payload?.status, 'open')
  const updatedBy = toText(payload?.updatedBy || payload?.adminName)
  const result = await getPool().query(
    `
      update feedback
      set
        status = $2,
        updated_by = $3,
        resolved_at = case
          when $2 = 'resolved' then coalesce(resolved_at, now())
          else resolved_at
        end,
        updated_at = now()
      where id = $1::bigint
      returning id::text as id
    `,
    [feedbackId, status, updatedBy],
  )

  return result.rowCount === 0 ? null : result.rows[0]
}

async function updateAdminFeedbackResponse(getPool, feedbackId, payload) {
  const adminResponse = toText(payload?.response || payload?.adminResponse)
  const updatedBy = toText(payload?.updatedBy || payload?.adminName)
  const result = await getPool().query(
    `
      update feedback
      set
        admin_response = $2,
        responded_by = $3,
        responded_at = now(),
        updated_by = $3,
        updated_at = now()
      where id = $1::bigint
      returning id::text as id
    `,
    [feedbackId, adminResponse, updatedBy],
  )

  return result.rowCount === 0 ? null : result.rows[0]
}

async function createAdminFeedback(getPool, payload) {
  const customerName = toText(payload?.customerName)
  const phone = toText(payload?.phone)
  const message = toText(payload?.message)
  const rating = toNumber(payload?.rating, 0)
  const adminName = toText(payload?.adminName)

  if (!customerName || !phone || !message) {
    return null
  }

  const result = await getPool().query(
    `
      insert into feedback (
        customer_name,
        phone,
        email,
        message,
        source,
        status,
        rating,
        user_id,
        created_by,
        updated_by
      )
      values ($1, $2, '', $3, 'admin_manual', 'open', $4, '', $5, $5)
      returning id::text as id, created_at as "createdAt"
    `,
    [customerName, phone, message, rating, adminName],
  )

  return result.rows[0]
}

async function fetchAdminBusinessSettings(getPool) {
  const result = await getPool().query(`
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
  `)

  return result.rows[0] || null
}

async function saveAdminBusinessSettings(getPool, payload) {
  const result = await getPool().query(
    `
      update business_settings
      set
        company_name = $1,
        support_phone = $2,
        support_email = $3,
        locality = $4,
        address_line1 = $5,
        address_line2 = $6,
        address_line3 = $7,
        gstin = $8,
        updated_at = now()
      where id = 1
      returning
        company_name as "companyName",
        support_phone as "supportPhone",
        support_email as "supportEmail",
        locality,
        address_line1 as "addressLine1",
        address_line2 as "addressLine2",
        address_line3 as "addressLine3",
        gstin
    `,
    [
      toText(payload?.companyName, 'A1 Water Tech'),
      toText(payload?.supportPhone),
      toText(payload?.supportEmail),
      toText(payload?.locality),
      toText(payload?.addressLine1),
      toText(payload?.addressLine2),
      toText(payload?.addressLine3),
      toText(payload?.gstin),
    ],
  )

  return result.rows[0] || null
}

async function fetchAdminBillingSettings(getPool) {
  const result = await getPool().query(`
    select
      company_name as "companyName",
      support_phone as "supportPhone",
      invoice_prefix as "invoicePrefix",
      gst_rate as "gstRate",
      gst_enabled as "gstEnabled"
    from billing_settings
    where id = 1
    limit 1
  `)

  return result.rows[0] || null
}

async function saveAdminBillingSettings(getPool, payload) {
  const result = await getPool().query(
    `
      update billing_settings
      set
        company_name = $1,
        support_phone = $2,
        invoice_prefix = $3,
        gst_rate = $4,
        gst_enabled = $5,
        updated_at = now()
      where id = 1
      returning
        company_name as "companyName",
        support_phone as "supportPhone",
        invoice_prefix as "invoicePrefix",
        gst_rate as "gstRate",
        gst_enabled as "gstEnabled"
    `,
    [
      toText(payload?.companyName, 'A1 Water Tech'),
      toText(payload?.supportPhone),
      toText(payload?.invoicePrefix, 'BILL').toUpperCase(),
      toNumber(payload?.gstRate, 0),
      toBoolean(payload?.gstEnabled),
    ],
  )

  return result.rows[0] || null
}

async function fetchAdminAnnouncements(getPool) {
  const result = await getPool().query(`
    select
      id,
      id as "docId",
      title,
      message,
      is_active as "isActive",
      is_pinned as "isPinned",
      created_at as "createdAt"
    from announcements
    order by is_pinned desc, created_at desc
  `)

  return result.rows
}

async function upsertAdminAnnouncement(getPool, payload) {
  const docId = toText(payload?.docId || payload?.id, randomUUID())
  const exists = await getPool().query(
    `select id from announcements where id = $1 limit 1`,
    [docId],
  )

  if (exists.rowCount === 0) {
    await getPool().query(
      `
        insert into announcements (
          id,
          title,
          message,
          is_active,
          is_pinned
        )
        values ($1, $2, $3, $4, $5)
      `,
      [
        docId,
        toText(payload?.title, 'Announcement'),
        toText(payload?.message),
        toBoolean(payload?.isActive),
        toBoolean(payload?.isPinned),
      ],
    )
  } else {
    await getPool().query(
      `
        update announcements
        set
          title = $2,
          message = $3,
          is_active = $4,
          is_pinned = $5,
          updated_at = now()
        where id = $1
      `,
      [
        docId,
        toText(payload?.title, 'Announcement'),
        toText(payload?.message),
        toBoolean(payload?.isActive),
        toBoolean(payload?.isPinned),
      ],
    )
  }

  return { id: docId, docId }
}

async function deleteAdminAnnouncement(getPool, docId) {
  await getPool().query(`delete from announcements where id = $1`, [docId])
  return { id: docId }
}

async function fetchAdminCatalog(getPool, collection) {
  if (collection === 'products') {
    const result = await getPool().query(`
      select
        id,
        id as "docId",
        name,
        description,
        price,
        image_url as "imageUrl"
      from products
      order by updated_at desc, name asc
    `)
    return result.rows
  }

  if (collection === 'services') {
    const result = await getPool().query(`
      select
        id,
        id as "docId",
        name,
        description,
        price,
        image_url as "imageUrl"
      from services
      order by updated_at desc, name asc
    `)
    return result.rows
  }

  return null
}

async function upsertAdminCatalogItem(getPool, collection, payload) {
  const name = toText(payload?.name, 'Unnamed')
  const description = toText(payload?.description)
  const price = toNumber(payload?.price, 0)
  const imageUrl = toText(payload?.imageUrl)
  const requestedId = toText(payload?.docId || payload?.id)
  const finalId = requestedId || slugify(name)

  if (collection === 'products') {
    const existing = await getPool().query(
      `select category from products where id = $1 limit 1`,
      [finalId],
    )
    const category =
        toText(payload?.category) ||
        toText(existing.rows[0]?.category, 'Purifiers')

    await getPool().query(
      `
        insert into products (
          id,
          name,
          category,
          image_url,
          price,
          description
        )
        values ($1, $2, $3, $4, $5, $6)
        on conflict (id)
        do update set
          name = excluded.name,
          category = excluded.category,
          image_url = excluded.image_url,
          price = excluded.price,
          description = excluded.description,
          updated_at = now()
      `,
      [finalId, name, category, imageUrl, price, description],
    )
    return { id: finalId, docId: finalId }
  }

  if (collection === 'services') {
    const existing = await getPool().query(
      `select duration from services where id = $1 limit 1`,
      [finalId],
    )
    const duration =
        toText(payload?.duration) ||
        toText(existing.rows[0]?.duration, 'Per Visit')

    await getPool().query(
      `
        insert into services (
          id,
          name,
          image_url,
          price,
          duration,
          description
        )
        values ($1, $2, $3, $4, $5, $6)
        on conflict (id)
        do update set
          name = excluded.name,
          image_url = excluded.image_url,
          price = excluded.price,
          duration = excluded.duration,
          description = excluded.description,
          updated_at = now()
      `,
      [finalId, name, imageUrl, price, duration, description],
    )
    return { id: finalId, docId: finalId }
  }

  return null
}

async function fetchAdminBills(getPool, limitValue) {
  const limit = toNumber(limitValue, 0)
  const sql = `
    select
      id::text as "docId",
      id::text as id,
      bill_number as "billNumber",
      source,
      customer,
      total,
      status,
      created_at as "createdAt"
    from bills
    order by created_at desc
    ${limit > 0 ? `limit ${Math.max(1, Math.min(limit, 200))}` : ''}
  `
  const result = await getPool().query(sql)
  return result.rows
}

async function fetchAdminBill(getPool, billId) {
  const result = await getPool().query(
    `
      select
        id::text as "docId",
        id::text as id,
        bill_number as "billNumber",
        source,
        source_order_doc_id as "sourceOrderDocId",
        source_order_id as "sourceOrderId",
        user_id as "userId",
        customer,
        items,
        subtotal,
        billing,
        total,
        status,
        company_name as "companyName",
        support_phone as "supportPhone",
        created_at as "createdAt",
        confirmed_at as "confirmedAt",
        updated_at as "updatedAt"
      from bills
      where id = $1::bigint
      limit 1
    `,
    [billId],
  )

  return result.rows[0] || null
}

async function createAdminBill(getPool, payload) {
  const config = payload?.config && typeof payload.config === 'object' ? payload.config : {}
  const source = toText(payload?.source, 'manual')
  const sourceOrderDocId = toText(payload?.sourceOrderDocId)
  const sourceOrderId = toText(payload?.sourceOrderId)
  const userId = toText(payload?.userId)
  const customer = payload?.customer && typeof payload.customer === 'object' ? payload.customer : {}
  const items = Array.isArray(payload?.items) ? payload.items : []
  const generatedBy = toText(payload?.generatedBy)
  const companyName = toText(config.companyName, 'A1 Water Tech')
  const supportPhone = toText(config.supportPhone)
  const prefix = toText(config.invoicePrefix, 'BILL').toUpperCase()
  const gstEnabled = toBoolean(config.gstEnabled)
  const gstRate = gstEnabled ? toNumber(config.gstRate, 0) : 0
  const subtotal = items.reduce((sum, raw) => {
    const item = raw && typeof raw === 'object' ? raw : {}
    return sum + toNumber(item.qty, 1) * toNumber(item.price, 0)
  }, 0)
  const gstAmount = subtotal * gstRate
  const total = subtotal + gstAmount
  const now = new Date()
  const billNumber =
    `${prefix}-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}-${String(now.getHours()).padStart(2, '0')}${String(now.getMinutes()).padStart(2, '0')}${String(now.getSeconds()).padStart(2, '0')}`

  const result = await getPool().query(
    `
      insert into bills (
        bill_number,
        source,
        source_order_doc_id,
        source_order_id,
        user_id,
        customer,
        items,
        subtotal,
        billing,
        total,
        status,
        generated_by,
        updated_by,
        company_name,
        support_phone,
        confirmed_at
      )
      values ($1, $2, $3, $4, $5, $6::jsonb, $7::jsonb, $8, $9::jsonb, $10, 'confirmed', $11, $11, $12, $13, now())
      returning id::text as id, id::text as "docId", bill_number as "billNumber"
    `,
    [
      billNumber,
      source,
      sourceOrderDocId,
      sourceOrderId,
      userId,
      JSON.stringify(customer),
      JSON.stringify(items),
      subtotal,
      JSON.stringify({ gstRate, gstAmount }),
      total,
      generatedBy,
      companyName,
      supportPhone,
    ],
  )

  if (source === 'automatic' && sourceOrderDocId) {
    await getPool().query(
      `
        update orders
        set
          status = 'billed',
          bill_number = $2,
          bill_id = $3,
          billed_at = now(),
          updated_at = now()
        where id = $1::bigint
      `,
      [sourceOrderDocId, billNumber, result.rows[0].id],
    )
  }

  return result.rows[0]
}

async function updateAdminBill(getPool, billId, payload) {
  const customer = payload?.customer && typeof payload.customer === 'object' ? payload.customer : {}
  const items = Array.isArray(payload?.items) ? payload.items : []
  const subtotal = toNumber(payload?.subtotal, 0)
  const billing = payload?.billing && typeof payload.billing === 'object' ? payload.billing : {}
  const total = toNumber(payload?.total, 0)
  const status = toText(payload?.status, 'confirmed')
  const updatedBy = toText(payload?.updatedBy || payload?.adminName)
  const userId = toText(payload?.userId)

  const result = await getPool().query(
    `
      update bills
      set
        customer = $2::jsonb,
        items = $3::jsonb,
        subtotal = $4,
        billing = $5::jsonb,
        total = $6,
        status = $7,
        user_id = case when $8 = '' then user_id else $8 end,
        updated_by = $9,
        updated_at = now()
      where id = $1::bigint
      returning id::text as id
    `,
    [
      billId,
      JSON.stringify(customer),
      JSON.stringify(items),
      subtotal,
      JSON.stringify(billing),
      total,
      status,
      userId,
      updatedBy,
    ],
  )

  return result.rowCount === 0 ? null : result.rows[0]
}

async function fetchAdminMetrics(getPool, daysValue) {
  const days = Math.max(1, toNumber(daysValue, 30))
  const since = new Date()
  since.setDate(since.getDate() - days)

  const [
    ordersCount,
    billsCount,
    bookingsCount,
    pendingOrders,
    activeProducts,
    activeServices,
    openFeedback,
    allBills,
    rangeBills,
    confirmedOrders,
    confirmedOrdersInRange,
  ] = await Promise.all([
    getPool().query(`select count(*)::int as count from orders`),
    getPool().query(`select count(*)::int as count from bills`),
    getPool().query(`select count(*)::int as count from bookings`),
    getPool().query(`select count(*)::int as count from orders where status = 'pending'`),
    getPool().query(`select count(*)::int as count from products where is_active = true`),
    getPool().query(`select count(*)::int as count from services where is_active = true`),
    getPool().query(`select count(*)::int as count from feedback where status = 'open'`),
    getPool().query(`select total, items, created_at as "createdAt" from bills`),
    getPool().query(
      `select total, items, created_at as "createdAt" from bills where created_at >= $1`,
      [since],
    ),
    getPool().query(`
      select total, items, created_at as "createdAt"
      from orders
      where status = 'confirmed'
        and coalesce(bill_number, '') = ''
        and coalesce(bill_id::text, '') = ''
    `),
    getPool().query(
      `
        select total, items, created_at as "createdAt"
        from orders
        where status = 'confirmed'
          and coalesce(bill_number, '') = ''
          and coalesce(bill_id::text, '') = ''
          and created_at >= $1
      `,
      [since],
    ),
  ])

  const allSalesRows = [...allBills.rows, ...confirmedOrders.rows]
  const rangeSalesRows = [...rangeBills.rows, ...confirmedOrdersInRange.rows]

  const totalRevenue = allSalesRows.reduce((sum, row) => sum + toNumber(row.total), 0)
  const revenueInRange = rangeSalesRows.reduce((sum, row) => sum + toNumber(row.total), 0)

  return {
    ordersCount: ordersCount.rows[0]?.count || 0,
    billsCount: billsCount.rows[0]?.count || 0,
    billsInRange: rangeBills.rows.length,
    salesCount: allSalesRows.length,
    salesCountInRange: rangeSalesRows.length,
    bookingsCount: bookingsCount.rows[0]?.count || 0,
    pendingOrders: pendingOrders.rows[0]?.count || 0,
    activeProducts: activeProducts.rows[0]?.count || 0,
    activeServices: activeServices.rows[0]?.count || 0,
    openFeedbackCount: openFeedback.rows[0]?.count || 0,
    totalRevenue,
    revenueInRange,
    topItems: mapTopItems(rangeSalesRows).slice(0, 10),
    dailyRevenue: mapDailyRevenue(rangeSalesRows, days),
  }
}

export async function handleAdminRoute({
  method,
  path,
  event,
  getPool,
  response,
  parseJsonBody,
  getQueryValue,
  getPathId,
}) {
  if (!path.includes('/admin/')) {
    return null
  }

  if (method === 'POST' && path.endsWith('/admin/session')) {
    const result = await authorizeAdminSession(getPool, parseJsonBody(event?.body))
    if (!result.ok) {
      return response(result.code, { message: result.message })
    }
    return response(200, { item: result.item, ok: true })
  }

  if (method === 'GET' && path.endsWith('/admin/orders')) {
    return response(200, { items: await fetchAdminOrders(getPool) })
  }

  if (method === 'PUT' && path.includes('/admin/orders/') && path.endsWith('/status')) {
    const item = await updateAdminOrderStatus(
      getPool,
      getPathId(path, '/admin/orders/'),
      parseJsonBody(event?.body),
    )
    return item
      ? response(200, { item, ok: true })
      : response(404, { message: 'Order not found' })
  }

  if (method === 'GET' && path.endsWith('/admin/bookings')) {
    return response(200, { items: await fetchAdminBookings(getPool) })
  }

  if (method === 'PUT' && path.includes('/admin/bookings/') && path.endsWith('/status')) {
    const item = await updateAdminBookingStatus(
      getPool,
      getPathId(path, '/admin/bookings/'),
      parseJsonBody(event?.body),
    )
    return item
      ? response(200, { item, ok: true })
      : response(404, { message: 'Booking not found' })
  }

  if (method === 'GET' && path.endsWith('/admin/feedback')) {
    return response(200, { items: await fetchAdminFeedback(getPool) })
  }

  if (method === 'PUT' && path.includes('/admin/feedback/') && path.endsWith('/status')) {
    const item = await updateAdminFeedbackStatus(
      getPool,
      getPathId(path, '/admin/feedback/'),
      parseJsonBody(event?.body),
    )
    return item
      ? response(200, { item, ok: true })
      : response(404, { message: 'Feedback not found' })
  }

  if (method === 'PUT' && path.includes('/admin/feedback/') && path.endsWith('/response')) {
    const item = await updateAdminFeedbackResponse(
      getPool,
      getPathId(path, '/admin/feedback/'),
      parseJsonBody(event?.body),
    )
    return item
      ? response(200, { item, ok: true })
      : response(404, { message: 'Feedback not found' })
  }

  if (method === 'POST' && path.endsWith('/admin/feedback')) {
    const item = await createAdminFeedback(getPool, parseJsonBody(event?.body))
    return item
      ? response(201, { item, ok: true })
      : response(400, { message: 'customerName, phone, and message are required' })
  }

  if (method === 'GET' && path.endsWith('/admin/settings/business')) {
    return response(200, { item: await fetchAdminBusinessSettings(getPool) })
  }

  if (method === 'PUT' && path.endsWith('/admin/settings/business')) {
    return response(200, {
      item: await saveAdminBusinessSettings(getPool, parseJsonBody(event?.body)),
      ok: true,
    })
  }

  if (method === 'GET' && path.endsWith('/admin/settings/billing')) {
    return response(200, { item: await fetchAdminBillingSettings(getPool) })
  }

  if (method === 'PUT' && path.endsWith('/admin/settings/billing')) {
    return response(200, {
      item: await saveAdminBillingSettings(getPool, parseJsonBody(event?.body)),
      ok: true,
    })
  }

  if (method === 'GET' && path.endsWith('/admin/announcements')) {
    return response(200, { items: await fetchAdminAnnouncements(getPool) })
  }

  if (method === 'POST' && path.endsWith('/admin/announcements')) {
    return response(200, {
      item: await upsertAdminAnnouncement(getPool, parseJsonBody(event?.body)),
      ok: true,
    })
  }

  if (method === 'DELETE' && path.includes('/admin/announcements/')) {
    return response(200, {
      item: await deleteAdminAnnouncement(
        getPool,
        getPathId(path, '/admin/announcements/'),
      ),
      ok: true,
    })
  }

  if (method === 'GET' && path.includes('/admin/catalog/')) {
    const collection = getPathId(path, '/admin/catalog/')
    const items = await fetchAdminCatalog(getPool, collection)
    return items
      ? response(200, { items })
      : response(404, { message: 'Catalog collection not found' })
  }

  if (method === 'POST' && path.includes('/admin/catalog/')) {
    const collection = getPathId(path, '/admin/catalog/')
    const item = await upsertAdminCatalogItem(
      getPool,
      collection,
      parseJsonBody(event?.body),
    )
    return item
      ? response(200, { item, ok: true })
      : response(404, { message: 'Catalog collection not found' })
  }

  if (method === 'GET' && path.endsWith('/admin/bills')) {
    return response(200, {
      items: await fetchAdminBills(getPool, getQueryValue(event, 'limit')),
    })
  }

  if (method === 'GET' && path.includes('/admin/bills/')) {
    const item = await fetchAdminBill(
      getPool,
      getPathId(path, '/admin/bills/'),
    )
    return item
      ? response(200, { item })
      : response(404, { message: 'Bill not found' })
  }

  if (method === 'POST' && path.endsWith('/admin/bills')) {
    return response(201, {
      item: await createAdminBill(getPool, parseJsonBody(event?.body)),
      ok: true,
    })
  }

  if (method === 'PUT' && path.includes('/admin/bills/')) {
    const item = await updateAdminBill(
      getPool,
      getPathId(path, '/admin/bills/'),
      parseJsonBody(event?.body),
    )
    return item
      ? response(200, { item, ok: true })
      : response(404, { message: 'Bill not found' })
  }

  if (method === 'GET' && path.endsWith('/admin/metrics')) {
    return response(200, {
      item: await fetchAdminMetrics(getPool, getQueryValue(event, 'days')),
    })
  }

  return response(404, {
    message: 'Not Found',
    method,
    path,
  })
}

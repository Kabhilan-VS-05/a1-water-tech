/**
 * Known public images that map product/service names to local files.
 * These files live in /public and are served at the root path.
 * All paths are encodeURI'd to handle spaces in filenames.
 */
const PUBLIC_PRODUCT_IMAGES = {
  'a1 aquashield ro':       encodeURI('/A1 AquaShield RO.png'),
  'aquashield':             encodeURI('/A1 AquaShield RO.png'),
  'a1 commercial ro':       encodeURI('/A1 Commercial RO 50L.png'),
  'commercial ro':          encodeURI('/A1 Commercial RO 50L.png'),
  '50l':                    encodeURI('/A1 Commercial RO 50L.png'),
  'a1 copper guard':        encodeURI('/A1 Copper Guard Pro.png'),
  'copper guard':           encodeURI('/A1 Copper Guard Pro.png'),
  'a1 mineral':             encodeURI('/A1 Mineral+ Cartridge.png'),
  'mineral+':               encodeURI('/A1 Mineral+ Cartridge.png'),
  'mineral':                encodeURI('/A1 Mineral+ Cartridge.png'),
  'a1 pureflow':            encodeURI('/A1 PureFlow RO + UV.png'),
  'pureflow':               encodeURI('/A1 PureFlow RO + UV.png'),
  'under sink':             encodeURI('/A1 PureFlow RO + UV.png'),
  'undersink':              encodeURI('/A1 PureFlow RO + UV.png'),
  'a1 ro membrane':         encodeURI('/A1 RO Membrane Kit.png'),
  'ro membrane':            encodeURI('/A1 RO Membrane Kit.png'),
  'membrane':               encodeURI('/A1 RO Membrane Kit.png'),
  'a1 sediment':            encodeURI('/A1 Sediment Guard.png'),
  'sediment':               encodeURI('/A1 Sediment Guard.png'),
  'wound':                  encodeURI('/Filters.png'),
  'wound filter':           encodeURI('/Filters.png'),
  'pre-carbon':             encodeURI('/Filters.png'),
  'carbon':                 encodeURI('/Filters.png'),
  'smart water dispenser':  encodeURI('/Smart Water Dispenser.png'),
  'dispenser':              encodeURI('/Smart Water Dispenser.png'),
  'uv compact':             encodeURI('/UV Compact.png'),
  'a1 alkaline max':        encodeURI('/Purifiers Explore.png'),
  'alkaline':               encodeURI('/Purifiers Explore.png'),
}

const PUBLIC_SERVICE_IMAGES = {
  'servicecare':   encodeURI('/ServiceCare Annual.png'),
  'annual':        encodeURI('/ServiceCare Annual.png'),
  'maintenance':   encodeURI('/Services.png'),
  'service':       encodeURI('/Services.png'),
  'installation':  encodeURI('/Services.png'),
  'repair':        encodeURI('/Services.png'),
  'clean':         encodeURI('/Services.png'),
  'quality':       encodeURI('/Services.png'),
}

const CATEGORY_FALLBACKS = {
  purifier:     encodeURI('/Purifiers Explore.png'),
  commercial:   encodeURI('/Commercial.png'),
  filter:       encodeURI('/Filters.png'),
  accessor:     encodeURI('/Accessories.png'),
  service:      encodeURI('/Services.png'),
}

const FALLBACK_PRODUCT  = encodeURI('/Purifiers Explore.png')
const FALLBACK_SERVICE  = encodeURI('/Services.png')

export function getProductImage(product) {
  const urlVal = product?.imageUrl || product?.image_url || product?.image
  if (urlVal && typeof urlVal === 'string' && urlVal.trim().length > 0) {
    const trimmed = urlVal.trim()
    if (!trimmed.includes('sample-product')) {
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return trimmed
      }
      try {
        return decodeURIComponent(trimmed)
      } catch (e) {
        return trimmed
      }
    }
  }

  const nameLower     = (product?.name     || '').toLowerCase().trim()
  const categoryLower = (product?.category || '').toLowerCase().trim()

  // If category is service, use service resolver
  if (categoryLower.includes('service')) {
    return getServiceImage(product)
  }

  // 2. Exact or strict inclusive match for local premium catalog images
  for (const [key, path] of Object.entries(PUBLIC_PRODUCT_IMAGES)) {
    if (nameLower.includes(key)) {
      return path
    }
  }

  // 3. Fallback to category standard assets
  for (const [key, path] of Object.entries(CATEGORY_FALLBACKS)) {
    if (categoryLower.includes(key)) return path
  }

  // 4. If name has filter-related words
  if (nameLower.includes('filter') || nameLower.includes('cartridge') || nameLower.includes('candle')) {
    return encodeURI('/Filters.png')
  }

  return FALLBACK_PRODUCT
}

/**
 * Resolves the best available image URL for a service.
 */
export function getServiceImage(service) {
  const urlVal = service?.imageUrl || service?.image_url || service?.image
  if (urlVal && typeof urlVal === 'string' && urlVal.trim().length > 0) {
    const trimmed = urlVal.trim()
    if (!trimmed.includes('sample-product')) {
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return trimmed
      }
      try {
        return decodeURIComponent(trimmed)
      } catch (e) {
        return trimmed
      }
    }
  }

  const nameLower = (service?.name || '').toLowerCase().trim()

  for (const [key, path] of Object.entries(PUBLIC_SERVICE_IMAGES)) {
    if (nameLower.includes(key)) return path
  }

  return FALLBACK_SERVICE
}

/**
 * onError handler — prevents infinite loops, falls back to a known-good local image.
 */
export function handleImageError(event, type = 'product') {
  event.currentTarget.onerror = null
  if (type === 'service') {
    event.currentTarget.src = FALLBACK_SERVICE
  } else if (type === 'filter' || event.currentTarget.alt?.toLowerCase().includes('filter')) {
    event.currentTarget.src = encodeURI('/Filters.png')
  } else {
    event.currentTarget.src = FALLBACK_PRODUCT
  }
}

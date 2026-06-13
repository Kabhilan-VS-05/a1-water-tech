-- Migration script to add HSN field and update business settings

ALTER TABLE products
ADD COLUMN IF NOT EXISTS hsn text not null default '';

ALTER TABLE services
ADD COLUMN IF NOT EXISTS hsn text not null default '';

UPDATE business_settings
SET 
  locality = 'Gobichettipalayam',
  address_line1 = '3/185/4 Bagavathi Nagar',
  address_line2 = 'Kanakappalayam',
  address_line3 = 'Erode-638505',
  gstin = '33CWHPJ8901N1Z6',
  updated_at = now()
WHERE id = 1;

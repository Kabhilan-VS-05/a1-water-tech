import { createContext, useContext, useEffect, useMemo, useState } from 'react'
import {
  DEFAULT_BILLING_SETTINGS,
  DEFAULT_BUSINESS_PROFILE,
} from '../config/company.js'

const SiteSettingsContext = createContext({
  ...DEFAULT_BUSINESS_PROFILE,
  ...DEFAULT_BILLING_SETTINGS,
  name: DEFAULT_BUSINESS_PROFILE.companyName,
  phonePrimary: DEFAULT_BUSINESS_PROFILE.supportPhone,
  phoneSecondary: DEFAULT_BUSINESS_PROFILE.supportPhone,
  emailPrimary: DEFAULT_BUSINESS_PROFILE.supportEmail,
  emailSecondary: DEFAULT_BUSINESS_PROFILE.supportEmail,
  loading: true,
})

export function SiteSettingsProvider({ children }) {
  const [businessProfile, setBusinessProfile] = useState(DEFAULT_BUSINESS_PROFILE)
  const [billingSettings, setBillingSettings] = useState(DEFAULT_BILLING_SETTINGS)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let active = true

    async function loadSettings() {
      try {
        const baseUrl = import.meta.env.VITE_API_BASE_URL
        if (!baseUrl) {
          throw new Error('Missing VITE_API_BASE_URL')
        }

        const [businessResponse, billingResponse] = await Promise.all([
          fetch(`${baseUrl}/settings/business`),
          fetch(`${baseUrl}/settings/billing`),
        ])

        if (!businessResponse.ok || !billingResponse.ok) {
          throw new Error('Settings request failed')
        }

        const businessPayload = await businessResponse.json()
        const billingPayload = await billingResponse.json()

        if (!active) {
          return
        }

        if (businessPayload?.item) {
          const data = businessPayload.item
          setBusinessProfile((prev) => ({
            ...prev,
            companyName: data.companyName || prev.companyName,
            supportPhone: data.supportPhone || prev.supportPhone,
            supportEmail: data.supportEmail || prev.supportEmail,
            locality: data.locality || prev.locality,
            addressLine1: data.addressLine1 || prev.addressLine1,
            addressLine2: data.addressLine2 || prev.addressLine2,
            addressLine3: data.addressLine3 || prev.addressLine3,
            gstin: data.gstin || prev.gstin,
          }))
        }

        if (billingPayload?.item) {
          const data = billingPayload.item
          setBillingSettings({
            invoicePrefix:
              data.invoicePrefix || DEFAULT_BILLING_SETTINGS.invoicePrefix,
            gstRate:
              typeof data.gstRate === 'number'
                ? data.gstRate
                : DEFAULT_BILLING_SETTINGS.gstRate,
            gstEnabled: data.gstEnabled === true,
          })
        }

        setLoading(false)
      } catch {
        if (active) {
          setLoading(false)
        }
      }
    }

    loadSettings()

    return () => {
      active = false
    }
  }, [])

  const value = useMemo(
    () => ({
      ...businessProfile,
      ...billingSettings,
      name: businessProfile.companyName,
      phonePrimary: businessProfile.supportPhone,
      phoneSecondary: businessProfile.supportPhone,
      emailPrimary: businessProfile.supportEmail,
      emailSecondary: businessProfile.supportEmail,
      loading,
    }),
    [billingSettings, businessProfile, loading],
  )

  return (
    <SiteSettingsContext.Provider value={value}>
      {children}
    </SiteSettingsContext.Provider>
  )
}

export function useSiteSettings() {
  return useContext(SiteSettingsContext)
}

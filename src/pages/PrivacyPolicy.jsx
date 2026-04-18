import PageHeader from '../components/PageHeader.jsx'
import { COMPANY } from '../config/company.js'

export default function PrivacyPolicy() {
  return (
    <div className="container mx-auto px-4 py-12 max-w-5xl font-sans text-slate-900">
      <PageHeader
        eyebrow="Legal"
        title="Privacy Policy"
        subtitle="How A1 Water Tech collects, uses, and protects your data."
      />

      <div className="mt-8 bg-white border border-slate-100 rounded-2xl p-6 md:p-8 space-y-6 text-sm leading-7 text-slate-700">
        <section>
          <h2 className="text-lg font-bold text-slate-900 mb-2">1. Information We Collect</h2>
          <p>
            We collect basic profile, order, address, and booking information needed to process purchases and provide support.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-slate-900 mb-2">2. How We Use Data</h2>
          <p>
            Data is used for order fulfillment, service scheduling, billing, and customer communication.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-slate-900 mb-2">3. Data Security</h2>
          <p>
            We use authenticated access controls and cloud security practices to protect account and transaction data.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-slate-900 mb-2">4. Data Sharing</h2>
          <p>
            We do not sell personal data. Information is shared only when needed for service delivery, legal compliance, or payment processing.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-slate-900 mb-2">5. Contact</h2>
          <p>
            For privacy requests, contact <span className="font-semibold">{COMPANY.emailPrimary}</span>.
          </p>
        </section>
      </div>
    </div>
  )
}

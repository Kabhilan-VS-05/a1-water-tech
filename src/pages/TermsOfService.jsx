import PageHeader from '../components/PageHeader.jsx'
import { COMPANY } from '../config/company.js'

export default function TermsOfService() {
  return (
    <div className="container mx-auto px-4 py-12 max-w-5xl font-sans text-slate-900">
      <PageHeader
        eyebrow="Legal"
        title="Terms of Service"
        subtitle="Please review the terms that govern your use of A1 Water Tech services."
      />

      <div className="mt-8 bg-white border border-slate-100 rounded-2xl p-6 md:p-8 space-y-6 text-sm leading-7 text-slate-700">
        <section>
          <h2 className="text-lg font-bold text-slate-900 mb-2">1. Use of Services</h2>
          <p>
            By placing orders or booking services through this website, you agree to provide accurate details and comply with applicable laws.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-slate-900 mb-2">2. Pricing and Billing</h2>
          <p>
            Prices shown are inclusive of applicable taxes unless stated otherwise. Final billing details are shown at checkout and in your invoice.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-slate-900 mb-2">3. Orders and Cancellations</h2>
          <p>
            Orders and service requests are subject to availability and operational confirmation. Cancellation and rescheduling may be limited once processing starts.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-slate-900 mb-2">4. Warranty and Service Scope</h2>
          <p>
            Product warranty and service-plan coverage depend on the selected model/plan and the terms specified at purchase time.
          </p>
        </section>

        <section>
          <h2 className="text-lg font-bold text-slate-900 mb-2">5. Contact</h2>
          <p>
            For legal or billing clarifications, contact support at <span className="font-semibold">{COMPANY.emailPrimary}</span>.
          </p>
        </section>
      </div>
    </div>
  )
}

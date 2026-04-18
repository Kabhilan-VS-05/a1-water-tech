const servicePlans = [
  {
    id: 'install-standard',
    name: 'Standard Installation',
    imageUrl: '/Services.png',
    price: 499,
    duration: 'Within 24 hours',
    description: 'Certified installation with pipe fitting and water test.',
  },
  {
    id: 'service-annual',
    name: 'ServiceCare Annual',
    imageUrl: '/ServiceCare%20Annual.png',
    price: 2499,
    duration: '12 months',
    description: 'Quarterly visits, filter checks, and priority support.',
  },
  {
    id: 'service-premium',
    name: 'ServiceCare Premium',
    imageUrl: '/Services.png',
    price: 3999,
    duration: '12 months',
    description: 'Includes spare filters and emergency callouts.',
  },
  {
    id: 'service-emergency-visit',
    name: 'Emergency Visit',
    imageUrl: '/Services.png',
    price: 899,
    duration: 'Same day',
    description: 'Fast technician dispatch for urgent purifier breakdowns.',
  },
]

const faqs = [
  {
    q: 'Do you offer free water testing?',
    a: 'Yes. We provide a free in-home TDS and hardness test in select areas.',
  },
  {
    q: 'How quickly can you install a purifier?',
    a: 'Most installations are scheduled within 24 hours after order confirmation.',
  },
  {
    q: 'Is GST included in the listed price?',
    a: 'Yes. All listed prices include GST. The invoice will show the breakup.',
  },
  {
    q: 'What payment methods are supported?',
    a: 'UPI, card, netbanking, and EMI options on select products.',
  },
]

export { servicePlans, faqs }


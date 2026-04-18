const formatter = new Intl.NumberFormat('en-IN')

export const formatCurrency = (value) => `Rs ${formatter.format(value)}`

export const createOrderId = () => {
  const stamp = Date.now().toString().slice(-6)
  const rand = Math.floor(Math.random() * 900 + 100)
  return `A1-${stamp}-${rand}`
}

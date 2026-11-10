export class ReportFormatterFactory {
  static create(type, { locale = "es-ES", currency = "USD" } = {}) {
    const options = {
      currency: { style: "currency", currency },
      number: { maximumFractionDigits: 2 },
      percent: { style: "percent", maximumFractionDigits: 2 },
    }[type];

    if (!options) {
      throw new Error(`Formato desconocido: ${type}`);
    }
    return new Intl.NumberFormat(locale, options);
  }
}

export function getStockStatus({ stock, minStock }) {
  if (stock <= 0) return "out_of_stock";
  if (stock <= minStock) return "low_stock";
  return "healthy";
}

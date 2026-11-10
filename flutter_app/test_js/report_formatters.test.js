import test from "node:test";
import assert from "node:assert/strict";

import {
  getStockStatus,
  ReportFormatterFactory,
} from "../web/js/report_formatters.js";

test("ReportFormatterFactory crea formateadores de moneda y porcentaje", () => {
  const currency = ReportFormatterFactory.create("currency");
  const percent = ReportFormatterFactory.create("percent");

  assert.match(currency.format(12.5), /12[,.]50/);
  assert.match(percent.format(0.125), /12[,.]5/);
});

test("ReportFormatterFactory rechaza formatos desconocidos", () => {
  assert.throws(() => ReportFormatterFactory.create("date"), /Formato desconocido/);
});

test("getStockStatus clasifica las existencias", () => {
  assert.equal(getStockStatus({ stock: 0, minStock: 2 }), "out_of_stock");
  assert.equal(getStockStatus({ stock: 2, minStock: 2 }), "low_stock");
  assert.equal(getStockStatus({ stock: 3, minStock: 2 }), "healthy");
});

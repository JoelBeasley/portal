import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  computeMachineScales,
  computeScaleFactor,
  computeWeightedEfficiency,
  computeDayRow,
  computeTableRows,
} from "../../app/javascript/site_analytics/calculator.js";

const SAMPLE_HR = [
  { hash_rate_24h: 11883780.516365379, date: 1774915200 },
  { hash_rate_24h: 13999310.880266042, date: 1775001600 },
];

const SAMPLE_REWARDS = [
  { date: 1774915200, total_reward: "0.00555833" },
  { date: 1775001600, total_reward: "0.00652924" },
];

const DEFAULTS = {
  efficiency: 15.5,
  costKwh: 0.02,
  btcPrice: 68800,
};

function dayRowAtScales(currentScale, projectedScale) {
  return computeDayRow({
    hashRate24h: SAMPLE_HR[0].hash_rate_24h,
    btcReward: SAMPLE_REWARDS[0].total_reward,
    ...DEFAULTS,
    currentScale,
    projectedScale,
  });
}

describe("computeMachineScales", () => {
  it("uses baseline captured at data load for both tables", () => {
    const baseline = 80;
    const atLoad = computeMachineScales(325, 80, baseline);
    assert.equal(atLoad.currentScale, 1);
    assert.equal(atLoad.projectedScale, 325 / 80);

    const afterCurrentEdit = computeMachineScales(325, 100, baseline);
    assert.equal(afterCurrentEdit.currentScale, 100 / 80);
    assert.equal(afterCurrentEdit.projectedScale, 325 / 80);
  });

  it("falls back to current machines when baseline is missing", () => {
    const scales = computeMachineScales(325, 80, null);
    assert.equal(scales.currentScale, 1);
    assert.equal(scales.projectedScale, 325 / 80);
  });
});

describe("computeScaleFactor (legacy ratio)", () => {
  it("returns projected divided by current", () => {
    assert.equal(computeScaleFactor(325, 80), 325 / 80);
  });
});

describe("computeWeightedEfficiency", () => {
  it("matches 80/20 S21 Pro / S21 mix", () => {
    assert.equal(computeWeightedEfficiency(80, 20), 15.5);
  });
});

describe("computeDayRow scaling invariants", () => {
  it("when scales are equal, projected equals current", () => {
    const row = dayRowAtScales(1, 1);

    assert.equal(row.thsProjected, row.ths);
    assert.equal(row.elecCostProjected, row.elecCostCurrent);
    assert.equal(row.grossProjected, row.gross);
    assert.equal(row.btcRewardScaled, row.btcReward);
    assert.equal(row.netProjected, row.netCurrent);
    assert.equal(row.sovrnProjected, row.sovrnCurrent);
    assert.equal(row.sovrn30Projected, row.sovrn30Current);
  });

  it("scales hashrate, energy, gross, and BTC linearly with projected scale", () => {
    const currentScale = 1;
    const projectedScale = 325 / 80;
    const row = dayRowAtScales(currentScale, projectedScale);

    assert.ok(Math.abs(row.thsProjected - row.ths * (projectedScale / currentScale)) < 1e-9);
    assert.ok(Math.abs(row.elecCostProjected - row.elecCostCurrent * (projectedScale / currentScale)) < 1e-9);
    assert.ok(Math.abs(row.grossProjected - row.gross * (projectedScale / currentScale)) < 1e-9);
    assert.ok(Math.abs(row.btcRewardScaled - row.btcReward * (projectedScale / currentScale)) < 1e-9);
    assert.ok(Math.abs(row.netProjected - row.netCurrent * (projectedScale / currentScale)) < 1e-9);
  });

  it("sovrn does not scale exactly linearly due to fixed generator cost", () => {
    const row = dayRowAtScales(1, 2);
    const linearSovrn = row.sovrnCurrent * 2;
    assert.notEqual(row.sovrnProjected, linearSovrn);
  });
});

describe("machine count consistency (baseline model)", () => {
  const baseline = 80;

  it("changing only currentMachines updates current table, not projected", () => {
    const at80 = dayRowAtScales(1, 325 / 80);
    const at100 = dayRowAtScales(100 / 80, 325 / 80);

    assert.ok(Math.abs(at100.ths / at80.ths - 100 / 80) < 1e-9);
    assert.ok(Math.abs(at100.netCurrent / at80.netCurrent - 100 / 80) < 1e-9);
    assert.equal(at100.thsProjected, at80.thsProjected);
    assert.equal(at100.netProjected, at80.netProjected);
  });

  it("changing only projectedMachines updates projected table, not current", () => {
    const at325 = dayRowAtScales(1, 325 / 80);
    const at400 = dayRowAtScales(1, 400 / 80);

    assert.equal(at400.ths, at325.ths);
    assert.equal(at400.netCurrent, at325.netCurrent);
    assert.ok(Math.abs(at400.netProjected / at325.netProjected - 400 / 325) < 1e-9);
  });

  it("when projected equals current, tables match regardless of absolute counts", () => {
    [80, 100, 325].forEach(machines => {
      const scale = machines / baseline;
      const row = dayRowAtScales(scale, scale);
      assert.equal(row.netProjected, row.netCurrent);
      assert.equal(row.sovrnProjected, row.sovrnCurrent);
    });
  });
});

describe("computeTableRows", () => {
  it("filters zero hashrate and missing rewards", () => {
    const rows = computeTableRows(
      [
        ...SAMPLE_HR,
        { hash_rate_24h: 0, date: 1775088000 },
        { hash_rate_24h: 1000, date: 9999999999 },
      ],
      SAMPLE_REWARDS,
      DEFAULTS.efficiency,
      DEFAULTS.costKwh,
      1,
      1,
      DEFAULTS.btcPrice
    );

    assert.equal(rows.length, 2);
    assert.equal(rows[0].date, SAMPLE_HR[0].date);
  });
});

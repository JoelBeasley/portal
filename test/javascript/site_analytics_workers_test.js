import assert from "node:assert/strict";
import { describe, it } from "node:test";
import {
  parseWorkerSummary,
  parseWorkerRows,
  workerStateLabel,
  workerStateBadgeClass,
  formatHashRate,
  formatLastShare,
} from "../../app/javascript/site_analytics/workers.js";

const SAMPLE_PROFILE = {
  btc: {
    ok_workers: 238,
    low_workers: 2,
    off_workers: 5,
    dis_workers: 1,
    hash_rate_unit: "Th/s",
    hash_rate_5m: 12500.5,
    hash_rate_24h: 12300.2,
  },
};

const SAMPLE_WORKERS = {
  btc: {
    workers: {
      "account.rig02": {
        state: "low",
        hash_rate_unit: "Th/s",
        hash_rate_5m: 50,
        hash_rate_24h: 48,
        last_share: 1_700_000_100,
      },
      "account.rig01": {
        state: "ok",
        hash_rate_unit: "Th/s",
        hash_rate_5m: 100,
        hash_rate_24h: 99,
        last_share: 1_700_000_000,
      },
    },
  },
};

describe("parseWorkerSummary", () => {
  it("returns counts and hashrate from profile payload", () => {
    const summary = parseWorkerSummary(SAMPLE_PROFILE);

    assert.equal(summary.ok, 238);
    assert.equal(summary.low, 2);
    assert.equal(summary.off, 5);
    assert.equal(summary.dis, 1);
    assert.equal(summary.total, 246);
    assert.equal(summary.hashRate5m, 12500.5);
    assert.equal(summary.hashRate24h, 12300.2);
    assert.equal(summary.unit, "Th/s");
  });

  it("returns zeros when profile payload is missing", () => {
    const summary = parseWorkerSummary(null);

    assert.equal(summary.total, 0);
    assert.equal(summary.ok, 0);
    assert.equal(summary.hashRate5m, null);
  });
});

describe("parseWorkerRows", () => {
  it("returns sorted worker rows with parsed fields", () => {
    const rows = parseWorkerRows(SAMPLE_WORKERS);

    assert.equal(rows.length, 2);
    assert.equal(rows[0].name, "account.rig01");
    assert.equal(rows[0].state, "ok");
    assert.equal(rows[0].hashRate5m, 100);
    assert.equal(rows[1].name, "account.rig02");
    assert.equal(rows[1].state, "low");
  });

  it("returns empty array for missing workers object", () => {
    assert.deepEqual(parseWorkerRows({}), []);
    assert.deepEqual(parseWorkerRows(null), []);
  });
});

describe("worker state display helpers", () => {
  it("maps known states to labels and badge classes", () => {
    assert.equal(workerStateLabel("ok"), "OK");
    assert.equal(workerStateLabel("off"), "Offline");
    assert.match(workerStateBadgeClass("ok"), /emerald/);
    assert.match(workerStateBadgeClass("off"), /red/);
  });
});

describe("formatHashRate", () => {
  it("formats numeric values with unit", () => {
    assert.equal(formatHashRate(123.456, "Th/s"), "123.46 Th/s");
  });

  it("returns dash for missing values", () => {
    assert.equal(formatHashRate(null, "Th/s"), "—");
  });
});

describe("formatLastShare", () => {
  it("formats unix timestamp", () => {
    const formatted = formatLastShare(1_700_000_000);
    assert.match(formatted, /2023/);
  });

  it("returns dash for invalid values", () => {
    assert.equal(formatLastShare(null), "—");
  });
});

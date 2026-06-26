/**
 * Parse Braiins pool profile and workers API payloads for the analytics page.
 */

const WORKER_STATE_LABELS = {
  ok: "OK",
  low: "Low",
  off: "Offline",
  dis: "Disabled",
};

const WORKER_STATE_BADGE_CLASSES = {
  ok: "bg-emerald-100 text-emerald-800",
  low: "bg-amber-100 text-amber-800",
  off: "bg-red-100 text-red-800",
  dis: "bg-gray-100 text-gray-700",
};

function profileBtc(payload) {
  return payload?.btc ?? null;
}

function workersMap(payload) {
  return payload?.btc?.workers ?? null;
}

export function workerStateLabel(state) {
  return WORKER_STATE_LABELS[state] ?? String(state || "Unknown");
}

export function workerStateBadgeClass(state) {
  return WORKER_STATE_BADGE_CLASSES[state] ?? "bg-gray-100 text-gray-700";
}

export function parseWorkerSummary(profilePayload) {
  const btc = profileBtc(profilePayload);
  if (!btc) {
    return {
      ok: 0,
      low: 0,
      off: 0,
      dis: 0,
      total: 0,
      hashRate5m: null,
      hashRate24h: null,
      unit: "Th/s",
    };
  }

  const ok = Number(btc.ok_workers) || 0;
  const low = Number(btc.low_workers) || 0;
  const off = Number(btc.off_workers) || 0;
  const dis = Number(btc.dis_workers) || 0;

  return {
    ok,
    low,
    off,
    dis,
    total: ok + low + off + dis,
    hashRate5m: btc.hash_rate_5m != null ? Number(btc.hash_rate_5m) : null,
    hashRate24h: btc.hash_rate_24h != null ? Number(btc.hash_rate_24h) : null,
    unit: btc.hash_rate_unit || "Th/s",
  };
}

export function parseWorkerRows(workersPayload) {
  const workers = workersMap(workersPayload);
  if (!workers || typeof workers !== "object") return [];

  return Object.entries(workers)
    .map(([name, worker]) => ({
      name,
      state: worker?.state || "off",
      hashRate5m: worker?.hash_rate_5m != null ? Number(worker.hash_rate_5m) : null,
      hashRate24h: worker?.hash_rate_24h != null ? Number(worker.hash_rate_24h) : null,
      unit: worker?.hash_rate_unit || "Th/s",
      lastShareAt: worker?.last_share != null ? Number(worker.last_share) : null,
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

export function formatHashRate(value, unit) {
  if (value == null || !Number.isFinite(value)) return "—";
  const formatted = value >= 1000 ? value.toLocaleString(undefined, { maximumFractionDigits: 2 }) : value.toFixed(2);
  return `${formatted} ${unit || "Th/s"}`;
}

export function formatLastShare(unixSeconds) {
  if (unixSeconds == null || !Number.isFinite(unixSeconds)) return "—";
  const when = new Date(unixSeconds * 1000);
  if (Number.isNaN(when.getTime())) return "—";
  return when.toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" });
}

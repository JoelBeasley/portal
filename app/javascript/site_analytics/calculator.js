/**
 * Pure calculation helpers for Braiins pool analytics tables.
 * Kept in sync with app/views/admin/site_analytics/show.html.erb
 */

export function parseMachineCount(value, fallback) {
  const parsed = parseFloat(value);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

export function computeMachineScales(projectedMachines, currentMachines, baselineCurrentMachines) {
  const current = parseMachineCount(currentMachines, 80);
  const projected = parseMachineCount(projectedMachines, 325);
  const baseline = parseMachineCount(baselineCurrentMachines, current);
  return {
    currentScale: current / baseline,
    projectedScale: projected / baseline,
    currentMachines: current,
    projectedMachines: projected,
    baselineCurrentMachines: baseline,
  };
}

/** @deprecated Use computeMachineScales; kept for backwards-compatible tests */
export function computeScaleFactor(projectedMachines, currentMachines) {
  const current = parseMachineCount(currentMachines, 80);
  const projected = parseMachineCount(projectedMachines, 325);
  return projected / current;
}

export function computeWeightedEfficiency(percentPro, percentStandard) {
  const pro = parseFloat(percentPro) || 0;
  const standard = parseFloat(percentStandard) || 0;
  const effPro = 15.0;
  const effStandard = 17.5;
  return (pro / 100 * effPro) + (standard / 100 * effStandard);
}

function computeProfitChain(net, generatorCostDaily = 4000 / 30) {
  const operatorCost = net * 0.07;
  const projectProfit = net - operatorCost - generatorCostDaily;
  const dmgProfit = projectProfit * 0.60;
  const partnerPool = dmgProfit * 0.20;
  const sovrn = partnerPool / 4;
  const sovrn30 = sovrn * 30;
  return { net, sovrn, sovrn30 };
}

function computeFleetMetrics(ths, btcReward, efficiency, costKwh, btcPrice, generatorCostDaily) {
  const powerKw = (ths * efficiency) / 1000;
  const elecCost = powerKw * 24 * costKwh;
  const gross = btcReward * btcPrice;
  const net = gross - elecCost;
  const chain = computeProfitChain(net, generatorCostDaily);
  return {
    ths,
    btcReward,
    elecCost,
    gross,
    ...chain,
  };
}

export function computeDayRow({
  hashRate24h,
  btcReward,
  efficiency,
  costKwh,
  currentScale,
  projectedScale,
  btcPrice,
  generatorCostDaily = 4000 / 30,
}) {
  const thsBaseline = (parseFloat(hashRate24h) || 0) / 1000;
  const rewardBaseline = parseFloat(btcReward) || 0;

  const current = computeFleetMetrics(
    thsBaseline * currentScale,
    rewardBaseline * currentScale,
    efficiency,
    costKwh,
    btcPrice,
    generatorCostDaily
  );

  const projected = computeFleetMetrics(
    thsBaseline * projectedScale,
    rewardBaseline * projectedScale,
    efficiency,
    costKwh,
    btcPrice,
    generatorCostDaily
  );

  return {
    ths: current.ths,
    thsProjected: projected.ths,
    elecCostCurrent: current.elecCost,
    elecCostProjected: projected.elecCost,
    btcReward: current.btcReward,
    btcRewardScaled: projected.btcReward,
    gross: current.gross,
    grossProjected: projected.gross,
    netCurrent: current.net,
    netProjected: projected.net,
    sovrnCurrent: current.sovrn,
    sovrn30Current: current.sovrn30,
    sovrnProjected: projected.sovrn,
    sovrn30Projected: projected.sovrn30,
  };
}

export function computeTableRows(
  hrArray,
  rewardArray,
  efficiency,
  costKwh,
  currentScale,
  projectedScale,
  btcPrice
) {
  const rewardMap = {};
  rewardArray.forEach(r => {
    if (r.date) rewardMap[r.date] = parseFloat(r.total_reward) || 0;
  });

  return hrArray
    .filter(day =>
      day.date &&
      Object.prototype.hasOwnProperty.call(rewardMap, day.date) &&
      (parseFloat(day.hash_rate_24h) || 0) > 0
    )
    .sort((a, b) => a.date - b.date)
    .slice(-10)
    .map(day => ({
      date: day.date,
      ...computeDayRow({
        hashRate24h: day.hash_rate_24h,
        btcReward: rewardMap[day.date],
        efficiency,
        costKwh,
        currentScale,
        projectedScale,
        btcPrice,
      }),
    }));
}

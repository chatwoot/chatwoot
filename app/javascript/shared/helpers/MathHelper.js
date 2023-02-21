export const asc = arr => arr.sort((a, b) => a - b);

export const quantile = (arr, q) => {
  const sorted = asc(arr);
  const pos = (sorted.length - 1) * q;
  const base = Math.floor(pos);
  const rest = pos - base;
  if (sorted[base + 1] !== undefined) {
    return sorted[base] + rest * (sorted[base + 1] - sorted[base]);
  }
  return sorted[base];
};

export const getQuanileIntervals = (data, interavals) => {
  return interavals.map(interval => {
    return quantile(data, interval);
  });
};

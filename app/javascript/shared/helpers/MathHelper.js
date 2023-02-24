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

export const reconcileHeatmapData = (data, heatmapData) => {
  // data = [{timestamp: 123, value: 10}, {timestamp: 124, value: 20}]
  // convert this data to key-value pair of timestamp and value
  const parsedData = data.reduce((acc, curr) => {
    acc[curr.timestamp] = curr.value;
    return acc;
  }, {});

  return heatmapData.map(dataItem => {
    if (parsedData[dataItem.timestamp]) {
      dataItem.value = parsedData[dataItem.timestamp];
    }

    return dataItem;
  });
};

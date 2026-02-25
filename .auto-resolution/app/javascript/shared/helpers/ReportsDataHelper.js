import {
  fromUnixTime,
  startOfDay,
  endOfDay,
  getUnixTime,
  subDays,
} from 'date-fns';

/**
 * Returns a key-value pair of timestamp and value for heatmap data
 *
 * @param {Array} data - An array of objects containing timestamp and value
 * @returns {Object} - An object with timestamp as keys and corresponding values as values
 */
export const flattenHeatmapData = data => {
  return data.reduce((acc, curr) => {
    acc[curr.timestamp] = curr.value;
    return acc;
  }, {});
};

/**
 * Filter the given array to remove data outside the timeline
 *
 * @param {Array} data - An array of objects containing timestamp and value
 * @param {number} from - Unix timestamp
 * @param {number} to - Unix timestamp
 * @returns {Array} - An array of objects containing timestamp and value
 */
export const clampDataBetweenTimeline = (data, from, to) => {
  if (from === undefined && to === undefined) {
    return data;
  }

  return data.filter(el => {
    const { timestamp } = el;

    const isWithinFrom = from === undefined || timestamp - from >= 0;
    const isWithinTo = to === undefined || to - timestamp > 0;

    return isWithinFrom && isWithinTo;
  });
};

/**
 * Generates an array of objects with timestamp and value as 0 for the last 7 days
 *
 * @returns {Array} - An array of objects containing timestamp and value
 */
export const generateEmptyHeatmapData = () => {
  const data = [];
  const today = new Date();

  let timeMarker = getUnixTime(startOfDay(subDays(today, 6)));
  let endOfToday = getUnixTime(endOfDay(today));

  const oneHour = 3600;

  while (timeMarker <= endOfToday) {
    data.push({ value: 0, timestamp: timeMarker });
    timeMarker += oneHour;
  }

  return data;
};

/**
 * Reconciles new data with existing heatmap data based on timestamps
 *
 * @param {Array} data - An array of objects containing timestamp and value
 * @param {Array} heatmapData - An array of objects containing timestamp, value and other properties
 * @returns {Array} - An array of objects with updated values
 */
export const reconcileHeatmapData = (data, dataFromStore) => {
  const parsedData = flattenHeatmapData(data);
  // make a copy of the data from store
  const heatmapData = dataFromStore.length
    ? dataFromStore
    : generateEmptyHeatmapData();

  return heatmapData.map(dataItem => {
    if (parsedData[dataItem.timestamp]) {
      dataItem.value = parsedData[dataItem.timestamp];
    }
    return dataItem;
  });
};

/**
 * Groups heatmap data by day
 *
 * @param {Array} heatmapData - An array of objects containing timestamp, value and other properties
 * @returns {Map} - A Map object with dates as keys and corresponding data objects as values
 */
export const groupHeatmapByDay = heatmapData => {
  return heatmapData.reduce((acc, data) => {
    const date = fromUnixTime(data.timestamp);
    const mapKey = startOfDay(date).toISOString();
    const dataToAppend = {
      ...data,
      date: fromUnixTime(data.timestamp),
      hour: date.getHours(),
    };
    if (!acc.has(mapKey)) {
      acc.set(mapKey, []);
    }
    acc.get(mapKey).push(dataToAppend);
    return acc;
  }, new Map());
};

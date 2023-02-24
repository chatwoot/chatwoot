import { fromUnixTime, startOfDay } from 'date-fns';

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

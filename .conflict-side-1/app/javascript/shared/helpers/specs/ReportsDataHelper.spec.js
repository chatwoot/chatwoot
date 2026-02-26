import {
  groupHeatmapByDay,
  reconcileHeatmapData,
  flattenHeatmapData,
  clampDataBetweenTimeline,
} from '../ReportsDataHelper';

describe('flattenHeatmapData', () => {
  it('should flatten heatmap data to key-value pairs', () => {
    const data = [
      { timestamp: 1614265200, value: 10 },
      { timestamp: 1614308400, value: 20 },
    ];
    const expected = {
      1614265200: 10,
      1614308400: 20,
    };
    expect(flattenHeatmapData(data)).toEqual(expected);
  });

  it('should handle empty data', () => {
    const data = [];
    const expected = {};
    expect(flattenHeatmapData(data)).toEqual(expected);
  });

  it('should handle data with same timestamps', () => {
    const data = [
      { timestamp: 1614265200, value: 10 },
      { timestamp: 1614265200, value: 20 },
    ];
    const expected = {
      1614265200: 20,
    };
    expect(flattenHeatmapData(data)).toEqual(expected);
  });
});

describe('reconcileHeatmapData', () => {
  it('should reconcile heatmap data with new data', () => {
    const data = [
      { timestamp: 1614265200, value: 10 },
      { timestamp: 1614308400, value: 20 },
    ];
    const heatmapData = [
      { timestamp: 1614265200, value: 5 },
      { timestamp: 1614308400, value: 15 },
      { timestamp: 1614387600, value: 25 },
    ];
    const expected = [
      { timestamp: 1614265200, value: 10 },
      { timestamp: 1614308400, value: 20 },
      { timestamp: 1614387600, value: 25 },
    ];
    expect(reconcileHeatmapData(data, heatmapData)).toEqual(expected);
  });

  it('should reconcile heatmap data with new data and handle missing data', () => {
    const data = [{ timestamp: 1614308400, value: 20 }];
    const heatmapData = [
      { timestamp: 1614265200, value: 5 },
      { timestamp: 1614308400, value: 15 },
      { timestamp: 1614387600, value: 25 },
    ];
    const expected = [
      { timestamp: 1614265200, value: 5 },
      { timestamp: 1614308400, value: 20 },
      { timestamp: 1614387600, value: 25 },
    ];
    expect(reconcileHeatmapData(data, heatmapData)).toEqual(expected);
  });

  it('should replace empty heatmap data with a new array', () => {
    const data = [{ timestamp: 1614308400, value: 20 }];
    const heatmapData = [];
    expect(reconcileHeatmapData(data, heatmapData).length).toEqual(7 * 24);
  });
});

describe('groupHeatmapByDay', () => {
  it('should group heatmap data by day', () => {
    const heatmapData = [
      { timestamp: 1614265200, value: 10 },
      { timestamp: 1614308400, value: 20 },
      { timestamp: 1614387600, value: 30 },
      { timestamp: 1614430800, value: 40 },
      { timestamp: 1614499200, value: 50 },
    ];

    expect(groupHeatmapByDay(heatmapData)).toMatchInlineSnapshot(`
      Map {
        "2021-02-25T00:00:00.000Z" => [
          {
            "date": 2021-02-25T15:00:00.000Z,
            "hour": 15,
            "timestamp": 1614265200,
            "value": 10,
          },
        ],
        "2021-02-26T00:00:00.000Z" => [
          {
            "date": 2021-02-26T03:00:00.000Z,
            "hour": 3,
            "timestamp": 1614308400,
            "value": 20,
          },
        ],
        "2021-02-27T00:00:00.000Z" => [
          {
            "date": 2021-02-27T01:00:00.000Z,
            "hour": 1,
            "timestamp": 1614387600,
            "value": 30,
          },
          {
            "date": 2021-02-27T13:00:00.000Z,
            "hour": 13,
            "timestamp": 1614430800,
            "value": 40,
          },
        ],
        "2021-02-28T00:00:00.000Z" => [
          {
            "date": 2021-02-28T08:00:00.000Z,
            "hour": 8,
            "timestamp": 1614499200,
            "value": 50,
          },
        ],
      }
    `);
  });

  it('should group empty heatmap data by day', () => {
    const heatmapData = [];
    const expected = new Map();
    expect(groupHeatmapByDay(heatmapData)).toEqual(expected);
  });

  it('should group heatmap data with same timestamp in the same day', () => {
    const heatmapData = [
      { timestamp: 1614265200, value: 10 },
      { timestamp: 1614265200, value: 20 },
    ];

    expect(groupHeatmapByDay(heatmapData)).toMatchInlineSnapshot(`
      Map {
        "2021-02-25T00:00:00.000Z" => [
          {
            "date": 2021-02-25T15:00:00.000Z,
            "hour": 15,
            "timestamp": 1614265200,
            "value": 10,
          },
          {
            "date": 2021-02-25T15:00:00.000Z,
            "hour": 15,
            "timestamp": 1614265200,
            "value": 20,
          },
        ],
      }
    `);
  });
});

describe('clampDataBetweenTimeline', () => {
  const data = [
    { timestamp: 1646054400, value: 'A' },
    { timestamp: 1646054500, value: 'B' },
    { timestamp: 1646054600, value: 'C' },
    { timestamp: 1646054700, value: 'D' },
    { timestamp: 1646054800, value: 'E' },
  ];

  it('should return empty array if data is empty', () => {
    expect(clampDataBetweenTimeline([], 1646054500, 1646054700)).toEqual([]);
  });

  it('should return empty array if no data is within the timeline', () => {
    expect(clampDataBetweenTimeline(data, 1646054900, 1646055000)).toEqual([]);
  });

  it('should return the data as is no time limits are provider', () => {
    expect(clampDataBetweenTimeline(data)).toEqual(data);
  });

  it('should return all data if all data is within the timeline', () => {
    expect(clampDataBetweenTimeline(data, 1646054300, 1646054900)).toEqual(
      data
    );
  });

  it('should return only data within the timeline', () => {
    expect(clampDataBetweenTimeline(data, 1646054500, 1646054700)).toEqual([
      { timestamp: 1646054500, value: 'B' },
      { timestamp: 1646054600, value: 'C' },
    ]);
  });

  it('should return empty array if from and to are the same', () => {
    expect(clampDataBetweenTimeline(data, 1646054500, 1646054500)).toEqual([]);
  });
});

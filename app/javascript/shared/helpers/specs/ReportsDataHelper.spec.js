import {
  groupHeatmapByDay,
  reconcileHeatmapData,
  flattenHeatmapData,
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

  it('should handle empty heatmap data', () => {
    const data = [{ timestamp: 1614308400, value: 20 }];
    const heatmapData = [];
    const expected = [];
    expect(reconcileHeatmapData(data, heatmapData)).toEqual(expected);
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
        "2021-02-25T00:00:00.000Z" => Array [
          Object {
            "date": 2021-02-25T15:00:00.000Z,
            "hour": 15,
            "timestamp": 1614265200,
            "value": 10,
          },
        ],
        "2021-02-26T00:00:00.000Z" => Array [
          Object {
            "date": 2021-02-26T03:00:00.000Z,
            "hour": 3,
            "timestamp": 1614308400,
            "value": 20,
          },
        ],
        "2021-02-27T00:00:00.000Z" => Array [
          Object {
            "date": 2021-02-27T01:00:00.000Z,
            "hour": 1,
            "timestamp": 1614387600,
            "value": 30,
          },
          Object {
            "date": 2021-02-27T13:00:00.000Z,
            "hour": 13,
            "timestamp": 1614430800,
            "value": 40,
          },
        ],
        "2021-02-28T00:00:00.000Z" => Array [
          Object {
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
        "2021-02-25T00:00:00.000Z" => Array [
          Object {
            "date": 2021-02-25T15:00:00.000Z,
            "hour": 15,
            "timestamp": 1614265200,
            "value": 10,
          },
          Object {
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

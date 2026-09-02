import { buildIntervalMatrix } from './intervalHelper';

describe('buildIntervalMatrix', () => {
  it('returns an empty matrix for empty input', () => {
    expect(buildIntervalMatrix([])).toEqual({
      days: [],
      values: {},
      maxValue: 0,
    });
  });

  it('groups several hours within one local day', () => {
    const intervalData = [
      { timestamp: Date.parse('2026-08-01T00:00:00Z') / 1000, value: 2 },
      { timestamp: Date.parse('2026-08-01T13:00:00Z') / 1000, value: 7 },
      { timestamp: Date.parse('2026-08-01T23:00:00Z') / 1000, value: 1 },
    ];

    const result = buildIntervalMatrix(intervalData);

    expect(result.days).toEqual([
      { key: '2026-08-01', date: new Date('2026-08-01T00:00:00Z') },
    ]);
    expect(result.values).toEqual({
      '2026-08-01': { 0: 2, 13: 7, 23: 1 },
    });
  });

  it('groups several local days and returns them in ascending order', () => {
    const intervalData = [
      { timestamp: Date.parse('2026-08-03T08:00:00Z') / 1000, value: 3 },
      { timestamp: Date.parse('2026-08-01T09:00:00Z') / 1000, value: 1 },
      { timestamp: Date.parse('2026-08-02T10:00:00Z') / 1000, value: 2 },
    ];

    const result = buildIntervalMatrix(intervalData);

    expect(result.days.map(({ key }) => key)).toEqual([
      '2026-08-01',
      '2026-08-02',
      '2026-08-03',
    ]);
    expect(result.values).toEqual({
      '2026-08-01': { 9: 1 },
      '2026-08-02': { 10: 2 },
      '2026-08-03': { 8: 3 },
    });
  });

  it('returns the largest bucket value', () => {
    const intervalData = [
      { timestamp: Date.parse('2026-08-01T08:00:00Z') / 1000, value: 4 },
      { timestamp: Date.parse('2026-08-02T09:00:00Z') / 1000, value: 12 },
      { timestamp: Date.parse('2026-08-03T10:00:00Z') / 1000, value: 6 },
    ];

    expect(buildIntervalMatrix(intervalData).maxValue).toBe(12);
  });
});

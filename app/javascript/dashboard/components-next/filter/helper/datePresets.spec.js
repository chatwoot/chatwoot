import { buildDatePresetConditions } from './datePresets';

// A Wednesday, so this week started on Monday 2026-11-02.
const TODAY = new Date(2026, 10, 4);

const after = values => ({ filterOperator: 'is_greater_than', values });
const before = values => ({ filterOperator: 'is_less_than', values });

describe('buildDatePresetConditions', () => {
  it.each([
    ['today', [after('2026-11-03')]],
    ['yesterday', [after('2026-11-02'), before('2026-11-04')]],
    ['this_week', [after('2026-11-01')]],
    ['last_week', [after('2026-10-25'), before('2026-11-02')]],
    ['this_month', [after('2026-10-31')]],
    ['last_month', [after('2026-09-30'), before('2026-11-01')]],
    ['this_year', [after('2025-12-31')]],
  ])('turns %s into rows covering that period', (preset, conditions) => {
    expect(buildDatePresetConditions(preset, undefined, TODAY)).toEqual(
      conditions
    );
  });

  it('counts back the given number of days, including today', () => {
    expect(buildDatePresetConditions('last_n_days', 3, TODAY)).toEqual([
      after('2026-11-01'),
    ]);
  });

  it('uses days_before for older than a number of days', () => {
    expect(buildDatePresetConditions('older_than_n_days', 5, TODAY)).toEqual([
      { filterOperator: 'days_before', values: '5' },
    ]);
  });

  it('leaves the value empty when a counted preset has no number of days', () => {
    expect(buildDatePresetConditions('last_n_days', undefined, TODAY)).toEqual([
      after(''),
    ]);
  });

  it('returns no rows for an unknown preset', () => {
    expect(buildDatePresetConditions('next_week', undefined, TODAY)).toEqual(
      []
    );
  });
});

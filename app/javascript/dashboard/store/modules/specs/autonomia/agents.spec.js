import autonomiaAgents from '../../autonomiaAgents';
import { generateMutationTypes } from '../../../storeFactory';

const { UPSERT } = generateMutationTypes('AutonomiaAgents');
const upsert = autonomiaAgents.mutations[UPSERT];

const agent = (overrides = {}) => ({
  id: 7,
  status: 'active',
  instruction: 'live',
  updated_at: '2026-07-03T12:00:00.000Z',
  ...overrides,
});

describe('#autonomiaAgents store — UPSERT staleness guard', () => {
  it('inserts a record that is not yet in the list', () => {
    const state = { records: [] };
    const incoming = agent();

    upsert(state, incoming);

    expect(state.records).toEqual([incoming]);
  });

  it('replaces the record when the incoming payload is newer', () => {
    const state = { records: [agent({ instruction: 'old' })] };
    const fresh = agent({
      instruction: 'new',
      updated_at: '2026-07-03T12:00:01.000Z',
    });

    upsert(state, fresh);

    expect(state.records[0].instruction).toBe('new');
  });

  it('replaces the record when both timestamps are equal (idempotent)', () => {
    const state = { records: [agent({ instruction: 'a' })] };
    const same = agent({ instruction: 'b' });

    upsert(state, same);

    expect(state.records[0].instruction).toBe('b');
  });

  it('ignores a stale show that resolves after a fresher write (the Onda 5 race)', () => {
    // A rollback/save already landed the fresh record (12:00:05); a `show` GET
    // issued earlier reflects DB state at 12:00:00 and arrives late.
    const state = {
      records: [
        agent({
          instruction: 'rolled-back',
          updated_at: '2026-07-03T12:00:05.000Z',
        }),
      ],
    };
    const staleShow = agent({
      instruction: 'pre-rollback',
      updated_at: '2026-07-03T12:00:00.000Z',
    });

    upsert(state, staleShow);

    expect(state.records[0].instruction).toBe('rolled-back');
    expect(state.records[0].updated_at).toBe('2026-07-03T12:00:05.000Z');
  });

  it('replaces when the stored record has no updated_at (nothing to compare against)', () => {
    const state = {
      records: [agent({ updated_at: undefined, instruction: 'x' })],
    };
    const incoming = agent({ instruction: 'y' });

    upsert(state, incoming);

    expect(state.records[0].instruction).toBe('y');
  });
});

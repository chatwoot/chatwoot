import { mutations } from '../../conversationPins';
import types from '../../../mutation-types';

describe('#mutations', () => {
  describe('#SET_CONVERSATION_PINS', () => {
    it('replaces the whole map', () => {
      const state = { records: { 9: 1 }, appliedAt: {}, revision: 0 };
      mutations[types.SET_CONVERSATION_PINS](state, {
        pins: [
          { conversation_id: 1, pinned_at: 100 },
          { conversation_id: 2, pinned_at: 200 },
        ],
      });
      expect(state.records).toEqual({ 1: 100, 2: 200 });
    });

    it('clears the map when the payload is empty', () => {
      const state = { records: { 9: 1 }, appliedAt: {}, revision: 0 };
      mutations[types.SET_CONVERSATION_PINS](state, { pins: [] });
      expect(state.records).toEqual({});
    });

    it('leaves the revision alone, since only a reset invalidates a hydration', () => {
      const state = { records: {}, appliedAt: {}, revision: 3 };
      mutations[types.SET_CONVERSATION_PINS](state, {
        pins: [{ conversation_id: 1, pinned_at: 100 }],
      });
      expect(state.revision).toBe(3);
    });
  });

  describe('#CLEAR_CONVERSATION_PINS', () => {
    it('drops the map, the versions and any hydration in flight', () => {
      const state = { records: { 1: 100 }, appliedAt: { 1: 100 }, revision: 3 };
      mutations[types.CLEAR_CONVERSATION_PINS](state);

      expect(state.records).toEqual({});
      expect(state.appliedAt).toEqual({});
      expect(state.revision).toBe(4);
    });
  });

  describe('#SET_CONVERSATION_PIN', () => {
    it('adds a pin without dropping the others', () => {
      const state = { records: { 1: 100 }, appliedAt: {}, revision: 0 };
      mutations[types.SET_CONVERSATION_PIN](state, {
        conversation_id: 2,
        pinned_at: 200,
      });
      expect(state.records).toEqual({ 1: 100, 2: 200 });
    });
  });

  describe('#REMOVE_CONVERSATION_PIN', () => {
    it('removes a single pin', () => {
      const state = { records: { 1: 100, 2: 200 }, appliedAt: {}, revision: 0 };
      mutations[types.REMOVE_CONVERSATION_PIN](state, { conversation_id: 1 });
      expect(state.records).toEqual({ 2: 200 });
    });
  });

  describe('out-of-order websocket events', () => {
    it('ignores a pinned event that lost the race with the unpin after it', () => {
      const state = { records: {}, appliedAt: {}, revision: 0 };
      // The unpin broadcast wins the race, so the pin it removed arrives afterwards.
      mutations[types.REMOVE_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 100,
      });
      mutations[types.SET_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 100,
      });

      expect(state.records).toEqual({});
    });

    it('ignores an unpin event older than the pin already applied', () => {
      const state = { records: {}, appliedAt: {}, revision: 0 };
      mutations[types.SET_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 200,
      });
      mutations[types.REMOVE_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 100,
      });

      expect(state.records).toEqual({ 1: 200 });
    });

    it('applies a pin created after the last event', () => {
      const state = { records: {}, appliedAt: {}, revision: 0 };
      mutations[types.REMOVE_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 100,
      });
      mutations[types.SET_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 200,
      });

      expect(state.records).toEqual({ 1: 200 });
    });

    it('ignores a pin event older than the pin currently held', () => {
      const state = { records: {}, appliedAt: {}, revision: 0 };
      // pin -> unpin -> re-pin, with the first pin's broadcast arriving last.
      mutations[types.SET_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 200,
      });
      mutations[types.SET_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 100,
      });

      expect(state.records).toEqual({ 1: 200 });
      expect(state.appliedAt).toEqual({ 1: 200 });
    });

    it('does not let a stale unpin remove the pin that replaced it', () => {
      const state = { records: {}, appliedAt: {}, revision: 0 };
      mutations[types.SET_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 200,
      });
      mutations[types.SET_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 100,
      });
      mutations[types.REMOVE_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 100,
      });

      expect(state.records).toEqual({ 1: 200 });
    });

    it('keeps the versions of unpinned conversations across a hydration', () => {
      const state = { records: {}, appliedAt: {}, revision: 0 };
      mutations[types.REMOVE_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 100,
      });
      mutations[types.SET_CONVERSATION_PINS](state, {
        pins: [{ conversation_id: 2, pinned_at: 300 }],
        appliedAtBefore: { ...state.appliedAt },
      });
      mutations[types.SET_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 100,
      });

      expect(state.records).toEqual({ 2: 300 });
    });
  });

  describe('snapshots racing events', () => {
    it('keeps a conversation whose pin landed while the request was in flight', () => {
      const state = { records: { 1: 500 }, appliedAt: { 1: 500 }, revision: 0 };

      mutations[types.SET_CONVERSATION_PINS](state, {
        pins: [],
        appliedAtBefore: {},
      });

      expect(state.records).toEqual({ 1: 500 });
    });

    it('drops a conversation whose unpin landed while the request was in flight', () => {
      const state = { records: {}, appliedAt: { 1: 500 }, revision: 0 };

      mutations[types.SET_CONVERSATION_PINS](state, {
        pins: [{ conversation_id: 1, pinned_at: 500 }],
        appliedAtBefore: {},
      });

      expect(state.records).toEqual({});
    });

    it('drops a conversation unpinned mid-flight even though the unpin kept its version', () => {
      const state = { records: { 1: 500 }, appliedAt: { 1: 500 }, revision: 0 };
      const appliedAtBefore = { ...state.appliedAt };
      const recordsBefore = { ...state.records };

      mutations[types.REMOVE_CONVERSATION_PIN](state, {
        conversation_id: 1,
        pinned_at: 500,
      });
      mutations[types.SET_CONVERSATION_PINS](state, {
        pins: [{ conversation_id: 1, pinned_at: 500 }],
        appliedAtBefore,
        recordsBefore,
      });

      expect(state.records).toEqual({});
    });

    it('takes the server value for everything the events did not touch', () => {
      const state = { records: { 1: 500 }, appliedAt: { 1: 500 }, revision: 0 };

      mutations[types.SET_CONVERSATION_PINS](state, {
        pins: [{ conversation_id: 2, pinned_at: 700 }],
        appliedAtBefore: { 1: 500 },
        recordsBefore: { 1: 500 },
      });

      expect(state.records).toEqual({ 2: 700 });
    });
  });

  describe('#SET_CONVERSATION_PINS_UI_FLAG', () => {
    it('merges the flags', () => {
      const state = { uiFlags: { isFetching: false } };
      mutations[types.SET_CONVERSATION_PINS_UI_FLAG](state, {
        isFetching: true,
      });
      expect(state.uiFlags).toEqual({ isFetching: true });
    });
  });
});

import {
  appendItems,
  appendItemIds,
  updateItemEntry,
  removeItemEntry,
  removeItemId,
  setItemUIFlag,
} from '../vuex/mutationHelpers';

describe('Mutation Helpers', () => {
  let state;

  beforeEach(() => {
    state = {
      items: {
        byId: {},
        allIds: [],
        uiFlags: {
          byId: {
            // 1: { isCreating: false, isPending: false, isDeleting: false, isUpdating: false },
          },
        },
      },
    };
  });

  it('should handle appending an empty list of items', () => {
    const entity = 'items';
    const items = [];
    appendItems(state, entity, items);

    // Assert that the state remains unchanged
    expect(state[entity].byId).toEqual({});
  });

  it('should handle appending a list of items', () => {
    const entity = 'items';
    const items = [{ id: 55 }, { id: 66 }];
    appendItems(state, entity, items);

    // Assert that the state remains unchanged
    expect(state[entity].byId).toEqual({
      55: { id: 55 },
      66: { id: 66 },
    });
  });

  it('should handle appending an empty list of item IDs', () => {
    const entity = 'items';
    const items = [];
    appendItemIds(state, entity, items);

    // Assert that the state remains unchanged
    expect(state[entity].allIds).toEqual([]);
  });

  it('should handle appending a list of item IDs from items', () => {
    const entity = 'items';
    const items = [{ id: 55 }, { id: 66 }];
    appendItemIds(state, entity, items);

    // Assert that the state remains unchanged
    expect(state[entity].allIds).toEqual([55, 66]);
  });

  it('should handle updating an item that does not exist', () => {
    const entity = 'items';
    const item = { id: 1, name: 'Item 1' };

    updateItemEntry(state, entity, item);

    // Assert that the state remains unchanged
    expect(state[entity].byId).toEqual({});
  });

  it('should handle updating an item that exist', () => {
    const entity = 'items';
    state.items = {
      byId: { 22: { id: 22, name: 'Item 22' } },
      allIds: [22],
    };
    const item = { id: 22, name: 'Item 22 updated' };

    updateItemEntry(state, entity, item);

    // Assert that the state remains unchanged
    expect(state[entity].byId[22]).toEqual({
      id: 22,
      name: 'Item 22 updated',
    });
  });

  it('should handle removing an item that does not exist', () => {
    const entity = 'items';
    const itemId = 1;

    removeItemEntry(state, entity, itemId);

    // Assert that the state remains unchanged
    expect(state[entity].byId).toEqual({});
  });

  it('should handle removing an item that does exist', () => {
    const entity = 'items';
    const itemId = 22;
    state.items = {
      byId: { 22: { id: 22, name: 'Item 22' } },
      allIds: [22],
    };

    removeItemEntry(state, entity, itemId);

    // Assert that the state remains unchanged
    expect(state[entity].byId).toEqual({});
  });

  it('should handle removing an item ID that does not exist', () => {
    const entity = 'items';
    const itemId = 1;

    removeItemId(state, entity, itemId);

    // Assert that the state remains unchanged
    expect(state[entity].allIds).toEqual([]);
  });

  it('should handle removing an item ID that does exist', () => {
    const entity = 'items';
    const itemId = 22;
    state.items = {
      byId: { 22: { id: 22, name: 'Item 22' } },
      allIds: [22],
    };

    removeItemId(state, entity, itemId);

    // Assert that the state remains unchanged
    expect(state[entity].allIds).toEqual([]);
  });

  it('should handle setting UI flags for an item that does not exist', () => {
    const entity = 'items';
    const itemId = 2;
    const uiFlags = { isCreating: false, isPending: false };

    setItemUIFlag(state, entity, itemId, uiFlags);

    // Assert that the state remains unchanged
    expect(state[entity].uiFlags.byId[2]).toEqual({
      isCreating: false,
      isPending: false,
    });
  });

  it('should handle setting UI flags with only the selected keys', () => {
    const entity = 'items';
    const itemId = 1;
    const uiFlags = { isPending: true };

    // Initialize state with an existing item UI flags
    state[entity] = {
      uiFlags: {
        byId: { 1: { isCreating: false, isPending: false } },
      },
    };

    setItemUIFlag(state, entity, itemId, uiFlags);

    // Assert that the state remains unchanged
    expect(state[entity].uiFlags.byId[1]).toEqual({
      isCreating: false,
      isPending: true,
    });
  });
});

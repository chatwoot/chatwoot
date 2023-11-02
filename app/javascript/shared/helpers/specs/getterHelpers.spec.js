import { uIFlags, itemById } from '../vuex/getterHelpers';

describe('Getters', () => {
  let state;

  beforeEach(() => {
    state = {
      uiFlags: {
        selected: true,
        expanded: false,
      },
      items: {
        byId: {
          1: { id: 1, name: 'Item 1' },
          2: { id: 2, name: 'Item 2' },
        },
      },
    };
  });

  it('should return UI flags from state', () => {
    const result = uIFlags(state);

    // Assert that the getter correctly returns the UI flags
    expect(result).toEqual({
      selected: true,
      expanded: false,
    });
  });

  it('should return an item by ID from state', () => {
    const entity = 'items';
    const itemId = 1;

    const result = itemById(state, entity)(itemId);

    // Assert that the getter correctly returns the item by ID
    expect(result).toEqual({ id: 1, name: 'Item 1' });
  });

  it('should return undefined for non-existent item', () => {
    const entity = 'items';
    const itemId = 3;

    const result = itemById(state, entity)(itemId);

    // Assert that the getter returns undefined for a non-existent item
    expect(result).toBeUndefined();
  });

  it('should return undefined for a non-existent entity', () => {
    const entity = 'nonexistent';
    const itemId = 1;

    const result = itemById(state, entity)(itemId);

    // Assert that the getter returns undefined for a non-existent entity
    expect(result).toBeUndefined();
  });
});

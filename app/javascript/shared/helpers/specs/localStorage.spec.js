import { LocalStorage } from '../localStorage';

// Mocking localStorage
const localStorageMock = (() => {
  let store = {};
  return {
    getItem: key => store[key] || null,
    setItem: (key, value) => {
      store[key] = String(value);
    },
    removeItem: key => delete store[key],
    clear: () => {
      store = {};
    },
  };
})();

Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
});

describe('LocalStorage utility', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('set and get methods', () => {
    LocalStorage.set('testKey', { a: 1 });
    expect(LocalStorage.get('testKey')).toEqual({ a: 1 });
  });

  it('remove method', () => {
    LocalStorage.set('testKey', 'testValue');
    LocalStorage.remove('testKey');
    expect(LocalStorage.get('testKey')).toBeNull();
  });

  it('updateJsonStore method', () => {
    LocalStorage.updateJsonStore('testStore', 'testKey', 'testValue');
    expect(LocalStorage.get('testStore')).toEqual({ testKey: 'testValue' });
  });

  it('getFromJsonStore method', () => {
    LocalStorage.set('testStore', { testKey: 'testValue' });
    expect(LocalStorage.getFromJsonStore('testStore', 'testKey')).toBe(
      'testValue'
    );
  });

  it('deleteFromJsonStore method', () => {
    LocalStorage.set('testStore', { testKey: 'testValue' });
    LocalStorage.deleteFromJsonStore('testStore', 'testKey');
    expect(LocalStorage.getFromJsonStore('testStore', 'testKey')).toBeNull();
  });

  it('setFlag and getFlag methods', () => {
    const store = 'testStore';
    const accountId = '123';
    const key = 'flagKey';
    const expiry = 1000; // 1 second

    // Set flag and verify it's set
    LocalStorage.setFlag(store, accountId, key, expiry);
    expect(LocalStorage.getFlag(store, accountId, key)).toBe(true);

    // Wait for expiry and verify flag is not set
    return new Promise(resolve => {
      setTimeout(() => {
        expect(LocalStorage.getFlag(store, accountId, key)).toBe(false);
        resolve();
      }, expiry + 100); // wait a bit more than expiry time to ensure the flag has expired
    });
  });

  it('clearAll method', () => {
    LocalStorage.set('testKey1', 'testValue1');
    LocalStorage.set('testKey2', 'testValue2');
    LocalStorage.clearAll();
    expect(LocalStorage.get('testKey1')).toBeNull();
    expect(LocalStorage.get('testKey2')).toBeNull();
  });

  it('set method with non-object value', () => {
    LocalStorage.set('testKey', 'testValue');
    expect(LocalStorage.get('testKey')).toBe('testValue');
  });

  it('set and get methods with null value', () => {
    LocalStorage.set('testKey', null);
    expect(LocalStorage.get('testKey')).toBeNull();
  });

  it('set and get methods with undefined value', () => {
    LocalStorage.set('testKey', undefined);
    expect(LocalStorage.get('testKey')).toBe('undefined');
  });

  it('set and get methods with boolean value', () => {
    LocalStorage.set('testKey', true);
    expect(LocalStorage.get('testKey')).toBe(true);
  });

  it('set and get methods with number value', () => {
    LocalStorage.set('testKey', 42);
    expect(LocalStorage.get('testKey')).toBe(42);
  });
});

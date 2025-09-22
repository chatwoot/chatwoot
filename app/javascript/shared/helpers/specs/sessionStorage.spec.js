import SessionStorage from '../sessionStorage';

// Mocking sessionStorage
const sessionStorageMock = (() => {
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

Object.defineProperty(window, 'sessionStorage', {
  value: sessionStorageMock,
});

describe('SessionStorage utility', () => {
  beforeEach(() => {
    sessionStorage.clear();
  });

  describe('clearAll method', () => {
    it('should clear all items from sessionStorage', () => {
      sessionStorage.setItem('testKey1', 'testValue1');
      sessionStorage.setItem('testKey2', 'testValue2');

      SessionStorage.clearAll();

      expect(sessionStorage.getItem('testKey1')).toBeNull();
      expect(sessionStorage.getItem('testKey2')).toBeNull();
    });
  });

  describe('get method', () => {
    it('should retrieve and parse JSON values correctly', () => {
      const testObject = { a: 1, b: 'test' };
      sessionStorage.setItem('testKey', JSON.stringify(testObject));

      expect(SessionStorage.get('testKey')).toEqual(testObject);
    });

    it('should return null for non-existent keys', () => {
      expect(SessionStorage.get('nonExistentKey')).toBeNull();
    });

    it('should handle non-JSON values by returning the raw value', () => {
      sessionStorage.setItem('testKey', 'plain string value');

      expect(SessionStorage.get('testKey')).toBe('plain string value');
    });

    it('should handle malformed JSON gracefully', () => {
      sessionStorage.setItem('testKey', '{malformed:json}');

      expect(SessionStorage.get('testKey')).toBe('{malformed:json}');
    });
  });

  describe('set method', () => {
    it('should store object values as JSON strings', () => {
      const testObject = { a: 1, b: 'test' };
      SessionStorage.set('testKey', testObject);

      expect(sessionStorage.getItem('testKey')).toBe(
        JSON.stringify(testObject)
      );
    });

    it('should store primitive values directly', () => {
      SessionStorage.set('stringKey', 'test string');
      expect(sessionStorage.getItem('stringKey')).toBe('test string');

      SessionStorage.set('numberKey', 42);
      expect(sessionStorage.getItem('numberKey')).toBe('42');

      SessionStorage.set('booleanKey', true);
      expect(sessionStorage.getItem('booleanKey')).toBe('true');
    });

    it('should handle null values', () => {
      SessionStorage.set('nullKey', null);

      expect(sessionStorage.getItem('nullKey')).toBe('null');
      expect(SessionStorage.get('nullKey')).toBeNull();
    });

    it('should handle undefined values', () => {
      SessionStorage.set('undefinedKey', undefined);

      expect(sessionStorage.getItem('undefinedKey')).toBe('undefined');
    });
  });

  describe('remove method', () => {
    it('should remove an item from sessionStorage', () => {
      SessionStorage.set('testKey', 'testValue');
      expect(SessionStorage.get('testKey')).toBe('testValue');

      SessionStorage.remove('testKey');

      expect(SessionStorage.get('testKey')).toBeNull();
    });

    it('should do nothing when removing a non-existent key', () => {
      expect(() => {
        SessionStorage.remove('nonExistentKey');
      }).not.toThrow();
    });
  });

  describe('Integration of methods', () => {
    it('should set, get, and remove values correctly', () => {
      SessionStorage.set('testKey', { value: 'test' });

      expect(SessionStorage.get('testKey')).toEqual({ value: 'test' });

      SessionStorage.remove('testKey');
      expect(SessionStorage.get('testKey')).toBeNull();
    });

    it('should correctly handle impersonation flag (common use case)', () => {
      SessionStorage.set('impersonationUser', true);

      expect(SessionStorage.get('impersonationUser')).toBe(true);

      expect(sessionStorage.getItem('impersonationUser')).toBe('true');

      SessionStorage.remove('impersonationUser');
      expect(SessionStorage.get('impersonationUser')).toBeNull();
    });
  });
});

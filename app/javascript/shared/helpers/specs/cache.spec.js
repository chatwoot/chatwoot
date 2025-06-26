import { getFromCache, setCache, clearCache } from '../cache';
import { LocalStorage } from '../localStorage';

vi.mock('../localStorage');

describe('Cache Helpers', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2023, 1, 1, 0, 0, 0));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  describe('getFromCache', () => {
    it('returns null when no data is cached', () => {
      LocalStorage.get.mockReturnValue(null);

      const result = getFromCache('test-key');

      expect(result).toBeNull();
      expect(LocalStorage.get).toHaveBeenCalledWith('test-key');
    });

    it('returns cached data when not expired', () => {
      // Current time is 2023-02-01 00:00:00
      // Cache timestamp is 1 hour ago
      const oneHourAgo =
        new Date(2023, 1, 1, 0, 0, 0).getTime() - 60 * 60 * 1000;

      LocalStorage.get.mockReturnValue({
        data: { foo: 'bar' },
        timestamp: oneHourAgo,
      });

      // Default expiry is 24 hours
      const result = getFromCache('test-key');

      expect(result).toEqual({ foo: 'bar' });
      expect(LocalStorage.get).toHaveBeenCalledWith('test-key');
      expect(LocalStorage.remove).not.toHaveBeenCalled();
    });

    it('removes and returns null when data is expired', () => {
      // Current time is 2023-02-01 00:00:00
      // Cache timestamp is 25 hours ago (beyond the default 24-hour expiry)
      const twentyFiveHoursAgo =
        new Date(2023, 1, 1, 0, 0, 0).getTime() - 25 * 60 * 60 * 1000;

      LocalStorage.get.mockReturnValue({
        data: { foo: 'bar' },
        timestamp: twentyFiveHoursAgo,
      });

      const result = getFromCache('test-key');

      expect(result).toBeNull();
      expect(LocalStorage.get).toHaveBeenCalledWith('test-key');
      expect(LocalStorage.remove).toHaveBeenCalledWith('test-key');
    });

    it('respects custom expiry time', () => {
      // Current time is 2023-02-01 00:00:00
      // Cache timestamp is 2 hours ago
      const twoHoursAgo =
        new Date(2023, 1, 1, 0, 0, 0).getTime() - 2 * 60 * 60 * 1000;

      LocalStorage.get.mockReturnValue({
        data: { foo: 'bar' },
        timestamp: twoHoursAgo,
      });

      // Set expiry to 1 hour
      const result = getFromCache('test-key', 60 * 60 * 1000);

      expect(result).toBeNull();
      expect(LocalStorage.get).toHaveBeenCalledWith('test-key');
      expect(LocalStorage.remove).toHaveBeenCalledWith('test-key');
    });

    it('handles errors gracefully', () => {
      LocalStorage.get.mockImplementation(() => {
        throw new Error('Storage error');
      });

      const result = getFromCache('test-key');

      expect(result).toBeNull();
    });
  });

  describe('setCache', () => {
    it('stores data with timestamp', () => {
      const data = { name: 'test' };
      const expectedCacheData = {
        data,
        timestamp: new Date(2023, 1, 1, 0, 0, 0).getTime(),
      };

      setCache('test-key', data);

      expect(LocalStorage.set).toHaveBeenCalledWith(
        'test-key',
        expectedCacheData
      );
    });

    it('handles errors gracefully', () => {
      LocalStorage.set.mockImplementation(() => {
        throw new Error('Storage error');
      });

      // Should not throw
      expect(() => setCache('test-key', { foo: 'bar' })).not.toThrow();
    });
  });

  describe('clearCache', () => {
    it('removes cached data', () => {
      clearCache('test-key');

      expect(LocalStorage.remove).toHaveBeenCalledWith('test-key');
    });

    it('handles errors gracefully', () => {
      LocalStorage.remove.mockImplementation(() => {
        throw new Error('Storage error');
      });

      // Should not throw
      expect(() => clearCache('test-key')).not.toThrow();
    });
  });
});

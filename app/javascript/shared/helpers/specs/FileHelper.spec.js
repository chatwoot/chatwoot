import {
  DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE,
  formatBytes,
  fileSizeInMegaBytes,
  checkFileSizeLimit,
  resolveMaximumFileUploadSize,
} from '../FileHelper';

describe('#File Helpers', () => {
  describe('formatBytes', () => {
    it('should return zero bytes if 0 is passed', () => {
      expect(formatBytes(0)).toBe('0 Bytes');
    });
    it('should return in bytes if 1000 is passed', () => {
      expect(formatBytes(1000)).toBe('1000 Bytes');
    });
    it('should return in KB if 100000 is passed', () => {
      expect(formatBytes(10000)).toBe('9.77 KB');
    });
    it('should return in MB if 10000000 is passed', () => {
      expect(formatBytes(10000000)).toBe('9.54 MB');
    });
  });

  describe('fileSizeInMegaBytes', () => {
    it('should return zero if 0 is passed', () => {
      expect(fileSizeInMegaBytes(0)).toBe(0);
    });
    it('should return 19.07 if 20000000 is passed', () => {
      expect(fileSizeInMegaBytes(20000000)).toBeCloseTo(19.07, 2);
    });
  });

  describe('checkFileSizeLimit', () => {
    it('should return false if file with size 62208194 and file size limit 40 are passed', () => {
      expect(checkFileSizeLimit({ file: { size: 62208194 } }, 40)).toBe(false);
    });
    it('should return true if file with size 62208194 and file size limit 40 are passed', () => {
      expect(checkFileSizeLimit({ file: { size: 199154 } }, 40)).toBe(true);
    });
  });

  describe('resolveMaximumFileUploadSize', () => {
    it('should return default when value is undefined', () => {
      expect(resolveMaximumFileUploadSize(undefined)).toBe(
        DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE
      );
    });

    it('should return default when value is not a positive number', () => {
      expect(resolveMaximumFileUploadSize('not-a-number')).toBe(
        DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE
      );
      expect(resolveMaximumFileUploadSize(-5)).toBe(
        DEFAULT_MAXIMUM_FILE_UPLOAD_SIZE
      );
    });

    it('should parse numeric strings and numbers', () => {
      expect(resolveMaximumFileUploadSize('50')).toBe(50);
      expect(resolveMaximumFileUploadSize(75)).toBe(75);
    });
  });
});

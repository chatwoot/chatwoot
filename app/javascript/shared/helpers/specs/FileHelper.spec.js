import {
  formatBytes,
  fileSizeInMegaBytes,
  checkFileSizeLimit,
  fileNameWithEllipsis,
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

  describe('fileNameWithEllipsis', () => {
    it('should return original filename if name length is within limit', () => {
      const file = { name: 'document.pdf' };
      expect(fileNameWithEllipsis(file)).toBe('document.pdf');
    });

    it('should truncate filename if it exceeds max length', () => {
      const file = { name: 'very-long-filename-that-needs-truncating.pdf' };
      expect(fileNameWithEllipsis(file)).toBe(
        'very-long-filename-that-ne….pdf'
      );
    });

    it('should handle files without extension', () => {
      const file = { name: 'README' };
      expect(fileNameWithEllipsis(file)).toBe('README');
    });

    it('should handle files with multiple dots', () => {
      const file = { name: 'archive.tar.gz' };
      expect(fileNameWithEllipsis(file)).toBe('archive.tar.gz');
    });

    it('should handle hidden files', () => {
      const file = { name: '.gitignore' };
      expect(fileNameWithEllipsis(file)).toBe('.gitignore');
    });

    it('should handle both filename and name properties', () => {
      const file = {
        filename: 'from-filename.pdf',
        name: 'from-name.pdf',
      };
      expect(fileNameWithEllipsis(file)).toBe('from-filename.pdf');
    });

    it('should handle special characters', () => {
      const file = { name: 'résumé-2023_final-version.doc' };
      expect(fileNameWithEllipsis(file)).toBe('résumé-2023_final-version.doc');
    });

    it('should handle very short filenames', () => {
      const file = { name: 'a.txt' };
      expect(fileNameWithEllipsis(file)).toBe('a.txt');
    });
  });
});

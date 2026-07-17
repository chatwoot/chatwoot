import {
  formatDate,
  importedCount,
  isActiveIntercomImport,
  statusDotClass,
} from '../importStatus';

describe('importStatus', () => {
  describe('isActiveIntercomImport', () => {
    it('only treats pending or processing Intercom imports as active', () => {
      expect(
        isActiveIntercomImport({
          data_type: 'intercom',
          source_provider: 'intercom',
          status: 'processing',
        })
      ).toBe(true);
      expect(
        isActiveIntercomImport({
          data_type: 'contacts',
          source_provider: null,
          status: 'processing',
        })
      ).toBe(false);
      expect(
        isActiveIntercomImport({
          data_type: 'intercom',
          source_provider: 'intercom',
          status: 'completed',
        })
      ).toBe(false);
    });
  });

  describe('importedCount', () => {
    it('sums Intercom imported stats', () => {
      expect(
        importedCount({
          data_type: 'intercom',
          source_provider: 'intercom',
          processed_records: 20,
          stats: {
            contacts: { imported: 2 },
            conversations: { imported: 3 },
            messages: { imported: 10 },
          },
        })
      ).toBe(15);
    });

    it('uses processed records for legacy imports', () => {
      expect(
        importedCount({
          data_type: 'contacts',
          source_provider: null,
          processed_records: 7,
          stats: {},
        })
      ).toBe(7);
    });
  });

  describe('statusDotClass', () => {
    it('maps each status to its dot color class', () => {
      expect(statusDotClass('pending')).toBe('bg-n-amber-9');
      expect(statusDotClass('processing')).toBe('bg-n-blue-9');
      expect(statusDotClass('completed')).toBe('bg-n-teal-9');
      expect(statusDotClass('completed_with_errors')).toBe('bg-n-amber-9');
      expect(statusDotClass('failed')).toBe('bg-n-ruby-9');
      expect(statusDotClass('abandoned')).toBe('bg-n-slate-9');
    });

    it('falls back to slate for unknown or missing status', () => {
      expect(statusDotClass('unknown')).toBe('bg-n-slate-9');
      expect(statusDotClass(undefined)).toBe('bg-n-slate-9');
    });
  });

  describe('formatDate', () => {
    it('returns a dash for empty values', () => {
      expect(formatDate(null)).toBe('-');
      expect(formatDate('')).toBe('-');
      expect(formatDate(undefined)).toBe('-');
    });

    it('formats a valid date into a readable string', () => {
      const formatted = formatDate('2026-07-10T18:09:00Z');
      expect(formatted).not.toBe('-');
      expect(formatted).toContain('2026');
    });
  });
});

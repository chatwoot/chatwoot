import {
  formatDate,
  importedCount,
  isActiveIntercomImport,
  isActiveIntegrationImport,
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

  describe('isActiveIntegrationImport', () => {
    it('treats matching Freshdesk and Intercom imports as active', () => {
      expect(
        isActiveIntegrationImport({
          data_type: 'freshdesk',
          source_provider: 'freshdesk',
          status: 'pending',
        })
      ).toBe(true);
      expect(
        isActiveIntegrationImport({
          data_type: 'intercom',
          source_provider: 'intercom',
          status: 'processing',
        })
      ).toBe(true);
      expect(
        isActiveIntegrationImport({
          data_type: 'freshdesk',
          source_provider: 'intercom',
          status: 'processing',
        })
      ).toBe(false);
    });
  });

  describe('importedCount', () => {
    it('sums integration imported stats', () => {
      expect(
        importedCount({
          data_type: 'freshdesk',
          source_provider: 'freshdesk',
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

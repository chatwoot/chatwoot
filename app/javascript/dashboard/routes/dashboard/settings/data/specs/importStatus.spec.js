import { importedCount, isActiveIntercomImport } from '../importStatus';

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
});

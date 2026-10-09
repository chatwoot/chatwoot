import { consumeExportDraft, saveExportDraft } from '../exportDraft';

describe('contact export selection transfer', () => {
  afterEach(() => {
    sessionStorage.clear();
    vi.useRealTimers();
  });

  it('preserves a filtered selection exactly and consumes it once', () => {
    const selection = {
      payload: [
        {
          attribute_key: 'email',
          filter_operator: 'contains',
          values: ['example.com'],
        },
      ],
      scope_name: 'Customers',
    };
    const token = saveExportDraft(1, selection);
    expect(consumeExportDraft(1, token)).toEqual(selection);
    expect(() => consumeExportDraft(1, token)).toThrow();
  });

  it('does not substitute all contacts for an unavailable or other-account draft', () => {
    const token = saveExportDraft(1, { label: 'vip' });
    expect(() => consumeExportDraft(2, token)).toThrow();
    expect(consumeExportDraft(1, token)).toEqual({ label: 'vip' });
  });

  it('rejects an expired selection', () => {
    vi.useFakeTimers();
    const token = saveExportDraft(1, { label: 'vip' });
    vi.advanceTimersByTime(31 * 60 * 1000);
    expect(() => consumeExportDraft(1, token)).toThrow();
  });
});

import ContactAPI from 'dashboard/api/contacts';
import {
  DATE_RANGE_TYPES,
  generateURLParams,
  parseURLParams,
  fetchContactDetails,
} from '../searchHelper';

// Mock ContactAPI
vi.mock('dashboard/api/contacts', () => ({
  default: {
    show: vi.fn(),
  },
}));

describe('#generateURLParams', () => {
  it('returns empty object when no parameters provided', () => {
    expect(generateURLParams({})).toEqual({});
  });

  it('generates params with from parameter', () => {
    const result = generateURLParams({ from: 'agent:123' });
    expect(result).toEqual({ from: 'agent:123' });
  });

  it('generates params with inbox_id parameter', () => {
    const result = generateURLParams({ in: 456 });
    expect(result).toEqual({ inbox_id: 456 });
  });

  it('generates params with all basic parameters', () => {
    const result = generateURLParams({
      from: 'contact:789',
      in: 123,
    });
    expect(result).toEqual({
      from: 'contact:789',
      inbox_id: 123,
    });
  });

  describe('with date range', () => {
    it('generates params with date range type only', () => {
      const result = generateURLParams({
        dateRange: { type: DATE_RANGE_TYPES.LAST_7_DAYS },
      });
      expect(result).toEqual({
        range: 'last_7_days',
      });
    });

    it('generates params with BETWEEN date range', () => {
      const result = generateURLParams({
        dateRange: {
          type: DATE_RANGE_TYPES.BETWEEN,
          from: 1640995200,
          to: 1672531199,
        },
      });
      expect(result).toEqual({
        range: 'between',
        since: 1640995200,
        until: 1672531199,
      });
    });

    it('generates params with CUSTOM date range', () => {
      const result = generateURLParams({
        dateRange: {
          type: DATE_RANGE_TYPES.CUSTOM,
          from: 1640995200,
          to: 1672531199,
        },
      });
      expect(result).toEqual({
        range: 'custom',
        since: 1640995200,
        until: 1672531199,
      });
    });

    it('handles date range with missing from/to values', () => {
      const result = generateURLParams({
        dateRange: {
          type: DATE_RANGE_TYPES.BETWEEN,
          from: null,
          to: undefined,
        },
      });
      expect(result).toEqual({
        range: 'between',
      });
    });
  });

  it('generates params with all parameters combined', () => {
    const result = generateURLParams({
      from: 'agent:456',
      in: 789,
      dateRange: {
        type: DATE_RANGE_TYPES.BETWEEN,
        from: 1640995200,
        to: 1672531199,
      },
    });
    expect(result).toEqual({
      from: 'agent:456',
      inbox_id: 789,
      range: 'between',
      since: 1640995200,
      until: 1672531199,
    });
  });

  describe('when advanced search is disabled', () => {
    it('returns empty object when isAdvancedSearchEnabled is false', () => {
      const result = generateURLParams(
        {
          from: 'agent:123',
          in: 456,
          dateRange: {
            type: DATE_RANGE_TYPES.BETWEEN,
            from: 1640995200,
            to: 1672531199,
          },
        },
        false
      );
      expect(result).toEqual({});
    });

    it('strips all filter params when feature flag is disabled', () => {
      const result = generateURLParams(
        {
          from: 'contact:789',
          in: 123,
        },
        false
      );
      expect(result).toEqual({});
    });

    it('strips date range params when feature flag is disabled', () => {
      const result = generateURLParams(
        {
          dateRange: {
            type: DATE_RANGE_TYPES.LAST_7_DAYS,
            from: 1640995200,
            to: 1672531199,
          },
        },
        false
      );
      expect(result).toEqual({});
    });
  });
});

describe('#parseURLParams', () => {
  it('returns default values for empty query', () => {
    const result = parseURLParams({});
    expect(result).toEqual({
      from: null,
      in: null,
      dateRange: {
        type: undefined,
        from: null,
        to: null,
      },
    });
  });

  it('parses from parameter', () => {
    const result = parseURLParams({ from: 'agent:123' });
    expect(result).toEqual({
      from: 'agent:123',
      in: null,
      dateRange: {
        type: undefined,
        from: null,
        to: null,
      },
    });
  });

  it('parses inbox_id parameter as number', () => {
    const result = parseURLParams({ inbox_id: '456' });
    expect(result).toEqual({
      from: null,
      in: 456,
      dateRange: {
        type: undefined,
        from: null,
        to: null,
      },
    });
  });

  it('parses explicit range parameter', () => {
    const result = parseURLParams({
      range: 'last_7_days',
      since: '1640995200',
      until: '1672531199',
    });
    expect(result).toEqual({
      from: null,
      in: null,
      dateRange: {
        type: 'last_7_days',
        from: 1640995200,
        to: 1672531199,
      },
    });
  });

  describe('inferred date range types', () => {
    it('infers BETWEEN type when both since and until are present', () => {
      const result = parseURLParams({
        since: '1640995200',
        until: '1672531199',
      });
      expect(result).toEqual({
        from: null,
        in: null,
        dateRange: {
          type: 'between',
          from: 1640995200,
          to: 1672531199,
        },
      });
    });

    it('prioritizes explicit range over inferred type', () => {
      const result = parseURLParams({
        range: 'custom',
        since: '1640995200',
        until: '1672531199',
      });
      expect(result).toEqual({
        from: null,
        in: null,
        dateRange: {
          type: 'custom',
          from: 1640995200,
          to: 1672531199,
        },
      });
    });
  });

  it('parses all parameters combined', () => {
    const result = parseURLParams({
      from: 'contact:789',
      inbox_id: '123',
      range: 'between',
      since: '1640995200',
      until: '1672531199',
    });
    expect(result).toEqual({
      from: 'contact:789',
      in: 123,
      dateRange: {
        type: 'between',
        from: 1640995200,
        to: 1672531199,
      },
    });
  });

  describe('when advanced search is disabled', () => {
    it('returns empty filters when isAdvancedSearchEnabled is false', () => {
      const result = parseURLParams(
        {
          from: 'agent:123',
          inbox_id: '456',
          range: 'between',
          since: '1640995200',
          until: '1672531199',
        },
        false
      );
      expect(result).toEqual({
        from: null,
        in: null,
        dateRange: {
          type: null,
          from: null,
          to: null,
        },
      });
    });

    it('ignores all filter params from URL when feature flag is disabled', () => {
      const result = parseURLParams(
        {
          from: 'contact:789',
          inbox_id: '123',
        },
        false
      );
      expect(result).toEqual({
        from: null,
        in: null,
        dateRange: {
          type: null,
          from: null,
          to: null,
        },
      });
    });

    it('ignores date range params from URL when feature flag is disabled', () => {
      const result = parseURLParams(
        {
          range: 'last_7_days',
          since: '1640995200',
          until: '1672531199',
        },
        false
      );
      expect(result).toEqual({
        from: null,
        in: null,
        dateRange: {
          type: null,
          from: null,
          to: null,
        },
      });
    });
  });
});

describe('#fetchContactDetails', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('returns contact data on successful API call', async () => {
    const mockContactData = {
      id: 123,
      name: 'John Doe',
      email: 'john@example.com',
    };

    ContactAPI.show.mockResolvedValue({
      data: {
        payload: mockContactData,
      },
    });

    const result = await fetchContactDetails(123);
    expect(result).toEqual(mockContactData);
    expect(ContactAPI.show).toHaveBeenCalledWith(123);
  });

  it('returns null on API error', async () => {
    ContactAPI.show.mockRejectedValue(new Error('API Error'));

    const result = await fetchContactDetails(123);
    expect(result).toBeNull();
    expect(ContactAPI.show).toHaveBeenCalledWith(123);
  });

  it('handles different contact ID types', async () => {
    const mockContactData = { id: 456, name: 'Jane Doe' };
    ContactAPI.show.mockResolvedValue({
      data: { payload: mockContactData },
    });

    // Test with string ID
    await fetchContactDetails('456');
    expect(ContactAPI.show).toHaveBeenCalledWith('456');

    // Test with number ID
    await fetchContactDetails(456);
    expect(ContactAPI.show).toHaveBeenCalledWith(456);
  });
});

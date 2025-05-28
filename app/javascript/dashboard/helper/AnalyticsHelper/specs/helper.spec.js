import helperObject, { AnalyticsHelper } from '../';

vi.mock('@june-so/analytics-next', () => ({
  AnalyticsBrowser: {
    load: () => [
      {
        identify: vi.fn(),
        track: vi.fn(),
        page: vi.fn(),
        group: vi.fn(),
      },
    ],
  },
}));

describe('helperObject', () => {
  it('should return an instance of AnalyticsHelper', () => {
    expect(helperObject).toBeInstanceOf(AnalyticsHelper);
  });
});

describe('AnalyticsHelper', () => {
  let analyticsHelper;
  beforeEach(() => {
    analyticsHelper = new AnalyticsHelper({ token: 'test_token' });
  });

  describe('init', () => {
    it('should initialize the analytics browser with the correct token', async () => {
      await analyticsHelper.init();
      expect(analyticsHelper.analytics).not.toBe(null);
    });

    it('should not initialize the analytics browser if token is not provided', async () => {
      analyticsHelper = new AnalyticsHelper();
      await analyticsHelper.init();
      expect(analyticsHelper.analytics).toBe(null);
    });
  });

  describe('identify', () => {
    beforeEach(() => {
      analyticsHelper.analytics = { identify: vi.fn(), group: vi.fn() };
    });

    it('should call identify on analytics browser with correct arguments', () => {
      analyticsHelper.identify({
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        avatar_url: 'avatar_url',
        accounts: [{ id: '1', name: 'Account 1' }],
        account_id: '1',
      });

      expect(analyticsHelper.analytics.identify).toHaveBeenCalledWith(
        'test@example.com',
        {
          userId: '123',
          email: 'test@example.com',
          name: 'Test User',
          avatar: 'avatar_url',
        }
      );
      expect(analyticsHelper.analytics.group).toHaveBeenCalled();
    });

    it('should call identify on analytics browser without group', () => {
      analyticsHelper.identify({
        id: '123',
        email: 'test@example.com',
        name: 'Test User',
        avatar_url: 'avatar_url',
        accounts: [{ id: '1', name: 'Account 1' }],
        account_id: '5',
      });

      expect(analyticsHelper.analytics.group).not.toHaveBeenCalled();
    });

    it('should not call analytics.page if analytics is null', () => {
      analyticsHelper.analytics = null;
      analyticsHelper.identify({});
      expect(analyticsHelper.analytics).toBe(null);
    });
  });

  describe('track', () => {
    beforeEach(() => {
      analyticsHelper.analytics = { track: vi.fn() };
      analyticsHelper.user = { id: '123' };
    });

    it('should call track on analytics browser with correct arguments', () => {
      analyticsHelper.track('Test Event', { prop1: 'value1', prop2: 'value2' });
      expect(analyticsHelper.analytics.track).toHaveBeenCalledWith({
        userId: '123',
        event: 'Test Event',
        properties: { prop1: 'value1', prop2: 'value2' },
      });
    });

    it('should call track on analytics browser with default properties', () => {
      analyticsHelper.track('Test Event');
      expect(analyticsHelper.analytics.track).toHaveBeenCalledWith({
        userId: '123',
        event: 'Test Event',
        properties: {},
      });
    });

    it('should not call track on analytics browser if analytics is not initialized', () => {
      analyticsHelper.analytics = null;
      analyticsHelper.track('Test Event', { prop1: 'value1', prop2: 'value2' });
      expect(analyticsHelper.analytics).toBe(null);
    });
  });

  describe('page', () => {
    beforeEach(() => {
      analyticsHelper.analytics = { page: vi.fn() };
    });

    it('should call the analytics.page method with the correct arguments', () => {
      const params = {
        name: 'Test page',
        url: '/test',
      };
      analyticsHelper.page(params);
      expect(analyticsHelper.analytics.page).toHaveBeenCalledWith(params);
    });

    it('should not call analytics.page if analytics is null', () => {
      analyticsHelper.analytics = null;
      analyticsHelper.page();
      expect(analyticsHelper.analytics).toBe(null);
    });
  });
});

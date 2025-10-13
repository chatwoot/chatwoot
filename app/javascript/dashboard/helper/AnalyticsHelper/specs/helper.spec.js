import helperObject, { AnalyticsHelper } from '../';

vi.mock('posthog-js', () => ({
  default: {
    init: vi.fn(),
    identify: vi.fn(),
    capture: vi.fn(),
    group: vi.fn(),
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
    it('should initialize posthog with the correct token', async () => {
      await analyticsHelper.init();
      expect(analyticsHelper.analytics).not.toBe(null);
    });

    it('should not initialize posthog if token is not provided', async () => {
      analyticsHelper = new AnalyticsHelper();
      await analyticsHelper.init();
      expect(analyticsHelper.analytics).toBe(null);
    });
  });

  describe('identify', () => {
    beforeEach(() => {
      analyticsHelper.analytics = { identify: vi.fn(), group: vi.fn() };
    });

    it('should call identify on posthog with correct arguments', () => {
      analyticsHelper.identify({
        id: 123,
        email: 'test@example.com',
        name: 'Test User',
        avatar_url: 'avatar_url',
        accounts: [{ id: 1, name: 'Account 1' }],
        account_id: 1,
      });

      expect(analyticsHelper.analytics.identify).toHaveBeenCalledWith('123', {
        email: 'test@example.com',
        name: 'Test User',
        avatar: 'avatar_url',
      });
      expect(analyticsHelper.analytics.group).toHaveBeenCalledWith(
        'company',
        '1',
        { name: 'Account 1' }
      );
    });

    it('should call identify on posthog without group', () => {
      analyticsHelper.identify({
        id: 123,
        email: 'test@example.com',
        name: 'Test User',
        avatar_url: 'avatar_url',
        accounts: [{ id: 1, name: 'Account 1' }],
        account_id: 5,
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
      analyticsHelper.analytics = { capture: vi.fn() };
      analyticsHelper.user = { id: 123 };
    });

    it('should call capture on posthog with correct arguments', () => {
      analyticsHelper.track('Test Event', { prop1: 'value1', prop2: 'value2' });
      expect(analyticsHelper.analytics.capture).toHaveBeenCalledWith(
        'Test Event',
        { prop1: 'value1', prop2: 'value2' }
      );
    });

    it('should call capture on posthog with default properties', () => {
      analyticsHelper.track('Test Event');
      expect(analyticsHelper.analytics.capture).toHaveBeenCalledWith(
        'Test Event',
        {}
      );
    });

    it('should not call capture on posthog if analytics is not initialized', () => {
      analyticsHelper.analytics = null;
      analyticsHelper.track('Test Event', { prop1: 'value1', prop2: 'value2' });
      expect(analyticsHelper.analytics).toBe(null);
    });
  });

  describe('page', () => {
    beforeEach(() => {
      analyticsHelper.analytics = { capture: vi.fn() };
    });

    it('should call the capture method for pageview with the correct arguments', () => {
      const params = {
        name: 'Test page',
        url: '/test',
      };
      analyticsHelper.page(params);
      expect(analyticsHelper.analytics.capture).toHaveBeenCalledWith(
        '$pageview',
        params
      );
    });

    it('should not call analytics.capture if analytics is null', () => {
      analyticsHelper.analytics = null;
      analyticsHelper.page();
      expect(analyticsHelper.analytics).toBe(null);
    });
  });
});

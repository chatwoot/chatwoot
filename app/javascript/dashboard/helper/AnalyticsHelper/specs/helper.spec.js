import helperObject, { AnalyticsHelper } from '../';

vi.mock('@amplitude/analytics-browser', () => ({
  init: vi.fn(),
  setUserId: vi.fn(),
  identify: vi.fn(),
  setGroup: vi.fn(),
  groupIdentify: vi.fn(),
  track: vi.fn(),
  Identify: vi.fn(() => ({
    set: vi.fn(),
  })),
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
    it('should initialize amplitude with the correct token', async () => {
      await analyticsHelper.init();
      expect(analyticsHelper.analytics).not.toBe(null);
    });

    it('should not initialize amplitude if token is not provided', async () => {
      analyticsHelper = new AnalyticsHelper();
      await analyticsHelper.init();
      expect(analyticsHelper.analytics).toBe(null);
    });
  });

  describe('identify', () => {
    beforeEach(() => {
      analyticsHelper.analytics = {
        setUserId: vi.fn(),
        identify: vi.fn(),
        setGroup: vi.fn(),
        groupIdentify: vi.fn(),
      };
    });

    it('should call setUserId and identify on amplitude with correct arguments', () => {
      analyticsHelper.identify({
        id: 123,
        email: 'test@example.com',
        name: 'Test User',
        avatar_url: 'avatar_url',
        accounts: [{ id: 1, name: 'Account 1' }],
        account_id: 1,
      });

      expect(analyticsHelper.analytics.setUserId).toHaveBeenCalledWith(
        'user-123'
      );
      expect(analyticsHelper.analytics.identify).toHaveBeenCalled();
      expect(analyticsHelper.analytics.setGroup).toHaveBeenCalledWith(
        'company',
        'account-1'
      );
      expect(analyticsHelper.analytics.groupIdentify).toHaveBeenCalled();
    });

    it('should call identify on amplitude without group', () => {
      analyticsHelper.identify({
        id: 123,
        email: 'test@example.com',
        name: 'Test User',
        avatar_url: 'avatar_url',
        accounts: [{ id: 1, name: 'Account 1' }],
        account_id: 5,
      });

      expect(analyticsHelper.analytics.setGroup).not.toHaveBeenCalled();
    });

    it('should not call analytics methods if analytics is null', () => {
      analyticsHelper.analytics = null;
      analyticsHelper.identify({});
      expect(analyticsHelper.analytics).toBe(null);
    });
  });

  describe('track', () => {
    beforeEach(() => {
      analyticsHelper.analytics = { track: vi.fn() };
      analyticsHelper.user = { id: 123 };
    });

    it('should call track on amplitude with correct arguments', () => {
      analyticsHelper.track('Test Event', { prop1: 'value1', prop2: 'value2' });
      expect(analyticsHelper.analytics.track).toHaveBeenCalledWith(
        'Test Event',
        { prop1: 'value1', prop2: 'value2' }
      );
    });

    it('should call track on amplitude with default properties', () => {
      analyticsHelper.track('Test Event');
      expect(analyticsHelper.analytics.track).toHaveBeenCalledWith(
        'Test Event',
        {}
      );
    });

    it('should not call track on amplitude if analytics is not initialized', () => {
      analyticsHelper.analytics = null;
      analyticsHelper.track('Test Event', { prop1: 'value1', prop2: 'value2' });
      expect(analyticsHelper.analytics).toBe(null);
    });
  });

  describe('page', () => {
    beforeEach(() => {
      analyticsHelper.analytics = { track: vi.fn() };
    });

    it('should call the track method for pageview with the correct arguments', () => {
      const pageName = 'home';
      const properties = {
        path: '/test',
        name: 'home',
      };
      analyticsHelper.page(pageName, properties);
      expect(analyticsHelper.analytics.track).toHaveBeenCalledWith(
        '$pageview',
        { pageName: 'home', path: '/test', name: 'home' }
      );
    });

    it('should not call analytics.track if analytics is null', () => {
      analyticsHelper.analytics = null;
      analyticsHelper.page('home');
      expect(analyticsHelper.analytics).toBe(null);
    });
  });
});

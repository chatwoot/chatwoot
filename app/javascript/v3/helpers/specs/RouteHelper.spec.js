import { validateRouteAccess, isOnOnboardingView } from '../RouteHelper';
import { clearBrowserSessionCookies } from 'dashboard/store/utils/api';
import { replaceRouteWithReload } from '../CommonHelper';
import Cookies from 'js-cookie';

const next = vi.fn();
vi.mock('dashboard/store/utils/api', () => ({
  clearBrowserSessionCookies: vi.fn(),
}));
vi.mock('../CommonHelper', () => ({ replaceRouteWithReload: vi.fn() }));

describe('#validateRouteAccess', () => {
  beforeEach(() => {
    vi.spyOn(Cookies, 'set');
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('reset cookies and continues to the login page if the SSO parameters are present', () => {
    validateRouteAccess(
      {
        name: 'login',
        query: { sso_auth_token: 'random_token', email: 'random@email.com' },
      },
      next
    );
    expect(clearBrowserSessionCookies).toHaveBeenCalledTimes(1);
    expect(next).toHaveBeenCalledTimes(1);
  });

  it('ignore session and continue to the page if the ignoreSession is present in route definition', () => {
    validateRouteAccess(
      {
        name: 'login',
        meta: { ignoreSession: true },
      },
      next
    );
    expect(clearBrowserSessionCookies).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalledTimes(1);
  });

  it('redirects to dashboard if auth cookie is present', () => {
    vi.spyOn(Cookies, 'get').mockReturnValueOnce(true);

    validateRouteAccess({ name: 'login' }, next);
    expect(clearBrowserSessionCookies).not.toHaveBeenCalled();
    expect(replaceRouteWithReload).toHaveBeenCalledWith('/app/');
    expect(next).not.toHaveBeenCalled();
  });

  it('redirects to login if route is empty', () => {
    validateRouteAccess({}, next);
    expect(clearBrowserSessionCookies).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalledWith('/app/login');
  });

  it('redirects to login if signup is disabled', () => {
    validateRouteAccess({ meta: { requireSignupEnabled: true } }, next, {
      signupEnabled: 'true',
    });
    expect(clearBrowserSessionCookies).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalledWith('/app/login');
  });

  it('continues to the route in every other case', () => {
    validateRouteAccess({ name: 'reset_password' }, next);
    expect(clearBrowserSessionCookies).not.toHaveBeenCalled();
    expect(next).toHaveBeenCalledWith();
  });
});

describe('isOnOnboardingView', () => {
  test('returns true for a route with onboarding name', () => {
    const route = { name: 'onboarding_welcome' };
    expect(isOnOnboardingView(route)).toBe(true);
  });

  test('returns false for a route without onboarding name', () => {
    const route = { name: 'home' };
    expect(isOnOnboardingView(route)).toBe(false);
  });

  test('returns false for a route with null name', () => {
    const route = { name: null };
    expect(isOnOnboardingView(route)).toBe(false);
  });

  test('returns false for an  undefined route object', () => {
    expect(isOnOnboardingView()).toBe(false);
  });
});

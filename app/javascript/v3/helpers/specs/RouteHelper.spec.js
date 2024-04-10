import { validateRouteAccess } from '../RouteHelper';
import { clearBrowserSessionCookies } from 'dashboard/store/utils/api';
import { replaceRouteWithReload } from '../CommonHelper';
import Cookies from 'js-cookie';

const next = jest.fn();
jest.mock('dashboard/store/utils/api', () => ({
  clearBrowserSessionCookies: jest.fn(),
}));
jest.mock('../CommonHelper', () => ({ replaceRouteWithReload: jest.fn() }));

jest.mock('js-cookie', () => ({
  getJSON: jest.fn(),
}));

Cookies.getJSON.mockReturnValueOnce(true).mockReturnValue(false);
describe('#validateRouteAccess', () => {
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
    Cookies.getJSON.mockImplementation(() => true);
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

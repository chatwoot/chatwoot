import {
  getLoadingStatus,
  parseAPIErrorResponse,
  setAuthCredentials,
  setLoadingStatus,
  throwErrorMessage,
  parseLinearAPIErrorResponse,
} from '../api';

describe('#getLoadingStatus', () => {
  it('returns correct status', () => {
    expect(getLoadingStatus({ fetchAPIloadingStatus: true })).toBe(true);
  });
});

describe('#setLoadingStatus', () => {
  it('set correct status', () => {
    const state = { fetchAPIloadingStatus: true };
    setLoadingStatus(state, false);
    expect(state.fetchAPIloadingStatus).toBe(false);
  });
});

describe('#parseAPIErrorResponse', () => {
  it('returns correct values', () => {
    expect(
      parseAPIErrorResponse({
        response: { data: { message: 'Error Message [message]' } },
      })
    ).toBe('Error Message [message]');

    expect(
      parseAPIErrorResponse({
        response: { data: { error: 'Error Message [error]' } },
      })
    ).toBe('Error Message [error]');

    expect(parseAPIErrorResponse('Error: 422 Failed')).toBe(
      'Error: 422 Failed'
    );
  });
});

describe('#throwErrorMessage', () => {
  it('throws correct error', () => {
    const errorFn = function throwErrorMessageFn() {
      throwErrorMessage({
        response: { data: { message: 'Error Message [message]' } },
      });
    };
    expect(errorFn).toThrow('Error Message [message]');
  });
});

describe('#parseLinearAPIErrorResponse', () => {
  it('returns correct values', () => {
    expect(
      parseLinearAPIErrorResponse(
        {
          response: {
            data: {
              error: {
                errors: [
                  {
                    message: 'Error Message [message]',
                  },
                ],
              },
            },
          },
        },
        'Default Message'
      )
    ).toBe('Error Message [message]');
  });
});

describe('#setAuthCredentials', () => {
  let cookieSpy;

  beforeEach(() => {
    cookieSpy = vi.spyOn(Cookies, 'set').mockImplementation(() => {});
  });

  afterEach(() => {
    cookieSpy.mockRestore();
  });

  it('sets cookie expiry using exact Date object, preserving fractional day lifespans', () => {
    const expiryDate = new Date(Date.now() + 12 * 60 * 60 * 1000);
    const expiryUnix = Math.floor(expiryDate.getTime() / 1000).toString();

    const mockResponse = {
      headers: {
        expiry: expiryUnix,
        'token-type': 'Bearer',
        uid: 'test@example.com',
        'access-token': 'abc123',
        client: 'client123',
      },
      data: { data: { id: 1, name: 'Test User' } },
    };

    setAuthCredentials(mockResponse);

    expect(cookieSpy).toHaveBeenCalledWith(
      'cw_d_session_info',
      JSON.stringify(mockResponse.headers),
      expect.objectContaining({
        expires: expect.any(Date),
      })
    );
  });

  it('does not truncate sub-day token lifespans to zero', () => {
    const expiryDate = new Date(Date.now() + 6 * 60 * 60 * 1000);
    const expiryUnix = Math.floor(expiryDate.getTime() / 1000).toString();

    const mockResponse = {
      headers: {
        expiry: expiryUnix,
        'token-type': 'Bearer',
        uid: 'test@example.com',
        'access-token': 'abc123',
        client: 'client123',
      },
      data: { data: { id: 1 } },
    };

    setAuthCredentials(mockResponse);

    const callArgs = cookieSpy.mock.calls[0];
    const cookieOptions = callArgs[2];

    expect(cookieOptions.expires).toBeInstanceOf(Date);
    expect(cookieOptions.expires).not.toBe(0);
  });
});

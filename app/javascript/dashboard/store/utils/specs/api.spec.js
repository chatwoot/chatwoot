import {
  getLoadingStatus,
  parseAPIErrorResponse,
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

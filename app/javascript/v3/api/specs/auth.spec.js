import { registerV2, accountSetup } from '../auth';
import MockAdapter from 'axios-mock-adapter';
import wootAPI from '../apiClient';

describe('Auth Helpers', () => {
  let mock;
  beforeEach(() => {
    mock = new MockAdapter(wootAPI);

    window.bus = {
      $emit: jest.fn(),
      $on: jest.fn(),
      $off: jest.fn(),
    };
  });

  afterEach(() => {
    mock.reset();
  });

  describe('registerV2', () => {
    const creds = {
      email: 'test@example.com',
      password: 'password',
      hCaptchaClientResponse: 'testResponse',
    };

    const expiry = Math.floor(new Date().getTime() / 1000) + 60 * 60 * 24;

    const response = {
      headers: { expiry },
      data: { data: 'testData' },
    };

    it('calls when all data is present', async () => {
      mock
        .onPost('api/v2/accounts', {
          email: creds.email,
          password: creds.password,
          h_captcha_client_response: creds.hCaptchaClientResponse,
        })
        .reply(200, response.data, response.headers);

      const result = await registerV2(creds);
      expect(result).toEqual(response.data);
    });
  });

  describe('accountSetup', () => {
    const payload = {
      id: 123,
      name: 'test-account-details',
      locale: 'en-US',
    };

    const response = {
      data: { data: 'testData' },
    };

    it('calls when all data is present', async () => {
      mock
        .onPut(`api/v2/accounts/${payload.id}`, {
          name: payload.name,
          locale: payload.locale,
        })
        .reply(200, response.data);

      const result = await accountSetup(payload);
      expect(result).toEqual(response.data);
    });
  });
});

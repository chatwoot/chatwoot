import { register } from '../auth';
import MockAdapter from 'axios-mock-adapter';
import wootAPI from '../../wootAPI';

describe('register', () => {
  it('should send a POST request to the correct endpoint with the correct body', async () => {
    const mock = new MockAdapter(wootAPI);
    const creds = {
      accountName: 'Test Account',
      fullName: 'Test User',
      email: 'test@example.com',
      password: 'password',
      hCaptchaClientResponse: 'testResponse',
    };
    const response = { data: 'testData' };

    mock
      .onPost('api/v1/accounts.json', {
        account_name: creds.accountName.trim(),
        user_full_name: creds.fullName.trim(),
        email: creds.email,
        password: creds.password,
        h_captcha_client_response: creds.hCaptchaClientResponse,
      })
      .reply(200, response);

    const result = await register(creds);

    expect(result).toEqual(response.data);
  });

  it('should throw an error if the request fails', async () => {
    const mock = new MockAdapter(wootAPI);
    const creds = {
      accountName: 'Test Account',
      fullName: 'Test User',
      email: 'test@example.com',
      password: 'password',
      hCaptchaClientResponse: 'testResponse',
    };

    mock.onPost('api/v1/accounts.json').reply(500);

    await expect(register(creds)).rejects.toThrow();
  });
});

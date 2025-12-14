import { test as base, expect } from '@playwright/test';

type AuthFixtures = {
  apiToken: string;
  authHeaders: {
    accessToken: string;
    client: string;
    uid: string;
  };
};

// Extend base test with authentication fixtures
export const test = base.extend<AuthFixtures>({
  // Fixture for API access token (permanent token)
  apiToken: async ({ request }, use) => {
    console.log('🔐 Authenticating via API...');

    // Step 1: Sign in
    const signInResponse = await request.post('/auth/sign_in', {
      data: {
        email: process.env.TEST_USER_EMAIL || 'admin@chatwoot.com',
        password: process.env.TEST_USER_PASSWORD || 'Password123@#',
        sso_auth_token: '',
      },
    });

    expect(signInResponse.ok()).toBeTruthy();

    // Extract auth headers from response
    const headers = signInResponse.headers();
    const accessToken = headers['access-token'];
    const client = headers['client'];
    const uid = headers['uid'];

    expect(accessToken).toBeTruthy();
    expect(client).toBeTruthy();
    expect(uid).toBeTruthy();

    // Step 2: Get profile to retrieve permanent API token
    const profileResponse = await request.get('/api/v1/profile', {
      headers: {
        'access-token': accessToken,
        client: client,
        uid: uid,
      },
    });

    expect(profileResponse.ok()).toBeTruthy();

    const profile = await profileResponse.json();
    const apiToken = profile.access_token;

    expect(apiToken).toBeTruthy();
    console.log('✅ API Token obtained:', apiToken.substring(0, 20) + '...');

    // Use the token in tests
    await use(apiToken);

    // Cleanup (if needed)
    console.log('🧹 Authentication cleanup complete');
  },

  // Fixture for DeviseTokenAuth headers (if you need session-based auth)
  authHeaders: async ({ request }, use) => {
    // Step 1: Sign in
    const signInResponse = await request.post('/auth/sign_in', {
      data: {
        email: process.env.TEST_USER_EMAIL || 'admin@chatwoot.com',
        password: process.env.TEST_USER_PASSWORD || 'Password123@#',
        sso_auth_token: '',
      },
    });

    expect(signInResponse.ok()).toBeTruthy();

    // Extract auth headers
    const headers = signInResponse.headers();
    const authHeaders = {
      accessToken: headers['access-token'],
      client: headers['client'],
      uid: headers['uid'],
    };

    await use(authHeaders);
  },
});

export { expect };
import { AuthComponent } from '@components/api';

export async function getAuthHeaders(email: string, password: string, baseUrl: string = process.env.BASE_URL || 'http://localhost:3000') {
  const authComponent = new AuthComponent(baseUrl);
  return await authComponent.login(email, password);
}

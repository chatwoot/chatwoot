import routes from './routes';

describe('authentication routes', () => {
  const loginRoute = routes.find(route => route.name === 'login');

  it('preserves Shopify return parameters as a billing redirect', () => {
    const props = loginRoute.props({
      query: {
        plan_handle: 'growth',
        shop: 'store.myshopify.com',
      },
    });

    expect(props.redirectUrl).toBe(
      'settings/billing?plan_handle=growth&shop=store.myshopify.com'
    );
  });

  it('keeps an explicit login redirect', () => {
    const props = loginRoute.props({
      query: {
        redirect_url: 'accounts/42/dashboard',
        shop: 'store.myshopify.com',
      },
    });

    expect(props.redirectUrl).toBe('accounts/42/dashboard');
  });
});

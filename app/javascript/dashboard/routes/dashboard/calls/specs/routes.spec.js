import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { routes } from '../routes';

describe('calls routes', () => {
  it('gates the calls dashboard on the voice channel feature flag', () => {
    const callsRoute = routes.find(
      route => route.name === 'calls_dashboard_index'
    );

    expect(callsRoute.meta.featureFlag).toBe(FEATURE_FLAGS.CHANNEL_VOICE);
  });
});

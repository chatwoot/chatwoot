import { flushPromises, mount } from '@vue/test-utils';
import Reauthorize from '../Reauthorize.vue';
import instagramClient from 'dashboard/api/channel/instagramClient';

vi.mock('dashboard/api/channel/instagramClient', () => ({
  default: { generateAuthorization: vi.fn() },
}));

describe('Instagram reauthorization', () => {
  it('includes the original inbox in the authorization request', async () => {
    Object.defineProperty(window, 'location', {
      configurable: true,
      value: { href: '' },
      writable: true,
    });
    instagramClient.generateAuthorization.mockResolvedValue({
      data: { url: 'https://www.facebook.com/dialog/oauth?state=signed' },
    });
    const wrapper = mount(Reauthorize, {
      props: { inbox: { id: 396 } },
      global: {
        stubs: {
          InboxReconnectionRequired: {
            template:
              '<button @click="$emit(\'reauthorize\')">Reconnect</button>',
          },
        },
      },
    });
    await wrapper.find('button').trigger('click');
    await flushPromises();
    expect(instagramClient.generateAuthorization).toHaveBeenCalledWith({
      inbox_id: 396,
    });
    expect(window.location.href).toBe(
      'https://www.facebook.com/dialog/oauth?state=signed'
    );
  });
});

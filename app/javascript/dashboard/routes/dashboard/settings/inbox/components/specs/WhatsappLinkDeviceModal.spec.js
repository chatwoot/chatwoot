import { shallowMount, flushPromises } from '@vue/test-utils';
import WhatsappLinkDeviceModal from '../WhatsappLinkDeviceModal.vue';

const KEY = 'INBOX_MGMT.ADD.WHATSAPP.EXTERNAL_PROVIDER.LINK_DEVICE_MODAL';
const IMPORT_TITLE_KEY = `${KEY}.IMPORT_SESSION_TITLE`;
const USE_PAIRING_CODE_KEY = `${KEY}.USE_PAIRING_CODE`;
const USE_QRCODE_KEY = `${KEY}.USE_QRCODE`;
const LOADING_PAIRING_CODE_KEY = `${KEY}.LOADING_PAIRING_CODE`;

const DISCONNECT_KEY = `${KEY}.DISCONNECT`;
const LINK_DEVICE_KEY = `${KEY}.LINK_DEVICE`;
const RECONNECTING_KEY = `${KEY}.RECONNECTING`;

const dispatch = vi.fn(() => Promise.resolve());

vi.mock('vuex', () => ({
  useStore: () => ({ dispatch: (...args) => dispatch(...args) }),
}));

const mountModal = (
  capabilities,
  providerConnection = { connection: 'close' }
) =>
  shallowMount(WhatsappLinkDeviceModal, {
    props: {
      show: true,
      onClose: () => {},
      inbox: {
        id: 1,
        name: 'WhatsApp',
        capabilities,
        provider_connection: providerConnection,
      },
    },
    global: {
      mocks: { $t: key => key },
      stubs: {
        'woot-modal': { template: '<div><slot /></div>' },
        'router-link': true,
        // The default stub swallows the slot, and the slot is where the button's
        // label lives — which is the whole thing these examples assert on.
        Button: {
          props: ['label', 'variant', 'color'],
          template:
            '<button :data-variant="variant" :data-color="color">{{ label }}<slot /></button>',
        },
      },
    },
  });

beforeEach(() => dispatch.mockClear());

describe('WhatsappLinkDeviceModal', () => {
  // A proxy change: the connector redials through the new proxy on its own. The record
  // carries no error for it, and the modal shows the reconnect rather than a failure
  // with the button to pair the phone again.
  it('shows a reconnect with no error as a reconnect, with nothing to pair', () => {
    const wrapper = mountModal(['qr_pairing'], { connection: 'reconnecting' });

    expect(wrapper.html()).toContain(RECONNECTING_KEY);
    expect(wrapper.html()).not.toContain(LINK_DEVICE_KEY);
  });

  // The redial of that reconnect is `connecting`, which is also what a pairing reads as.
  // The account is paired: the QR loader would be asking for a scan nobody needs.
  it('keeps showing the reconnect while its redial is connecting', () => {
    const wrapper = mountModal(['qr_pairing'], {
      connection: 'connecting',
      rerouting: true,
    });

    expect(wrapper.html()).toContain(RECONNECTING_KEY);
    expect(wrapper.html()).not.toContain(`${KEY}.LOADING_QRCODE`);
  });

  it('shows the cause when a reconnect carries one', () => {
    const wrapper = mountModal(['qr_pairing'], {
      connection: 'reconnecting',
      error: 'The proxy is not answering.',
    });

    expect(wrapper.html()).toContain('The proxy is not answering.');
    expect(wrapper.html()).not.toContain(RECONNECTING_KEY);
  });

  // The extension hands over Baileys credentials, so a provider that cannot consume
  // them must not be offered an install and a scan that end in a refused request.
  it('hides the session import when the provider cannot accept one', () => {
    const wrapper = mountModal(['qr_pairing']);

    expect(wrapper.html()).not.toContain(IMPORT_TITLE_KEY);
  });

  it('offers the session import when the provider declares it', () => {
    const wrapper = mountModal(['qr_pairing', 'session_import']);

    expect(wrapper.html()).toContain(IMPORT_TITLE_KEY);
  });

  describe('pairing by code', () => {
    const connecting = {
      connection: 'connecting',
      qr_data_url: 'data:image/png;base64,x',
    };

    it('is not offered by a provider that cannot do it', () => {
      const wrapper = mountModal(['qr_pairing'], connecting);

      expect(wrapper.html()).not.toContain(USE_PAIRING_CODE_KEY);
    });

    it('is offered next to the QR when the provider declares it', () => {
      const wrapper = mountModal(['qr_pairing', 'code_pairing'], connecting);

      expect(wrapper.html()).toContain(USE_PAIRING_CODE_KEY);
    });

    // The code takes a moment to arrive, and the QR is still on the record until it
    // does: leaving it up would put the operator back on the thing they just said they
    // could not use.
    it('waits for the code instead of falling back to the QR', async () => {
      const wrapper = mountModal(['qr_pairing', 'code_pairing'], connecting);

      await wrapper.find('button').trigger('click');
      await flushPromises();

      expect(dispatch).toHaveBeenCalledWith('inboxes/requestPairingCode', 1);
      expect(wrapper.html()).toContain(LOADING_PAIRING_CODE_KEY);
      expect(wrapper.html()).not.toContain('data:image/png;base64,x');
    });

    // The provider can answer a code pairing with a QR alongside the code (uazapi keeps
    // rotating one), and this component's request is client-side state that a blip in
    // the connection resets to the QR. Both together hid a perfectly good code behind
    // the QR branch, which is what an operator reported as "the code never shows up".
    it('shows the code even when the mode was reset and a QR is on the record', () => {
      const wrapper = mountModal(['qr_pairing', 'code_pairing'], {
        connection: 'connecting',
        qr_data_url: 'data:image/png;base64,x',
        pairing_code: 'K7QP-2M4X',
      });

      expect(wrapper.html()).toContain('K7QP-2M4X');
      expect(wrapper.html()).not.toContain('data:image/png;base64,x');
    });

    // The option used to live only inside the `connecting` branch, so reaching it meant
    // starting the QR first. That is the one state a provider can refuse to issue a code
    // from, which left the way in through the thing the operator already said they could
    // not use.
    it('is offered before the pairing starts, not only during it', async () => {
      const wrapper = mountModal(['qr_pairing', 'code_pairing'], {
        connection: 'close',
      });

      expect(wrapper.html()).toContain(USE_PAIRING_CODE_KEY);

      await wrapper.findAll('button')[1].trigger('click');
      await flushPromises();

      expect(dispatch).toHaveBeenCalledWith('inboxes/requestPairingCode', 1);
    });

    it('spells the phone steps out one by one under the code', () => {
      const wrapper = mountModal(['qr_pairing', 'code_pairing'], {
        connection: 'connecting',
        pairing_code: 'K7QP-2M4X',
      });

      expect(wrapper.html()).toContain(`${KEY}.PAIRING_CODE_STEP_1`);
      expect(wrapper.html()).toContain(`${KEY}.PAIRING_CODE_STEP_3`);
      expect(wrapper.html()).toContain(`${KEY}.PAIRING_CODE_EXPIRES`);
    });

    // Refreshing the inboxes from here replaces them in the store, which re-renders the
    // settings page this is mounted inside and takes the modal down with it: the operator
    // clicks the button and nothing opens. What is on screen is kept current by the cable
    // and by the poll behind the pairing.
    it('opens on the record it was given, without reloading the inboxes', async () => {
      const wrapper = mountModal(['qr_pairing', 'code_pairing'], {
        connection: 'connecting',
        pairing_code: 'K7QP-2M4X',
      });
      await flushPromises();

      expect(dispatch).not.toHaveBeenCalledWith('inboxes/get');
      expect(wrapper.html()).toContain('K7QP-2M4X');
    });

    // Closing the screen is not abandoning the account: it used to disconnect on the way
    // out, and on a provider that issues a code only from a disconnected instance that
    // turned a look-and-close into a new round of pairing.
    it('leaves the pairing alone when the screen is closed', async () => {
      const wrapper = mountModal(['qr_pairing', 'code_pairing'], {
        connection: 'connecting',
        pairing_code: 'K7QP-2M4X',
      });
      await flushPromises();
      dispatch.mockClear();

      wrapper.unmount();

      expect(dispatch).not.toHaveBeenCalledWith(
        'inboxes/disconnectChannelProvider',
        1
      );
    });

    it('shows the code the provider issued, and the way back to the QR', async () => {
      const wrapper = mountModal(['qr_pairing', 'code_pairing'], {
        ...connecting,
        pairing_code: 'K7QP-2M4X',
      });

      await wrapper.find('button').trigger('click');
      await flushPromises();

      expect(wrapper.html()).toContain('K7QP-2M4X');
      expect(wrapper.html()).toContain(USE_QRCODE_KEY);
    });
  });

  // A send stall leaves the connection reading 'open'. The error branch used to win
  // regardless, which hid Disconnect and offered a setup call that only refreshes
  // presence on a socket the provider already considers live: the one action that
  // cannot repair the fault was the only one on offer.
  it('offers disconnect, not setup, when an open connection is stalled', () => {
    const wrapper = mountModal(['qr_pairing'], {
      connection: 'open',
      error: 'This connection cannot send messages.',
      send_stall: { consecutive_timeouts: 3, action: 'suppressed' },
    });

    const html = wrapper.html();
    expect(html).toContain(DISCONNECT_KEY);
    expect(html).not.toContain(LINK_DEVICE_KEY);
    expect(html).toContain('This connection cannot send messages.');
  });

  // The error is still the whole story when the connection is genuinely down:
  // re-pairing from scratch is the action, and Disconnect would be a no-op.
  it('keeps offering setup when the connection is closed with an error', () => {
    const wrapper = mountModal(['qr_pairing'], {
      connection: 'close',
      error: 'Wrong phone number.',
    });

    const html = wrapper.html();
    expect(html).toContain(LINK_DEVICE_KEY);
    expect(html).not.toContain(DISCONNECT_KEY);
  });
});

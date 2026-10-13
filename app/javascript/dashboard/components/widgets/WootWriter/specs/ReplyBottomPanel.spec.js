import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ReplyBottomPanel from '../ReplyBottomPanel.vue';

const mountPanel = props =>
  shallowMount(ReplyBottomPanel, {
    props: {
      conversationId: 1,
      portalSlug: '',
      inbox: { channel_type: 'Channel::Whatsapp' },
      ...props,
    },
    global: {
      plugins: [
        createStore({
          getters: {
            getCurrentAccountId: () => 1,
            'accounts/isFeatureEnabledonAccount': () => () => false,
            'integrations/getUIFlags': () => ({ isFetching: false }),
            getUISettings: () => ({}),
          },
        }),
      ],
      mocks: { $t: key => key },
      directives: { tooltip: () => {} },
    },
  });

describe('ReplyBottomPanel', () => {
  it('keeps the capability action visible when supported types are unavailable', async () => {
    const wrapper = mountPanel({
      whatsappInteractiveCapabilities: {
        button: {
          implemented: true,
          available: false,
          unavailable_reason: 'temporarily_disabled',
        },
        list: {
          implemented: true,
          available: false,
          unavailable_reason: 'service_window_closed',
        },
      },
    });
    const action = wrapper.find('[icon="i-ph-chat-circle-dots"]');

    expect(action.exists()).toBe(true);
    expect(action.attributes('disabled')).toBeUndefined();
    await action.trigger('click');
    expect(wrapper.emitted('toggleWhatsappInteractive')).toHaveLength(1);
  });

  it('does not duplicate or replace the existing location action', () => {
    const wrapper = mountPanel({
      enableLocationRequest: true,
      whatsappInteractiveCapabilities: {
        button: { implemented: true, available: true },
        list: { implemented: true, available: true },
      },
    });
    const icons = wrapper
      .findAll('[icon]')
      .map(button => button.attributes('icon'));

    expect(icons.filter(icon => icon === 'i-ph-map-pin')).toHaveLength(1);
    expect(icons.filter(icon => icon === 'i-ph-chat-circle-dots')).toHaveLength(
      1
    );
  });

  it('uses open copy when any supported type remains available', () => {
    const wrapper = mountPanel({
      whatsappInteractiveCapabilities: {
        button: { implemented: true, available: true },
        list: {
          implemented: true,
          available: false,
          unavailable_reason: 'service_window_closed',
        },
      },
    });

    expect(wrapper.vm.whatsappInteractiveTooltip).toBe(
      'CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.OPEN'
    );
  });

  it('uses a current restriction when every supported type is unavailable', () => {
    const wrapper = mountPanel({
      whatsappInteractiveCapabilities: {
        button: {
          implemented: true,
          available: false,
          unavailable_reason: 'temporarily_disabled',
        },
        list: {
          implemented: true,
          available: false,
          unavailable_reason: 'service_window_closed',
        },
      },
    });

    expect(wrapper.vm.whatsappInteractiveTooltip).toBe(
      'CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.UNAVAILABLE.temporarily_disabled'
    );
  });

  it('uses generic open copy when every supported type is available', () => {
    const wrapper = mountPanel({
      whatsappInteractiveCapabilities: {
        button: { implemented: true, available: true },
        list: { implemented: true, available: true },
      },
    });

    expect(wrapper.vm.whatsappInteractiveTooltip).toBe(
      'CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.OPEN'
    );
  });
});

import { shallowMount } from '@vue/test-utils';
import Message from '../Message.vue';

vi.mock('dashboard/composables', () => ({ useTrack: vi.fn() }));
vi.mock('dashboard/composables/store', async () => {
  const { ref } = await import('vue');
  return {
    useMapGetter: key => ref(key === 'inboxes/getInbox' ? () => ({}) : false),
  };
});
vi.mock('vue-router', () => ({ useRoute: () => ({ query: {} }) }));
vi.mock('shared/composables/useBranding', () => ({
  useBranding: () => ({ replaceInstallationName: value => value }),
}));

const createWrapper = ({
  type = 'button',
  status = 'sent',
  contentAttributes = {},
} = {}) => {
  return shallowMount(Message, {
    props: {
      id: 42,
      messageType: 1,
      status,
      content: 'Stored interactive body',
      contentAttributes: {
        whatsappInteractive: { type, body: { text: 'Stored body' } },
        ...contentAttributes,
      },
      conversationId: 7,
      createdAt: 1_700_000_000,
      currentUserId: 1,
    },
    global: {
      stubs: {
        WhatsAppInteractiveBubble: {
          template: '<div data-testid="whatsapp-interactive-bubble" />',
        },
        TextBubble: { template: '<div data-testid="text-bubble" />' },
        MessageError: {
          props: ['error'],
          template: '<div data-testid="message-error">{{ error }}</div>',
        },
      },
    },
  });
};

describe('Message', () => {
  it.each(['button', 'list', 'carousel', 'cta_url'])(
    'routes a stored %s snapshot to the structured bubble',
    type => {
      const wrapper = createWrapper({ type });

      expect(
        wrapper.find('[data-testid="whatsapp-interactive-bubble"]').exists()
      ).toBe(true);
      expect(wrapper.find('[data-testid="text-bubble"]').exists()).toBe(false);
    }
  );

  it('hides a preserved failure reason while an accepted retry is pending', () => {
    const wrapper = createWrapper({
      status: 'pending',
      contentAttributes: { externalError: 'Previous provider failure' },
    });

    expect(wrapper.find('[data-testid="message-error"]').exists()).toBe(false);
  });

  it('shows the current actionable reason and one retry presentation when failed', () => {
    const wrapper = createWrapper({
      status: 'failed',
      contentAttributes: { externalError: 'Current provider failure' },
    });

    expect(wrapper.findAll('[data-testid="message-error"]')).toHaveLength(1);
    expect(wrapper.get('[data-testid="message-error"]').text()).toBe(
      'Current provider failure'
    );
  });

  it('keeps structured inbound selections on the ordinary text bubble path', () => {
    const wrapper = createWrapper({
      contentAttributes: {
        whatsappInteractive: undefined,
        whatsappInteractiveReply: {
          type: 'list_reply',
          title: 'Pasta',
          deliveryId: 'row-1',
        },
      },
    });

    expect(wrapper.find('[data-testid="text-bubble"]').exists()).toBe(true);
    expect(
      wrapper.find('[data-testid="whatsapp-interactive-bubble"]').exists()
    ).toBe(false);
  });
});

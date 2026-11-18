import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ChatFooter from '../ChatFooter.vue';

vi.mock('vue-router', () => ({ useRouter: () => ({ replace: vi.fn() }) }));

describe('ChatFooter', () => {
  let sendAttachment;

  const mountFooter = () =>
    shallowMount(ChatFooter, {
      global: {
        plugins: [
          createStore({
            modules: {
              appConfig: {
                namespaced: true,
                getters: {
                  getWidgetColor: () => '#1f93ff',
                  isWidgetStyleFlat: () => false,
                },
              },
              conversation: {
                namespaced: true,
                getters: { getConversationSize: () => 1 },
                actions: {
                  sendAttachment: (_, params) => sendAttachment(params),
                },
              },
              conversationAttributes: {
                namespaced: true,
                getters: { getConversationParams: () => ({ status: 'open' }) },
                actions: { getAttributes: () => {} },
              },
              contacts: {
                namespaced: true,
                getters: { getCurrentUser: () => ({}) },
              },
            },
          }),
        ],
        mocks: { $t: key => key },
      },
    });

  const sendWith = wrapper =>
    wrapper.findComponent({ name: 'ChatInputWrap' }).props('onSendAttachment')(
      [{ file: 'blob-1' }],
      'see the screen'
    );

  beforeEach(() => {
    window.chatwootWebChannel = { allowMessagesAfterResolved: true };
  });

  it('keeps the reply target when the attachment message fails', async () => {
    sendAttachment = vi.fn().mockResolvedValue(false);
    const wrapper = mountFooter();
    const message = { id: 42, content: 'Which page?' };
    wrapper.vm.toggleReplyTo(message);

    await sendWith(wrapper);
    expect(wrapper.vm.inReplyTo).toEqual(message);

    sendAttachment.mockResolvedValue(true);
    await sendWith(wrapper);
    expect(sendAttachment).toHaveBeenLastCalledWith(
      expect.objectContaining({ replyTo: 42 })
    );
    expect(wrapper.vm.inReplyTo).toBeNull();
  });
});

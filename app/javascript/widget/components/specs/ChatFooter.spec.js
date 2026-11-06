import { shallowMount, flushPromises } from '@vue/test-utils';
import { nextTick } from 'vue';
import { createStore } from 'vuex';
import { useRouter } from 'vue-router';
import FileUpload from 'vue-upload-component';
import { directive as onClickaway } from 'vue3-click-away';
import { DirectUpload } from 'activestorage';
import CustomButton from 'shared/components/Button.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import { sendEmailTranscript } from 'widget/api/conversation';
import { IFrameHelper } from 'widget/helpers/utils';
import { CHATWOOT_ON_START_CONVERSATION } from 'widget/constants/sdkEvents';
import ChatFooter from '../ChatFooter.vue';
import ChatInputWrap from '../ChatInputWrap.vue';
import FooterReplyTo from '../FooterReplyTo.vue';

vi.mock('vue-router', () => ({ useRouter: vi.fn() }));
vi.mock('widget/api/conversation', () => ({ sendEmailTranscript: vi.fn() }));
vi.mock('activestorage', () => ({
  DirectUpload: vi.fn(function MockDirectUpload(file) {
    this.create = callback => callback(null, { signed_id: file.name });
  }),
}));

describe('ChatFooter', () => {
  let wrapper;
  let store;
  let dispatch;
  let replace;
  let originalChannel;
  let originalCreateObjectURL;

  beforeEach(() => {
    vi.useFakeTimers();
    originalChannel = window.chatwootWebChannel;
    originalCreateObjectURL = window.URL.createObjectURL;
    window.chatwootWebChannel = {
      allowMessagesAfterResolved: false,
      enabledFeatures: ['attachments'],
      websiteToken: 'website-token',
    };
    store = createStore({
      state: () => ({
        status: 'open',
        conversationSize: 1,
        currentUser: { has_email: true },
        widgetColor: '#000000',
        isWidgetStyleFlat: false,
        directUploadsEnabled: false,
      }),
      getters: {
        'conversationAttributes/getConversationParams': state => ({
          status: state.status,
        }),
        'conversation/getConversationSize': state => state.conversationSize,
        'contacts/getCurrentUser': state => state.currentUser,
        'appConfig/getWidgetColor': state => state.widgetColor,
        'appConfig/isWidgetStyleFlat': state => state.isWidgetStyleFlat,
        'appConfig/getIsWidgetOpen': () => false,
        'appConfig/getShouldShowEmojiPicker': () => false,
        'globalConfig/get': state => ({
          maximumFileUploadSize: 1,
          directUploadsEnabled: state.directUploadsEnabled,
        }),
      },
    });
    dispatch = vi.spyOn(store, 'dispatch').mockResolvedValue();
    replace = vi.fn();
    useRouter.mockReturnValue({ replace });
    sendEmailTranscript.mockResolvedValue();
    vi.spyOn(IFrameHelper, 'sendMessage').mockImplementation(() => {});
    vi.spyOn(emitter, 'emit');
    wrapper = shallowMount(ChatFooter, { global: { plugins: [store] } });
  });

  afterEach(() => {
    wrapper.unmount();
    window.chatwootWebChannel = originalChannel;
    window.URL.createObjectURL = originalCreateObjectURL;
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it('sends a message without a reply through Vuex', async () => {
    await wrapper.findComponent(ChatInputWrap).props('onSendMessage')('Hello');

    expect(dispatch).toHaveBeenCalledExactlyOnceWith(
      'conversation/sendMessage',
      {
        content: 'Hello',
        replyTo: null,
      }
    );
  });

  it('keeps the reply preview until a message is sent successfully', async () => {
    const reply = { id: 42, content: 'Original message' };
    emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, reply);
    await nextTick();
    expect(wrapper.findComponent(FooterReplyTo).props('inReplyTo')).toEqual(
      reply
    );

    let finishSend;
    dispatch.mockReturnValueOnce(
      new Promise(resolve => {
        finishSend = resolve;
      })
    );
    const sending = wrapper.findComponent(ChatInputWrap).props('onSendMessage')(
      'Reply'
    );
    await nextTick();
    expect(wrapper.findComponent(FooterReplyTo).exists()).toBe(true);

    finishSend();
    await sending;
    await nextTick();

    expect(dispatch).toHaveBeenCalledWith('conversation/sendMessage', {
      content: 'Reply',
      replyTo: 42,
    });
    expect(wrapper.findComponent(FooterReplyTo).exists()).toBe(false);
  });

  it('refreshes attributes for a new conversation after sending', async () => {
    store.state.conversationSize = 0;
    await wrapper.findComponent(ChatInputWrap).props('onSendMessage')('Hello');

    expect(dispatch.mock.calls.map(([action]) => action)).toEqual([
      'conversation/sendMessage',
      'conversationAttributes/getAttributes',
    ]);
  });

  it.each(['onSendMessage', 'onSendAttachment'])(
    'preserves the reply if %s fails',
    async handler => {
      emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, {
        id: 42,
        content: 'Original message',
      });
      dispatch.mockRejectedValueOnce(new Error('Send failed'));

      await expect(
        wrapper.findComponent(ChatInputWrap).props(handler)('payload')
      ).rejects.toThrow('Send failed');
      await nextTick();

      expect(wrapper.findComponent(FooterReplyTo).props('inReplyTo').id).toBe(
        42
      );
    }
  );

  it('dismisses an attachment-only reply and sends a single attachment without a reply', async () => {
    emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, {
      id: 42,
      attachments: [{ id: 1, file_type: 'image' }],
    });
    await nextTick();
    wrapper.findComponent(FooterReplyTo).vm.$emit('dismiss');
    await nextTick();
    expect(wrapper.findComponent(FooterReplyTo).exists()).toBe(false);

    const attachment = { file: 'signed-id', fileType: 'image' };
    const replyTo = await wrapper
      .findComponent(ChatInputWrap)
      .props('onSendAttachment')(attachment);

    expect(replyTo).toBeNull();
    expect(dispatch).toHaveBeenCalledExactlyOnceWith(
      'conversation/sendAttachment',
      { attachment, replyTo: null }
    );
  });

  it.each([false, true])(
    'preserves reply_to through real overflow uploads (direct uploads: %s)',
    async directUploadsEnabled => {
      wrapper.unmount();
      store.state.directUploadsEnabled = directUploadsEnabled;
      window.URL.createObjectURL = vi.fn(file => `blob:${file.name}`);
      wrapper = shallowMount(ChatFooter, {
        global: {
          plugins: [store],
          directives: { 'on-clickaway': onClickaway },
          stubs: { ChatInputWrap: false, ChatAttachment: false },
        },
      });
      emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, {
        id: 42,
        content: 'Original message',
      });
      const files = Array.from({ length: 17 }, (_, index) => ({
        file: new File(['image'], `${index}.png`, { type: 'image/png' }),
        type: 'image/png',
        size: 5,
      }));
      files.forEach(file => {
        wrapper.findComponent(FileUpload).vm.$emit('inputFile', file);
      });

      await vi.advanceTimersByTimeAsync(50);

      expect(dispatch).toHaveBeenCalledTimes(2);
      const payloads = dispatch.mock.calls.map(([action, payload]) => {
        expect(action).toBe('conversation/sendAttachment');
        return payload;
      });
      expect(payloads.map(({ replyTo }) => replyTo)).toEqual([42, 42]);
      expect(payloads.map(({ attachment }) => attachment.length)).toEqual([
        15, 2,
      ]);
      expect(
        payloads.flatMap(({ attachment }) => attachment.map(a => a.file))
      ).toEqual(
        files.map(({ file }) => (directUploadsEnabled ? file.name : file))
      );
      expect(DirectUpload).toHaveBeenCalledTimes(directUploadsEnabled ? 17 : 0);
      expect(wrapper.findComponent(FooterReplyTo).exists()).toBe(false);
    }
  );

  it('keeps a reply picked while an overflow batch is still sending', async () => {
    const sendAttachment = wrapper
      .findComponent(ChatInputWrap)
      .props('onSendAttachment');
    emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, {
      id: 42,
      content: 'Original message',
    });
    const replyTo = await sendAttachment(['first batch']);

    let finishSend;
    dispatch.mockReturnValueOnce(
      new Promise(resolve => {
        finishSend = resolve;
      })
    );
    const sending = sendAttachment(['later batch'], replyTo);
    const newerReply = { id: 43, content: 'Newer message' };
    emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, newerReply);
    finishSend();
    await sending;
    await nextTick();

    expect(dispatch).toHaveBeenLastCalledWith('conversation/sendAttachment', {
      attachment: ['later batch'],
      replyTo: 42,
    });
    expect(wrapper.findComponent(FooterReplyTo).props('inReplyTo')).toEqual(
      newerReply
    );
  });

  it('reacts to conversation status, widget style, and contact changes in Vuex', async () => {
    expect(wrapper.find('footer').classes()).toContain('rounded-lg');
    store.state.isWidgetStyleFlat = true;
    await nextTick();
    expect(wrapper.find('footer').classes()).not.toContain('rounded-lg');

    store.state.status = 'resolved';
    store.state.widgetColor = '#ffffff';
    await nextTick();
    expect(wrapper.findComponent(ChatInputWrap).exists()).toBe(false);
    expect(wrapper.findComponent(CustomButton).props()).toMatchObject({
      bgColor: '#ffffff',
      textColor: '#000000',
    });
    expect(wrapper.findAllComponents(CustomButton)).toHaveLength(2);

    store.state.currentUser = null;
    await nextTick();
    expect(wrapper.findAllComponents(CustomButton)).toHaveLength(1);
    store.state.status = 'open';
    await nextTick();
    expect(wrapper.findComponent(ChatInputWrap).exists()).toBe(true);
  });

  it('allows replies to resolved conversations when configured', async () => {
    window.chatwootWebChannel.allowMessagesAfterResolved = true;
    store.state.status = 'resolved';
    await nextTick();

    expect(wrapper.findComponent(ChatInputWrap).exists()).toBe(true);
  });

  it('starts a new conversation through the router and SDK event', async () => {
    store.state.status = 'resolved';
    await nextTick();
    await wrapper.findComponent(CustomButton).trigger('click');

    expect(replace).toHaveBeenCalledWith({ name: 'prechat-form' });
    expect(IFrameHelper.sendMessage).toHaveBeenCalledWith({
      event: 'onEvent',
      eventIdentifier: CHATWOOT_ON_START_CONVERSATION,
      data: { hasConversation: true },
    });
  });

  it('prevents duplicate transcript sends while pending and during the cooldown', async () => {
    store.state.status = 'resolved';
    await nextTick();
    let finishSend;
    sendEmailTranscript.mockReturnValueOnce(
      new Promise(resolve => {
        finishSend = resolve;
      })
    );
    const button = wrapper.findAllComponents(CustomButton)[1];
    await button.trigger('click');
    await button.trigger('click');
    expect(sendEmailTranscript).toHaveBeenCalledTimes(1);
    expect(button.props('disabled')).toBe(true);

    finishSend();
    await flushPromises();
    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.SHOW_ALERT, {
      message: 'EMAIL_TRANSCRIPT.SEND_EMAIL_SUCCESS',
      type: 'success',
    });
    await button.trigger('click');
    expect(sendEmailTranscript).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(14999);
    expect(button.props('disabled')).toBe(true);
    await vi.advanceTimersByTimeAsync(1);
    expect(button.props('disabled')).toBe(false);
    await button.trigger('click');
    expect(sendEmailTranscript).toHaveBeenCalledTimes(2);
  });

  it('shows a transcript error and allows an immediate retry', async () => {
    store.state.status = 'resolved';
    sendEmailTranscript.mockRejectedValueOnce(new Error('Request failed'));
    await nextTick();
    const button = wrapper.findAllComponents(CustomButton)[1];
    await button.trigger('click');
    await flushPromises();

    expect(emitter.emit).toHaveBeenCalledWith(BUS_EVENTS.SHOW_ALERT, {
      message: 'EMAIL_TRANSCRIPT.SEND_EMAIL_ERROR',
    });
    expect(button.props('disabled')).toBe(false);
    await button.trigger('click');
    expect(sendEmailTranscript).toHaveBeenCalledTimes(2);
  });

  it('does not send a transcript after the contact loses its email', async () => {
    store.state.status = 'resolved';
    await nextTick();
    const button = wrapper.findAllComponents(CustomButton)[1];
    store.state.currentUser = { has_email: false };
    // The stale button can still emit before the next render removes it.
    await button.trigger('click');

    expect(sendEmailTranscript).not.toHaveBeenCalled();
    expect(wrapper.findAllComponents(CustomButton)).toHaveLength(1);
  });

  it('removes the reply subscription and cooldown timer on unmount', async () => {
    const unsubscribe = vi.spyOn(emitter, 'off');
    store.state.status = 'resolved';
    await nextTick();
    await wrapper.findAllComponents(CustomButton)[1].trigger('click');
    await flushPromises();
    expect(vi.getTimerCount()).toBe(1);

    wrapper.unmount();

    expect(unsubscribe).toHaveBeenCalledWith(
      BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE,
      expect.any(Function)
    );
    expect(emitter.all.get(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE)).toHaveLength(0);
    expect(vi.getTimerCount()).toBe(0);
  });
});

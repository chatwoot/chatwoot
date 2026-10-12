import { shallowMount } from '@vue/test-utils';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import { nextTick } from 'vue';
import { createStore } from 'vuex';
import ReplyBox from '../ReplyBox.vue';
import WhatsappTemplates from '../WhatsappTemplates/Modal.vue';

const CHANNELS = [
  { name: 'WhatsApp Cloud', inbox: { channel_type: 'Channel::Whatsapp' } },
  {
    name: 'Twilio WhatsApp',
    inbox: { channel_type: 'Channel::TwilioSms', medium: 'whatsapp' },
  },
  { name: 'API', inbox: { channel_type: 'Channel::Api' } },
  { name: 'Instagram', inbox: { channel_type: 'Channel::Instagram' } },
  { name: 'TikTok', inbox: { channel_type: 'Channel::Tiktok' } },
  { name: 'Facebook', inbox: { channel_type: 'Channel::FacebookPage' } },
  { name: 'Line', inbox: { channel_type: 'Channel::Line' } },
  { name: 'Telegram', inbox: { channel_type: 'Channel::Telegram' } },
  { name: 'Email', inbox: { channel_type: 'Channel::Email' } },
  { name: 'Web widget', inbox: { channel_type: 'Channel::WebWidget' } },
];

const exemptFromMessagingWindow = name =>
  ['WhatsApp Cloud', 'Twilio WhatsApp', 'API'].includes(name);

const REPLIABLE = {
  id: 1,
  inbox_id: 1,
  can_reply: true,
  status: 'open',
  meta: { sender: { id: 2 } },
  messages: [],
};

const buildStore = ({
  inbox,
  chat,
  templates,
  drafts = {},
  inboxes,
  isMetaMessageSendingDisabled = false,
}) =>
  createStore({
    state: {
      chat: { ...REPLIABLE, ...chat },
      replyEditorMode: REPLY_EDITOR_MODES.REPLY,
      drafts: { ...drafts },
    },
    mutations: {
      selectChat: (s, c) => {
        s.chat = c;
      },
      setReplyEditorMode: (s, mode) => {
        s.replyEditorMode = mode;
      },
      setDraft: (s, { key, message }) => {
        s.drafts = { ...s.drafts, [key]: message };
      },
    },
    actions: {
      'draftMessages/setReplyEditorMode': ({ commit }, { mode }) =>
        commit('setReplyEditorMode', mode),
      'draftMessages/set': ({ commit }, payload) => commit('setDraft', payload),
    },
    getters: {
      getSelectedChat: s => s.chat,
      getCurrentUser: () => ({ id: 7, name: 'Agent', accounts: [] }),
      getCurrentAccountId: () => 1,
      getMessageSignature: () => '',
      getUISettings: () => ({}),
      getLastEmailInSelectedChat: () => null,
      'globalConfig/get': () => ({}),
      'globalConfig/isMetaMessageSendingDisabled': () =>
        isMetaMessageSendingDisabled,
      'inboxes/getInbox': () => inboxId => ({
        id: inboxId,
        ...(inboxes?.[inboxId] || inbox),
      }),
      'inboxes/getWhatsAppTemplates': () => () => templates,
      'contacts/getContact': () => () => ({}),
      'draftMessages/get': s => key => s.drafts[key] || '',
      'draftMessages/getReplyEditorMode': s => s.replyEditorMode,
      'accounts/isFeatureEnabledonAccount': () => () => false,
      'accounts/getAccount': () => () => ({}),
      'portals/allPortals': () => [],
      'integrations/getUIFlags': () => ({ isFetching: false }),
    },
  });

const mountWith = ({
  inbox,
  chat,
  templates = [{ name: 'greeting' }],
  drafts,
  inboxes,
  isMetaMessageSendingDisabled,
}) => {
  const store = buildStore({
    inbox,
    chat,
    templates,
    drafts,
    inboxes,
    isMetaMessageSendingDisabled,
  });
  const wrapper = shallowMount(ReplyBox, {
    global: {
      plugins: [store],
      mocks: { $t: key => key },
      // The bottom panel sits inside a <Transition>, which shallowMount stubs
      // without rendering its children.
      stubs: { transition: false },
    },
  });
  return { wrapper, store };
};

const topPanel = wrapper =>
  wrapper.findComponent({ name: 'ReplyTopPanel' }).props();
const bottomPanel = wrapper =>
  wrapper.findComponent({ name: 'ReplyBottomPanel' }).props();
const editor = wrapper =>
  wrapper.findComponent({ name: 'WootMessageEditor' }).props();

describe('ReplyBox', () => {
  describe('WhatsApp reply buttons', () => {
    const capability = {
      schema_version: 1,
      account_mode: 'test',
      interactive_types: {
        button: {
          implemented: true,
          available: true,
          limits: {
            body_max_length: 1024,
            button_title_max_length: 20,
            button_min_count: 1,
            button_max_count: 3,
          },
        },
      },
    };

    it('submits only the normalized text-button input fields', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const sendMessage = vi
        .spyOn(wrapper.vm, 'sendMessage')
        .mockResolvedValue(undefined);

      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft = {
        body: ' Choose one. ',
        buttons: [' Confirm ', 'Change'],
      };
      wrapper.vm.confirmOnSendReply();

      expect(sendMessage).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Choose one.',
          contentAttributes: {
            whatsapp_interactive: {
              schema_version: 1,
              type: 'button',
              body: { text: 'Choose one.' },
              action: {
                buttons: [{ title: 'Confirm' }, { title: 'Change' }],
              },
            },
          },
        }),
        'Choose one.',
        ''
      );
      expect(wrapper.vm.whatsappInteractiveDraft).toEqual({
        body: '',
        buttons: [''],
      });
    });

    it('discards the unfinished interaction when the conversation changes', async () => {
      const { wrapper, store } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'Unfinished',
        buttons: ['Continue'],
      };

      store.commit('selectChat', {
        ...REPLIABLE,
        id: 2,
        whatsapp_interactive: capability,
      });
      await nextTick();

      expect(wrapper.vm.isWhatsappInteractive).toBe(false);
      expect(wrapper.vm.whatsappInteractiveDraft).toEqual({
        body: '',
        buttons: [''],
      });
    });

    it('discards the unfinished interaction when switching to a private note', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'Unfinished',
        buttons: ['Continue'],
      };

      wrapper.vm.setReplyMode(REPLY_EDITOR_MODES.NOTE);
      await nextTick();

      expect(wrapper.vm.isWhatsappInteractive).toBe(false);
      expect(wrapper.vm.whatsappInteractiveDraft).toEqual({
        body: '',
        buttons: [''],
      });
      expect(wrapper.vm.isPrivate).toBe(true);
    });

    it('keeps an unavailable capability visible but disabled', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: {
          whatsapp_interactive: {
            ...capability,
            interactive_types: {
              button: {
                ...capability.interactive_types.button,
                available: false,
                unavailable_reason: 'test_recipient_not_allowlisted',
              },
            },
          },
        },
      });

      expect(bottomPanel(wrapper).whatsappInteractiveCapability).toMatchObject({
        implemented: true,
        available: false,
        unavailable_reason: 'test_recipient_not_allowlisted',
      });
      wrapper.vm.toggleWhatsappInteractive();
      expect(wrapper.vm.isWhatsappInteractive).toBe(false);
    });

    it('submits text headers and footers as normalized visible fields', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const sendMessage = vi
        .spyOn(wrapper.vm, 'sendMessage')
        .mockResolvedValue(undefined);
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'Choose',
        buttons: ['Confirm'],
        headerType: 'text',
        headerText: ' Header ',
        footer: ' Footer ',
      };
      wrapper.vm.confirmOnSendReply();
      expect(
        sendMessage.mock.calls[0][0].contentAttributes.whatsapp_interactive
      ).toMatchObject({
        header: { type: 'text', text: 'Header' },
        footer: { text: 'Footer' },
      });
      expect(sendMessage.mock.calls[0][0].files).toBeUndefined();
    });

    it.each(['image', 'video', 'document'])(
      'submits one %s header upload without a client attachment ID',
      type => {
        const { wrapper } = mountWith({
          inbox: {
            channel_type: 'Channel::Whatsapp',
            provider: 'whatsapp_cloud',
          },
          chat: { whatsapp_interactive: capability },
        });
        const sendMessage = vi
          .spyOn(wrapper.vm, 'sendMessage')
          .mockResolvedValue(undefined);
        wrapper.vm.toggleWhatsappInteractive();
        wrapper.vm.whatsappInteractiveDraft = {
          body: 'Choose',
          buttons: ['Confirm'],
          headerType: type,
          media: { file: 'signed-upload', name: 'media' },
        };
        wrapper.vm.confirmOnSendReply();
        expect(sendMessage).toHaveBeenCalledTimes(1);
        expect(sendMessage.mock.calls[0][0]).toMatchObject({
          files: ['signed-upload'],
          contentAttributes: { whatsapp_interactive: { header: { type } } },
        });
        expect(wrapper.vm.whatsappInteractiveDraft).toEqual({
          body: '',
          buttons: [''],
        });
      }
    );

    it('rejects blank, duplicate, overflow, and incomplete media drafts using capability limits', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const valid = {
        body: 'x'.repeat(1024),
        buttons: ['1'.repeat(20), '2', '3'],
        headerType: 'text',
        headerText: 'h'.repeat(60),
        footer: 'f'.repeat(60),
      };
      wrapper.vm.whatsappInteractiveDraft = valid;
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(true);
      [
        { body: 'x'.repeat(1025) },
        { headerText: 'h'.repeat(61) },
        { headerText: ' ' },
        { footer: 'f'.repeat(61) },
        { footer: ' ' },
        { buttons: ['Same', 'Same'] },
        { buttons: ['x'.repeat(21)] },
        { headerType: 'image', media: null },
        { headerType: 'audio' },
      ].forEach(invalid => {
        wrapper.vm.whatsappInteractiveDraft = { ...valid, ...invalid };
        expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
      });
    });

    it('uses the existing upload method for one matching file and clears media on reset', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft.headerType = 'image';
      const upload = vi
        .spyOn(wrapper.vm, 'onFileUpload')
        .mockImplementation(() => {});
      const file = new File(['image'], 'header.png', { type: 'image/png' });
      wrapper.vm.uploadWhatsappHeader(file);
      expect(upload).toHaveBeenCalledWith(
        expect.objectContaining({ file, conversationId: 1 })
      );
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
      wrapper.vm.resetWhatsappInteractive();
      expect(wrapper.vm.whatsappInteractiveDraft).toEqual({
        body: '',
        buttons: [''],
      });
    });

    it('keeps an upload when visible fields change while it finishes', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft.headerType = 'image';
      const upload = vi
        .spyOn(wrapper.vm, 'onFileUpload')
        .mockImplementation(() => {});
      const file = new File(['image'], 'header.png', { type: 'image/png' });
      wrapper.vm.uploadWhatsappHeader(file);
      const reader = {
        readAsDataURL: vi.fn(),
        result: 'data:image/png;base64,image',
      };
      const readerMock = vi
        .spyOn(window, 'FileReader')
        .mockImplementation(() => reader);
      wrapper.vm.attachFile({
        file: upload.mock.calls[0][0],
        blob: { signed_id: 'signed-upload' },
      });
      wrapper.vm.whatsappInteractiveDraft = {
        ...wrapper.vm.whatsappInteractiveDraft,
        body: 'Edited during upload',
      };
      reader.onloadend();
      expect(wrapper.vm.whatsappInteractiveDraft.media).toMatchObject({
        file: 'signed-upload',
        name: 'header.png',
      });
      expect(wrapper.vm.attachedFiles).toEqual([]);
      readerMock.mockRestore();
    });

    it('ignores an upload that finishes after leaving the interactive composer', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft.headerType = 'image';
      const upload = vi
        .spyOn(wrapper.vm, 'onFileUpload')
        .mockImplementation(() => {});
      wrapper.vm.uploadWhatsappHeader(
        new File(['image'], 'header.png', { type: 'image/png' })
      );
      const reader = {
        readAsDataURL: vi.fn(),
        result: 'data:image/png;base64,image',
      };
      const readerMock = vi
        .spyOn(window, 'FileReader')
        .mockImplementation(() => reader);
      wrapper.vm.attachFile({ file: upload.mock.calls[0][0] });
      wrapper.vm.resetWhatsappInteractive();
      reader.onloadend();
      expect(wrapper.vm.whatsappInteractiveDraft).toEqual({
        body: '',
        buttons: [''],
      });
      expect(wrapper.vm.attachedFiles).toEqual([]);
      readerMock.mockRestore();
    });
  });

  describe('Instagram incident restriction', () => {
    it('opens in note mode and restores only the private-note draft', async () => {
      const { wrapper, store } = mountWith({
        inbox: { channel_type: 'Channel::Instagram' },
        isMetaMessageSendingDisabled: true,
        drafts: {
          'draft-1-REPLY': 'unsent public reply',
          'draft-1-NOTE': 'incident note',
        },
      });
      await nextTick();

      expect(topPanel(wrapper).mode).toBe(REPLY_EDITOR_MODES.NOTE);
      expect(topPanel(wrapper).isReplyRestricted).toBe(true);
      expect(bottomPanel(wrapper).isOnPrivateNote).toBe(true);
      expect(editor(wrapper).editorId).toBe('draft-1-NOTE');
      expect(wrapper.vm.message).toBe('incident note');
      expect(store.getters['draftMessages/getReplyEditorMode']).toBe(
        REPLY_EDITOR_MODES.NOTE
      );
      expect(store.getters['draftMessages/get']('draft-1-REPLY')).toBe(
        'unsent public reply'
      );
    });

    it('preserves draft ownership when switching to a restricted conversation', async () => {
      const drafts = {
        'draft-1-REPLY': 'conversation A reply',
        'draft-1-NOTE': 'conversation A note',
        'draft-2-REPLY': 'conversation B reply',
        'draft-2-NOTE': 'conversation B note',
      };
      const { wrapper, store } = mountWith({
        inbox: { channel_type: 'Channel::WebWidget' },
        inboxes: {
          1: { channel_type: 'Channel::WebWidget' },
          2: { channel_type: 'Channel::Instagram' },
        },
        drafts,
        isMetaMessageSendingDisabled: true,
      });
      await nextTick();

      store.commit('selectChat', { ...REPLIABLE, id: 2, inbox_id: 2 });
      await nextTick();

      expect(editor(wrapper)).toMatchObject({
        editorId: 'draft-2-NOTE',
        modelValue: 'conversation B note',
      });
      Object.entries(drafts).forEach(([key, message]) => {
        expect(store.getters['draftMessages/get'](key)).toBe(message);
      });
    });
  });

  describe.each(CHANNELS)('$name', ({ name, inbox }) => {
    it('locks the composer and hides template sends when a bot owns a pending conversation', () => {
      const { wrapper } = mountWith({
        inbox,
        chat: {
          status: 'pending',
          meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
        },
      });

      expect(topPanel(wrapper).isReplyRestricted).toBe(true);
      expect(bottomPanel(wrapper).enableWhatsAppTemplates).toBe(false);
      expect(bottomPanel(wrapper).enableContentTemplates).toBe(false);
      // The note composer stays usable — this is a restriction, not a lockout.
      expect(topPanel(wrapper).isEditorDisabled).toBe(false);
    });

    it('opens directly in note mode when a bot already owns the pending conversation', () => {
      const { wrapper, store } = mountWith({
        inbox,
        chat: {
          can_reply: false,
          status: 'pending',
          meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
        },
      });

      expect(bottomPanel(wrapper).isOnPrivateNote).toBe(true);
      expect(store.getters['draftMessages/getReplyEditorMode']).toBe(
        REPLY_EDITOR_MODES.NOTE
      );
      expect(topPanel(wrapper).isEditorDisabled).toBe(false);
    });

    it('opens in reply mode for every other conversation', () => {
      const { wrapper, store } = mountWith({ inbox });

      expect(bottomPanel(wrapper).isOnPrivateNote).toBe(false);
      expect(store.getters['draftMessages/getReplyEditorMode']).toBe(
        REPLY_EDITOR_MODES.REPLY
      );
    });

    it.each(['open', 'resolved', 'snoozed'])(
      'leaves the composer open when a bot owns a %s conversation',
      status => {
        const { wrapper } = mountWith({
          inbox,
          chat: {
            status,
            meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
          },
        });

        expect(topPanel(wrapper).isReplyRestricted).toBe(false);
        expect(bottomPanel(wrapper).enableWhatsAppTemplates).toBe(true);
      }
    );

    it('leaves the composer open when a human owns a pending conversation', () => {
      const { wrapper } = mountWith({
        inbox,
        chat: {
          status: 'pending',
          meta: { sender: { id: 2 }, assignee_type: 'User' },
        },
      });

      expect(topPanel(wrapper).isReplyRestricted).toBe(false);
      expect(bottomPanel(wrapper).enableWhatsAppTemplates).toBe(true);
    });

    it('matches the existing messaging-window rule when no bot is involved', () => {
      const { wrapper } = mountWith({
        inbox,
        chat: { can_reply: false, status: 'resolved' },
      });

      const stillRepliable = exemptFromMessagingWindow(name);
      expect(topPanel(wrapper).isReplyRestricted).toBe(!stillRepliable);
      expect(bottomPanel(wrapper).enableWhatsAppTemplates).toBe(stillRepliable);
      // WhatsApp/API disable the editor and steer to templates; everywhere
      // else the composer falls back to a usable private note.
      expect(topPanel(wrapper).isEditorDisabled).toBe(stillRepliable);
    });
  });

  it('hides the template action when the inbox has no templates synced', () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
      chat: { can_reply: false, status: 'open' },
      templates: [],
    });

    expect(bottomPanel(wrapper).enableWhatsAppTemplates).toBe(false);
    expect(topPanel(wrapper).isReplyRestricted).toBe(false);
  });

  describe('drafts', () => {
    const DRAFTS = {
      'draft-1-REPLY': 'half typed reply',
      'draft-1-NOTE': 'a note',
    };

    it('loads the note draft while a bot owns the conversation', async () => {
      const { wrapper } = mountWith({
        inbox: { channel_type: 'Channel::WebWidget' },
        chat: {
          status: 'pending',
          meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
        },
        drafts: DRAFTS,
      });
      await nextTick();

      expect(editor(wrapper)).toMatchObject({
        editorId: 'draft-1-NOTE',
        modelValue: 'a note',
      });
    });

    it('leaves the saved reply draft intact and restores it on takeover', async () => {
      const { wrapper, store } = mountWith({
        inbox: { channel_type: 'Channel::WebWidget' },
        chat: {
          status: 'pending',
          meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
        },
        drafts: DRAFTS,
      });
      await nextTick();
      expect(store.getters['draftMessages/get']('draft-1-REPLY')).toBe(
        'half typed reply'
      );

      store.commit('selectChat', {
        ...REPLIABLE,
        status: 'open',
        meta: { sender: { id: 2 }, assignee_type: 'User' },
      });
      await nextTick();

      expect(editor(wrapper)).toMatchObject({
        editorId: 'draft-1-REPLY',
        modelValue: 'half typed reply',
      });
    });
  });

  it('offers content templates on Twilio WhatsApp when no bot owns the conversation', () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::TwilioSms', medium: 'whatsapp' },
      chat: { can_reply: true, status: 'open' },
    });

    expect(bottomPanel(wrapper).enableContentTemplates).toBe(true);
  });

  it('offers location requests only for WhatsApp Cloud conversations', () => {
    const { wrapper: cloudWrapper } = mountWith({
      inbox: {
        channel_type: 'Channel::Whatsapp',
        provider: 'whatsapp_cloud',
      },
    });
    const { wrapper: dialogWrapper } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp', provider: 'default' },
    });

    expect(bottomPanel(cloudWrapper).enableLocationRequest).toBe(true);
    expect(bottomPanel(dialogWrapper).enableLocationRequest).toBe(false);
  });

  it('clears the rendered editor content immediately', async () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
    });
    await nextTick();
    const setEditorContent = vi.fn();
    wrapper.vm.messageEditor.setEditorContent = setEditorContent;
    wrapper.vm.message = 'Message being sent';

    wrapper.vm.clearMessage();

    expect(wrapper.vm.message).toBe('');
    expect(setEditorContent).toHaveBeenCalledWith('');
  });

  it('lets agents edit a location request before sending it', async () => {
    const { wrapper } = mountWith({
      inbox: {
        channel_type: 'Channel::Whatsapp',
        provider: 'whatsapp_cloud',
      },
    });
    const sendMessage = vi
      .spyOn(wrapper.vm, 'sendMessage')
      .mockResolvedValue(undefined);

    wrapper.vm.requestLocation();
    expect(wrapper.vm.isLocationRequest).toBe(true);
    expect(wrapper.vm.message).toBe(
      'CONVERSATION.REPLYBOX.REQUEST_LOCATION_DEFAULT'
    );

    wrapper.vm.message = 'Comparte tu ubicación actual.';
    await nextTick();
    wrapper.vm.confirmOnSendReply();

    expect(sendMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'Comparte tu ubicación actual.',
        contentAttributes: {
          whatsapp_interactive: { type: 'location_request_message' },
        },
      }),
      'Comparte tu ubicación actual.',
      ''
    );
    expect(wrapper.vm.isLocationRequest).toBe(false);
  });

  describe('on selecting a conversation', () => {
    const selectChat = async chat => {
      const { wrapper, store } = mountWith({
        inbox: { channel_type: 'Channel::WebWidget' },
      });
      store.commit('selectChat', { ...REPLIABLE, id: 99, ...chat });
      await nextTick();
      return { wrapper, store };
    };

    it('switches to note mode when a bot owns a pending conversation', async () => {
      const { wrapper } = await selectChat({
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      });

      expect(bottomPanel(wrapper).isOnPrivateNote).toBe(true);
    });

    it('stays in reply mode when a human owns a pending conversation', async () => {
      const { wrapper } = await selectChat({
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'User' },
      });

      expect(bottomPanel(wrapper).isOnPrivateNote).toBe(false);
    });

    it('closes an open template modal when a bot takes over the conversation', async () => {
      const { wrapper, store } = mountWith({
        inbox: { channel_type: 'Channel::Whatsapp' },
      });
      wrapper
        .findComponent({ name: 'ReplyBottomPanel' })
        .vm.$emit('selectWhatsappTemplate');
      await nextTick();
      expect(wrapper.findComponent(WhatsappTemplates).props('show')).toBe(true);

      store.commit('selectChat', {
        ...REPLIABLE,
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      });
      await nextTick();

      expect(wrapper.findComponent(WhatsappTemplates).props('show')).toBe(
        false
      );
    });

    it('returns to reply mode once the agent takes over', async () => {
      const { wrapper, store } = await selectChat({
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      });
      expect(bottomPanel(wrapper).isOnPrivateNote).toBe(true);

      store.commit('selectChat', {
        ...REPLIABLE,
        id: 99,
        status: 'open',
        meta: { sender: { id: 2 }, assignee_type: 'User' },
      });
      await nextTick();

      expect(bottomPanel(wrapper).isOnPrivateNote).toBe(false);
      expect(topPanel(wrapper).isReplyRestricted).toBe(false);
      expect(store.getters['draftMessages/getReplyEditorMode']).toBe(
        REPLY_EDITOR_MODES.REPLY
      );
    });

    it('keeps the agent in note mode after they chose it themselves', async () => {
      const { wrapper } = await selectChat({});
      wrapper
        .findComponent({ name: 'ReplyTopPanel' })
        .vm.$emit('setReplyMode', REPLY_EDITOR_MODES.NOTE);
      await nextTick();

      expect(bottomPanel(wrapper).isOnPrivateNote).toBe(true);
    });

    it('mirrors the forced note mode into the draftMessages store', async () => {
      const { store } = await selectChat({
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      });

      expect(store.getters['draftMessages/getReplyEditorMode']).toBe(
        REPLY_EDITOR_MODES.NOTE
      );
    });
  });
});

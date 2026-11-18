import { flushPromises, shallowMount } from '@vue/test-utils';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import { AUDIO_FORMATS } from 'shared/constants/messages';
import { nextTick } from 'vue';
import { createStore } from 'vuex';
import ReplyBox from '../ReplyBox.vue';

const mockAlert = vi.fn();
vi.mock('dashboard/composables', async () => {
  const actual = await vi.importActual('dashboard/composables');
  return { ...actual, useAlert: (...args) => mockAlert(...args) };
});
import WhatsappTemplates from '../WhatsappTemplates/Modal.vue';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

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
  uiSettings = {},
  signature = '',
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
      getMessageSignature: () => signature,
      getUISettings: () => uiSettings,
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

// Every mount subscribes to the global reply-to bus in mounted(). Left alive,
// they all answer an emit from whichever test fires one, and each one reaches
// for an editor method the stub doesn't have.
const mounted = [];
afterEach(() => {
  while (mounted.length) mounted.pop().unmount();
});

const mountWith = ({
  inbox,
  chat,
  templates = [{ name: 'greeting' }],
  drafts,
  inboxes,
  isMetaMessageSendingDisabled,
  uiSettings,
  signature,
}) => {
  const store = buildStore({
    inbox,
    chat,
    templates,
    drafts,
    inboxes,
    isMetaMessageSendingDisabled,
    uiSettings,
    signature,
  });
  const wrapper = shallowMount(ReplyBox, {
    global: {
      plugins: [store],
      mocks: { $t: key => key },
      // The bottom panel sits inside a <Transition>, which shallowMount stubs
      // without rendering its children.
      stubs: {
        transition: false,
        // Same name and props the auto-stub would carry, so findComponent and
        // props() keep working, plus the one method the composer calls on the
        // editor ref after a reply-to reset.
        WootMessageEditor: {
          name: 'WootMessageEditor',
          props: ['editorId', 'modelValue', 'isPrivate', 'placeholder'],
          template: '<div />',
          methods: { focusEditorInputField: () => {} },
        },
      },
    },
  });
  mounted.push(wrapper);
  return { wrapper, store };
};

const topPanel = wrapper =>
  wrapper.findComponent({ name: 'ReplyTopPanel' }).props();
const bottomPanel = wrapper =>
  wrapper.findComponent({ name: 'ReplyBottomPanel' }).props();
const editor = wrapper =>
  wrapper.findComponent({ name: 'WootMessageEditor' }).props();

describe('ReplyBox', () => {
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
    it('locks the composer and hides template sends when the conversation has an AI assignee', () => {
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

    it('opens directly in note mode when the conversation has an AI assignee', () => {
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

    it('offers the voice recorder once the agent switches to a note', async () => {
      const { wrapper } = mountWith({ inbox });
      wrapper
        .findComponent({ name: 'ReplyTopPanel' })
        .vm.$emit('setReplyMode', REPLY_EDITOR_MODES.NOTE);
      await nextTick();

      expect(bottomPanel(wrapper).showAudioRecorder).toBe(true);
      // A note never leaves Chatwoot, so it records in the one container every
      // browser and both mobile apps play, whatever the channel accepts.
      expect(wrapper.vm.audioRecordFormat).toBe(AUDIO_FORMATS.MP3);
    });

    it('opens in reply mode for every other conversation', () => {
      const { wrapper, store } = mountWith({ inbox });

      expect(bottomPanel(wrapper).isOnPrivateNote).toBe(false);
      expect(store.getters['draftMessages/getReplyEditorMode']).toBe(
        REPLY_EDITOR_MODES.REPLY
      );
    });

    it.each(['open', 'resolved', 'snoozed'])(
      'keeps the composer available when a %s conversation has an AI assignee',
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

  it('locks the composer when the conversation has a Captain assistant assignee', () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::WebWidget' },
      chat: {
        status: 'pending',
        meta: {
          sender: { id: 2 },
          assignee_type: 'Captain::Assistant',
        },
      },
    });

    expect(topPanel(wrapper).isReplyRestricted).toBe(true);
    expect(bottomPanel(wrapper).isOnPrivateNote).toBe(true);
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

    it('loads the note draft while the conversation has an AI assignee', async () => {
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

  it('offers content templates on Twilio WhatsApp when the conversation has no AI assignee', () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::TwilioSms', medium: 'whatsapp' },
      chat: { can_reply: true, status: 'open' },
    });

    expect(bottomPanel(wrapper).enableContentTemplates).toBe(true);
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

    it('switches to note mode when a pending conversation has an AI assignee', async () => {
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

  it('unlocks the recorder on a note in an inbox that takes no uploads', async () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::Tiktok' },
      chat: {
        additional_attributes: { tiktok_capabilities: { image_send: false } },
      },
    });

    expect(wrapper.vm.showAudioRecorder).toBe(false);

    wrapper
      .findComponent({ name: 'ReplyTopPanel' })
      .vm.$emit('setReplyMode', REPLY_EDITOR_MODES.NOTE);
    await nextTick();

    expect(wrapper.vm.showAudioRecorder).toBe(true);
  });

  it('sends a recorded note as a private voice message', async () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
    });
    wrapper
      .findComponent({ name: 'ReplyTopPanel' })
      .vm.$emit('setReplyMode', REPLY_EDITOR_MODES.NOTE);
    await nextTick();
    wrapper.vm.attachedFiles = [
      { isVoiceMessage: true, resource: { file: new Blob(['audio']) } },
    ];

    const payload = wrapper.vm.getMessagePayload('');

    expect(payload.private).toBe(true);
    expect(payload.isVoiceMessage).toBe(true);
  });

  it('drops a note recording when the bot hands the conversation back', async () => {
    const { wrapper, store } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
      chat: {
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      },
    });
    await nextTick();
    expect(wrapper.vm.isOnPrivateNote).toBe(true);

    wrapper.vm.attachedFiles = [
      { isVoiceMessage: true, resource: { file: new Blob(['audio']) } },
    ];
    wrapper.vm.isRecordingAudio = true;

    // The bot releases the conversation: nobody switched the composer, but it is
    // no longer on a note, and the recording was made for the team.
    store.commit('selectChat', {
      ...REPLIABLE,
      status: 'open',
      meta: { sender: { id: 2 } },
    });
    await nextTick();

    expect(wrapper.vm.isOnPrivateNote).toBe(false);
    expect(wrapper.vm.attachedFiles).toEqual([]);
    expect(wrapper.vm.isRecordingAudio).toBe(false);
  });

  it('drops a cited private note when the composer stops being internal', async () => {
    const { wrapper, store } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
      chat: {
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      },
    });
    await nextTick();
    wrapper.vm.inReplyTo = { id: 99, private: true };

    store.commit('selectChat', {
      ...REPLIABLE,
      status: 'open',
      meta: { sender: { id: 2 } },
    });
    await nextTick();

    // Left in place, the note's id would ride along in the outbound message's
    // in_reply_to and its preview would be quoted to the contact.
    expect(wrapper.vm.inReplyTo).toEqual({});
  });

  it('drops an upload that lands after the composer stopped being internal', async () => {
    const { wrapper, store } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
      chat: {
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      },
    });
    await nextTick();

    // The agent stops the recorder: MP3 conversion and the upload start here,
    // and attachFile only runs once they finish.
    const recorded = { isVoiceMessage: true, file: new Blob(['audio']) };
    wrapper.vm.stageFile(recorded);

    store.commit('selectChat', {
      ...REPLIABLE,
      status: 'open',
      meta: { sender: { id: 2 } },
    });
    await nextTick();

    // Staged after the switch, so this one is legitimate. Waiting for it is what
    // makes the recording's absence a result rather than a race: both go through
    // the same async FileReader, and this one was queued second.
    const current = { name: 'current.png', file: new Blob(['image']) };
    wrapper.vm.stageFile(current);
    await vi.waitUntil(() => wrapper.vm.attachedFiles.length > 0);

    expect(wrapper.vm.attachedFiles).toHaveLength(1);
    expect(wrapper.vm.attachedFiles[0].isVoiceMessage).toBe(false);
  });

  it('drops a recording whose conversion outlived the note it was made on', async () => {
    const { wrapper, store } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
      chat: {
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      },
    });
    await nextTick();

    // Mic armed on a note. Talking and the MP3 conversion that follows both
    // happen before onFinishRecorder ever runs.
    wrapper.vm.toggleAudioRecorder();
    store.commit('selectChat', {
      ...REPLIABLE,
      status: 'open',
      meta: { sender: { id: 2 } },
    });
    await nextTick();
    wrapper.vm.onFinishRecorder({
      name: 'nota.mp3',
      file: new Blob(['audio']),
    });

    const current = { name: 'current.png', file: new Blob(['image']) };
    wrapper.vm.stageFile(current);
    await vi.waitUntil(() => wrapper.vm.attachedFiles.length > 0);

    expect(wrapper.vm.attachedFiles).toHaveLength(1);
    expect(wrapper.vm.attachedFiles[0].isVoiceMessage).toBe(false);
  });

  it('stages a file the uploader hands over with its (newFile, oldFile) pair', async () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
    });
    await nextTick();

    // vue-upload-component emits input-file with two arguments and re-emits on
    // every progress update. stageFile is wired straight to it, so a second
    // positional parameter there would silently read oldFile.
    const newFile = { name: 'doc.pdf', file: new Blob(['pdf']) };
    const oldFile = {
      name: 'doc.pdf',
      file: new Blob(['pdf']),
      progress: '0.00',
    };
    wrapper.vm.stageFile(newFile, oldFile);
    await vi.waitUntil(() => wrapper.vm.attachedFiles.length > 0);

    expect(wrapper.vm.attachedFiles).toHaveLength(1);
  });

  // The three drops above are not the same event to the agent. Leaving note mode is the one
  // nothing they did causes -- a bot releases the conversation, the messaging window
  // reopens, a restriction lifts -- so the recording goes with the composer looking exactly
  // as they left it, and a silent drop there is indistinguishable from a broken button.
  it('says so when the composer leaving note mode discarded a capture', async () => {
    const { wrapper, store } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
      chat: {
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      },
    });
    await nextTick();
    mockAlert.mockClear();

    const recorded = { isVoiceMessage: true, file: new Blob(['audio']) };
    wrapper.vm.stageFile(recorded);

    store.commit('selectChat', {
      ...REPLIABLE,
      status: 'open',
      meta: { sender: { id: 2 } },
    });
    await nextTick();
    await vi.waitUntil(() => mockAlert.mock.calls.length > 0);

    expect(mockAlert).toHaveBeenCalledWith(
      'CONVERSATION.REPLYBOX.RECORDING_DISCARDED_ON_MODE_CHANGE'
    );
  });

  // The ordinary shape of this: the recording finished and is sitting in the composer when
  // the bot hands the conversation back. It is discarded synchronously by the reset, so a
  // message that waits for an upload callback is a message that never arrives.
  it('says so when the capture had already finished uploading', async () => {
    const { wrapper, store } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
      chat: {
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      },
    });
    await nextTick();

    wrapper.vm.stageFile({ isVoiceMessage: true, file: new Blob(['audio']) });
    await vi.waitUntil(() => wrapper.vm.attachedFiles.length > 0);
    mockAlert.mockClear();

    store.commit('selectChat', {
      ...REPLIABLE,
      status: 'open',
      meta: { sender: { id: 2 } },
    });
    await nextTick();

    expect(wrapper.vm.attachedFiles).toHaveLength(0);
    expect(mockAlert).toHaveBeenCalledWith(
      'CONVERSATION.REPLYBOX.RECORDING_DISCARDED_ON_MODE_CHANGE'
    );
  });

  // The recorder is the other thing setReplyMode used to tear down ahead of the mode
  // actually changing, and a finished recording has no upload callback left to speak for it.
  it('says so when a recording was going when the mode switched', async () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
    });
    await nextTick();

    wrapper.vm.toggleAudioRecorder();
    await nextTick();
    expect(wrapper.vm.isRecordingAudio).toBe(true);
    mockAlert.mockClear();

    wrapper
      .findComponent({ name: 'ReplyTopPanel' })
      .vm.$emit('setReplyMode', REPLY_EDITOR_MODES.NOTE);
    await nextTick();

    expect(wrapper.vm.isRecordingAudio).toBe(false);
    expect(mockAlert).toHaveBeenCalledWith(
      'CONVERSATION.REPLYBOX.RECORDING_DISCARDED_ON_MODE_CHANGE'
    );
  });

  // stageFile is also the clip button, drag and drop, and paste. Telling an agent their
  // recording was discarded when what they dropped was a PDF is a message they cannot act
  // on, and one wrong message is enough to stop the right ones being read.
  it('names what was actually discarded', async () => {
    const { wrapper, store } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
      chat: {
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      },
    });
    await nextTick();
    mockAlert.mockClear();

    wrapper.vm.stageFile({ name: 'contrato.pdf', file: new Blob(['pdf']) });
    store.commit('selectChat', {
      ...REPLIABLE,
      status: 'open',
      meta: { sender: { id: 2 } },
    });
    await nextTick();
    await vi.waitUntil(() => mockAlert.mock.calls.length > 0);

    expect(mockAlert).toHaveBeenCalledWith(
      'CONVERSATION.REPLYBOX.ATTACHMENT_DISCARDED_ON_MODE_CHANGE'
    );
  });

  // One transition, one message. With several files staged together every completion runs
  // this, and a stack of identical toasts for a single event is its own kind of unreadable.
  it('says it once for a batch discarded by one transition', async () => {
    const { wrapper, store } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
      chat: {
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      },
    });
    await nextTick();
    mockAlert.mockClear();

    wrapper.vm.stageFile({ name: 'um.png', file: new Blob(['a']) });
    wrapper.vm.stageFile({ name: 'dois.png', file: new Blob(['b']) });
    store.commit('selectChat', {
      ...REPLIABLE,
      status: 'open',
      meta: { sender: { id: 2 } },
    });
    await nextTick();
    await vi.waitUntil(() => mockAlert.mock.calls.length > 0);

    expect(mockAlert).toHaveBeenCalledTimes(1);
  });

  // A slow upload can span more than one switch. The message belongs to the capture that
  // has not landed yet, so a later transition must not take it: overwriting the marker
  // loses it, and so does clearing it after announcing something else visible.
  it('keeps the message for an upload that outlived two switches', async () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
    });
    await nextTick();
    mockAlert.mockClear();

    wrapper.vm.stageFile({ name: 'lento.pdf', file: new Blob(['pdf']) });
    const panel = wrapper.findComponent({ name: 'ReplyTopPanel' });
    panel.vm.$emit('setReplyMode', REPLY_EDITOR_MODES.NOTE);
    await nextTick();
    panel.vm.$emit('setReplyMode', REPLY_EDITOR_MODES.REPLY);
    await nextTick();
    await vi.waitUntil(() => mockAlert.mock.calls.length > 0);

    expect(mockAlert).toHaveBeenCalledWith(
      'CONVERSATION.REPLYBOX.ATTACHMENT_DISCARDED_ON_MODE_CHANGE'
    );
  });

  // An empty switch marks a generation nobody will ever claim. Keeping it was harmless on
  // its own and fatal next to a rule that never replaced a marker: the real loss that came
  // afterwards found the slot taken and said nothing.
  it('still speaks for a later capture after empty mode switches', async () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
    });
    await nextTick();
    const panel = wrapper.findComponent({ name: 'ReplyTopPanel' });

    panel.vm.$emit('setReplyMode', REPLY_EDITOR_MODES.NOTE);
    await nextTick();
    panel.vm.$emit('setReplyMode', REPLY_EDITOR_MODES.REPLY);
    await nextTick();
    mockAlert.mockClear();

    wrapper.vm.stageFile({ name: 'depois.pdf', file: new Blob(['pdf']) });
    panel.vm.$emit('setReplyMode', REPLY_EDITOR_MODES.NOTE);
    await nextTick();
    await vi.waitUntil(() => mockAlert.mock.calls.length > 0);

    expect(mockAlert).toHaveBeenCalledWith(
      'CONVERSATION.REPLYBOX.ATTACHMENT_DISCARDED_ON_MODE_CHANGE'
    );
  });

  // And the list is bounded, since ReplyBox stays mounted all day and a switch with nothing
  // staged leaves an entry no capture will ever claim.
  it('does not accumulate markers across a day of switching', async () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
    });
    await nextTick();
    const panel = wrapper.findComponent({ name: 'ReplyTopPanel' });

    for (let i = 0; i < 20; i += 1) {
      panel.vm.$emit(
        'setReplyMode',
        i % 2 ? REPLY_EDITOR_MODES.REPLY : REPLY_EDITOR_MODES.NOTE
      );
      // eslint-disable-next-line no-await-in-loop
      await nextTick();
    }

    expect(wrapper.vm.composerDropGenerations.length).toBeLessThanOrEqual(5);
  });

  // ReplyBox stays mounted for the whole session, so a map that recorded every navigation
  // and every send would only ever grow: nothing consumes an entry that is never announced.
  it('records nothing for the transitions it does not announce', async () => {
    const { wrapper, store } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
    });
    await nextTick();

    store.commit('selectChat', { ...REPLIABLE, id: 42 });
    await nextTick();
    wrapper.vm.clearMessage();
    store.commit('selectChat', { ...REPLIABLE, id: 43 });
    await nextTick();

    expect(wrapper.vm.composerDropGenerations).toHaveLength(0);
  });

  // A capture carries the generation it was staged under, and by the time it lands the
  // composer may have moved on twice more. What invalidated it is the first transition past
  // it, not the last one overall: reading only the latest reason loses the message here, and
  // hands it to the wrong capture in the mirror case.
  it('blames the transition that discarded the capture, not the last one', async () => {
    const { wrapper, store } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
      chat: {
        status: 'pending',
        meta: { sender: { id: 2 }, assignee_type: 'AgentBot' },
      },
    });
    await nextTick();
    mockAlert.mockClear();

    const recorded = { isVoiceMessage: true, file: new Blob(['audio']) };
    wrapper.vm.stageFile(recorded);

    // The bot hands the conversation back: this is what the recording is lost to.
    store.commit('selectChat', {
      ...REPLIABLE,
      status: 'open',
      meta: { sender: { id: 2 } },
    });
    await nextTick();
    // And the agent moves on before the upload lands.
    store.commit('selectChat', { ...REPLIABLE, id: 99 });
    await nextTick();
    await vi.waitUntil(() => mockAlert.mock.calls.length > 0);

    expect(mockAlert).toHaveBeenCalledWith(
      'CONVERSATION.REPLYBOX.RECORDING_DISCARDED_ON_MODE_CHANGE'
    );
  });

  // Both directions are worth reporting: what the agent loses is a file that will not be
  // sent, which is news whoever caused the switch. Only the claim about the contact
  // receiving it would have been direction-specific, and the wording does not make it.
  it('says so when the agent switched into note mode', async () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
    });
    await nextTick();
    mockAlert.mockClear();

    wrapper.vm.stageFile({ name: 'doc.pdf', file: new Blob(['pdf']) });
    await vi.waitUntil(() => wrapper.vm.attachedFiles.length > 0);
    mockAlert.mockClear();

    // Through the panel the agent actually clicks, not by assigning replyType: setReplyMode
    // used to empty the composer before the watcher could see what it was emptying.
    wrapper
      .findComponent({ name: 'ReplyTopPanel' })
      .vm.$emit('setReplyMode', REPLY_EDITOR_MODES.NOTE);
    await nextTick();

    expect(mockAlert).toHaveBeenCalledWith(
      'CONVERSATION.REPLYBOX.ATTACHMENT_DISCARDED_ON_MODE_CHANGE'
    );
  });

  // Moving to another conversation is the agent's own action, with the composer resetting in
  // front of them. An alert on every upload in flight when they change conversation is noise
  // on the ordinary case, which is how a message that matters stops being read.
  it('stays quiet when the agent moved to another conversation', async () => {
    const { wrapper, store } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
    });
    await nextTick();
    mockAlert.mockClear();

    wrapper.vm.stageFile({ name: 'doc.pdf', file: new Blob(['pdf']) });
    store.commit('selectChat', { ...REPLIABLE, id: 99 });
    await nextTick();

    wrapper.vm.stageFile({ name: 'current.png', file: new Blob(['image']) });
    await vi.waitUntil(() => wrapper.vm.attachedFiles.length > 0);

    expect(mockAlert).not.toHaveBeenCalled();
  });

  it('drops a capture still uploading when the message it belonged to is sent', async () => {
    const { wrapper } = mountWith({
      inbox: { channel_type: 'Channel::Whatsapp' },
    });
    await nextTick();

    const recorded = { isVoiceMessage: true, file: new Blob(['audio']) };
    wrapper.vm.stageFile(recorded);
    // The agent sends the typed note without waiting for the upload.
    wrapper.vm.clearMessage();

    const current = { name: 'current.png', file: new Blob(['image']) };
    wrapper.vm.stageFile(current);
    await vi.waitUntil(() => wrapper.vm.attachedFiles.length > 0);

    expect(wrapper.vm.attachedFiles).toHaveLength(1);
    expect(wrapper.vm.attachedFiles[0].isVoiceMessage).toBe(false);
  });

  describe('recording format in reply mode', () => {
    it.each([
      [
        'WhatsApp Cloud',
        { channel_type: 'Channel::Whatsapp', provider: 'whatsapp_cloud' },
        AUDIO_FORMATS.OGG,
      ],
      // The native connector sends what it is given and does not transcode, and Android
      // plays a voice note only as Opus in Ogg: an MP3 note plays on WhatsApp Web and
      // shows "something is wrong with the audio file" on the phone.
      [
        'native WhatsApp',
        { channel_type: 'Channel::Whatsapp', provider: 'native' },
        AUDIO_FORMATS.OGG,
      ],
      // The other session providers convert on their own side (baileys-api runs every
      // voice note through ffmpeg), so they stay on the container they already take.
      [
        'Baileys WhatsApp',
        { channel_type: 'Channel::Whatsapp', provider: 'baileys' },
        AUDIO_FORMATS.MP3,
      ],
      [
        'Z-API WhatsApp',
        { channel_type: 'Channel::Whatsapp', provider: 'zapi' },
        AUDIO_FORMATS.MP3,
      ],
      [
        'uazapi WhatsApp',
        { channel_type: 'Channel::Whatsapp', provider: 'uazapi' },
        AUDIO_FORMATS.MP3,
      ],
      [
        'Twilio WhatsApp',
        { channel_type: 'Channel::TwilioSms', medium: 'whatsapp' },
        AUDIO_FORMATS.MP3,
      ],
      ['Telegram', { channel_type: 'Channel::Telegram' }, AUDIO_FORMATS.MP3],
      ['API', { channel_type: 'Channel::Api' }, AUDIO_FORMATS.MP3],
      ['Web widget', { channel_type: 'Channel::WebWidget' }, AUDIO_FORMATS.WAV],
    ])(
      'keeps %s on the container the channel accepts',
      (_name, inbox, format) => {
        const { wrapper } = mountWith({ inbox });

        expect(wrapper.vm.audioRecordFormat).toBe(format);
      }
    );
  });

  // A paste is the fifth way a file reaches the composer, and the only one that used to drop a
  // zero-byte file without a word. The filter is deliberate and comes from upstream: the macOS
  // Numbers app puts an invalid zero-byte attachment on the clipboard next to the copied text,
  // so warning on every dropped file would fire on every spreadsheet paste.
  //
  // The shapes below were measured (macOS, Chromium 153) rather than guessed, and they are what
  // separates the two cases: a Numbers copy carries text/plain, text/html and text/rtf beside
  // its zero-byte `image.png`; a file copied in Finder arrives as `Files` alone, with the file
  // name that the pasteboard does carry as text dropped by the browser.
  describe('pasting a file', () => {
    const file = (name, type, size) =>
      new File(size ? [new Uint8Array(size)] : [], name, { type });

    const clipboard = (types, files) => ({
      clipboardData: {
        types,
        files: files.map(([name, type, size]) => file(name, type, size)),
      },
    });

    const NUMBERS = clipboard(
      ['text/plain', 'text/html', 'text/rtf', 'Files'],
      [['image.png', 'image/png', 0]]
    );
    const EMPTY_FILE = clipboard(['Files'], [['vazio.txt', 'text/plain', 0]]);

    it('says the file was empty instead of dropping it in silence', () => {
      const { wrapper } = mountWith({
        inbox: { channel_type: 'Channel::Api' },
      });

      wrapper.vm.onPaste(EMPTY_FILE);

      expect(mockAlert).toHaveBeenCalledWith('CONVERSATION.FILE_IS_EMPTY');
      expect(wrapper.vm.attachedFiles).toHaveLength(0);
    });

    it('stays quiet for a spreadsheet paste, which is why the filter exists', () => {
      const { wrapper } = mountWith({
        inbox: { channel_type: 'Channel::Api' },
      });

      wrapper.vm.onPaste(NUMBERS);

      expect(mockAlert).not.toHaveBeenCalled();
      expect(wrapper.vm.attachedFiles).toHaveLength(0);
    });

    it('attaches a real file without saying anything', async () => {
      const { wrapper } = mountWith({
        inbox: { channel_type: 'Channel::Api' },
      });

      wrapper.vm.onPaste(
        clipboard(['Files'], [['valido.txt', 'text/plain', 4]])
      );
      // stageFile finishes through a FileReader, so the attachment lands a tick later.
      await vi.waitUntil(() => wrapper.vm.attachedFiles.length > 0);

      expect(mockAlert).not.toHaveBeenCalled();
      expect(wrapper.vm.attachedFiles).toHaveLength(1);
    });

    it('keeps the valid file of a mixed paste and still explains the empty one', async () => {
      const { wrapper } = mountWith({
        inbox: { channel_type: 'Channel::Api' },
      });

      wrapper.vm.onPaste(
        clipboard(
          ['Files'],
          [
            ['vazio.txt', 'text/plain', 0],
            ['valido.txt', 'text/plain', 4],
          ]
        )
      );

      await vi.waitUntil(() => wrapper.vm.attachedFiles.length > 0);

      expect(mockAlert).toHaveBeenCalledWith('CONVERSATION.FILE_IS_EMPTY');
      expect(wrapper.vm.attachedFiles).toHaveLength(1);
      expect(wrapper.vm.attachedFiles[0].resource.name).toBe('valido.txt');
    });

    // The refusal is one alert, not one per dropped file: two empty files pasted together are
    // one thing that happened to the person pasting.
    it('explains once, however many empty files came in the same paste', () => {
      const { wrapper } = mountWith({
        inbox: { channel_type: 'Channel::Api' },
      });

      wrapper.vm.onPaste(
        clipboard(
          ['Files'],
          [
            ['um.txt', 'text/plain', 0],
            ['dois.txt', 'text/plain', 0],
          ]
        )
      );

      expect(mockAlert).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.attachedFiles).toHaveLength(0);
    });
  });

  describe('send shortcut', () => {
    const pressEnter = init =>
      document.dispatchEvent(
        new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', ...init })
      );

    it('ignores Enter while an IME composition is active', async () => {
      const { wrapper } = mountWith({
        inbox: { channel_type: 'Channel::WebWidget' },
        uiSettings: { editor_message_key: 'enter' },
      });
      await flushPromises();
      wrapper.vm.isFocused = true;
      const onSendReply = vi
        .spyOn(wrapper.vm, 'onSendReply')
        .mockImplementation(() => {});

      pressEnter({ key: 'Process', isComposing: true });
      expect(onSendReply).not.toHaveBeenCalled();

      pressEnter({});
      expect(onSendReply).toHaveBeenCalledTimes(1);

      wrapper.unmount();
    });
  });

  describe('inserting content while a Copilot draft is open', () => {
    it('dismisses the draft and appends the text to the reply', async () => {
      const { wrapper } = mountWith({ chat: REPLIABLE });
      await flushPromises();
      wrapper.vm.message = 'Hello';
      wrapper.vm.copilot.showEditor.value = true;

      emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, 'Thanks for writing');
      await nextTick();

      expect(wrapper.vm.copilot.isActive.value).toBe(false);
      expect(wrapper.vm.message).toBe('Hello\nThanks for writing');
      wrapper.unmount();
    });

    it('strips formatting the channel cannot carry', async () => {
      const { wrapper } = mountWith({
        chat: REPLIABLE,
        inbox: { channel_type: 'Channel::Api' },
      });
      await flushPromises();
      wrapper.vm.copilot.showEditor.value = true;

      emitter.emit(
        BUS_EVENTS.INSERT_INTO_RICH_EDITOR,
        'See [the docs](https://example.com) for `details`'
      );
      await nextTick();

      expect(wrapper.vm.message).toBe(
        'See the docs: https://example.com for details'
      );
      wrapper.unmount();
    });

    it('leaves the reply alone when the editor is showing', async () => {
      const { wrapper } = mountWith({ chat: REPLIABLE });
      await flushPromises();
      wrapper.vm.message = 'Hello';

      emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, 'Thanks for writing');
      await nextTick();

      expect(wrapper.vm.message).toBe('Hello');
      wrapper.unmount();
    });
  });
});

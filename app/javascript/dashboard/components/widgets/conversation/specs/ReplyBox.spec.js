import { shallowMount } from '@vue/test-utils';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import { nextTick } from 'vue';
import { createStore } from 'vuex';
import ReplyBox from '../ReplyBox.vue';

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

// Only WhatsApp and API inboxes stay repliable once the messaging window
// closes, because a template can still re-engage the contact there.
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

const buildStore = ({ inbox, chat, templates }) =>
  createStore({
    state: {
      chat: { ...REPLIABLE, ...chat },
      replyEditorMode: REPLY_EDITOR_MODES.REPLY,
    },
    mutations: {
      selectChat: (s, c) => {
        s.chat = c;
      },
      setReplyEditorMode: (s, mode) => {
        s.replyEditorMode = mode;
      },
    },
    actions: {
      'draftMessages/setReplyEditorMode': ({ commit }, { mode }) =>
        commit('setReplyEditorMode', mode),
    },
    getters: {
      getSelectedChat: s => s.chat,
      getCurrentUser: () => ({ id: 7, name: 'Agent', accounts: [] }),
      getCurrentAccountId: () => 1,
      getMessageSignature: () => '',
      getUISettings: () => ({}),
      getLastEmailInSelectedChat: () => null,
      'globalConfig/get': () => ({}),
      'inboxes/getInbox': () => () => ({ id: 1, ...inbox }),
      'inboxes/getWhatsAppTemplates': () => () => templates,
      'contacts/getContact': () => () => ({}),
      'draftMessages/get': () => () => '',
      'draftMessages/getReplyEditorMode': s => s.replyEditorMode,
      'accounts/isFeatureEnabledonAccount': () => () => false,
      'accounts/getAccount': () => () => ({}),
      'portals/allPortals': () => [],
      'integrations/getUIFlags': () => ({ isFetching: false }),
    },
  });

const mountWith = ({ inbox, chat, templates = [{ name: 'greeting' }] }) => {
  const store = buildStore({ inbox, chat, templates });
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

describe('ReplyBox', () => {
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

  it('offers content templates on Twilio WhatsApp when no bot owns the conversation', () => {
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

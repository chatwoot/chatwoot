import { flushPromises, shallowMount } from '@vue/test-utils';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import { nextTick } from 'vue';
import { createStore } from 'vuex';
import ReplyBox from '../ReplyBox.vue';
import WhatsappTemplates from '../WhatsappTemplates/Modal.vue';
import whatsappInteractivePresetsAPI from 'dashboard/api/whatsappInteractivePresets';
import { uploadFile } from 'dashboard/helper/uploadHelper';

vi.mock('dashboard/api/whatsappInteractivePresets', () => ({
  default: {
    get: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
  },
}));

vi.mock('dashboard/helper/uploadHelper', () => ({
  uploadFile: vi.fn(),
}));

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
      createPendingMessageAndSend: () => Promise.resolve(),
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
  stubs = {},
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
      stubs: { transition: false, ...stubs },
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
        list: {
          implemented: true,
          available: true,
          limits: {
            body_max_length: 4096,
            header_max_length: 60,
            footer_max_length: 60,
            button_max_length: 20,
            section_min_count: 1,
            section_max_count: 10,
            row_min_count: 1,
            row_max_count: 10,
            section_title_max_length: 24,
            row_title_max_length: 24,
            row_description_max_length: 72,
          },
        },
        carousel: {
          implemented: true,
          available: true,
          limits: {
            body_max_length: 1024,
            card_min_count: 2,
            card_max_count: 10,
            card_body_max_length: 160,
            card_body_max_line_breaks: 2,
            media: ['image'],
            action_modes: ['quick_reply', 'url'],
            button_max_length: 20,
          },
        },
        cta_url: {
          implemented: true,
          available: true,
          limits: {
            body_max_length: 1024,
            header_max_length: 60,
            footer_max_length: 60,
            header_types: ['text', 'image', 'video', 'document'],
            button_max_length: 20,
            action_count: 1,
            url_schemes: ['http', 'https'],
          },
        },
      },
    };

    beforeEach(() => {
      whatsappInteractivePresetsAPI.get.mockReset().mockResolvedValue({
        data: { payload: [] },
      });
      whatsappInteractivePresetsAPI.create.mockReset();
      whatsappInteractivePresetsAPI.update.mockReset();
      whatsappInteractivePresetsAPI.delete.mockReset();
      uploadFile.mockReset();
    });

    it('keeps the interactive scroll region separate from the send control', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
        stubs: {
          WhatsAppInteractiveComposer: {
            template:
              '<section data-testid="interactive-scroll-region"></section>',
          },
          ReplyBottomPanel: {
            template:
              '<footer><button data-testid="interactive-send">Send interaction</button></footer>',
          },
        },
      });

      wrapper.vm.toggleWhatsappInteractive();
      await nextTick();

      const scrollRegion = wrapper.get(
        '[data-testid="interactive-scroll-region"]'
      );
      const send = wrapper.get('[data-testid="interactive-send"]');
      expect(wrapper.get('.reply-box').classes()).toEqual(
        expect.arrayContaining([
          'flex',
          'max-h-[calc(100dvh-8rem)]',
          'flex-col',
          'overflow-hidden',
        ])
      );
      expect(wrapper.get('.reply-box__top').classes()).toEqual(
        expect.arrayContaining([
          'flex',
          'min-h-0',
          'flex-1',
          'flex-col',
          'overflow-hidden',
        ])
      );
      expect(scrollRegion.element.contains(send.element)).toBe(false);
      expect(scrollRegion.element.parentElement).not.toBe(
        send.element.parentElement
      );
    });

    it('submits only the normalized text-button input fields', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const sendMessage = vi
        .spyOn(wrapper.vm, 'sendMessage')
        .mockResolvedValue(true);

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
        '',
        { preserveDraft: true }
      );
      await flushPromises();
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

    it('keeps unavailable capabilities visible and opens their explanations', () => {
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
              list: capability.interactive_types.list,
            },
          },
        },
      });

      expect(
        bottomPanel(wrapper).whatsappInteractiveCapabilities.button
      ).toMatchObject({
        implemented: true,
        available: false,
        unavailable_reason: 'test_recipient_not_allowlisted',
      });
      wrapper.vm.toggleWhatsappInteractive();
      expect(wrapper.vm.isWhatsappInteractive).toBe(true);
      expect(wrapper.vm.selectedWhatsappInteractiveType).toBe('list');
    });

    it('reacts to a refreshed one-type flag without changing the other type', async () => {
      const { wrapper, store } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });

      store.commit('selectChat', {
        ...REPLIABLE,
        whatsapp_interactive: {
          ...capability,
          interactive_types: {
            button: {
              ...capability.interactive_types.button,
              available: false,
              unavailable_reason: 'temporarily_disabled',
            },
            list: capability.interactive_types.list,
          },
        },
      });
      await nextTick();

      expect(
        bottomPanel(wrapper).whatsappInteractiveCapabilities
      ).toMatchObject({
        button: {
          available: false,
          unavailable_reason: 'temporarily_disabled',
        },
        list: { available: true },
      });
    });

    it('keeps an unavailable CTA visible with its independent server reason', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: {
          whatsapp_interactive: {
            ...capability,
            business_verification_status: 'not_verified',
            interactive_types: {
              ...capability.interactive_types,
              cta_url: {
                ...capability.interactive_types.cta_url,
                available: false,
                unavailable_reason: 'service_window_closed',
              },
            },
          },
        },
      });

      expect(
        bottomPanel(wrapper).whatsappInteractiveCapabilities.cta_url
      ).toMatchObject({
        implemented: true,
        available: false,
        unavailable_reason: 'service_window_closed',
      });
    });

    it('submits ordered URL carousel cards and uploads without client fields', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const sendMessage = vi
        .spyOn(wrapper.vm, 'sendMessage')
        .mockResolvedValue(true);
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.selectWhatsappInteractiveType('carousel');
      wrapper.vm.whatsappInteractiveDraft = {
        body: ' Choose a destination. ',
        actionMode: 'url',
        cards: [
          {
            clientKey: 'mountain',
            body: ' Mountain escape ',
            media: {
              file: 'mountain-upload',
              name: 'mountain.png',
              type: 'image/png',
            },
            action: {
              button: ' View mountain ',
              url: ' https://example.test/mountain ',
            },
          },
          {
            clientKey: 'beach',
            body: ' ',
            media: {
              file: 'beach-upload',
              name: 'beach.png',
              type: 'image/png',
            },
            action: {
              button: 'View beach',
              url: 'https://example.test/beach',
            },
          },
        ],
      };

      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(true);
      wrapper.vm.confirmOnSendReply();

      const payload = sendMessage.mock.calls[0][0];
      expect(payload.files).toEqual(['mountain-upload', 'beach-upload']);
      expect(payload.contentAttributes.whatsapp_interactive).toEqual({
        schema_version: 1,
        type: 'carousel',
        body: { text: 'Choose a destination.' },
        action: {
          cards: [
            {
              card_index: 0,
              type: 'cta_url',
              header: { type: 'image' },
              body: { text: 'Mountain escape' },
              action: {
                button: 'View mountain',
                url: 'https://example.test/mountain',
              },
            },
            {
              card_index: 1,
              type: 'cta_url',
              header: { type: 'image' },
              action: {
                button: 'View beach',
                url: 'https://example.test/beach',
              },
            },
          ],
        },
      });
      expect(JSON.stringify(payload.contentAttributes)).not.toMatch(
        /clientKey|uploadFile|delivery_id|attachment_id/
      );
      await flushPromises();
    });

    it('validates uniform quick replies and preserves option identity and order', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const sendMessage = vi
        .spyOn(wrapper.vm, 'sendMessage')
        .mockResolvedValue(false);
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.selectWhatsappInteractiveType('carousel');
      const card = (clientKey, buttons) => ({
        clientKey,
        body: '',
        media: { file: `${clientKey}-upload`, type: 'image/png' },
        action: { buttons },
      });
      const firstReply = {
        clientKey: 'reply-a',
        title: ' Choose ',
        preset_option_id: '11111111-1111-4111-8111-111111111111',
      };
      const secondReply = {
        clientKey: 'reply-b',
        title: 'Details',
        preset_option_id: '22222222-2222-4222-8222-222222222222',
      };
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'Choose',
        actionMode: 'quick_reply',
        source: { preset_id: 42 },
        cards: [
          card('first', [secondReply, firstReply]),
          card('second', [
            { clientKey: 'reply-c', title: 'Choose' },
            { clientKey: 'reply-d', title: 'Details' },
          ]),
        ],
      };

      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(true);
      wrapper.vm.confirmOnSendReply();
      const interactive =
        sendMessage.mock.calls[0][0].contentAttributes.whatsapp_interactive;
      expect(interactive.source).toEqual({ preset_id: 42 });
      expect(interactive.action.cards[0].action.buttons).toEqual([
        {
          title: 'Details',
          preset_option_id: '22222222-2222-4222-8222-222222222222',
        },
        {
          title: 'Choose',
          preset_option_id: '11111111-1111-4111-8111-111111111111',
        },
      ]);

      wrapper.vm.whatsappInteractiveDraft = {
        ...wrapper.vm.whatsappInteractiveDraft,
        cards: [
          wrapper.vm.whatsappInteractiveDraft.cards[0],
          card('second', [{ clientKey: 'reply-c', title: 'Choose' }]),
        ],
      };
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
      wrapper.vm.whatsappInteractiveDraft.cards[1].action.buttons = [
        { title: 'Same' },
        { title: 'Same' },
      ];
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
      wrapper.vm.whatsappInteractiveDraft = {
        ...wrapper.vm.whatsappInteractiveDraft,
        cards: [
          card('first', [{ title: ' ' }, { title: 'Details' }]),
          card('second', [{ title: 'Choose' }, { title: 'Details' }]),
        ],
      };
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
      wrapper.vm.whatsappInteractiveDraft = {
        ...wrapper.vm.whatsappInteractiveDraft,
        cards: [
          card('first', [{ title: 'x'.repeat(21) }, { title: 'Details' }]),
          card('second', [{ title: 'Choose' }, { title: 'Details' }]),
        ],
      };
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
    });

    it('rejects missing images, video cards, overflow content, and excess line breaks', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.selectWhatsappInteractiveType('carousel');
      const valid = wrapper.vm.whatsappInteractiveDraft;
      valid.body = 'Choose';
      valid.cards.forEach((card, index) => {
        card.media = { file: `image-${index}`, type: 'image/png' };
        card.action = {
          button: `Card ${index + 1}`,
          url: `https://example.test/${index}`,
        };
      });
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(true);

      const original = valid.cards[0];
      wrapper.vm.whatsappInteractiveDraft = {
        ...valid,
        cards: [{ ...original, media: null }, valid.cards[1]],
      };
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
      wrapper.vm.whatsappInteractiveDraft = {
        ...valid,
        cards: [
          { ...original, media: { file: 'video', type: 'video/mp4' } },
          valid.cards[1],
        ],
      };
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
      wrapper.vm.whatsappInteractiveDraft = {
        ...valid,
        cards: [{ ...original, body: 'x'.repeat(161) }, valid.cards[1]],
      };
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
      wrapper.vm.whatsappInteractiveDraft = {
        ...valid,
        cards: [{ ...original, body: 'one\ntwo\nthree\nfour' }, valid.cards[1]],
      };
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
    });

    it('correlates concurrent carousel uploads after edits and reordering', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.selectWhatsappInteractiveType('carousel');
      vi.spyOn(wrapper.vm, 'onFileUpload').mockImplementation(() => {});
      const keys = wrapper.vm.whatsappInteractiveDraft.cards.map(
        card => card.clientKey
      );
      const firstFile = new File(['first'], 'first.png', { type: 'image/png' });
      const secondFile = new File(['second'], 'second.png', {
        type: 'image/png',
      });
      wrapper.vm.uploadWhatsappHeader(firstFile, keys[0]);
      wrapper.vm.uploadWhatsappHeader(secondFile, keys[1]);
      const uploads = wrapper.vm.onFileUpload.mock.calls.map(call => call[0]);
      const readers = [];
      const readerMock = vi
        .spyOn(window, 'FileReader')
        .mockImplementation(() => {
          const reader = { readAsDataURL: vi.fn(), result: '' };
          readers.push(reader);
          return reader;
        });
      wrapper.vm.attachFile({ file: uploads[0], blob: { signed_id: 'first' } });
      wrapper.vm.attachFile({
        file: uploads[1],
        blob: { signed_id: 'second' },
      });
      wrapper.vm.whatsappInteractiveDraft = {
        ...wrapper.vm.whatsappInteractiveDraft,
        cards: [...wrapper.vm.whatsappInteractiveDraft.cards].reverse(),
      };
      readers[1].result = 'data:image/png;base64,second';
      readers[1].onloadend();
      readers[0].result = 'data:image/png;base64,first';
      readers[0].onloadend();

      expect(
        wrapper.vm.whatsappInteractiveDraft.cards.map(card => [
          card.clientKey,
          card.media.file,
        ])
      ).toEqual([
        [keys[1], 'second'],
        [keys[0], 'first'],
      ]);
      readerMock.mockRestore();
    });

    it.each([undefined, 'text', 'image', 'video', 'document'])(
      'submits a boundary-valid CTA with a %s header and no client attachment ID',
      async headerType => {
        const { wrapper } = mountWith({
          inbox: {
            channel_type: 'Channel::Whatsapp',
            provider: 'whatsapp_cloud',
          },
          chat: { whatsapp_interactive: capability },
        });
        const sendMessage = vi
          .spyOn(wrapper.vm, 'sendMessage')
          .mockResolvedValue(true);
        wrapper.vm.toggleWhatsappInteractive();
        wrapper.vm.selectWhatsappInteractiveType('cta_url');
        wrapper.vm.whatsappInteractiveDraft = {
          body: ` ${'b'.repeat(1024)} `,
          footer: ` ${'f'.repeat(60)} `,
          button: ` ${'a'.repeat(20)} `,
          url: ' https://example.test/details ',
          ...(headerType && { headerType }),
          ...(headerType === 'text' && {
            headerText: ` ${'h'.repeat(60)} `,
          }),
          ...(['image', 'video', 'document'].includes(headerType) && {
            media: { file: 'signed-upload', name: 'header-media' },
          }),
        };

        expect(wrapper.vm.isWhatsappInteractiveValid).toBe(true);
        wrapper.vm.confirmOnSendReply();

        const payload = sendMessage.mock.calls[0][0];
        expect(payload.contentAttributes.whatsapp_interactive).toMatchObject({
          schema_version: 1,
          type: 'cta_url',
          body: { text: 'b'.repeat(1024) },
          footer: { text: 'f'.repeat(60) },
          action: {
            button: 'a'.repeat(20),
            url: 'https://example.test/details',
          },
          ...(headerType && {
            header: {
              type: headerType,
              ...(headerType === 'text' && { text: 'h'.repeat(60) }),
            },
          }),
        });
        expect(payload.files).toEqual(
          ['image', 'video', 'document'].includes(headerType)
            ? ['signed-upload']
            : undefined
        );
        expect(JSON.stringify(payload.contentAttributes)).not.toMatch(
          /attachment_id|delivery_id/
        );
        await flushPromises();
      }
    );

    it('blocks invalid CTA content and non-HTTP destinations', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.selectWhatsappInteractiveType('cta_url');
      const sendMessage = vi.spyOn(wrapper.vm, 'sendMessage');
      const valid = {
        body: 'Review your order',
        footer: '',
        button: 'View details',
        url: 'https://example.test/details',
      };
      wrapper.vm.whatsappInteractiveDraft = valid;
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(true);

      [
        { body: ' ' },
        { body: 'x'.repeat(1025) },
        { footer: 'x'.repeat(61) },
        { button: ' ' },
        { button: 'x'.repeat(21) },
        { url: '' },
        { url: 'not a URL' },
        { url: 'ftp://example.test/file' },
        { url: 'https:///missing-host' },
        { url: 'https://example.test/a path' },
        { url: 'https://invalid_host.example/path' },
        { headerType: 'text', headerText: ' ' },
        { headerType: 'image', media: null },
      ].forEach(invalid => {
        wrapper.vm.whatsappInteractiveDraft = { ...valid, ...invalid };
        expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
        wrapper.vm.confirmOnSendReply();
      });
      expect(sendMessage).not.toHaveBeenCalled();
    });

    it('submits a boundary-valid native list without client IDs', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const sendMessage = vi
        .spyOn(wrapper.vm, 'sendMessage')
        .mockResolvedValue(true);
      wrapper.vm.message = 'Keep the ordinary draft';
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.selectWhatsappInteractiveType('list');
      wrapper.vm.whatsappInteractiveDraft = {
        header: ` ${'h'.repeat(60)} `,
        body: ` ${'b'.repeat(4096)} `,
        footer: ` ${'f'.repeat(60)} `,
        button: ` ${'o'.repeat(20)} `,
        sections: Array.from({ length: 10 }, (_, index) => ({
          title: `Section ${index + 1}`,
          rows: [
            {
              title: `${index + 1}`.padEnd(24, 'r'),
              description: 'd'.repeat(72),
            },
          ],
        })),
      };

      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(true);
      wrapper.vm.confirmOnSendReply();

      const interactive =
        sendMessage.mock.calls[0][0].contentAttributes.whatsapp_interactive;
      expect(interactive).toMatchObject({
        schema_version: 1,
        type: 'list',
        header: { type: 'text', text: 'h'.repeat(60) },
        body: { text: 'b'.repeat(4096) },
        footer: { text: 'f'.repeat(60) },
        action: { button: 'o'.repeat(20) },
      });
      expect(interactive.action.sections).toHaveLength(10);
      expect(interactive.action.sections[0].rows[0]).toEqual({
        title: '1'.padEnd(24, 'r'),
        description: 'd'.repeat(72),
      });
      expect(JSON.stringify(interactive)).not.toMatch(/delivery_id|"id"/);
      await flushPromises();
      expect(wrapper.vm.isWhatsappInteractive).toBe(false);
      expect(wrapper.vm.message).toBe('Keep the ordinary draft');
    });

    it('rejects blank and overflow list structures before submission', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.selectWhatsappInteractiveType('list');
      const valid = {
        header: '',
        body: 'Choose',
        footer: '',
        button: 'Open',
        sections: [{ title: '', rows: [{ title: 'One', description: '' }] }],
      };
      wrapper.vm.whatsappInteractiveDraft = valid;
      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(true);

      [
        { body: ' ' },
        { body: 'x'.repeat(4097) },
        { header: 'x'.repeat(61) },
        { footer: 'x'.repeat(61) },
        { button: 'x'.repeat(21) },
        { sections: [] },
        {
          sections: Array.from({ length: 11 }, () => ({
            title: '',
            rows: [{ title: 'Row', description: '' }],
          })),
        },
        { sections: [{ title: '', rows: [] }] },
        {
          sections: [
            {
              title: 'x'.repeat(25),
              rows: [{ title: 'Row', description: '' }],
            },
          ],
        },
        {
          sections: [
            {
              title: '',
              rows: [{ title: 'x'.repeat(25), description: '' }],
            },
          ],
        },
        {
          sections: [
            {
              title: '',
              rows: [{ title: 'Row', description: 'x'.repeat(73) }],
            },
          ],
        },
        {
          sections: [{ title: '', rows: [{ title: ' ', description: '' }] }],
        },
        {
          sections: [
            {
              title: '',
              rows: Array.from({ length: 11 }, () => ({
                title: 'Row',
                description: '',
              })),
            },
          ],
        },
      ].forEach(invalid => {
        wrapper.vm.whatsappInteractiveDraft = { ...valid, ...invalid };
        expect(wrapper.vm.isWhatsappInteractiveValid).toBe(false);
      });
    });

    it('normalizes whitespace-only optional list fields to absence', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const sendMessage = vi
        .spyOn(wrapper.vm, 'sendMessage')
        .mockResolvedValue(true);
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.selectWhatsappInteractiveType('list');
      wrapper.vm.whatsappInteractiveDraft = {
        header: '   ',
        body: 'Choose',
        footer: '   ',
        button: 'Open',
        sections: [
          {
            title: '   ',
            rows: [{ title: 'One', description: '   ' }],
          },
        ],
      };

      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(true);
      wrapper.vm.confirmOnSendReply();

      const interactive =
        sendMessage.mock.calls[0][0].contentAttributes.whatsapp_interactive;
      expect(interactive).not.toHaveProperty('header');
      expect(interactive).not.toHaveProperty('footer');
      expect(interactive.action.sections[0]).not.toHaveProperty('title');
      expect(interactive.action.sections[0].rows[0]).toEqual({ title: 'One' });
      await flushPromises();
    });

    it('discards structured state without changing the ordinary text draft', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.message = 'Keep this ordinary reply';
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.selectWhatsappInteractiveType('list');
      wrapper.vm.whatsappInteractiveDraft.body = 'Discard this list';

      wrapper.vm.resetWhatsappInteractive();

      expect(wrapper.vm.message).toBe('Keep this ordinary reply');
      expect(wrapper.vm.whatsappInteractiveDraft).toEqual({
        body: '',
        buttons: [''],
      });
    });

    it('keeps structured content when sending fails', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      vi.spyOn(wrapper.vm, 'sendMessage').mockResolvedValue(false);
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'Choose',
        buttons: ['Confirm'],
      };

      wrapper.vm.confirmOnSendReply();
      await flushPromises();

      expect(wrapper.vm.isWhatsappInteractive).toBe(true);
      expect(wrapper.vm.whatsappInteractiveDraft).toEqual({
        body: 'Choose',
        buttons: ['Confirm'],
      });
    });

    it('preserves the ordinary draft entry only for structured sends', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const removeFromDraft = vi.spyOn(wrapper.vm, 'removeFromDraft');

      await wrapper.vm.sendMessage({}, '', '', { preserveDraft: true });
      expect(removeFromDraft).not.toHaveBeenCalled();

      await wrapper.vm.sendMessage({});
      expect(removeFromDraft).toHaveBeenCalledTimes(1);
    });

    it('does not reset a newer interactive draft after an earlier send succeeds', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      let resolveSend;
      vi.spyOn(wrapper.vm, 'sendMessage').mockReturnValue(
        new Promise(resolve => {
          resolveSend = resolve;
        })
      );
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'First',
        buttons: ['Send'],
      };
      wrapper.vm.confirmOnSendReply();
      const newerDraft = { body: 'Second', buttons: ['Keep'] };
      wrapper.vm.whatsappInteractiveDraft = newerDraft;

      resolveSend(true);
      await flushPromises();

      expect(wrapper.vm.isWhatsappInteractive).toBe(true);
      expect(wrapper.vm.whatsappInteractiveDraft).toBe(newerDraft);
    });

    it('dispatches an interactive draft only once while its send is pending', () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const sendMessage = vi
        .spyOn(wrapper.vm, 'sendMessage')
        .mockReturnValue(new Promise(() => {}));
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'Send once',
        buttons: ['Confirm'],
      };

      wrapper.vm.confirmOnSendReply();
      wrapper.vm.confirmOnSendReply();

      expect(sendMessage).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.isReplyButtonDisabled).toBe(true);
    });

    it('keeps a replacement header upload selected while a send completes', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      let resolveSend;
      vi.spyOn(wrapper.vm, 'sendMessage').mockReturnValue(
        new Promise(resolve => {
          resolveSend = resolve;
        })
      );
      vi.spyOn(wrapper.vm, 'onFileUpload').mockImplementation(() => {});
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'First',
        buttons: ['Send'],
        headerType: 'image',
        media: { file: 'signed-upload', name: 'first.png' },
      };
      wrapper.vm.confirmOnSendReply();
      const replacement = new File(['replacement'], 'replacement.png', {
        type: 'image/png',
      });

      wrapper.vm.uploadWhatsappHeader(replacement);
      resolveSend(true);
      await flushPromises();

      expect(wrapper.vm.isWhatsappInteractive).toBe(true);
      expect(wrapper.vm.whatsappInteractiveDraft.uploadFile).toBe(replacement);
    });

    it('does not reset a new conversation composer after an earlier send succeeds', async () => {
      const { wrapper, store } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      let resolveSend;
      vi.spyOn(wrapper.vm, 'sendMessage').mockReturnValue(
        new Promise(resolve => {
          resolveSend = resolve;
        })
      );
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'First conversation',
        buttons: ['Send'],
      };
      wrapper.vm.confirmOnSendReply();

      store.commit('selectChat', {
        ...REPLIABLE,
        id: 2,
        whatsapp_interactive: capability,
      });
      await nextTick();
      wrapper.vm.toggleWhatsappInteractive();
      const newerDraft = { body: 'Second conversation', buttons: ['Keep'] };
      wrapper.vm.whatsappInteractiveDraft = newerDraft;
      resolveSend(true);
      await flushPromises();

      expect(wrapper.vm.isWhatsappInteractive).toBe(true);
      expect(wrapper.vm.whatsappInteractiveDraft).toBe(newerDraft);
    });

    it('bypasses hidden ordinary-editor variable checks for interactive sends', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.message = 'Hidden {{unknown.variable}}';
      wrapper.vm.toggleWhatsappInteractive();
      const confirmOnSendReply = vi
        .spyOn(wrapper.vm, 'confirmOnSendReply')
        .mockImplementation(() => {});

      await wrapper.vm.onSendReply();

      expect(confirmOnSendReply).toHaveBeenCalledTimes(1);
    });

    it('uses type-neutral send copy for native lists', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      wrapper.vm.toggleWhatsappInteractive();
      wrapper.vm.selectWhatsappInteractiveType('list');
      await nextTick();

      expect(bottomPanel(wrapper).sendButtonText).toContain(
        'CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.SEND'
      );
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
      async type => {
        const { wrapper } = mountWith({
          inbox: {
            channel_type: 'Channel::Whatsapp',
            provider: 'whatsapp_cloud',
          },
          chat: { whatsapp_interactive: capability },
        });
        const sendMessage = vi
          .spyOn(wrapper.vm, 'sendMessage')
          .mockResolvedValue(true);
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
        await flushPromises();
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

    it('keeps only the newest preset search response', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      let resolveFirst;
      let resolveSecond;
      whatsappInteractivePresetsAPI.get
        .mockReturnValueOnce(
          new Promise(resolve => {
            resolveFirst = resolve;
          })
        )
        .mockReturnValueOnce(
          new Promise(resolve => {
            resolveSecond = resolve;
          })
        );
      wrapper.vm.isWhatsappInteractive = true;

      const first = wrapper.vm.fetchWhatsappPresets('first');
      const second = wrapper.vm.fetchWhatsappPresets('second');
      resolveSecond({ data: { payload: [{ id: 2, name: 'Second' }] } });
      await second;
      resolveFirst({ data: { payload: [{ id: 1, name: 'First' }] } });
      await first;

      expect(wrapper.vm.whatsappPresets).toEqual([{ id: 2, name: 'Second' }]);
    });

    it('preserves the draft and existing results when preset search fails', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const draft = { body: 'Keep this', buttons: ['Continue'] };
      const presets = [{ id: 42, name: 'Existing' }];
      whatsappInteractivePresetsAPI.get.mockRejectedValue(
        new Error('request failed')
      );
      wrapper.vm.isWhatsappInteractive = true;
      wrapper.vm.whatsappInteractiveDraft = draft;
      wrapper.vm.whatsappPresets = presets;

      await wrapper.vm.fetchWhatsappPresets('missing');

      expect(wrapper.vm.whatsappInteractiveDraft).toBe(draft);
      expect(wrapper.vm.whatsappPresets).toBe(presets);
      expect(wrapper.vm.whatsappPresetsLoading).toBe(false);
    });

    it('saves while sending is unavailable and rehydrates the response', async () => {
      const unavailableCapability = {
        ...capability,
        interactive_types: {
          ...capability.interactive_types,
          button: {
            ...capability.interactive_types.button,
            available: false,
            unavailable_reason: 'service_window_closed',
          },
        },
      };
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: unavailableCapability },
      });
      const source = {
        id: 42,
        name: 'Original',
        interactive_type: 'button',
        creator: { id: 8, name: 'Other agent' },
        permissions: { update: false, delete: false },
        attachments: [],
        definition: {
          schema_version: 1,
          type: 'button',
          body: { text: 'Choose' },
          action: {
            buttons: [{ title: 'Continue', preset_option_id: 'old-option' }],
          },
        },
      };
      const saved = {
        ...source,
        id: 43,
        name: 'My copy',
        creator: { id: 7, name: 'Agent' },
        permissions: { update: true, delete: false },
        definition: {
          ...source.definition,
          action: {
            buttons: [{ title: 'Continue', preset_option_id: 'new-option' }],
          },
        },
      };
      whatsappInteractivePresetsAPI.create.mockResolvedValue({ data: saved });
      wrapper.vm.isWhatsappInteractive = true;
      wrapper.vm.selectWhatsappPreset(source);
      wrapper.vm.whatsappPresetName = 'My copy';

      expect(wrapper.vm.isWhatsappInteractiveValid).toBe(true);
      expect(wrapper.vm.isReplyButtonDisabled).toBe(true);
      await wrapper.vm.saveWhatsappPreset('create');

      expect(whatsappInteractivePresetsAPI.create).toHaveBeenCalledWith({
        name: 'My copy',
        definition: {
          schema_version: 1,
          type: 'button',
          body: { text: 'Choose' },
          action: { buttons: [{ title: 'Continue' }] },
        },
      });
      expect(wrapper.vm.selectedWhatsappPreset.id).toBe(43);
      expect(
        wrapper.vm.whatsappInteractiveDraft.buttons[0].preset_option_id
      ).toBe('new-option');
      expect(wrapper.vm.whatsappInteractiveCapability.unavailable_reason).toBe(
        'service_window_closed'
      );
    });

    it('uploads indirect media before saving a preset', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const file = new File(['image'], 'header.png', { type: 'image/png' });
      const saved = {
        id: 43,
        name: 'Media preset',
        interactive_type: 'button',
        creator: { id: 7, name: 'Agent' },
        permissions: { update: true, delete: false },
        attachments: [
          {
            position: 0,
            filename: 'header.png',
            content_type: 'image/png',
            data_url: 'data:image/png;base64,image',
            signed_id: 'saved-blob',
          },
        ],
        definition: {
          schema_version: 1,
          type: 'button',
          body: { text: 'Choose' },
          header: { type: 'image' },
          action: { buttons: [{ title: 'Continue' }] },
        },
      };
      uploadFile.mockResolvedValue({ blobId: 'uploaded-blob' });
      whatsappInteractivePresetsAPI.create.mockResolvedValue({ data: saved });
      wrapper.vm.isWhatsappInteractive = true;
      wrapper.vm.selectedWhatsappInteractiveType = 'button';
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'Choose',
        headerType: 'image',
        headerText: '',
        footer: '',
        buttons: ['Continue'],
        media: { name: 'header.png', file },
      };
      wrapper.vm.whatsappPresetName = 'Media preset';

      await wrapper.vm.saveWhatsappPreset('create');

      expect(uploadFile).toHaveBeenCalledWith(file, 1);
      expect(whatsappInteractivePresetsAPI.create).toHaveBeenCalledWith(
        expect.objectContaining({ attachments: ['uploaded-blob'] })
      );
    });

    it('owns the draft until save rehydrates the canonical response', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      let resolveSave;
      const response = {
        id: 77,
        name: 'Saved copy',
        interactive_type: 'button',
        creator: { id: 7, name: 'Agent' },
        permissions: { update: true, delete: false },
        attachments: [],
        definition: {
          schema_version: 1,
          type: 'button',
          body: { text: 'Choose' },
          action: {
            buttons: [{ title: 'Continue', preset_option_id: 'canonical-id' }],
          },
        },
      };
      whatsappInteractivePresetsAPI.create.mockReturnValue(
        new Promise(resolve => {
          resolveSave = resolve;
        })
      );
      wrapper.vm.isWhatsappInteractive = true;
      wrapper.vm.selectedWhatsappInteractiveType = 'button';
      const submittedDraft = { body: 'Choose', buttons: ['Continue'] };
      wrapper.vm.whatsappInteractiveDraft = submittedDraft;
      wrapper.vm.whatsappPresetName = 'Saved copy';

      const saving = wrapper.vm.saveWhatsappPreset('create');
      wrapper.vm.updateWhatsappInteractiveDraft({
        body: 'Changed',
        buttons: ['Stop'],
      });
      wrapper.vm.updateWhatsappPresetName('Changed name');
      wrapper.vm.selectWhatsappInteractiveType('list');

      expect(wrapper.vm.whatsappPresetBusy).toBe(true);
      expect(wrapper.vm.whatsappInteractiveDraft).toBe(submittedDraft);
      expect(wrapper.vm.whatsappPresetName).toBe('Saved copy');
      expect(wrapper.vm.selectedWhatsappInteractiveType).toBe('button');

      resolveSave({ data: response });
      await saving;

      expect(whatsappInteractivePresetsAPI.get).toHaveBeenCalled();
      expect(wrapper.vm.selectedWhatsappPreset.id).toBe(77);
      expect(
        wrapper.vm.whatsappInteractiveDraft.buttons[0].preset_option_id
      ).toBe('canonical-id');
      expect(wrapper.vm.whatsappPresetBusy).toBe(false);
    });

    it('updates only a permitted original with identity hints and media removal', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const preset = {
        id: 42,
        name: 'Original',
        interactive_type: 'button',
        creator: { id: 7, name: 'Agent' },
        permissions: { update: true, delete: false },
        attachments: [],
        definition: {
          schema_version: 1,
          type: 'button',
          body: { text: 'Choose' },
          action: {
            buttons: [{ title: 'Continue', preset_option_id: 'option-1' }],
          },
        },
      };
      whatsappInteractivePresetsAPI.update.mockResolvedValue({ data: preset });
      wrapper.vm.isWhatsappInteractive = true;
      wrapper.vm.selectWhatsappPreset(preset);

      await wrapper.vm.saveWhatsappPreset('update');

      expect(whatsappInteractivePresetsAPI.update).toHaveBeenCalledWith(42, {
        name: 'Original',
        definition: {
          schema_version: 1,
          type: 'button',
          body: { text: 'Choose' },
          action: {
            buttons: [{ title: 'Continue', preset_option_id: 'option-1' }],
          },
        },
        attachments: [],
      });
    });

    it('preserves the editable draft when saving fails', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      const draft = { body: 'Choose', buttons: ['Continue'] };
      whatsappInteractivePresetsAPI.create.mockRejectedValue(
        new Error('request failed')
      );
      wrapper.vm.isWhatsappInteractive = true;
      wrapper.vm.selectedWhatsappInteractiveType = 'button';
      wrapper.vm.whatsappInteractiveDraft = draft;
      wrapper.vm.whatsappPresetName = 'Keep me';

      await wrapper.vm.saveWhatsappPreset('create');

      expect(wrapper.vm.whatsappInteractiveDraft).toBe(draft);
      expect(wrapper.vm.whatsappPresetName).toBe('Keep me');
    });

    it('deletes only with permission and keeps a copy without provenance', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      whatsappInteractivePresetsAPI.delete.mockResolvedValue({});
      wrapper.vm.isWhatsappInteractive = true;
      wrapper.vm.selectedWhatsappInteractiveType = 'button';
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'Choose',
        source: { preset_id: 42 },
        buttons: [{ title: 'Continue', preset_option_id: 'option-1' }],
      };
      wrapper.vm.selectedWhatsappPreset = {
        id: 42,
        permissions: { update: false, delete: true },
      };
      wrapper.vm.whatsappPresets = [{ id: 42 }];

      await wrapper.vm.deleteWhatsappPreset();

      expect(whatsappInteractivePresetsAPI.delete).toHaveBeenCalledWith(42);
      expect(wrapper.vm.selectedWhatsappPreset).toBeNull();
      expect(wrapper.vm.whatsappPresets).toEqual([]);
      expect(wrapper.vm.whatsappInteractiveDraft).toEqual({
        body: 'Choose',
        buttons: [{ title: 'Continue' }],
      });
    });

    it('owns the selected draft until deletion detaches its provenance', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      let resolveDelete;
      whatsappInteractivePresetsAPI.delete.mockReturnValue(
        new Promise(resolve => {
          resolveDelete = resolve;
        })
      );
      wrapper.vm.isWhatsappInteractive = true;
      wrapper.vm.selectedWhatsappInteractiveType = 'button';
      const submittedDraft = {
        body: 'Choose',
        source: { preset_id: 42 },
        buttons: [{ title: 'Continue', preset_option_id: 'option-1' }],
      };
      wrapper.vm.whatsappInteractiveDraft = submittedDraft;
      wrapper.vm.selectedWhatsappPreset = {
        id: 42,
        permissions: { update: false, delete: true },
      };

      const deleting = wrapper.vm.deleteWhatsappPreset();
      wrapper.vm.updateWhatsappInteractiveDraft({
        body: 'Changed',
        buttons: ['Stop'],
      });
      wrapper.vm.selectWhatsappPreset({
        id: 99,
        definition: { type: 'button' },
      });

      expect(wrapper.vm.whatsappInteractiveDraft).toBe(submittedDraft);
      expect(wrapper.vm.selectedWhatsappPreset.id).toBe(42);

      resolveDelete({});
      await deleting;

      expect(wrapper.vm.selectedWhatsappPreset).toBeNull();
      expect(wrapper.vm.whatsappInteractiveDraft).toEqual({
        body: 'Choose',
        buttons: [{ title: 'Continue' }],
      });
      expect(wrapper.vm.whatsappPresetBusy).toBe(false);
    });

    it('does not let an old mutation clear a newer operation busy state', async () => {
      const { wrapper } = mountWith({
        inbox: {
          channel_type: 'Channel::Whatsapp',
          provider: 'whatsapp_cloud',
        },
        chat: { whatsapp_interactive: capability },
      });
      let resolveFirst;
      let resolveSecond;
      whatsappInteractivePresetsAPI.create
        .mockReturnValueOnce(
          new Promise(resolve => {
            resolveFirst = resolve;
          })
        )
        .mockReturnValueOnce(
          new Promise(resolve => {
            resolveSecond = resolve;
          })
        );
      wrapper.vm.isWhatsappInteractive = true;
      wrapper.vm.selectedWhatsappInteractiveType = 'button';
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'First',
        buttons: ['Continue'],
      };
      wrapper.vm.whatsappPresetName = 'First';
      const first = wrapper.vm.saveWhatsappPreset('create');

      wrapper.vm.resetWhatsappInteractive();
      wrapper.vm.isWhatsappInteractive = true;
      wrapper.vm.selectedWhatsappInteractiveType = 'button';
      wrapper.vm.whatsappInteractiveDraft = {
        body: 'Second',
        buttons: ['Continue'],
      };
      wrapper.vm.whatsappPresetName = 'Second';
      const second = wrapper.vm.saveWhatsappPreset('create');

      resolveFirst({ data: {} });
      await first;
      expect(wrapper.vm.whatsappPresetBusy).toBe(true);
      expect(wrapper.vm.whatsappPresetName).toBe('Second');

      resolveSecond({
        data: {
          id: 2,
          name: 'Second',
          attachments: [],
          definition: {
            schema_version: 1,
            type: 'button',
            body: { text: 'Second' },
            action: { buttons: [{ title: 'Continue' }] },
          },
        },
      });
      await second;
      expect(wrapper.vm.whatsappPresetBusy).toBe(false);
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

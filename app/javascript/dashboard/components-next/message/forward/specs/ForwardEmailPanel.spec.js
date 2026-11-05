import { defineComponent, ref } from 'vue';
import { mount, flushPromises } from '@vue/test-utils';
import { createStore } from 'vuex';
import { parseISO } from 'date-fns';
import { withFullI18n } from 'test-i18n';
import MessageFormatter from 'shared/helpers/MessageFormatter';
import { formatQuotedEmailDate } from 'dashboard/helper/quotedEmailHelper';
import { createContactSearcher } from 'dashboard/components-next/NewConversation/helpers/composeConversationHelper';
import Button from 'dashboard/components-next/button/Button.vue';
import ForwardEmailPanel from '../ForwardEmailPanel.vue';
import { provideMessageContext } from '../../provider.js';
import { MESSAGE_TYPES } from '../../constants';

vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({ fetchSignatureFlagFromUISettings: () => false }),
}));

vi.mock(
  'dashboard/components-next/NewConversation/helpers/composeConversationHelper',
  async importOriginal => ({
    ...(await importOriginal()),
    createContactSearcher: vi.fn(),
  })
);

withFullI18n();

Object.defineProperty(HTMLElement.prototype, 'innerText', {
  configurable: true,
  get() {
    return this.textContent;
  },
});

const stub = (name, props, emits = []) => ({
  name,
  props,
  emits,
  template: '<div><slot /></div>',
});

const stubs = {
  ContextMenu: {
    name: 'ContextMenu',
    props: ['x', 'y', 'closeOnFocusOut'],
    template: '<div><slot /></div>',
  },
  InboxSelector: stub('InboxSelector', ['targetInbox', 'removable']),
  RecipientsInput: stub(
    'RecipientsInput',
    ['modelValue', 'contacts', 'showDropdown', 'isLoading'],
    ['update:modelValue', 'input', 'onClickOutside']
  ),
  MessageEditor: stub(
    'MessageEditor',
    { modelValue: String, placeholder: String, compact: Boolean },
    ['update:modelValue']
  ),
  AttachmentPreviews: stub(
    'AttachmentPreviews',
    ['attachments'],
    ['update:attachments']
  ),
  ActionButtons: stub(
    'ActionButtons',
    ['disableSendButton', 'attachedFiles', 'isDropdownActive'],
    ['sendMessage', 'discard', 'attachFile']
  ),
};

const contact = { name: 'Jane Doe', email: 'jane@example.com' };
const inbox = {
  id: 9,
  name: 'Support',
  email: 'support@example.com',
  channel_type: 'Channel::Email',
};
const email = {
  from: ['jane@example.com'],
  to: ['support@example.com'],
  date: '2026-09-17T09:39:00Z',
  subject: 'Order #42',
  htmlContent: { full: '<p>Original body</p>' },
  textContent: { full: 'Original body' },
};
const attachment = {
  id: 7,
  thumbUrl: 'https://cdn.example.com/thumb.png',
  dataUrl: 'https://cdn.example.com/files/invoice.pdf',
  fileType: 'file',
};

const mountPanel = ({ message = {}, directUploadsEnabled = false } = {}) => {
  const sendMessage = vi.fn();
  const store = createStore({
    getters: {
      getSelectedChat: () => ({
        meta: { sender: contact },
        additional_attributes: { mail_subject: 'Conversation subject' },
      }),
      getCurrentUser: () => ({
        name: 'Agent Smith',
        avatar_url: 'https://cdn.example.com/agent.png',
      }),
      'globalConfig/get': () => ({ directUploadsEnabled }),
      getMessageSignature: () => '',
      'inboxes/getInbox': () => () => inbox,
      getSelectedChatAttachments: () => [],
    },
    actions: { createPendingMessageAndSend: sendMessage },
  });
  const context = {
    id: 501,
    content: 'Plain fallback',
    contentAttributes: { email },
    attachments: [attachment],
    messageType: MESSAGE_TYPES.INCOMING,
    sender: contact,
    createdAt: 1789000000,
    conversationId: 77,
    inboxId: 9,
    ...message,
  };
  const Host = defineComponent({
    components: { ForwardEmailPanel },
    setup() {
      provideMessageContext(
        Object.fromEntries(
          Object.entries(context).map(([key, value]) => [key, ref(value)])
        )
      );
    },
    template: '<ForwardEmailPanel :x="10" :y="20" @close="$emit(\'close\')" />',
  });
  const wrapper = mount(Host, {
    attachTo: document.body,
    global: { plugins: [store], stubs },
  });

  return { wrapper, sendMessage };
};

const sentPayload = sendMessage => sendMessage.mock.calls[0][1];

const find = (wrapper, name) => wrapper.findComponent({ name });
const bodyElement = wrapper => wrapper.find('[contenteditable="true"]').element;

const addRecipient = wrapper =>
  find(wrapper, 'RecipientsInput').vm.$emit('update:modelValue', [
    'vendor@example.com',
  ]);

describe('ForwardEmailPanel', () => {
  let searchContacts;

  beforeEach(() => {
    document.execCommand = vi.fn();
    searchContacts = vi.fn().mockResolvedValue([]);
    createContactSearcher.mockReturnValue(searchContacts);
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('prefills the gmail style header, original body and attachments', () => {
    const { wrapper } = mountPanel();
    const text = wrapper.text();

    expect(text).toContain('---------- Forwarded message ---------');
    expect(text).toContain('From: Jane Doe <jane@example.com>');
    expect(text).toContain(
      `Date: ${formatQuotedEmailDate(parseISO(email.date))}`
    );
    expect(text).toContain('Subject: Order #42');
    expect(text).toContain('To: <support@example.com>');
    expect(text).toContain('Original body');

    expect(find(wrapper, 'InboxSelector').props()).toMatchObject({
      targetInbox: { name: 'Support', email: 'support@example.com' },
      removable: false,
    });
    expect(find(wrapper, 'MessageEditor').props('compact')).toBe(true);
    expect(find(wrapper, 'AttachmentPreviews').props('attachments')).toEqual([
      {
        forwardedAttachmentId: 7,
        thumb: attachment.thumbUrl,
        resource: { id: 'forwarded-7', name: 'invoice.pdf', type: 'file' },
      },
    ]);
  });

  it('uses the inbox as sender when forwarding an outgoing email', () => {
    const { wrapper } = mountPanel({
      message: { messageType: MESSAGE_TYPES.OUTGOING },
    });

    expect(wrapper.text()).toContain('From: Support <support@example.com>');
  });

  it('uses the inbox as sender when forwarding a template message', () => {
    const { wrapper } = mountPanel({
      message: { messageType: MESSAGE_TYPES.TEMPLATE, sender: null },
    });

    expect(wrapper.text()).toContain('From: Support <support@example.com>');
  });

  it('falls back to plain text, the conversation subject and the contact', () => {
    const { wrapper } = mountPanel({
      message: {
        content: 'Line one\nLine two',
        contentAttributes: {},
        attachments: [],
      },
    });
    const text = wrapper.text();

    expect(text).toContain('Line one');
    expect(text).toContain('Line two');
    expect(text).toContain('Subject: Conversation subject');
    expect(text).toContain('To: <jane@example.com>');
    expect(text).toContain(
      `Date: ${formatQuotedEmailDate(new Date(1789000000 * 1000))}`
    );
    expect(find(wrapper, 'AttachmentPreviews').exists()).toBe(false);
  });

  it('enables send only once a recipient is added', async () => {
    const { wrapper, sendMessage } = mountPanel();
    const actions = find(wrapper, 'ActionButtons');

    expect(actions.props('disableSendButton')).toBe(true);
    await actions.vm.$emit('sendMessage');
    expect(sendMessage).not.toHaveBeenCalled();

    await addRecipient(wrapper);
    expect(actions.props('disableSendButton')).toBe(false);
  });

  it('sends the note, the edited body and the kept attachments', async () => {
    const { wrapper, sendMessage } = mountPanel();

    await addRecipient(wrapper);
    await find(wrapper, 'MessageEditor').vm.$emit(
      'update:modelValue',
      'Please handle this'
    );
    bodyElement(wrapper).innerHTML = '<p>Edited body</p>';
    await find(wrapper, 'ActionButtons').vm.$emit('sendMessage');

    expect(sentPayload(sendMessage)).toEqual({
      conversationId: 77,
      message: 'Please handle this\n\nEdited body',
      emailHtmlContent: `${new MessageFormatter('Please handle this').formattedMessage}<p>Edited body</p>`,
      toEmails: 'vendor@example.com',
      ccEmails: '',
      bccEmails: '',
      private: false,
      contentAttributes: { forwarded_message_id: 501 },
      forwardedAttachmentIds: [7],
      files: [],
      sender: {
        name: 'Agent Smith',
        thumbnail: 'https://cdn.example.com/agent.png',
      },
    });
    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('resolves variables in the note before building the email', async () => {
    const { wrapper, sendMessage } = mountPanel();

    await addRecipient(wrapper);
    await find(wrapper, 'MessageEditor').vm.$emit(
      'update:modelValue',
      'Hello {{contact.name}}, please help.'
    );
    bodyElement(wrapper).innerHTML = '<p>Edited body</p>';
    await find(wrapper, 'ActionButtons').vm.$emit('sendMessage');

    const payload = sentPayload(sendMessage);
    expect(payload.message).toBe('Hello Jane Doe, please help.\n\nEdited body');
    expect(payload.emailHtmlContent).toContain('Hello Jane Doe, please help.');
  });

  it('drops removed original attachments and sends newly attached files', async () => {
    const { wrapper, sendMessage } = mountPanel();
    const file = new File(['pdf'], 'new.pdf', { type: 'application/pdf' });

    await addRecipient(wrapper);
    await find(wrapper, 'AttachmentPreviews').vm.$emit(
      'update:attachments',
      []
    );
    await find(wrapper, 'ActionButtons').vm.$emit('attachFile', [
      { resource: { file, name: 'new.pdf', type: 'application/pdf' } },
    ]);
    await find(wrapper, 'ActionButtons').vm.$emit('sendMessage');

    expect(sentPayload(sendMessage)).toMatchObject({
      forwardedAttachmentIds: [],
      files: [file],
    });
  });

  it('sends signed blob ids when direct uploads are enabled', async () => {
    const { wrapper, sendMessage } = mountPanel({ directUploadsEnabled: true });
    const actions = find(wrapper, 'ActionButtons');

    await addRecipient(wrapper);
    await actions.vm.$emit('attachFile', [
      ...actions.props('attachedFiles'),
      { blobSignedId: 'signed-id', resource: { name: 'new.pdf' } },
    ]);
    await find(wrapper, 'ActionButtons').vm.$emit('sendMessage');

    expect(sentPayload(sendMessage)).toMatchObject({
      forwardedAttachmentIds: [7],
      files: ['signed-id'],
    });
  });

  it('searches contacts once two characters are typed', async () => {
    vi.useFakeTimers();
    const contacts = [{ id: 1, name: 'Vendor', email: 'vendor@example.com' }];
    searchContacts.mockResolvedValue(contacts);
    const { wrapper } = mountPanel();
    const recipients = find(wrapper, 'RecipientsInput');

    await recipients.vm.$emit('input', 'v');
    vi.advanceTimersByTime(400);
    expect(searchContacts).not.toHaveBeenCalled();
    expect(recipients.props('showDropdown')).toBe(false);

    await recipients.vm.$emit('input', 've');
    vi.advanceTimersByTime(400);
    await flushPromises();

    expect(searchContacts).toHaveBeenCalledWith('ve');
    expect(recipients.props()).toMatchObject({
      showDropdown: true,
      isLoading: false,
      contacts,
    });

    await recipients.vm.$emit('onClickOutside');
    expect(recipients.props('showDropdown')).toBe(false);
    vi.useRealTimers();
  });

  it('opens the contact dropdown only on the row being typed in', async () => {
    vi.useFakeTimers();
    const { wrapper } = mountPanel();
    const [to, cc] = wrapper.findAllComponents({ name: 'RecipientsInput' });

    await cc.vm.$emit('input', 'ab');
    vi.advanceTimersByTime(400);
    await flushPromises();

    expect(cc.props('showDropdown')).toBe(true);
    expect(to.props('showDropdown')).toBe(false);
    expect(find(wrapper, 'ActionButtons').props('isDropdownActive')).toBe(true);
    vi.useRealTimers();
  });

  it('keeps a row dropdown open when a sibling row reports a click outside', async () => {
    vi.useFakeTimers();
    const { wrapper } = mountPanel();
    const [to, cc] = wrapper.findAllComponents({ name: 'RecipientsInput' });

    await to.vm.$emit('input', 'ab');
    vi.advanceTimersByTime(400);
    await flushPromises();

    await cc.vm.$emit('onClickOutside');
    expect(to.props('showDropdown')).toBe(true);

    await to.vm.$emit('onClickOutside');
    expect(to.props('showDropdown')).toBe(false);
    vi.useRealTimers();
  });

  it('sends cc and bcc recipients', async () => {
    const { wrapper, sendMessage } = mountPanel();

    expect(wrapper.findAllComponents({ name: 'RecipientsInput' })).toHaveLength(
      2
    );
    await wrapper.findComponent(Button).trigger('click');
    const [, cc, bcc] = wrapper.findAllComponents({ name: 'RecipientsInput' });

    await addRecipient(wrapper);
    await cc.vm.$emit('update:modelValue', ['ops@example.com']);
    await bcc.vm.$emit('update:modelValue', ['audit@example.com']);
    await find(wrapper, 'ActionButtons').vm.$emit('sendMessage');

    expect(sentPayload(sendMessage)).toMatchObject({
      toEmails: 'vendor@example.com',
      ccEmails: 'ops@example.com',
      bccEmails: 'audit@example.com',
    });
  });

  it('closes on discard without sending', async () => {
    const { wrapper, sendMessage } = mountPanel();

    await find(wrapper, 'ActionButtons').vm.$emit('discard');

    expect(sendMessage).not.toHaveBeenCalled();
    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('undoes body edits from the keyboard shortcut when focus is elsewhere', async () => {
    const { wrapper } = mountPanel();
    await flushPromises();
    await flushPromises();

    document.dispatchEvent(
      new KeyboardEvent('keydown', {
        key: 'z',
        code: 'KeyZ',
        ctrlKey: true,
        bubbles: true,
      })
    );

    expect(document.activeElement).toBe(bodyElement(wrapper));
    expect(document.execCommand).toHaveBeenCalledWith('undo');
  });
});

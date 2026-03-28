/* eslint-disable vue/no-unused-properties */
import { createStore } from 'vuex';
import { defineComponent } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { describe, expect, it, vi, beforeEach } from 'vitest';
import ConversationHeader from '../ConversationHeader.vue';

const mocks = vi.hoisted(() => {
  const useRoute = vi.fn();
  const useI18n = vi.fn();
  const useInbox = vi.fn();

  return {
    useRoute,
    useI18n,
    useInbox,
  };
});

vi.mock('vue-router', async importOriginal => {
  const actual = await importOriginal();

  return {
    ...actual,
    useRoute: mocks.useRoute,
  };
});

vi.mock('vue-i18n', () => ({
  useI18n: mocks.useI18n,
}));

vi.mock('dashboard/composables/useInbox', () => ({
  useInbox: mocks.useInbox,
}));

describe('ConversationHeader.vue', () => {
  const voiceInbox = {
    id: 22,
    channel_type: 'Channel::Voice',
    name: 'Voice inbox',
  };
  const emailInbox = {
    id: 33,
    channel_type: 'Channel::Email',
    name: 'Email inbox',
  };
  const VoiceCallButtonStub = defineComponent({
    name: 'VoiceCallButton',
    props: {
      phone: { type: String, default: '' },
      contactId: { type: [String, Number], default: null },
      fixedInboxId: { type: [String, Number], default: null },
      navigateOnSuccess: { type: Boolean, default: true },
      label: { type: String, default: '' },
      icon: { type: [String, Object, Function], default: '' },
    },
    template: '<div data-test-id="voice-call-button-stub" />',
  });

  const createSubject = ({
    inbox = voiceInbox,
    contact = {
      id: 91,
      name: 'Voice Contact',
      phone_number: '+15555550100',
      thumbnail: '',
      availability_status: 'online',
    },
  } = {}) => {
    const store = createStore({
      getters: {
        getSelectedChat: () => ({
          id: 101,
          status: 'open',
          inbox_id: inbox.id,
        }),
        getCurrentAccountId: () => 1,
      },
      modules: {
        contacts: {
          namespaced: true,
          getters: {
            getContact: () => id => (id === contact.id ? contact : null),
          },
        },
        inboxes: {
          namespaced: true,
          getters: {
            getInbox: () => inboxId => {
              if (inboxId === voiceInbox.id) return voiceInbox;
              if (inboxId === emailInbox.id) return emailInbox;
              return inbox;
            },
            getInboxes: () => [voiceInbox, emailInbox],
          },
        },
      },
    });

    mocks.useRoute.mockReturnValue({
      params: {
        accountId: 1,
        inbox_id: inbox.id,
        label: undefined,
        teamId: undefined,
        id: undefined,
      },
      name: 'conversation_index',
    });
    mocks.useI18n.mockReturnValue({ t: key => key });
    mocks.useInbox.mockReturnValue({
      isAWebWidgetInbox: { value: false },
    });

    return shallowMount(ConversationHeader, {
      props: {
        chat: {
          id: 101,
          inbox_id: inbox.id,
          meta: {
            sender: { id: contact.id },
            hmac_verified: true,
          },
        },
      },
      global: {
        plugins: [store],
        stubs: {
          Avatar: true,
          BackButton: true,
          InboxName: true,
          MoreActions: true,
          SLACardLabel: true,
          VoiceCallButton: VoiceCallButtonStub,
          'fluent-icon': true,
        },
      },
    });
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders the voice call action for a Voice inbox contact with a phone number', () => {
    const wrapper = createSubject();

    const callButton = wrapper.getComponent(VoiceCallButtonStub);

    expect(callButton.exists()).toBe(true);
    expect(callButton.props()).toMatchObject({
      phone: '+15555550100',
      contactId: 91,
      fixedInboxId: voiceInbox.id,
      navigateOnSuccess: false,
      label: 'CONTACT_PANEL.CALL',
    });
  });

  it('hides the voice call action for non-voice inboxes', () => {
    const wrapper = createSubject({ inbox: emailInbox });

    expect(wrapper.findComponent({ name: 'VoiceCallButton' }).exists()).toBe(
      false
    );
  });

  it('hides the voice call action when the contact has no phone number', () => {
    const wrapper = createSubject({
      contact: {
        id: 92,
        name: 'Email Contact',
        phone_number: null,
        thumbnail: '',
        availability_status: 'offline',
      },
    });

    expect(wrapper.findComponent({ name: 'VoiceCallButton' }).exists()).toBe(
      false
    );
  });

  it('places the voice call action before the more actions cluster', () => {
    const wrapper = createSubject();
    const html = wrapper.html();

    expect(html).toContain('voice-call-button-stub');
    expect(html).toContain('more-actions-stub');
    expect(html.indexOf('voice-call-button-stub')).toBeLessThan(
      html.indexOf('more-actions-stub')
    );
  });
});

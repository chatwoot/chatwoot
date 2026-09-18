import { ref } from 'vue';
import { flushPromises, shallowMount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { VOICE_CALL_PROVIDERS, INBOX_TYPES } from 'dashboard/helper/inbox';
import {
  MESSAGE_TYPES,
  VOICE_CALL_DIRECTION,
  VOICE_CALL_STATUS,
} from 'dashboard/components-next/message/constants';
import { useCallsStore } from 'dashboard/stores/calls';
import ConversationCallButton from 'dashboard/components/widgets/conversation/ConversationCallButton.vue';
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';
import VoiceCall from 'dashboard/components-next/message/bubbles/VoiceCall.vue';

const mocks = vi.hoisted(() => ({
  dispatch: vi.fn(),
  inboxes: [],
  messageContext: null,
}));

vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { accountId: '1' } }),
  useRouter: () => ({ push: vi.fn() }),
}));

vi.mock('vuex', () => ({
  useStore: () => ({
    dispatch: mocks.dispatch,
    getters: {
      getConversationById: vi.fn(() => ({ meta: { assignee: null } })),
      'agents/getAgentById': vi.fn(),
    },
  }),
}));

vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({
    dispatch: mocks.dispatch,
    getters: {
      getConversationById: vi.fn(),
    },
  }),
  useMapGetter: key => {
    const values = {
      'contacts/getUIFlags': {},
      'inboxes/getInboxes': mocks.inboxes,
    };
    return { value: values[key] };
  },
}));

vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ isCloudFeatureEnabled: () => true }),
}));

vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

vi.mock('dashboard/composables/useWhatsappCallSession', () => ({
  cleanupWhatsappSession: vi.fn(),
  useWhatsappCallSession: () => ({
    isInitiating: ref(false),
    initiateOutboundCall: vi.fn(),
  }),
}));

vi.mock('dashboard/api/channel/voice/twilioVoiceClient', () => ({
  default: { endClientCall: vi.fn() },
}));

vi.mock('dashboard/composables/useCallSession', () => ({
  useCallActions: () => ({
    activeCall: ref(null),
    hasActiveCall: ref(false),
    isJoining: ref(false),
    joinCall: vi.fn(),
    endCall: vi.fn(),
  }),
}));

vi.mock('dashboard/components-next/message/provider.js', () => ({
  useMessageContext: () => mocks.messageContext,
}));

const twilioInbox = {
  id: 7,
  name: 'Support line',
  channel_type: INBOX_TYPES.TWILIO,
  voice_enabled: true,
  phone_number: '+16045550198',
};

const twilioResponse = {
  call_sid: 'CA123',
  conversation_id: 42,
};

const expectNormalizedTwilioCall = callsStore => {
  callsStore.setCallActive(twilioResponse.call_sid);

  expect(callsStore.activeCall).toEqual({
    callSid: twilioResponse.call_sid,
    conversationId: twilioResponse.conversation_id,
    inboxId: twilioInbox.id,
    callDirection: VOICE_CALL_DIRECTION.OUTBOUND,
    provider: VOICE_CALL_PROVIDERS.TWILIO,
    isActive: true,
  });
};

describe('outbound Twilio call producers', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    mocks.inboxes = [twilioInbox];
    mocks.dispatch.mockResolvedValue(twilioResponse);
    mocks.messageContext = {
      call: ref({
        status: VOICE_CALL_STATUS.NO_ANSWER,
        direction: VOICE_CALL_DIRECTION.INCOMING,
        provider: VOICE_CALL_PROVIDERS.TWILIO,
      }),
      attachments: ref([]),
      contentAttributes: ref({}),
      conversationId: ref(twilioResponse.conversation_id),
      currentUserId: ref(1),
      inboxId: ref(twilioInbox.id),
      sender: ref({ id: 99 }),
      messageType: ref(MESSAGE_TYPES.INCOMING),
    };
  });

  it('retains the Twilio provider when started from the conversation header', async () => {
    const callsStore = useCallsStore();
    const wrapper = shallowMount(ConversationCallButton, {
      props: {
        inbox: twilioInbox,
        chat: {
          id: twilioResponse.conversation_id,
          meta: { sender: { id: 99 } },
        },
      },
    });

    await wrapper.get('button').trigger('click');
    await flushPromises();

    expectNormalizedTwilioCall(callsStore);
  });

  it('retains the Twilio provider when started from a contact', async () => {
    const callsStore = useCallsStore();
    const wrapper = shallowMount(VoiceCallButton, {
      props: { phone: '+16045550198', contactId: 99 },
    });

    await wrapper.findComponent({ name: 'Button' }).trigger('click');
    await flushPromises();

    expectNormalizedTwilioCall(callsStore);
  });

  it('retains the Twilio provider when calling back from a message bubble', async () => {
    const callsStore = useCallsStore();
    const wrapper = shallowMount(VoiceCall, {
      global: {
        stubs: {
          BaseBubble: { template: '<div><slot /></div>' },
        },
      },
    });

    await wrapper.get('button').trigger('click');
    await flushPromises();

    expectNormalizedTwilioCall(callsStore);
  });
});

import { ref } from 'vue';
import { mount } from '@vue/test-utils';
import VoiceCallBubble from './VoiceCall.vue';
import { MESSAGE_TYPES, VOICE_CALL_STATUS } from '../constants';

let messageContext;
let joinCallMock;
let endCallMock;
let conversationsById;
let activeCall;
let hasActiveCall;
let isJoining;

vi.mock('../provider.js', () => ({
  useMessageContext: () => messageContext,
}));

vi.mock('dashboard/composables/useCallSession', () => ({
  useCallSession: () => ({
    activeCall,
    hasActiveCall,
    isJoining,
    joinCall: joinCallMock,
    endCall: endCallMock,
  }),
}));

vi.mock('vuex', () => ({
  useStore: () => ({
    getters: {
      getConversationById: id => conversationsById[id] || null,
    },
  }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params = {}) => {
      const translations = {
        'CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS': 'Call in progress',
        'CONVERSATION.VOICE_CALL.AGENT_ANSWERED': `${params.agentName} answered`,
        'CONVERSATION.VOICE_CALL.YOU_ANSWERED': 'You answered',
        'CONVERSATION.VOICE_CALL.THEY_ANSWERED': 'They answered',
        'CONVERSATION.VOICE_CALL.NOT_ANSWERED_YET': 'Not answered yet',
        'CONVERSATION.VOICE_CALL.CALL_ENDED': 'Call ended',
        'CONVERSATION.VOICE_CALL.NO_ANSWER': 'No answer',
        'CONVERSATION.VOICE_CALL.JOIN_CALL': 'Join call',
        'CONVERSATION.VOICE_CALL.REJOIN_CALL': 'Rejoin call',
      };

      return translations[key] || key;
    },
  }),
}));

const mountComponent = () =>
  mount(VoiceCallBubble, {
    global: {
      stubs: {
        BaseBubble: {
          template: '<div><slot /></div>',
        },
        Icon: true,
        AudioChip: {
          props: ['attachment'],
          template:
            '<div data-test-id="audio-chip">{{ attachment.dataUrl }}</div>',
        },
      },
      mocks: {
        $t: key => key,
      },
    },
  });

describe('VoiceCall.vue', () => {
  beforeEach(() => {
    joinCallMock = vi.fn().mockResolvedValue({ conferenceSid: 'CF123' });
    endCallMock = vi.fn().mockResolvedValue();
    conversationsById = {
      12: {
        id: 12,
        inbox_id: 3,
        meta: {
          assignee: null,
        },
      },
    };
    activeCall = ref(null);
    hasActiveCall = ref(false);
    isJoining = ref(false);
    messageContext = {
      contentAttributes: ref({
        data: {
          status: VOICE_CALL_STATUS.IN_PROGRESS,
          call_sid: 'CALL123',
          meta: {},
        },
      }),
      attachments: ref([]),
      conversationId: ref(12),
      currentUserId: ref(1),
      inboxId: ref(3),
      messageType: ref(MESSAGE_TYPES.INCOMING),
    };
  });

  it('shows the answering agent name when another agent answers the call', () => {
    messageContext.contentAttributes.value.data.meta.joinedBy = {
      id: 2,
      name: 'Ben',
    };

    const wrapper = mountComponent();

    expect(wrapper.text()).toContain('Ben answered');
  });

  it('shows "You answered" when the current user answered the call', () => {
    messageContext.contentAttributes.value.data.meta.joinedBy = {
      id: 1,
      name: 'John',
    };

    const wrapper = mountComponent();

    expect(wrapper.text()).toContain('You answered');
  });

  it('shows the formatted duration when a call has ended', () => {
    messageContext.contentAttributes.value.data.status =
      VOICE_CALL_STATUS.COMPLETED;
    messageContext.contentAttributes.value.data.meta.duration = 133;

    const wrapper = mountComponent();

    expect(wrapper.text()).toContain('Call ended');
    expect(wrapper.text()).toContain('02:13');
  });

  it('renders the recording attachment on the voice call message', () => {
    messageContext.attachments.value = [
      {
        id: 1,
        fileType: 'audio',
        dataUrl: 'https://example.com/recording.mp3',
      },
    ];

    const wrapper = mountComponent();

    expect(wrapper.find('[data-test-id="audio-chip"]').exists()).toBe(true);
    expect(wrapper.text()).toContain('https://example.com/recording.mp3');
  });

  it('shows a rejoin action for an in-progress call when not already connected', async () => {
    const wrapper = mountComponent();

    await wrapper.find('[data-test-id="voice-call-join"]').trigger('click');

    expect(joinCallMock).toHaveBeenCalledWith({
      conversationId: 12,
      inboxId: 3,
      callSid: 'CALL123',
    });
    expect(wrapper.text()).toContain('Rejoin call');
  });

  it('joins the call after refresh when the payload is camel-cased', async () => {
    messageContext.contentAttributes.value.data = {
      status: VOICE_CALL_STATUS.IN_PROGRESS,
      callSid: 'CALL456',
      meta: {},
    };

    const wrapper = mountComponent();

    await wrapper.find('[data-test-id="voice-call-join"]').trigger('click');

    expect(joinCallMock).toHaveBeenCalledWith({
      conversationId: 12,
      inboxId: 3,
      callSid: 'CALL456',
    });
    expect(wrapper.text()).toContain('Rejoin call');
  });

  it('hides the rejoin action when the agent is already on the same call', async () => {
    activeCall.value = {
      callSid: 'CALL123',
      conversationId: 12,
    };
    hasActiveCall.value = true;

    const wrapper = mountComponent();
    const joinButton = wrapper.find('[data-test-id="voice-call-join"]');

    await joinButton.trigger('click');

    expect(joinButton.attributes('disabled')).toBeDefined();
    expect(joinCallMock).not.toHaveBeenCalled();
    expect(wrapper.text()).not.toContain('Join call');
    expect(wrapper.text()).not.toContain('Rejoin call');
  });

  it('does not expose a join action when another agent is assigned', () => {
    conversationsById[12].meta.assignee = { id: 99, name: 'Ben' };

    const wrapper = mountComponent();
    const joinButton = wrapper.find('[data-test-id="voice-call-join"]');

    expect(joinButton.attributes('disabled')).toBeDefined();
    expect(wrapper.text()).not.toContain('Join call');
    expect(wrapper.text()).not.toContain('Rejoin call');
  });
});

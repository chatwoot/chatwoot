import { ref } from 'vue';
import { mount } from '@vue/test-utils';
import VoiceCallBubble from './VoiceCall.vue';
import { MESSAGE_TYPES, VOICE_CALL_STATUS } from '../constants';

let messageContext;

vi.mock('../provider.js', () => ({
  useMessageContext: () => messageContext,
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
      },
      mocks: {
        $t: key => key,
      },
    },
  });

describe('VoiceCall.vue', () => {
  beforeEach(() => {
    messageContext = {
      contentAttributes: ref({
        data: {
          status: VOICE_CALL_STATUS.IN_PROGRESS,
          meta: {},
        },
      }),
      currentUserId: ref(1),
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
});

import { mount, shallowMount } from '@vue/test-utils';
import AgentMessage from '../AgentMessage.vue';
import UnreadMessage from '../UnreadMessage.vue';

const maliciousName =
  '<img src="https://example.com/tracker.png" onerror="alert(1)">Agent';
const maliciousCompanyName = '<strong>Example Company</strong>';

const channelConfig = {
  avatarUrl: '',
  enabledFeatures: [],
  websiteName: maliciousCompanyName,
};

describe('agent identity rendering', () => {
  beforeEach(() => {
    window.chatwootWebChannel = channelConfig;
  });

  afterEach(() => {
    delete window.chatwootWebChannel;
  });

  it('renders the agent name as plain text beside widget messages', () => {
    const wrapper = shallowMount(AgentMessage, {
      props: {
        message: {
          id: 1,
          attachments: [],
          content: 'Hello',
          content_attributes: {},
          content_type: 'text',
          message_type: 1,
          sender: {
            available_name: maliciousName,
            avatar_url: '',
          },
          showAvatar: true,
        },
      },
    });
    const agentName = wrapper.find('.agent-name');

    expect(agentName.text()).toBe(maliciousName);
    expect(agentName.find('img').exists()).toBe(false);
    expect(agentName.html()).toContain('&lt;img');
  });

  it('renders agent and company names as plain text in unread messages', () => {
    const wrapper = mount(UnreadMessage, {
      props: {
        message: 'Hello',
        showSender: true,
        sender: {
          available_name: maliciousName,
          avatar_url: '',
        },
      },
      global: {
        stubs: { Avatar: true },
        directives: {
          dompurifyHtml: (element, binding) => {
            element.textContent = binding.value;
          },
        },
      },
    });
    const agentName = wrapper.find('.agent--name');
    const companyName = wrapper.find('.company--name');

    expect(agentName.text()).toBe(maliciousName);
    expect(agentName.find('img').exists()).toBe(false);
    expect(companyName.text()).toContain(maliciousCompanyName);
    expect(companyName.find('strong').exists()).toBe(false);
  });

  it('marks Captain replies as AI next to the sender name', () => {
    const wrapper = shallowMount(AgentMessage, {
      props: {
        message: {
          id: 2,
          attachments: [],
          content: 'Hello',
          content_attributes: {},
          content_type: 'text',
          message_type: 1,
          sender: {
            name: 'Support',
            avatar_url: 'https://example.com/logo.png',
            type: 'captain_assistant',
          },
          showAvatar: true,
        },
      },
    });

    expect(wrapper.find('.agent-name').text()).toBe('Support · AI_ASSISTANT');
  });

  it('marks Captain replies as AI in the unread preview', () => {
    const wrapper = mount(UnreadMessage, {
      props: {
        message: 'Hello',
        showSender: true,
        sender: {
          name: 'Support',
          avatar_url: 'https://example.com/logo.png',
          type: 'captain_assistant',
        },
      },
      global: {
        stubs: { Avatar: true },
        directives: {
          dompurifyHtml: (element, binding) => {
            element.textContent = binding.value;
          },
        },
      },
    });

    const senderParts = wrapper
      .findAll('.row--agent-block > span > span')
      .map(part => part.text());

    expect(senderParts.slice(0, 2)).toEqual(['Support', '· AI_ASSISTANT']);
    expect(senderParts[2]).toContain('UNREAD_VIEW.COMPANY_FROM');
  });
});

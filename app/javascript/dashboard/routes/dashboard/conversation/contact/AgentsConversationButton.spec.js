import { createHash } from 'node:crypto';
import { flushPromises, mount } from '@vue/test-utils';
import AgentsConversationButton from './AgentsConversationButton.vue';

const mocks = vi.hoisted(() => ({ getAgentBot: vi.fn() }));

vi.mock('dashboard/api/inboxes', () => ({
  default: { getAgentBot: mocks.getAgentBot },
}));

const AGENTS = 'https://agents.example.com/api/v1/chatwoot/webhook/tok';
const tokSha256 = createHash('sha256').update('tok').digest('hex');
// `bot_config` defaults to {} but the column is nullable, and an API client can null it.
const botReply = (outgoingUrl, botConfig = null) => ({
  data: {
    agent_bot: outgoingUrl
      ? { outgoing_url: outgoingUrl, bot_config: botConfig }
      : {},
  },
});

const mountWith = conversation =>
  mount(AgentsConversationButton, {
    props: { conversation },
    global: { mocks: { $t: key => key } },
  });

describe('AgentsConversationButton', () => {
  beforeEach(() => {
    mocks.getAgentBot.mockReset();
  });

  it('opens the conversation in fazer.ai agents when the inbox bot delivers there', async () => {
    mocks.getAgentBot.mockResolvedValue(botReply(AGENTS));
    const open = vi.spyOn(window, 'open').mockImplementation(() => null);
    const wrapper = mountWith({ id: 42, account_id: 3, inbox_id: 9 });
    await vi.waitFor(() => expect(wrapper.find('button').exists()).toBe(true));

    expect(mocks.getAgentBot).toHaveBeenCalledWith(9);
    await wrapper.find('button').trigger('click');
    expect(open).toHaveBeenCalledWith(
      `https://agents.example.com/chatwoot/accounts/3/conversations/42?inbox=9&bot=${tokSha256}`,
      '_blank',
      'noopener'
    );
    open.mockRestore();
  });

  it('opens the public console address the bot carries instead of the address Chatwoot calls', async () => {
    mocks.getAgentBot.mockResolvedValue(
      botReply('http://10.40.10.20:3000/api/v1/chatwoot/webhook/tok', {
        console_url: 'https://console.example.com',
      })
    );
    const open = vi.spyOn(window, 'open').mockImplementation(() => null);
    const wrapper = mountWith({ id: 42, account_id: 3, inbox_id: 9 });
    await vi.waitFor(() => expect(wrapper.find('button').exists()).toBe(true));

    await wrapper.find('button').trigger('click');
    expect(open).toHaveBeenCalledWith(
      `https://console.example.com/chatwoot/accounts/3/conversations/42?inbox=9&bot=${tokSha256}`,
      '_blank',
      'noopener'
    );
    open.mockRestore();
  });

  it('shows nothing when the inbox has no bot or another bot', async () => {
    mocks.getAgentBot.mockResolvedValueOnce(botReply(null));
    const none = mountWith({ id: 1, account_id: 3, inbox_id: 9 });
    await flushPromises();
    expect(none.find('button').exists()).toBe(false);

    mocks.getAgentBot.mockResolvedValueOnce(
      botReply('https://bot.example.com/hook')
    );
    const other = mountWith({ id: 1, account_id: 3, inbox_id: 10 });
    await flushPromises();
    expect(other.find('button').exists()).toBe(false);
  });

  it('follows the conversation to another inbox, and a late reply for the old one does not count', async () => {
    let answerOld;
    mocks.getAgentBot
      .mockReturnValueOnce(
        new Promise(resolve => {
          answerOld = resolve;
        })
      )
      .mockResolvedValueOnce(botReply(null));
    const wrapper = mountWith({ id: 1, account_id: 3, inbox_id: 9 });
    await wrapper.setProps({
      conversation: { id: 2, account_id: 3, inbox_id: 10 },
    });
    await flushPromises();
    answerOld(botReply(AGENTS));
    // NOTE: the old reply still has to be hashed, which settles outside the microtask queue.
    await new Promise(resolve => {
      setTimeout(resolve, 50);
    });
    await flushPromises();

    expect(mocks.getAgentBot).toHaveBeenLastCalledWith(10);
    expect(wrapper.find('button').exists()).toBe(false);
  });

  it('hides the button while the next inbox is still being asked about', async () => {
    mocks.getAgentBot
      .mockResolvedValueOnce(botReply(AGENTS))
      .mockReturnValueOnce(new Promise(() => {}));
    const wrapper = mountWith({ id: 1, account_id: 3, inbox_id: 9 });
    await vi.waitFor(() => expect(wrapper.find('button').exists()).toBe(true));

    await wrapper.setProps({
      conversation: { id: 2, account_id: 3, inbox_id: 10 },
    });
    expect(wrapper.find('button').exists()).toBe(false);
  });
});

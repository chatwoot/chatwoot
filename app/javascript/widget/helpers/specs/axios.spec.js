import { API, setActiveConversationId } from '../axios';

describe('widget API client', () => {
  beforeEach(() => {
    API.defaults.adapter = async config => ({
      data: {},
      status: 200,
      statusText: 'OK',
      headers: {},
      config,
    });
  });

  afterEach(() => {
    setActiveConversationId(null);
    delete window.chatwootWebChannel;
  });

  it('names the active conversation on every request when multiple conversations are enabled', async () => {
    window.chatwootWebChannel = { enabledFeatures: ['multiple_conversations'] };
    setActiveConversationId(42);

    const { config } = await API.get('/api/v1/widget/messages', {
      params: { before: 7 },
    });

    expect(config.params).toEqual({ before: 7, conversation_id: 42 });
  });

  it('keeps the conversation a request already names', async () => {
    window.chatwootWebChannel = { enabledFeatures: ['multiple_conversations'] };
    setActiveConversationId(42);

    const { config } = await API.post(
      '/api/v1/widget/messages',
      {},
      { params: { conversation_id: 7 } }
    );

    expect(config.params).toEqual({ conversation_id: 7 });
  });

  it('leaves requests untouched when multiple conversations are disabled', async () => {
    setActiveConversationId(42);

    const { config } = await API.get('/api/v1/widget/messages', {
      params: { before: 7 },
    });

    expect(config.params).toEqual({ before: 7 });
  });

  it('leaves requests untouched when no conversation is active', async () => {
    window.chatwootWebChannel = { enabledFeatures: ['multiple_conversations'] };
    setActiveConversationId('');

    const { config } = await API.post('/api/v1/widget/messages', {});

    expect(config.params).toBe(undefined);
  });
});

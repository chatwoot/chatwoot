import agents from '../autonomia/agents';
import sources from '../autonomia/sources';
import channels from '../autonomia/channels';
import buildThreads from '../autonomia/buildThreads';
import ApiClient from '../ApiClient';

describe('Autonomia API clients', () => {
  const originalAxios = window.axios;
  const axiosMock = {
    get: vi.fn(() => Promise.resolve()),
    post: vi.fn(() => Promise.resolve()),
    patch: vi.fn(() => Promise.resolve()),
    delete: vi.fn(() => Promise.resolve()),
  };

  beforeEach(() => {
    window.history.pushState({}, '', '/app/accounts/85/agents');
    window.axios = axiosMock;
  });

  afterEach(() => {
    vi.clearAllMocks();
    window.axios = originalAxios;
  });

  describe('#AutonomiaAgentsAPI', () => {
    it('creates correct instance', () => {
      expect(agents).toBeInstanceOf(ApiClient);
      expect(agents).toHaveProperty('get');
      expect(agents).toHaveProperty('show');
      expect(agents).toHaveProperty('create');
      expect(agents).toHaveProperty('update');
      expect(agents).toHaveProperty('delete');
      expect(agents).toHaveProperty('test');
      expect(agents).toHaveProperty('suggest');
    });

    it('lists, shows, creates, updates and deletes agents with account scope', () => {
      agents.get();
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents'
      );

      agents.show(7);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7'
      );

      agents.create({ name: 'Suporte' });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents',
        { name: 'Suporte' }
      );

      agents.update(7, { name: 'Suporte 2' });
      expect(axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7',
        { name: 'Suporte 2' }
      );

      agents.delete(7);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7'
      );
    });

    it('posts test and suggest evaluations to the per-agent endpoints', () => {
      agents.test(7, { message: 'oi', history: [{ role: 'user' }] });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7/test',
        { message: 'oi', history: [{ role: 'user' }], images: [] }
      );

      agents.suggest(7, { message: 'oi', history: [] });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7/suggest',
        { message: 'oi', history: [] }
      );
    });
  });

  describe('#AutonomiaSourcesAPI', () => {
    it('lists, deletes and resyncs sources for an agent', () => {
      sources.get(7);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7/sources'
      );

      sources.delete(7, 3);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7/sources/3'
      );

      sources.resync(7, 3);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7/sources/3/resync'
      );
    });

    it('wraps a link source under the source key', () => {
      sources.create(7, { url: 'https://example.com' });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7/sources',
        {
          source: {
            source_type: 'link',
            reference: 'https://example.com',
            external_link: 'https://example.com',
          },
        }
      );
    });

    it('uploads a file source as multipart with inferred source_type', () => {
      const file = new File(['x'], 'manual.pdf', { type: 'application/pdf' });
      sources.create(7, { file });

      expect(axiosMock.post).toHaveBeenCalledTimes(1);
      const [endpoint, formData] = axiosMock.post.mock.calls[0];
      expect(endpoint).toBe('/api/v1/accounts/85/autonomia/agents/7/sources');
      expect(formData).toBeInstanceOf(FormData);
      expect(formData.get('source[source_type]')).toBe('pdf');
      expect(formData.get('source[reference]')).toBe('manual.pdf');
      expect(formData.get('file')).toBe(file);
    });
  });

  describe('#AutonomiaChannelsAPI', () => {
    it('lists, connects and disconnects inboxes for an agent', () => {
      channels.get(7);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7/channels'
      );

      channels.connect(7, 12);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7/channels',
        { inbox_id: 12 }
      );

      channels.disconnect(7, 12);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/agents/7/channels/12'
      );
    });
  });

  describe('#AutonomiaBuildThreadsAPI', () => {
    it('targets the top-level build_threads route and maps agentId to autonomia_agent_id', () => {
      buildThreads.create({ message: 'oi', agentId: 7 });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/build_threads',
        {
          message: 'oi',
          autonomia_agent_id: 7,
          client_message_id: expect.any(String),
        }
      );

      buildThreads.show(3);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/build_threads/3'
      );

      buildThreads.sendMessage(3, 'mais contexto');
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/85/autonomia/build_threads/3/messages',
        { message: 'mais contexto', client_message_id: expect.any(String) }
      );
    });

    it('reuses the turn client_message_id handed by the store instead of minting one per call', () => {
      buildThreads.sendMessage(3, 'mesma resposta', {}, 'turn-uuid-1');
      buildThreads.sendMessage(3, 'mesma resposta', {}, 'turn-uuid-1');

      expect(axiosMock.post).toHaveBeenCalledTimes(2);
      axiosMock.post.mock.calls.forEach(([, body]) => {
        expect(body.client_message_id).toBe('turn-uuid-1');
      });
    });
  });
});

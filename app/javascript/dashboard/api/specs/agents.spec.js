import agents from '../agents';
import ApiClient from '../ApiClient';

describe('#AgentAPI', () => {
  it('creates correct instance', () => {
    expect(agents).toBeInstanceOf(ApiClient);
    expect(agents).toHaveProperty('get');
    expect(agents).toHaveProperty('show');
    expect(agents).toHaveProperty('create');
    expect(agents).toHaveProperty('update');
    expect(agents).toHaveProperty('delete');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#bulkInvite', () => {
      agents.bulkInvite({ emails: ['hello@hi.com'] });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/agents/bulk_create',
        {
          emails: ['hello@hi.com'],
        }
      );
    });
  });
});

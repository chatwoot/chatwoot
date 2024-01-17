import csatTemplatesAPI from '../csatTemplates';
import ApiClient from '../ApiClient';

describe('#Templates API', () => {
  it('creates correct instance', () => {
    expect(csatTemplatesAPI).toBeInstanceOf(ApiClient);
    expect(csatTemplatesAPI.apiVersion).toBe('/api/v1');
    expect(csatTemplatesAPI).toHaveProperty('get');
    expect(csatTemplatesAPI).toHaveProperty('getTemplate');
    expect(csatTemplatesAPI).toHaveProperty('create');
    expect(csatTemplatesAPI).toHaveProperty('delete');
    expect(csatTemplatesAPI).toHaveProperty('getInboxes');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: jest.fn(() => Promise.resolve()),
      get: jest.fn(() => Promise.resolve()),
      patch: jest.fn(() => Promise.resolve()),
      delete: jest.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#get', () => {
      csatTemplatesAPI.get({ page: 1 });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/csat_templates', {
        params: {
          page: 1,
        },
      });
    });

    it('#getTemplate', () => {
      csatTemplatesAPI.getTemplate(1);
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/csat_templates/1');
    });

    it('#delete', () => {
      csatTemplatesAPI.delete(1);
      expect(axiosMock.delete).toHaveBeenCalledWith('/api/v1/csat_templates/1');
    });

    it('#create', () => {
      csatTemplatesAPI.create({
        inbox_ids: [1, 2],
        questions: [
          {
            id: null,
            content: 'test question',
          },
        ],
      });
      expect(axiosMock.post).toHaveBeenCalledWith('/api/v1/csat_templates', {
        inbox_ids: [1, 2],
        questions: [
          {
            id: null,
            content: 'test question',
          },
        ],
      });
    });
  });
});

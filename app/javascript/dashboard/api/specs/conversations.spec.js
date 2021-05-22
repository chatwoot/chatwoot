import conversationsAPI from '../conversations';
import ApiClient from '../ApiClient';

describe('#ConversationApi', () => {
  it('creates correct instance', () => {
    expect(conversationsAPI).toBeInstanceOf(ApiClient);
    expect(conversationsAPI).toHaveProperty('get');
    expect(conversationsAPI).toHaveProperty('show');
    expect(conversationsAPI).toHaveProperty('create');
    expect(conversationsAPI).toHaveProperty('update');
    expect(conversationsAPI).toHaveProperty('delete');
    expect(conversationsAPI).toHaveProperty('getLabels');
    expect(conversationsAPI).toHaveProperty('updateLabels');
  });

  describe('API calls', () => {
    let originalAxios = null;
    let axiosMock = null;
    beforeEach(() => {
      originalAxios = window.axios;
      axiosMock = {
        post: jest.fn(() => Promise.resolve()),
        get: jest.fn(() => Promise.resolve()),
      };
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#getLabels', () => {
      conversationsAPI.getLabels(1);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/conversations/1/labels'
      );
    });

    it('#updateLabels', () => {
      const labels = ['support-query'];
      conversationsAPI.updateLabels(1, labels);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/conversations/1/labels',
        {
          labels,
        }
      );
    });
  });
});

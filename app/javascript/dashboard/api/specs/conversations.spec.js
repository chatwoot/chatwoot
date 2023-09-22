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

  describe('API calls', context => {
    it('#getLabels', () => {
      conversationsAPI.getLabels(1);
      expect(axios.get).toHaveBeenCalledWith('/api/v1/conversations/1/labels');
    });

    it('#updateLabels', () => {
      const labels = ['support-query'];
      conversationsAPI.updateLabels(1, labels);
      expect(axios.post).toHaveBeenCalledWith(
        '/api/v1/conversations/1/labels',
        {
          labels,
        }
      );
    });
  });
});

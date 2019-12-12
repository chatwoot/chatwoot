import { actions } from '../../conversation';
import getUuid from '../../../../helpers/uuid';

jest.mock('../../../../helpers/uuid');

const commit = jest.fn();

describe('#actions', () => {
  describe('#addMessage', () => {
    it('sends correct mutations', () => {
      actions.addMessage({ commit }, { id: 1 });
      expect(commit).toBeCalledWith('pushMessageToConversation', { id: 1 });
    });
  });

  describe('#sendMessage', () => {
    it('sends correct mutations', () => {
      const mockDate = new Date(1466424490000);
      getUuid.mockImplementationOnce(() => '1111');
      const spy = jest.spyOn(global, 'Date').mockImplementation(() => mockDate);
      actions.sendMessage({ commit }, { content: 'hello' });
      spy.mockRestore();
      expect(commit).toBeCalledWith('pushMessageToConversation', {
        id: '1111',
        content: 'hello',
        status: 'in_progress',
        created_at: 1466424490000,
        message_type: 0,
      });
    });
  });
});

import { API } from 'widget/helpers/axios';
import { actions } from '../../agent';
import { agents } from './data';

const commit = jest.fn();
jest.mock('widget/helpers/axios');

describe('#actions', () => {
  describe('#fetchAvailableAgents', () => {
    it('sends correct actions if API is success', async () => {
      API.get.mockResolvedValue({ data: { payload: agents } });
      await actions.fetchAvailableAgents({ commit }, 'Hi');
      expect(commit.mock.calls).toEqual([
        ['setAgents', agents],
        ['setError', false],
        ['setHasFetched', true],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      API.get.mockRejectedValue({ message: 'Authentication required' });
      await actions.fetchAvailableAgents({ commit }, 'Hi');
      expect(commit.mock.calls).toEqual([
        ['setError', true],
        ['setHasFetched', true],
      ]);
    });
  });

  describe('#updatePresence', () => {
    actions.updatePresence({ commit }, { 1: 'online' });
    expect(commit.mock.calls).toEqual([['updatePresence', { 1: 'online' }]]);
  });
});

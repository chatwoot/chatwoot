import axios from 'axios';
import { actions } from '../../agentBots';
import types from '../../../mutation-types';
import { agentBotRecords } from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: agentBotRecords });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isFetching: true }],
        [types.SET_AGENT_BOTS, agentBotRecords],
        [types.SET_AGENT_BOT_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isFetching: true }],
        [types.SET_AGENT_BOT_UI_FLAG, { isFetching: false }],
      ]);
    });
  });
  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: agentBotRecords[0] });
      await actions.create({ commit }, agentBotRecords[0]);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isCreating: true }],
        [types.ADD_AGENT_BOT, agentBotRecords[0]],
        [types.SET_AGENT_BOT_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isCreating: true }],
        [types.SET_AGENT_BOT_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: agentBotRecords[0] });
      await actions.update({ commit }, agentBotRecords[0]);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isUpdating: true }],
        [types.EDIT_AGENT_BOT, agentBotRecords[0]],
        [types.SET_AGENT_BOT_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.update({ commit }, agentBotRecords[0])
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isUpdating: true }],
        [types.SET_AGENT_BOT_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: agentBotRecords[0] });
      await actions.delete({ commit }, agentBotRecords[0].id);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isDeleting: true }],
        [types.DELETE_AGENT_BOT, agentBotRecords[0].id],
        [types.SET_AGENT_BOT_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete({ commit }, agentBotRecords[0].id)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isDeleting: true }],
        [types.SET_AGENT_BOT_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});

import axios from 'axios';
import { actions } from '../../agentBots';
import types from '../../../mutation-types';
import { agentBotRecords } from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

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
  describe('#setAgentBotInbox', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: {} });
      await actions.setAgentBotInbox({ commit }, { inboxId: 2, botId: 3 });
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isSettingAgentBot: true }],
        [types.SET_AGENT_BOT_INBOX, { inboxId: 2, agentBotId: 3 }],
        [types.SET_AGENT_BOT_UI_FLAG, { isSettingAgentBot: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.setAgentBotInbox({ commit }, { inboxId: 2, botId: 3 })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isSettingAgentBot: true }],
        [types.SET_AGENT_BOT_UI_FLAG, { isSettingAgentBot: false }],
      ]);
    });
  });
  describe('#fetchAgentBotInbox', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { agent_bot: { id: 3 } } });
      await actions.fetchAgentBotInbox({ commit }, 2);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isFetchingAgentBot: true }],
        [types.SET_AGENT_BOT_INBOX, { inboxId: 2, agentBotId: 3 }],
        [types.SET_AGENT_BOT_UI_FLAG, { isFetchingAgentBot: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.fetchAgentBotInbox({ commit }, { inboxId: 2, agentBotId: 3 })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isFetchingAgentBot: true }],
        [types.SET_AGENT_BOT_UI_FLAG, { isFetchingAgentBot: false }],
      ]);
    });
  });
  describe('#disconnectBot', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: {} });
      await actions.disconnectBot({ commit }, { inboxId: 2 });
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isDisconnecting: true }],
        [types.SET_AGENT_BOT_INBOX, { inboxId: 2, agentBotId: '' }],
        [types.SET_AGENT_BOT_UI_FLAG, { isDisconnecting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.disconnectBot({ commit }, { inboxId: 2, agentBotId: '' })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_AGENT_BOT_UI_FLAG, { isDisconnecting: true }],
        [types.SET_AGENT_BOT_UI_FLAG, { isDisconnecting: false }],
      ]);
    });
  });
});

import axios from 'axios';
import { actions } from '../../teams/actions';
import {
  SET_TEAM_UI_FLAG,
  CLEAR_TEAMS,
  SET_TEAMS,
  SET_TEAM_ITEM,
  EDIT_TEAM,
  DELETE_TEAM,
} from '../../teams/types';
import teamsList from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      const mockedGet = vi.fn(url => {
        if (url === '/api/v1/teams') {
          return Promise.resolve({ data: teamsList[1] });
        }
        if (url === '/api/v1/accounts//cache_keys') {
          return Promise.resolve({ data: { cache_keys: { teams: 0 } } });
        }
        // Return default value or throw an error for unexpected requests
        return Promise.reject(new Error('Unexpected request: ' + url));
      });

      axios.get = mockedGet;

      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [SET_TEAM_UI_FLAG, { isFetching: true }],
        [CLEAR_TEAMS],
        [SET_TEAMS, teamsList[1]],
        [SET_TEAM_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.get({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [SET_TEAM_UI_FLAG, { isFetching: true }],
        [SET_TEAM_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: teamsList[1] });
      await actions.create({ commit }, teamsList[1]);

      expect(commit.mock.calls).toEqual([
        [SET_TEAM_UI_FLAG, { isCreating: true }],
        [SET_TEAM_ITEM, teamsList[1]],
        [SET_TEAM_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit })).rejects.toThrow(Error);

      expect(commit.mock.calls).toEqual([
        [SET_TEAM_UI_FLAG, { isCreating: true }],
        [SET_TEAM_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct actions if API is success', async () => {
      axios.patch.mockResolvedValue({ data: teamsList[1] });
      await actions.update({ commit }, teamsList[1]);

      expect(commit.mock.calls).toEqual([
        [SET_TEAM_UI_FLAG, { isUpdating: true }],
        [EDIT_TEAM, teamsList[1]],
        [SET_TEAM_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.update({ commit }, teamsList[1])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [SET_TEAM_UI_FLAG, { isUpdating: true }],
        [SET_TEAM_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue();
      await actions.delete({ commit }, 1);
      expect(commit.mock.calls).toEqual([
        [SET_TEAM_UI_FLAG, { isDeleting: true }],
        [DELETE_TEAM, 1],
        [SET_TEAM_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.delete({ commit }, 1)).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [SET_TEAM_UI_FLAG, { isDeleting: true }],
        [SET_TEAM_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});

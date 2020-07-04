import axios from 'axios';
import { actions } from '../../contacts';
import * as types from '../../../mutation-types';
import contactList from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct mutations if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: contactList } });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_UI_FLAG, { isFetching: true }],
        [types.default.SET_CONTACTS, contactList],
        [types.default.SET_CONTACT_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct mutations if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_UI_FLAG, { isFetching: true }],
        [types.default.SET_CONTACT_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#show', () => {
    it('sends correct mutations if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: contactList[0] } });
      await actions.show({ commit }, { id: contactList[0].id });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_UI_FLAG, { isFetchingItem: true }],
        [types.default.SET_CONTACT_ITEM, contactList[0]],
        [types.default.SET_CONTACT_UI_FLAG, { isFetchingItem: false }],
      ]);
    });
    it('sends correct mutations if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.show({ commit }, { id: contactList[0].id });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_UI_FLAG, { isFetchingItem: true }],
        [types.default.SET_CONTACT_UI_FLAG, { isFetchingItem: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct mutations if API is success', async () => {
      axios.patch.mockResolvedValue({ data: { payload: contactList[0] } });
      await actions.update({ commit }, contactList[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_UI_FLAG, { isUpdating: true }],
        [types.default.EDIT_CONTACT, contactList[0]],
        [types.default.SET_CONTACT_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.update({ commit }, contactList[0])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_UI_FLAG, { isUpdating: true }],
        [types.default.SET_CONTACT_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#setContact', () => {
    it('returns correct mutations', () => {
      const data = { id: 1, name: 'john doe', availability_status: 'online' };
      actions.setContact({ commit }, data);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_ITEM, data],
      ]);
    });
  });
});

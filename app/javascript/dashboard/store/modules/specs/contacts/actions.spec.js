import axios from 'axios';
import Contacts from '../../contacts';
import types from '../../../mutation-types';
import contactList from './fixtures';
import {
  DuplicateContactException,
  ExceptionWithMessage,
} from '../../../../../shared/helpers/CustomErrors';

const { actions } = Contacts;

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct mutations if API is success', async () => {
      axios.get.mockResolvedValue({
        data: { payload: contactList, meta: { count: 100, current_page: 1 } },
      });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isFetching: true }],
        [types.CLEAR_CONTACTS],
        [types.SET_CONTACTS, contactList],
        [types.SET_CONTACT_META, { count: 100, current_page: 1 }],
        [types.SET_CONTACT_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct mutations if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isFetching: true }],
        [types.SET_CONTACT_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#show', () => {
    it('sends correct mutations if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: contactList[0] } });
      await actions.show({ commit }, { id: contactList[0].id });
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isFetchingItem: true }],
        [types.SET_CONTACT_ITEM, contactList[0]],
        [types.SET_CONTACT_UI_FLAG, { isFetchingItem: false }],
      ]);
    });
    it('sends correct mutations if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.show({ commit }, { id: contactList[0].id });
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isFetchingItem: true }],
        [types.SET_CONTACT_UI_FLAG, { isFetchingItem: false }],
      ]);
    });
  });

  describe('#update', () => {
    it('sends correct mutations if API is success', async () => {
      axios.patch.mockResolvedValue({ data: { payload: contactList[0] } });
      await actions.update({ commit }, contactList[0]);
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isUpdating: true }],
        [types.EDIT_CONTACT, contactList[0]],
        [types.SET_CONTACT_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.patch.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.update({ commit }, contactList[0])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isUpdating: true }],
        [types.SET_CONTACT_UI_FLAG, { isUpdating: false }],
      ]);
    });

    it('sends correct actions if duplicate contact is found', async () => {
      axios.patch.mockRejectedValue({
        response: {
          data: {
            message: 'Incorrect header',
            contact: { id: 1, name: 'contact-name' },
          },
        },
      });
      await expect(actions.update({ commit }, contactList[0])).rejects.toThrow(
        DuplicateContactException
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isUpdating: true }],
        [types.SET_CONTACT_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct mutations if API is success', async () => {
      axios.post.mockResolvedValue({
        data: { payload: { contact: contactList[0] } },
      });
      await actions.create({ commit }, contactList[0]);
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isCreating: true }],
        [types.SET_CONTACT_ITEM, contactList[0]],
        [types.SET_CONTACT_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit }, contactList[0])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isCreating: true }],
        [types.SET_CONTACT_UI_FLAG, { isCreating: false }],
      ]);
    });

    it('sends correct actions if email is already present', async () => {
      axios.post.mockRejectedValue({
        response: {
          data: {
            message: 'Email exists already',
          },
        },
      });
      await expect(actions.create({ commit }, contactList[0])).rejects.toThrow(
        ExceptionWithMessage
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isCreating: true }],
        [types.SET_CONTACT_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct mutations if API is success', async () => {
      axios.delete.mockResolvedValue();
      await actions.delete({ commit }, contactList[0].id);
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isDeleting: true }],
        [types.SET_CONTACT_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete({ commit }, contactList[0].id)
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isDeleting: true }],
        [types.SET_CONTACT_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('#setContact', () => {
    it('returns correct mutations', () => {
      const data = { id: 1, name: 'john doe', availability_status: 'online' };
      actions.setContact({ commit }, data);
      expect(commit.mock.calls).toEqual([[types.SET_CONTACT_ITEM, data]]);
    });
  });

  describe('#merge', () => {
    it('sends correct mutations if API is success', async () => {
      axios.post.mockResolvedValue({
        data: contactList[0],
      });
      await actions.merge({ commit }, { childId: 0, parentId: 1 });
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isMerging: true }],
        [types.SET_CONTACT_ITEM, contactList[0]],
        [types.SET_CONTACT_UI_FLAG, { isMerging: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.merge({ commit }, { childId: 0, parentId: 1 })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.SET_CONTACT_UI_FLAG, { isMerging: true }],
        [types.SET_CONTACT_UI_FLAG, { isMerging: false }],
      ]);
    });
  });

  describe('#deleteContactThroughConversations', () => {
    it('returns correct mutations', () => {
      actions.deleteContactThroughConversations({ commit }, contactList[0].id);
      expect(commit.mock.calls).toEqual([
        [types.DELETE_CONTACT, contactList[0].id],
        [types.CLEAR_CONTACT_CONVERSATIONS, contactList[0].id, { root: true }],
        [
          `contactConversations/${types.DELETE_CONTACT_CONVERSATION}`,
          contactList[0].id,
          { root: true },
        ],
      ]);
    });
  });
});

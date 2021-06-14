import axios from 'axios';
import { actions } from '../../contactNotes';
import * as types from '../../../mutation-types';
import notesData from './fixtures';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: notesData });
      await actions.get({ commit }, { contactId: 23 });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isFetching: true }],
        [types.default.SET_CONTACT_NOTES, { contactId: 23, data: notesData }],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.get({ commit }, { contactId: 23 })).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isFetching: true }],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isFetching: false }],
      ]);
    });
  });
  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: { id: 2, content: 'hi' } });
      await actions.create({ commit }, { contactId: 1, content: 'hi' });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isCreating: true }],
        [
          types.default.ADD_CONTACT_NOTE,
          { contactId: 1, data: { id: 2, content: 'hi' } },
        ],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.create({ commit }, { contactId: 1, content: 'hi' })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isCreating: true }],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: notesData[0] });
      await actions.delete({ commit }, { contactId: 1, noteId: 2 });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_CONTACT_NOTE, { contactId: 1, noteId: 2 }],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.delete({ commit }, { contactId: 1, noteId: 2 })
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isDeleting: true }],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});

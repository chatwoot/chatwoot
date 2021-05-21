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
      await actions.get({ commit }, { inboxId: 23 });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isFetching: true }],
        [types.default.SET_CONTACT_NOTES, notesData],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit }, { inboxId: 23 });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isFetching: true }],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isFetching: false }],
      ]);
    });
  });
  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: notesData[0] });
      await actions.create({ commit }, notesData[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isCreating: true }],
        [types.default.ADD_CONTACT_NOTES, notesData[0]],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isCreating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.create({ commit })).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isCreating: true }],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({ data: notesData[0] });
      await actions.update({ commit }, notesData[0]);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_CONTACT_NOTES, notesData[0]],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.update({ commit }, notesData[0])).rejects.toThrow(
        Error
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isDeleting: true }],
        [types.default.SET_CONTACT_NOTES_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });
});

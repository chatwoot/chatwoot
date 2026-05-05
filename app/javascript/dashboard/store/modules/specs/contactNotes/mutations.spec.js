import types from '../../../mutation-types';
import { mutations } from '../../contactNotes';
import allNotes from './fixtures';

describe('#mutations', () => {
  describe('#SET_CONTACT_NOTES', () => {
    it('set allNotes records', () => {
      const state = { records: {} };
      mutations[types.SET_CONTACT_NOTES](state, {
        data: allNotes,
        contactId: 1,
      });
      expect(state.records).toEqual({ 1: allNotes });
    });
  });

  describe('#ADD_CONTACT_NOTE', () => {
    it('push newly created note to the store', () => {
      const state = { records: { 1: [allNotes[0]] } };
      mutations[types.ADD_CONTACT_NOTE](state, {
        data: allNotes[1],
        contactId: 1,
      });
      expect(state.records[1]).toEqual([allNotes[0], allNotes[1]]);
    });
  });
  describe('#EDIT_CONTACT_NOTE', () => {
    it('replaces edited note in records', () => {
      const editedNote = {
        ...allNotes[1],
        content: 'Updated note content',
      };
      const state = { records: { 1: [allNotes[0], allNotes[1]] } };
      mutations[types.EDIT_CONTACT_NOTE](state, {
        data: editedNote,
        contactId: 1,
      });
      expect(state.records[1]).toEqual([allNotes[0], editedNote]);
    });

    it('handles missing contact records', () => {
      const state = { records: {} };
      mutations[types.EDIT_CONTACT_NOTE](state, {
        data: { id: 1, content: 'Updated note content' },
        contactId: 1,
      });
      expect(state.records[1]).toEqual([]);
    });
  });
  describe('#DELETE_CONTACT_NOTE', () => {
    it('Delete existing note from records', () => {
      const state = { records: { 1: [{ id: 2 }] } };
      mutations[types.DELETE_CONTACT_NOTE](state, {
        noteId: 2,
        contactId: 1,
      });
      expect(state.records[1]).toEqual([]);
    });
  });
});

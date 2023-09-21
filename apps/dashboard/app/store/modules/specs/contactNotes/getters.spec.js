import { getters } from '../../contactNotes';
import notesData from './fixtures';

describe('#getters', () => {
  it('getAllNotesByContact', () => {
    const state = { records: { 1: notesData } };
    expect(getters.getAllNotesByContact(state)(1)).toEqual(notesData);
  });

  it('getUIFlags', () => {
    const state = {
      uiFlags: {
        isFetching: true,
        isCreating: false,
        isDeleting: false,
      },
    };
    expect(getters.getUIFlags(state)).toEqual({
      isFetching: true,
      isCreating: false,
      isDeleting: false,
    });
  });
});

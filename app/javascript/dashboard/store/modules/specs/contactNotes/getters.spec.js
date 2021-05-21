import { getters } from '../../contactNotes';
import notesData from './fixtures';

describe('#getters', () => {
  it('getAllNotes', () => {
    const state = { records: notesData };
    expect(getters.getAllNotes(state)).toEqual(notesData);
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

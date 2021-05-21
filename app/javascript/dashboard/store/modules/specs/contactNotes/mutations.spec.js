import types from '../../../mutation-types';
import { mutations } from '../../contactNotes';
import allNotes from './fixtures';

describe('#mutations', () => {
  describe('#SET_CAMPAIGNS', () => {
    it('set allNotes records', () => {
      const state = { records: [] };
      mutations[types.SET_CAMPAIGNS](state, allNotes);
      expect(state.records).toEqual(allNotes);
    });
  });

  describe('#ADD_CAMPAIGN', () => {
    it('push newly created allNotes to the store', () => {
      const state = { records: [allNotes[0]] };
      mutations[types.ADD_CAMPAIGN](state, allNotes[1]);
      expect(state.records).toEqual([allNotes[0], allNotes[1]]);
    });
  });
  describe('#EDIT_CAMPAIGN', () => {
    it('update campaign record', () => {
      const state = { records: [allNotes[0]] };
      mutations[types.EDIT_CAMPAIGN](state, {
        id: 12347,
        content: 'wow',
        user: {
          name: 'John Doe',
          thumbnail: 'https://randomuser.me/api/portraits/men/69.jpg',
        },
        created_at: 1618046084,
      });
      expect(state.records[0].content).toEqual('wow');
    });
  });
});

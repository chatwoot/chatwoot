import types from '../../../mutation-types';
import { mutations } from '../../macros';
import macros from './fixtures';
describe('#mutations', () => {
  describe('#SET_MACROS', () => {
    it('set macrtos records', () => {
      const state = { records: [] };
      mutations[types.SET_MACROS](state, macros);
      expect(state.records).toEqual(macros);
    });
  });

  describe('#ADD_MACRO', () => {
    it('push newly created macro to the store', () => {
      const state = { records: [macros[0]] };
      mutations[types.ADD_MACRO](state, macros[1]);
      expect(state.records).toEqual([macros[0], macros[1]]);
    });
  });

  describe('#EDIT_MACRO', () => {
    it('update macro record', () => {
      const state = { records: [macros[0]] };
      mutations[types.EDIT_MACRO](state, macros[0]);
      expect(state.records[0].name).toEqual(
        'Assign billing label and sales team and message user'
      );
    });
  });

  describe('#DELETE_MACRO', () => {
    it('delete macro record', () => {
      const state = { records: [macros[0]] };
      mutations[types.DELETE_MACRO](state, 22);
      expect(state.records).toEqual([]);
    });
  });
});

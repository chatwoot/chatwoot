import types from '../../../mutation-types';
import { mutations } from '../../automations';
import automations from './fixtures';
describe('#mutations', () => {
  describe('#SET_automations', () => {
    it('set autonmation records', () => {
      const state = { records: [] };
      mutations[types.SET_AUTOMATIONS](state, automations);
      expect(state.records).toEqual(automations);
    });
  });

  describe('#ADD_AUTOMATION', () => {
    it('push newly created automatuion to the store', () => {
      const state = { records: [automations[0]] };
      mutations[types.ADD_AUTOMATION](state, automations[1]);
      expect(state.records).toEqual([automations[0], automations[1]]);
    });
  });

  describe('#EDIT_AUTOMATION', () => {
    it('update automation record', () => {
      const state = { records: [automations[0]] };
      mutations[types.EDIT_AUTOMATION](state, automations[0]);
      expect(state.records[0].name).toEqual('Test 5');
    });
  });

  describe('#DELETE_AUTOMATION', () => {
    it('delete automation record', () => {
      const state = { records: [automations[0]] };
      mutations[types.DELETE_AUTOMATION](state, 46);
      expect(state.records).toEqual([]);
    });
  });
});

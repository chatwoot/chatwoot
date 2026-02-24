import types from '../../../mutation-types';
import { mutations } from '../../labels';
import labels from './fixtures';
describe('#mutations', () => {
  describe('#SET_LABELS', () => {
    it('set label records', () => {
      const state = { records: [] };
      mutations[types.SET_LABELS](state, labels);
      expect(state.records).toEqual(labels);
    });
  });

  describe('#ADD_LABEL', () => {
    it('push newly created label to the store', () => {
      const state = { records: [labels[0]] };
      mutations[types.ADD_LABEL](state, labels[1]);
      expect(state.records).toEqual([labels[0], labels[1]]);
    });
  });

  describe('#EDIT_LABEL', () => {
    it('update label record', () => {
      const state = { records: [labels[0]] };
      mutations[types.EDIT_LABEL](state, {
        id: 1,
        title: 'customer-support-queries',
      });
      expect(state.records[0].title).toEqual('customer-support-queries');
    });
  });

  describe('#DELETE_LABEL', () => {
    it('delete label record', () => {
      const state = { records: [labels[0]] };
      mutations[types.DELETE_LABEL](state, 1);
      expect(state.records).toEqual([]);
    });
  });
});

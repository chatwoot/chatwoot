import types from '../../../mutation-types';
import { mutations } from '../../attributes';
import attributesList from './fixtures';

describe('#mutations', () => {
  describe('#SET_CUSTOM_ATTRIBUTES', () => {
    it('set attribute records', () => {
      const state = { records: [] };
      mutations[types.SET_CUSTOM_ATTRIBUTES](state, attributesList);
      expect(state.records).toEqual(attributesList);
    });
  });

  describe('#ADD_CUSTOM_ATTRIBUTES', () => {
    it('push newly created attributes to the store', () => {
      const state = { records: [attributesList[0]] };
      mutations[types.ADD_CUSTOM_ATTRIBUTES](state, attributesList[1]);
      expect(state.records).toEqual([attributesList[0], attributesList[1]]);
    });
  });
  describe('#EDIT_CUSTOM_ATTRIBUTES', () => {
    it('update attribute record', () => {
      const state = { records: [attributesList[0]] };
      mutations[types.EDIT_CUSTOM_ATTRIBUTES](state, {
        attribute_display_name: 'Language',
        attribute_display_type: 0,
        attribute_description: 'The conversation language',
        attribute_key: 'language',
        attribute_model: 0,
      });
      expect(state.records[0].attribute_description).toEqual(
        'The conversation language'
      );
    });
  });

  describe('#DELETE_CUSTOM_ATTRIBUTES', () => {
    it('delete attribute record', () => {
      const state = { records: [attributesList[0]] };
      mutations[types.DELETE_CUSTOM_ATTRIBUTES](state, attributesList[0]);
      expect(state.records).toEqual([attributesList[0]]);
    });
  });
});

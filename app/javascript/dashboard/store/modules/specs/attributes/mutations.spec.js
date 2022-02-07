import types from '../../../mutation-types';
import { mutations } from '../../attributes';
import attributesList from './fixtures';

describe('#mutations', () => {
  describe('#SET_CUSTOM_ATTRIBUTE', () => {
    it('set attribute records', () => {
      const state = { records: [] };
      mutations[types.SET_CUSTOM_ATTRIBUTE](state, attributesList);
      expect(state.records).toEqual(attributesList);
    });
  });

  describe('#ADD_CUSTOM_ATTRIBUTE', () => {
    it('push newly created attributes to the store', () => {
      const state = { records: [attributesList[0]] };
      mutations[types.ADD_CUSTOM_ATTRIBUTE](state, attributesList[1]);
      expect(state.records).toEqual([attributesList[0], attributesList[1]]);
    });
  });
  describe('#EDIT_CUSTOM_ATTRIBUTE', () => {
    it('update attribute record', () => {
      const state = { records: [attributesList[0]] };
      mutations[types.EDIT_CUSTOM_ATTRIBUTE](state, {
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

  describe('#DELETE_CUSTOM_ATTRIBUTE', () => {
    it('delete attribute record', () => {
      const state = { records: [attributesList[0]] };
      mutations[types.DELETE_CUSTOM_ATTRIBUTE](state, attributesList[0]);
      expect(state.records).toEqual([attributesList[0]]);
    });
  });
});

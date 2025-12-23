import * as types from '../../../mutation-types';
import { mutations } from '../../messageTemplates';
import { templates, builderConfig } from './fixtures';

describe('#mutations', () => {
  describe('#SET_MESSAGE_TEMPLATE_UI_FLAG', () => {
    it('sets ui flags correctly', () => {
      const state = { uiFlags: { isFetching: false, isCreating: false } };
      mutations[types.default.SET_MESSAGE_TEMPLATE_UI_FLAG](state, {
        isFetching: true,
        isCreating: true,
      });
      expect(state.uiFlags).toEqual({
        isFetching: true,
        isCreating: true,
      });
    });

    it('updates specific flags without affecting others', () => {
      const state = {
        uiFlags: {
          isFetching: false,
          isCreating: false,
          isUpdating: false,
          isDeleting: false,
        },
      };
      mutations[types.default.SET_MESSAGE_TEMPLATE_UI_FLAG](state, {
        isDeleting: true,
      });
      expect(state.uiFlags).toEqual({
        isFetching: false,
        isCreating: false,
        isUpdating: false,
        isDeleting: true,
      });
    });
  });

  describe('#SET_MESSAGE_TEMPLATES', () => {
    it('sets templates array', () => {
      const state = { records: [] };
      mutations[types.default.SET_MESSAGE_TEMPLATES](state, templates);
      expect(state.records).toEqual(templates);
    });

    it('replaces existing templates', () => {
      const state = { records: [{ id: 999 }] };
      mutations[types.default.SET_MESSAGE_TEMPLATES](state, templates);
      expect(state.records).toEqual(templates);
    });
  });

  describe('#ADD_MESSAGE_TEMPLATE', () => {
    it('adds new template to records', () => {
      const state = { records: [] };
      const newTemplate = templates[0];
      mutations[types.default.ADD_MESSAGE_TEMPLATE](state, newTemplate);
      expect(state.records).toEqual([newTemplate]);
    });

    it('adds template to existing records', () => {
      const state = { records: [templates[0]] };
      const newTemplate = templates[1];
      mutations[types.default.ADD_MESSAGE_TEMPLATE](state, newTemplate);
      expect(state.records).toEqual([templates[0], newTemplate]);
    });
  });

  describe('#DELETE_MESSAGE_TEMPLATE', () => {
    it('removes template from records', () => {
      const state = { records: [templates[0], templates[1], templates[2]] };
      mutations[types.default.DELETE_MESSAGE_TEMPLATE](state, 2);
      expect(state.records).toEqual([templates[0], templates[2]]);
    });

    it('does nothing if template not found', () => {
      const state = { records: [templates[0]] };
      mutations[types.default.DELETE_MESSAGE_TEMPLATE](state, 999);
      expect(state.records).toEqual([templates[0]]);
    });

    it('handles empty records', () => {
      const state = { records: [] };
      mutations[types.default.DELETE_MESSAGE_TEMPLATE](state, 1);
      expect(state.records).toEqual([]);
    });
  });

  describe('#SET_TEMPLATE_BUILDER_CONFIG', () => {
    it('updates builder config', () => {
      const state = { builderConfig: {} };
      mutations[types.default.SET_TEMPLATE_BUILDER_CONFIG](
        state,
        builderConfig
      );
      expect(state.builderConfig).toEqual(builderConfig);
    });

    it('merges config with existing values', () => {
      const state = { builderConfig: { name: 'Old', language: 'en' } };
      const newConfig = { name: 'New', category: 'UTILITY' };
      mutations[types.default.SET_TEMPLATE_BUILDER_CONFIG](state, newConfig);
      expect(state.builderConfig).toEqual({
        name: 'New',
        language: 'en',
        category: 'UTILITY',
      });
    });
  });

  describe('#RESET_TEMPLATE_BUILDER', () => {
    it('resets to default config', () => {
      const state = {
        builderConfig: { name: 'Test', language: 'es', templateId: 123 },
      };
      mutations[types.default.RESET_TEMPLATE_BUILDER](state);
      expect(state.builderConfig).toEqual({
        name: '',
        language: 'en',
        channelType: 'Channel::Whatsapp',
        inboxId: null,
        category: 'utility',
        templateId: null,
      });
    });
  });
});

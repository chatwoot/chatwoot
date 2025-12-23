import axios from 'axios';
import * as types from '../../../mutation-types';
import { actions } from '../../messageTemplates';
import {
  createTemplatePayload,
  createTemplateResponse,
  templateResponse,
  templates,
  templatesResponse,
} from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue(templatesResponse);
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isFetching: true }],
        [types.default.SET_MESSAGE_TEMPLATES, templates],
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue(new Error('Network Error'));
      try {
        await actions.get({ commit });
      } catch (error) {
        // Expected to throw
      }
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isFetching: true }],
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isFetching: false }],
      ]);
    });

    it('sends correct actions with filters', async () => {
      const filters = { inbox_id: 1, status: 'approved' };
      axios.get.mockResolvedValue(templatesResponse);
      await actions.get({ commit }, filters);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isFetching: true }],
        [types.default.SET_MESSAGE_TEMPLATES, templates],
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#create', () => {
    it('creates template successfully', async () => {
      axios.post.mockResolvedValue(createTemplateResponse);
      const result = await actions.create({ commit }, createTemplatePayload);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isCreating: true }],
        [types.default.ADD_MESSAGE_TEMPLATE, createTemplateResponse.data],
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isCreating: false }],
      ]);
      expect(result).toEqual(createTemplateResponse.data);
    });

    it('handles creation errors', async () => {
      axios.post.mockRejectedValue({ message: 'Creation failed' });
      await expect(
        actions.create({ commit }, createTemplatePayload)
      ).rejects.toThrow();
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isCreating: true }],
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isCreating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('deletes template successfully', async () => {
      axios.delete.mockResolvedValue();
      await actions.delete({ commit }, 1);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isDeleting: true }],
        [types.default.DELETE_MESSAGE_TEMPLATE, 1],
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isDeleting: false }],
      ]);
    });

    it('handles deletion errors', async () => {
      axios.delete.mockRejectedValue({ message: 'Deletion failed' });
      await expect(actions.delete({ commit }, 1)).rejects.toThrow();
      expect(commit.mock.calls).toEqual([
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isDeleting: true }],
        [types.default.SET_MESSAGE_TEMPLATE_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('#show', () => {
    it('fetches single template', async () => {
      axios.get.mockResolvedValue(templateResponse);
      const result = await actions.show({ commit }, 1);
      expect(result).toEqual(templates[0]);
      expect(commit).not.toHaveBeenCalled();
    });

    it('handles show errors', async () => {
      axios.get.mockRejectedValue({ message: 'Template not found' });
      await expect(actions.show({ commit }, 1)).rejects.toThrow();
    });
  });

  describe('#setBuilderConfig', () => {
    it('updates builder configuration', () => {
      const config = { name: 'New Template', language: 'es' };
      actions.setBuilderConfig({ commit }, config);
      expect(commit).toHaveBeenCalledWith(
        types.default.SET_TEMPLATE_BUILDER_CONFIG,
        config
      );
    });
  });

  describe('#resetBuilderConfig', () => {
    it('resets builder to default state', () => {
      actions.resetBuilderConfig({ commit });
      expect(commit).toHaveBeenCalledWith(types.default.RESET_TEMPLATE_BUILDER);
    });
  });
});

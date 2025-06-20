import { describe, it, expect, vi, beforeEach } from 'vitest';
import { actions, mutations, getters } from '../prompts';
import PromptAPI from '../../../api/prompts';

// Mock the PromptAPI
vi.mock('../../../api/prompts', () => ({
  default: {
    get: vi.fn(),
    update: vi.fn(),
  },
}));

describe('prompts store module', () => {
  describe('getters', () => {
    const state = {
      records: [
        { id: 1, prompt_key: 'greeting', text: 'Hello there!' },
        { id: 2, prompt_key: 'closing', text: 'Thank you!' },
      ],
      uiFlags: {
        isFetching: false,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
      },
    };

    it('getPrompts should return all prompts from state.records', () => {
      const result = getters.getPrompts(state);
      expect(result).toEqual(state.records);
      expect(result).toHaveLength(2);
    });

    it('getUIFlags should return uiFlags from state', () => {
      const result = getters.getUIFlags(state);
      expect(result).toEqual(state.uiFlags);
      expect(result.isFetching).toBe(false);
    });

    it('getPromptById should return the correct prompt by id', () => {
      const getPromptById = getters.getPromptById(state);
      
      const prompt1 = getPromptById(1);
      expect(prompt1).toEqual(state.records[0]);
      
      const prompt2 = getPromptById('2'); // Test string conversion
      expect(prompt2).toEqual(state.records[1]);
      
      const nonExistent = getPromptById(999);
      expect(nonExistent).toBeUndefined();
    });
  });

  describe('mutations', () => {
    let state;

    beforeEach(() => {
      state = {
        records: [],
        uiFlags: {
          isFetching: false,
          isCreating: false,
          isUpdating: false,
          isDeleting: false,
        },
      };
    });

    it('SET_PROMPTS should update state.records with provided data', () => {
      const mockPrompts = [
        { id: 1, prompt_key: 'greeting', text: 'Hello!' },
        { id: 2, prompt_key: 'closing', text: 'Goodbye!' },
      ];

      mutations.SET_PROMPTS(state, mockPrompts);

      expect(state.records).toEqual(mockPrompts);
      expect(state.records).toHaveLength(2);
    });

    it('SET_PROMPTS should replace existing records', () => {
      state.records = [{ id: 999, prompt_key: 'old', text: 'Old prompt' }];

      const newPrompts = [
        { id: 1, prompt_key: 'new', text: 'New prompt' },
      ];

      mutations.SET_PROMPTS(state, newPrompts);

      expect(state.records).toEqual(newPrompts);
      expect(state.records).toHaveLength(1);
      expect(state.records[0].id).toBe(1);
    });

    it('SET_UI_FLAG should update specific UI flags', () => {
      mutations.SET_UI_FLAG(state, { isFetching: true });

      expect(state.uiFlags.isFetching).toBe(true);
      expect(state.uiFlags.isCreating).toBe(false); // Others should remain unchanged
    });

    it('SET_UI_FLAG should merge multiple flags', () => {
      mutations.SET_UI_FLAG(state, { isFetching: true, isCreating: true });

      expect(state.uiFlags.isFetching).toBe(true);
      expect(state.uiFlags.isCreating).toBe(true);
      expect(state.uiFlags.isUpdating).toBe(false);
    });

    describe('UPDATE_PROMPT', () => {
      it('should update the correct prompt in state.records', () => {
        const state = {
          records: [
            { id: 1, prompt_key: 'greeting', text: 'Hello there!' },
            { id: 2, prompt_key: 'closing', text: 'Thank you!' },
            { id: 3, prompt_key: 'help', text: 'How can I help?' },
          ],
        };

        const updatedPrompt = {
          id: 2,
          prompt_key: 'closing_updated',
          text: 'Thank you for contacting us! Have a great day!',
          updated_at: '2024-01-02T00:00:00Z',
        };

        mutations.UPDATE_PROMPT(state, updatedPrompt);

        expect(state.records).toHaveLength(3);
        expect(state.records[1]).toEqual(updatedPrompt);
        expect(state.records[0]).toEqual({ id: 1, prompt_key: 'greeting', text: 'Hello there!' });
        expect(state.records[2]).toEqual({ id: 3, prompt_key: 'help', text: 'How can I help?' });
      });

      it('should not modify state if prompt ID does not exist', () => {
        const state = {
          records: [
            { id: 1, prompt_key: 'greeting', text: 'Hello there!' },
            { id: 2, prompt_key: 'closing', text: 'Thank you!' },
          ],
        };

        const originalRecords = [...state.records];
        const nonExistentPrompt = {
          id: 999,
          prompt_key: 'non_existent',
          text: 'This prompt does not exist',
        };

        mutations.UPDATE_PROMPT(state, nonExistentPrompt);

        expect(state.records).toEqual(originalRecords);
        expect(state.records).toHaveLength(2);
      });

      it('should handle partial updates correctly', () => {
        const state = {
          records: [
            {
              id: 1,
              prompt_key: 'greeting',
              text: 'Hello there!',
              account_id: 1,
              created_at: '2024-01-01T00:00:00Z',
              updated_at: '2024-01-01T00:00:00Z',
            },
          ],
        };

        const fullUpdate = {
          id: 1,
          prompt_key: 'greeting',
          text: 'Hello! How can I help you today?',
          account_id: 1,
          created_at: '2024-01-01T00:00:00Z',
          updated_at: '2024-01-02T00:00:00Z',
        };

        mutations.UPDATE_PROMPT(state, fullUpdate);

        expect(state.records[0]).toEqual(fullUpdate);
      });

      it('should replace the entire prompt object when UPDATE_PROMPT is called', () => {
        const state = {
          records: [
            {
              id: 1,
              prompt_key: 'greeting',
              text: 'Old text',
              extra_field: 'should be replaced',
            },
          ],
        };

        const newPrompt = {
          id: 1,
          prompt_key: 'greeting_new',
          text: 'New text',
          account_id: 1,
          updated_at: '2024-01-02T00:00:00Z',
        };

        mutations.UPDATE_PROMPT(state, newPrompt);

        expect(state.records[0]).toEqual(newPrompt);
        expect(state.records[0]).not.toHaveProperty('extra_field');
      });
    });
  });

  describe('actions', () => {
    let commit;
    let mockPrompts;

    beforeEach(() => {
      commit = vi.fn();
      mockPrompts = [
        { id: 1, prompt_key: 'greeting', text: 'Hello there!' },
        { id: 2, prompt_key: 'closing', text: 'Thank you!' },
      ];
      vi.clearAllMocks();
    });

    describe('get action', () => {
      it('should dispatch GET request and commit SET_PROMPTS on success', async () => {
        const mockResponse = { data: mockPrompts };
        PromptAPI.get.mockResolvedValue(mockResponse);

        await actions.get({ commit });

        expect(commit).toHaveBeenCalledWith('SET_UI_FLAG', { isFetching: true });
        expect(PromptAPI.get).toHaveBeenCalledTimes(1);
        expect(commit).toHaveBeenCalledWith('SET_PROMPTS', mockPrompts);
        expect(commit).toHaveBeenCalledWith('SET_UI_FLAG', { isFetching: false });
      });

      it('should handle API errors and still reset isFetching flag', async () => {
        const mockError = new Error('API Error');
        PromptAPI.get.mockRejectedValue(mockError);

        await expect(actions.get({ commit })).rejects.toThrow('API Error');

        expect(commit).toHaveBeenCalledWith('SET_UI_FLAG', { isFetching: true });
        expect(PromptAPI.get).toHaveBeenCalledTimes(1);
        expect(commit).toHaveBeenCalledWith('SET_UI_FLAG', { isFetching: false });
        
        // SET_PROMPTS should not be called on error
        expect(commit).not.toHaveBeenCalledWith('SET_PROMPTS', expect.anything());
      });

      it('should ensure isFetching is reset even if an exception occurs', async () => {
        PromptAPI.get.mockRejectedValue(new Error('Network Error'));

        try {
          await actions.get({ commit });
        } catch (error) {
          // Expected to throw
        }

        // Verify that the finally block executed
        expect(commit).toHaveBeenCalledWith('SET_UI_FLAG', { isFetching: false });
      });
    });

    describe('update', () => {
      it('should call PromptAPI.update and commit UPDATE_PROMPT on success', async () => {
        const commit = vi.fn();
        const promptId = 1;
        const updateData = {
          text: 'Updated greeting message',
          prompt_key: 'greeting_updated',
        };
        const mockResponse = {
          data: {
            id: promptId,
            ...updateData,
            account_id: 1,
            updated_at: '2024-01-02T00:00:00Z',
          },
        };

        PromptAPI.update.mockResolvedValue(mockResponse);

        await actions.update({ commit }, { id: promptId, ...updateData });

        expect(PromptAPI.update).toHaveBeenCalledWith(promptId, updateData);
        expect(commit).toHaveBeenCalledWith('UPDATE_PROMPT', mockResponse.data);
      });

      it('should handle API errors gracefully', async () => {
        const commit = vi.fn();
        const promptId = 1;
        const updateData = {
          text: '',
          prompt_key: 'greeting',
        };
        const mockError = new Error('Validation failed');

        PromptAPI.update.mockRejectedValue(mockError);

        await expect(actions.update({ commit }, { id: promptId, ...updateData }))
          .rejects.toThrow('Validation failed');

        expect(PromptAPI.update).toHaveBeenCalledWith(promptId, updateData);
        expect(commit).not.toHaveBeenCalledWith('UPDATE_PROMPT', expect.anything());
      });

      it('should pass correct parameters to PromptAPI.update', async () => {
        const commit = vi.fn();
        const promptId = 42;
        const updateData = {
          text: 'Hello! How can we help you today?',
          prompt_key: 'help_greeting',
        };
        const mockResponse = {
          data: { id: promptId, ...updateData },
        };

        PromptAPI.update.mockResolvedValue(mockResponse);

        await actions.update({ commit }, { id: promptId, ...updateData });

        expect(PromptAPI.update).toHaveBeenCalledTimes(1);
        expect(PromptAPI.update).toHaveBeenCalledWith(promptId, updateData);
      });
    });
  });
}); 
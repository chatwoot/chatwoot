import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { useAttachments } from '../useAttachments';
import { useStore } from 'vuex';
import { computed } from 'vue';

// Mock Vue's useStore
vi.mock('vuex', () => ({
  useStore: vi.fn(),
}));

// Mock Vue's computed
vi.mock('vue', () => ({
  computed: vi.fn(fn => ({ value: fn() })),
}));

describe('useAttachments', () => {
  let mockStore;
  let mockGetters;

  beforeEach(() => {
    // Reset window.chatwootWebChannel
    delete window.chatwootWebChannel;

    // Create mock store
    mockGetters = {};
    mockStore = {
      getters: mockGetters,
    };
    vi.mocked(useStore).mockReturnValue(mockStore);

    // Mock computed to return a reactive-like object
    vi.mocked(computed).mockImplementation(fn => ({ value: fn() }));
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('shouldShowFilePicker', () => {
    it('returns value from store getter', () => {
      mockGetters['appConfig/getShouldShowFilePicker'] = true;

      const { shouldShowFilePicker } = useAttachments();

      expect(shouldShowFilePicker.value).toBe(true);
    });

    it('returns undefined when not set in store', () => {
      mockGetters['appConfig/getShouldShowFilePicker'] = undefined;

      const { shouldShowFilePicker } = useAttachments();

      expect(shouldShowFilePicker.value).toBeUndefined();
    });
  });

  describe('hasAttachmentsEnabled', () => {
    it('returns true when attachments are enabled in channel config', () => {
      window.chatwootWebChannel = {
        enabledFeatures: ['attachments', 'emoji'],
      };

      const { hasAttachmentsEnabled } = useAttachments();

      expect(hasAttachmentsEnabled.value).toBe(true);
    });

    it('returns false when attachments are not enabled in channel config', () => {
      window.chatwootWebChannel = {
        enabledFeatures: ['emoji'],
      };

      const { hasAttachmentsEnabled } = useAttachments();

      expect(hasAttachmentsEnabled.value).toBe(false);
    });

    it('returns false when channel config has no enabled features', () => {
      window.chatwootWebChannel = {
        enabledFeatures: [],
      };

      const { hasAttachmentsEnabled } = useAttachments();

      expect(hasAttachmentsEnabled.value).toBe(false);
    });

    it('returns false when channel config is missing', () => {
      window.chatwootWebChannel = undefined;

      const { hasAttachmentsEnabled } = useAttachments();

      expect(hasAttachmentsEnabled.value).toBe(false);
    });

    it('returns false when enabledFeatures is missing', () => {
      window.chatwootWebChannel = {};

      const { hasAttachmentsEnabled } = useAttachments();

      expect(hasAttachmentsEnabled.value).toBe(false);
    });
  });

  describe('canHandleAttachments', () => {
    beforeEach(() => {
      // Set up a default channel config
      window.chatwootWebChannel = {
        enabledFeatures: ['attachments'],
      };
    });

    it('prioritizes SDK flag when explicitly set to true', () => {
      mockGetters['appConfig/getShouldShowFilePicker'] = true;

      const { canHandleAttachments } = useAttachments();

      expect(canHandleAttachments.value).toBe(true);
    });

    it('prioritizes SDK flag when explicitly set to false', () => {
      mockGetters['appConfig/getShouldShowFilePicker'] = false;

      const { canHandleAttachments } = useAttachments();

      expect(canHandleAttachments.value).toBe(false);
    });

    it('falls back to inbox settings when SDK flag is undefined', () => {
      mockGetters['appConfig/getShouldShowFilePicker'] = undefined;
      window.chatwootWebChannel = {
        enabledFeatures: ['attachments'],
      };

      const { canHandleAttachments } = useAttachments();

      expect(canHandleAttachments.value).toBe(true);
    });

    it('falls back to inbox settings when SDK flag is undefined and attachments disabled', () => {
      mockGetters['appConfig/getShouldShowFilePicker'] = undefined;
      window.chatwootWebChannel = {
        enabledFeatures: ['emoji'],
      };

      const { canHandleAttachments } = useAttachments();

      expect(canHandleAttachments.value).toBe(false);
    });

    it('prioritizes SDK false over inbox settings true', () => {
      mockGetters['appConfig/getShouldShowFilePicker'] = false;
      window.chatwootWebChannel = {
        enabledFeatures: ['attachments'],
      };

      const { canHandleAttachments } = useAttachments();

      expect(canHandleAttachments.value).toBe(false);
    });

    it('prioritizes SDK true over inbox settings false', () => {
      mockGetters['appConfig/getShouldShowFilePicker'] = true;
      window.chatwootWebChannel = {
        enabledFeatures: ['emoji'], // no attachments
      };

      const { canHandleAttachments } = useAttachments();

      expect(canHandleAttachments.value).toBe(true);
    });
  });

  describe('hasEmojiPickerEnabled', () => {
    it('returns true when emoji picker is enabled in channel config', () => {
      window.chatwootWebChannel = {
        enabledFeatures: ['emoji_picker', 'attachments'],
      };

      const { hasEmojiPickerEnabled } = useAttachments();

      expect(hasEmojiPickerEnabled.value).toBe(true);
    });

    it('returns false when emoji picker is not enabled in channel config', () => {
      window.chatwootWebChannel = {
        enabledFeatures: ['attachments'],
      };

      const { hasEmojiPickerEnabled } = useAttachments();

      expect(hasEmojiPickerEnabled.value).toBe(false);
    });
  });

  describe('shouldShowEmojiPicker', () => {
    it('returns value from store getter', () => {
      mockGetters['appConfig/getShouldShowEmojiPicker'] = true;

      const { shouldShowEmojiPicker } = useAttachments();

      expect(shouldShowEmojiPicker.value).toBe(true);
    });
  });

  describe('integration test', () => {
    it('returns all expected properties', () => {
      mockGetters['appConfig/getShouldShowFilePicker'] = undefined;
      mockGetters['appConfig/getShouldShowEmojiPicker'] = true;
      window.chatwootWebChannel = {
        enabledFeatures: ['attachments', 'emoji_picker'],
      };

      const result = useAttachments();

      expect(result).toHaveProperty('shouldShowFilePicker');
      expect(result).toHaveProperty('shouldShowEmojiPicker');
      expect(result).toHaveProperty('hasAttachmentsEnabled');
      expect(result).toHaveProperty('hasEmojiPickerEnabled');
      expect(result).toHaveProperty('canHandleAttachments');
      expect(Object.keys(result)).toHaveLength(5);
    });
  });
});

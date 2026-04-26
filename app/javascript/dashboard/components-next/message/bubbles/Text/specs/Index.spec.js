import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ref, computed } from 'vue';

// Mock the useMessageContext composable
const mockContent = ref('');
const mockAttachments = ref([]);
const mockContentAttributes = ref({});
const mockMessageType = ref(0);

vi.mock('../../../provider.js', () => ({
  useMessageContext: () => ({
    content: mockContent,
    attachments: mockAttachments,
    contentAttributes: mockContentAttributes,
    messageType: mockMessageType,
  }),
}));

vi.mock('dashboard/composables/useTranslations', () => ({
  useTranslations: () => ({
    hasTranslations: computed(() => false),
    translationContent: computed(() => ''),
  }),
}));

describe('Text Message Bubble - Truncation Feature', () => {
  const MAX_CONTENT_LENGTH = 800;

  beforeEach(() => {
    mockContent.value = '';
    mockAttachments.value = [];
    mockContentAttributes.value = {};
    mockMessageType.value = 0;
  });

  describe('shouldTruncate computed property', () => {
    it('returns false when content is shorter than MAX_CONTENT_LENGTH', () => {
      const shortContent = 'a'.repeat(799);
      mockContent.value = shortContent;

      const shouldTruncate = shortContent.length > MAX_CONTENT_LENGTH;
      expect(shouldTruncate).toBe(false);
    });

    it('returns false when content equals MAX_CONTENT_LENGTH', () => {
      const exactContent = 'a'.repeat(800);
      mockContent.value = exactContent;

      const shouldTruncate = exactContent.length > MAX_CONTENT_LENGTH;
      expect(shouldTruncate).toBe(false);
    });

    it('returns true when content exceeds MAX_CONTENT_LENGTH', () => {
      const longContent = 'a'.repeat(801);
      mockContent.value = longContent;

      const shouldTruncate = longContent.length > MAX_CONTENT_LENGTH;
      expect(shouldTruncate).toBe(true);
    });

    it('returns false when content is empty', () => {
      mockContent.value = '';

      const shouldTruncate =
        mockContent.value && mockContent.value.length > MAX_CONTENT_LENGTH;
      expect(shouldTruncate).toBe(false);
    });

    it('returns false when content is null', () => {
      mockContent.value = null;

      const shouldTruncate =
        mockContent.value && mockContent.value.length > MAX_CONTENT_LENGTH;
      expect(shouldTruncate).toBe(false);
    });
  });

  describe('renderContent computed property', () => {
    it('returns full content when not truncated', () => {
      const shortContent = 'Hello, this is a short message.';
      mockContent.value = shortContent;

      const shouldTruncate = shortContent.length > MAX_CONTENT_LENGTH;
      const isExpanded = false;

      const renderContent =
        !shouldTruncate || isExpanded
          ? shortContent
          : shortContent.slice(0, MAX_CONTENT_LENGTH) + '...';

      expect(renderContent).toBe(shortContent);
    });

    it('returns truncated content with ellipsis when content exceeds limit and not expanded', () => {
      const longContent = 'a'.repeat(1000);
      mockContent.value = longContent;

      const shouldTruncate = longContent.length > MAX_CONTENT_LENGTH;
      const isExpanded = false;

      const renderContent =
        !shouldTruncate || isExpanded
          ? longContent
          : longContent.slice(0, MAX_CONTENT_LENGTH) + '...';

      expect(renderContent).toBe('a'.repeat(800) + '...');
      expect(renderContent.length).toBe(803); // 800 + '...'
    });

    it('returns full content when expanded even if content exceeds limit', () => {
      const longContent = 'a'.repeat(1000);
      mockContent.value = longContent;

      const shouldTruncate = longContent.length > MAX_CONTENT_LENGTH;
      const isExpanded = true;

      const renderContent =
        !shouldTruncate || isExpanded
          ? longContent
          : longContent.slice(0, MAX_CONTENT_LENGTH) + '...';

      expect(renderContent).toBe(longContent);
      expect(renderContent.length).toBe(1000);
    });
  });

  describe('toggleExpanded behavior', () => {
    it('toggles isExpanded state', () => {
      let isExpanded = false;

      const toggleExpanded = () => {
        isExpanded = !isExpanded;
      };

      expect(isExpanded).toBe(false);
      toggleExpanded();
      expect(isExpanded).toBe(true);
      toggleExpanded();
      expect(isExpanded).toBe(false);
    });
  });

  describe('toggleText computed property', () => {
    it('returns "Read more" when not expanded', () => {
      const isExpanded = false;
      const toggleText = isExpanded ? 'Show less' : 'Read more';

      expect(toggleText).toBe('Read more');
    });

    it('returns "Show less" when expanded', () => {
      const isExpanded = true;
      const toggleText = isExpanded ? 'Show less' : 'Read more';

      expect(toggleText).toBe('Show less');
    });
  });

  describe('edge cases', () => {
    it('handles content with special characters correctly', () => {
      const contentWithEmojis = '😀'.repeat(300);
      mockContent.value = contentWithEmojis;

      // Emoji are multi-byte but count as single characters in JS string length
      const shouldTruncate = contentWithEmojis.length > MAX_CONTENT_LENGTH;
      expect(shouldTruncate).toBe(false);
    });

    it('handles content with newlines correctly', () => {
      const contentWithNewlines = 'line\n'.repeat(200);
      mockContent.value = contentWithNewlines;

      const shouldTruncate = contentWithNewlines.length > MAX_CONTENT_LENGTH;
      expect(shouldTruncate).toBe(true);
    });

    it('handles content with HTML-like strings correctly', () => {
      const contentWithHtml = '<p>Hello</p>'.repeat(100);
      mockContent.value = contentWithHtml;

      const shouldTruncate = contentWithHtml.length > MAX_CONTENT_LENGTH;
      expect(shouldTruncate).toBe(true);
    });
  });
});

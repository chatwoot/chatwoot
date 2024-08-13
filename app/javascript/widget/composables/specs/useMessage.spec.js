import { describe, it, expect } from 'vitest';
import { reactive, nextTick } from 'vue';
import { useMessage } from '../useMessage';

describe('useMessage', () => {
  it('should handle deleted messages', () => {
    const message = reactive({
      content_attributes: { deleted: true },
      attachments: [],
    });

    const { messageContentAttributes, hasAttachments } = useMessage(message);

    expect(messageContentAttributes.value).toEqual({ deleted: true });
    expect(hasAttachments.value).toBe(false);
  });

  it('should handle non-deleted messages with attachments', () => {
    const message = reactive({
      content_attributes: {},
      attachments: ['attachment1', 'attachment2'],
    });

    const { messageContentAttributes, hasAttachments } = useMessage(message);

    expect(messageContentAttributes.value).toEqual({});
    expect(hasAttachments.value).toBe(true);
  });

  it('should handle messages without content_attributes', () => {
    const message = reactive({
      attachments: [],
    });

    const { messageContentAttributes, hasAttachments } = useMessage(message);

    expect(messageContentAttributes.value).toEqual({});
    expect(hasAttachments.value).toBe(false);
  });

  it('should handle messages with empty attachments array', () => {
    const message = reactive({
      content_attributes: { someAttribute: 'value' },
      attachments: [],
    });

    const { messageContentAttributes, hasAttachments } = useMessage(message);

    expect(messageContentAttributes.value).toEqual({ someAttribute: 'value' });
    expect(hasAttachments.value).toBe(false);
  });

  it('should update reactive properties when message changes', async () => {
    const message = reactive({
      content_attributes: {},
      attachments: [],
    });

    const { messageContentAttributes, hasAttachments } = useMessage(message);

    expect(messageContentAttributes.value).toEqual({});
    expect(hasAttachments.value).toBe(false);

    message.content_attributes = { updated: true };
    message.attachments.push('newAttachment');
    await nextTick();

    expect(messageContentAttributes.value).toEqual({ updated: true });
    expect(hasAttachments.value).toBe(true);
  });
});

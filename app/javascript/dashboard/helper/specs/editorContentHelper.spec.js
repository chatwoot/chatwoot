// Moved from editorHelper.spec.js to editorContentHelper.spec.js
// the mock of chatwoot/prosemirror-schema is getting conflicted with other specs
import { getContentNode } from '../editorHelper';
import {
  MessageMarkdownTransformer,
  messageSchema,
} from '@chatwoot/prosemirror-schema';
import { replaceVariablesInMessage } from '@chatwoot/utils';

vi.mock('@chatwoot/prosemirror-schema', () => ({
  MessageMarkdownTransformer: vi.fn(),
  messageSchema: {},
}));

vi.mock('@chatwoot/utils', () => ({
  replaceVariablesInMessage: vi.fn(),
}));

describe('getContentNode', () => {
  let editorView;

  beforeEach(() => {
    editorView = {
      state: {
        schema: {
          nodes: {
            mention: {
              create: vi.fn(),
            },
          },
          text: vi.fn(),
        },
      },
    };
  });

  describe('getMentionNode', () => {
    it('should create a mention node', () => {
      const content = { id: 1, name: 'John Doe' };
      const from = 0;
      const to = 10;
      getContentNode(editorView, 'mention', content, {
        from,
        to,
      });

      expect(editorView.state.schema.nodes.mention.create).toHaveBeenCalledWith(
        {
          userId: content.id,
          userFullName: content.name,
        }
      );
    });
  });

  describe('getCannedResponseNode', () => {
    it('should create a canned response node', () => {
      const content = 'Hello {{name}}';
      const variables = { name: 'John' };
      const from = 0;
      const to = 10;
      const updatedMessage = 'Hello John';

      replaceVariablesInMessage.mockReturnValue(updatedMessage);
      MessageMarkdownTransformer.mockImplementation(() => ({
        parse: vi.fn().mockReturnValue({ textContent: updatedMessage }),
      }));

      const { node } = getContentNode(
        editorView,
        'cannedResponse',
        content,
        { from, to },
        variables
      );

      expect(replaceVariablesInMessage).toHaveBeenCalledWith({
        message: content,
        variables,
      });
      expect(MessageMarkdownTransformer).toHaveBeenCalledWith(messageSchema);
      expect(node.textContent).toBe(updatedMessage);
    });
  });

  describe('getVariableNode', () => {
    it('should create a variable node', () => {
      const content = 'name';
      const from = 0;
      const to = 10;
      getContentNode(editorView, 'variable', content, {
        from,
        to,
      });

      expect(editorView.state.schema.text).toHaveBeenCalledWith('{{name}}');
    });
  });

  describe('getEmojiNode', () => {
    it('should create an emoji node', () => {
      const content = '😊';
      const from = 0;
      const to = 2;
      getContentNode(editorView, 'emoji', content, {
        from,
        to,
      });

      expect(editorView.state.schema.text).toHaveBeenCalledWith('😊');
    });
  });

  describe('getContentNode', () => {
    it('should return null for invalid type', () => {
      const content = 'invalid';
      const from = 0;
      const to = 10;
      const { node } = getContentNode(editorView, 'invalid', content, {
        from,
        to,
      });

      expect(node).toBeNull();
    });
  });
});

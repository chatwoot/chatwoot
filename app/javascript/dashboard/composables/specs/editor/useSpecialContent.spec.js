import useSpecialContent from 'dashboard/composables/editor/useSpecialContent';
import {
  MessageMarkdownTransformer,
  messageSchema,
} from '@chatwoot/prosemirror-schema';
import { replaceVariablesInMessage } from '@chatwoot/utils';

jest.mock('@chatwoot/prosemirror-schema', () => ({
  MessageMarkdownTransformer: jest.fn(),
  messageSchema: {},
}));

jest.mock('@chatwoot/utils', () => ({
  replaceVariablesInMessage: jest.fn(),
}));

describe('useSpecialContent', () => {
  let editorView;
  let specialContent;

  beforeEach(() => {
    editorView = {
      state: {
        schema: {
          nodes: {
            mention: {
              create: jest.fn(),
            },
          },
          text: jest.fn(),
        },
      },
    };
    specialContent = useSpecialContent();
  });

  describe('getMentionNode', () => {
    it('should create a mention node', () => {
      const content = { id: 1, name: 'John Doe' };
      const from = 0;
      const to = 10;
      specialContent.getContentNode(editorView, 'mention', content, {
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
        parse: jest.fn().mockReturnValue({ textContent: updatedMessage }),
      }));

      const { node } = specialContent.getContentNode(
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
      specialContent.getContentNode(editorView, 'variable', content, {
        from,
        to,
      });

      expect(editorView.state.schema.text).toHaveBeenCalledWith('{{name}}');
    });
  });

  describe('getContentNode', () => {
    it('should return null for invalid type', () => {
      const content = 'invalid';
      const from = 0;
      const to = 10;
      const { node } = specialContent.getContentNode(
        editorView,
        'invalid',
        content,
        { from, to }
      );

      expect(node).toBeNull();
    });
  });
});

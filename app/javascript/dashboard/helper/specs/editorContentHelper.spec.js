// Moved from editorHelper.spec.js to editorContentHelper.spec.js
// the mock of chatwoot/prosemirror-schema is getting conflicted with other specs
import { getContentNode } from '../editorHelper';
import { MessageMarkdownTransformer } from '@chatwoot/prosemirror-schema';
import { replaceVariablesInMessage } from '@chatwoot/utils';

vi.mock('@chatwoot/prosemirror-schema', () => ({
  MessageMarkdownTransformer: vi.fn(),
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
          mentionType: 'user',
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

      // Mock the node that will be returned by parse
      const mockNode = { textContent: updatedMessage };

      replaceVariablesInMessage.mockReturnValue(updatedMessage);

      // Mock MessageMarkdownTransformer instance with parse method
      const mockTransformer = {
        parse: vi.fn().mockReturnValue(mockNode),
      };
      MessageMarkdownTransformer.mockImplementation(() => mockTransformer);

      const result = getContentNode(
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
      expect(MessageMarkdownTransformer).toHaveBeenCalledWith(
        editorView.state.schema
      );
      expect(mockTransformer.parse).toHaveBeenCalledWith(updatedMessage);
      expect(result.node).toBe(mockNode);
      expect(result.node.textContent).toBe(updatedMessage);
      // When textContent matches updatedMessage, from should remain unchanged
      expect(result.from).toBe(from);
      expect(result.to).toBe(to);
    });
  });

  describe('getVariableNode', () => {
    it('should render the resolved value directly when the variable has a value', () => {
      getContentNode(
        editorView,
        'variable',
        'contact.name',
        { from: 0, to: 10 },
        { 'contact.name': 'John' }
      );

      expect(editorView.state.schema.text).toHaveBeenCalledWith('John');
    });

    it('should resolve camelCase custom attributes and non-string values', () => {
      getContentNode(
        editorView,
        'variable',
        'contact.custom_attribute.cloudCustomer',
        { from: 0, to: 10 },
        { 'contact.custom_attribute.cloudCustomer': true }
      );

      expect(editorView.state.schema.text).toHaveBeenCalledWith('true');
    });

    it('should keep the placeholder when the variable has no value', () => {
      getContentNode(
        editorView,
        'variable',
        'contact.email',
        { from: 0, to: 10 },
        {}
      );

      expect(editorView.state.schema.text).toHaveBeenCalledWith(
        '{{contact.email}}'
      );
    });

    it('should keep the placeholder when the value contains Liquid syntax', () => {
      getContentNode(
        editorView,
        'variable',
        'contact.name',
        { from: 0, to: 10 },
        { 'contact.name': '{{agent.email}}' }
      );

      expect(editorView.state.schema.text).toHaveBeenCalledWith(
        '{{contact.name}}'
      );
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

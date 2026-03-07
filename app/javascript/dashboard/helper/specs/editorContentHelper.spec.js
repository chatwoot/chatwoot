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
    MessageMarkdownTransformer.mockImplementation(() => ({
      parse: vi.fn(content => ({
        type: { name: 'doc' },
        textContent: content.replaceAll('**', ''),
      })),
    }));

    editorView = {
      state: {
        schema: {
          nodes: {
            doc: {
              create: vi.fn((attrs, content) => ({
                type: { name: 'doc' },
                content,
                textContent: content
                  .map(paragraph =>
                    (paragraph.content || [])
                      .map(node =>
                        node.type?.name === 'hard_break' ? '\n' : node.text
                      )
                      .join('')
                  )
                  .join('\n'),
              })),
            },
            paragraph: {
              create: vi.fn((attrs, content = []) => ({
                type: { name: 'paragraph' },
                content,
              })),
            },
            hard_break: {
              create: vi.fn(() => ({
                type: { name: 'hard_break' },
              })),
            },
            mention: {
              create: vi.fn(),
            },
          },
          text: vi.fn(text => ({
            type: { name: 'text' },
            text,
          })),
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
    it('should create a plain-text canned response node without markdown parsing', () => {
      const content = { text: 'Hello {{name}}', format: 'plain_text' };
      const variables = { name: 'John' };
      const from = 0;
      const to = 10;
      const updatedMessage = 'Hello John';

      replaceVariablesInMessage.mockReturnValue(updatedMessage);

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
      expect(MessageMarkdownTransformer).not.toHaveBeenCalled();
      expect(editorView.state.schema.nodes.doc.create).toHaveBeenCalled();
      expect(result.node.type.name).toBe('doc');
      expect(result.node.textContent).toBe(updatedMessage);
      // When textContent matches updatedMessage, from should remain unchanged
      expect(result.from).toBe(from);
      expect(result.to).toBe(to);
    });

    it('preserves literal dash prefixes and blank lines in canned responses', () => {
      const content = {
        text: 'Первая строка\n\n- пункт один\n- пункт два',
        format: 'plain_text',
      };
      replaceVariablesInMessage.mockReturnValue(content.text);

      const result = getContentNode(
        editorView,
        'cannedResponse',
        content,
        { from: 0, to: 10 },
        {}
      );

      expect(MessageMarkdownTransformer).not.toHaveBeenCalled();
      expect(result.node.textContent).toBe(content.text);
    });

    it('keeps markdown canned responses on the markdown parser path', () => {
      const content = { text: '**Hello** {{name}}', format: null };
      const variables = { name: 'John' };

      replaceVariablesInMessage.mockReturnValue('**Hello** John');

      const result = getContentNode(
        editorView,
        'cannedResponse',
        content,
        { from: 0, to: 10 },
        variables
      );

      expect(MessageMarkdownTransformer).toHaveBeenCalled();
      expect(result.node.textContent).toBe('Hello John');
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

import {
  findSignatureInBody,
  appendSignature,
  removeSignature,
  replaceSignature,
  cleanSignature,
  extractTextFromMarkdown,
  stripUnsupportedMarkdown,
  insertAtCursor,
  findNodeToInsertImage,
  setURLWithQueryAndSize,
  getContentNode,
  getFormattingForEditor,
  getSelectionCoords,
  getMenuAnchor,
  calculateMenuPosition,
  stripUnsupportedFormatting,
} from '../editorHelper';
import { FORMATTING } from 'dashboard/constants/editor';
import { EditorState } from '@chatwoot/prosemirror-schema';
import { EditorView } from '@chatwoot/prosemirror-schema';
import { Schema } from 'prosemirror-model';

// Define a basic ProseMirror schema
const schema = new Schema({
  nodes: {
    doc: { content: 'paragraph+' },
    paragraph: {
      content: 'inline*',
      group: 'block',
      toDOM: () => ['p', 0], // Represents a paragraph as a <p> tag in the DOM.
    },
    text: {
      group: 'inline',
      toDOM: node => node.text, // Represents text as its actual string value.
    },
    mention: {
      attrs: {
        userId: { default: '' },
        userFullName: { default: '' },
        mentionType: { default: 'user' },
      },
      inline: true,
      group: 'inline',
      toDOM: node => [
        'span',
        { class: 'mention' },
        `@${node.attrs.userFullName}`,
      ],
    },
  },
});

// Initialize a basic EditorState for testing
const createEditorState = (content = '') => {
  if (!content) {
    return EditorState.create({
      schema,
      doc: schema.node('doc', null, [schema.node('paragraph')]),
    });
  }
  return EditorState.create({
    schema,
    doc: schema.node('doc', null, [
      schema.node('paragraph', null, [schema.text(content)]),
    ]),
  });
};

const NEW_SIGNATURE = 'This is a new signature';

const DOES_NOT_HAVE_SIGNATURE = {
  'no signature': {
    body: 'This is a test',
    signature: 'This is a signature',
  },
  'text after signature': {
    body: 'This is a test\n\n--\n\nThis is a signature\n\nThis is more text',
    signature: 'This is a signature',
  },
  'signature has images': {
    body: 'This is a test',
    signature:
      'Testing\n![](http://localhost:3000/rails/active_storage/blobs/redirect/some-hash/image.png)',
  },
  'signature has non commonmark syntax': {
    body: 'This is a test',
    signature: '- Signature',
  },
  'signature has trailing spaces': {
    body: 'This is a test',
    signature: '**hello**      \n**world**',
  },
};

const HAS_SIGNATURE = {
  'signature at end': {
    body: 'This is a test\n\n--\n\nThis is a signature',
    signature: 'This is a signature',
  },
  'signature at end with spaces and new lines': {
    body: 'This is a test\n\n--\n\nThis is a signature \n\n',
    signature: 'This is a signature ',
  },
  'no text before signature': {
    body: '\n\n--\n\nThis is a signature',
    signature: 'This is a signature',
  },
  'signature has non-commonmark syntax': {
    body: '\n\n--\n\n* Signature',
    signature: '- Signature',
  },
};

describe.skip('findSignatureInBody - SKIP(#78): Due to changes on append signature logic', () => {
  it('returns -1 if there is no signature', () => {
    Object.keys(DOES_NOT_HAVE_SIGNATURE).forEach(key => {
      const { body, signature } = DOES_NOT_HAVE_SIGNATURE[key];
      expect(findSignatureInBody(body, signature).index).toBe(-1);
    });
  });
  it('returns the index of the signature if there is one', () => {
    Object.keys(HAS_SIGNATURE).forEach(key => {
      const { body, signature } = HAS_SIGNATURE[key];
      expect(findSignatureInBody(body, signature).index).toBeGreaterThan(0);
    });
  });
});

describe('appendSignature', () => {
  it('appends the signature if it is not present', () => {
    Object.keys(DOES_NOT_HAVE_SIGNATURE).forEach(key => {
      const { body, signature } = DOES_NOT_HAVE_SIGNATURE[key];
      const cleanedSignature = cleanSignature(signature);
      expect(
        appendSignature(body, signature, {
          position: 'bottom',
          separator: '--',
        }).includes(cleanedSignature)
      ).toBeTruthy();
    });
  });

  it('appends the signature at the top with -- separator', () => {
    const { body, signature } = DOES_NOT_HAVE_SIGNATURE['no signature'];
    const cleanedSignature = cleanSignature(signature);
    expect(
      appendSignature(body, signature, {
        position: 'top',
        separator: '--',
      })
    ).toBe(`${cleanedSignature}\n\n--\n\n${body}`);
  });

  it('appends the signature at the bottom with blank separator', () => {
    const { body, signature } = DOES_NOT_HAVE_SIGNATURE['no signature'];
    const cleanedSignature = cleanSignature(signature);
    expect(
      appendSignature(body, signature, {
        position: 'bottom',
        separator: 'blank',
      })
    ).toBe(`${body}\n\n${cleanedSignature}`);
  });

  it('appends the signature at the top with blank separator', () => {
    const { body, signature } = DOES_NOT_HAVE_SIGNATURE['no signature'];
    const cleanedSignature = cleanSignature(signature);
    expect(
      appendSignature(body, signature, {
        position: 'top',
        separator: 'blank',
      })
    ).toBe(`${cleanedSignature}\n\n${body}`);
  });

  it.skip('does not append signature if already present - SKIP(#78): Due to changes on append signature logic', () => {
    Object.keys(HAS_SIGNATURE).forEach(key => {
      const { body, signature } = HAS_SIGNATURE[key];
      expect(appendSignature(body, signature)).toBe(body);
    });
  });
});

describe('stripUnsupportedMarkdown', () => {
  const richSignature =
    '**Bold** _italic_ [link](http://example.com) ![](http://localhost:3000/image.png)';

  it('keeps all formatting for Email channel (supports image, link, strong, em)', () => {
    const result = stripUnsupportedMarkdown(richSignature, 'Channel::Email');
    expect(result).toContain('**Bold**');
    expect(result).toContain('_italic_');
    expect(result).toContain('[link](http://example.com)');
    expect(result).toContain('![](http://localhost:3000/image.png)');
  });
  it('strips images but keeps bold/italic for Api channel', () => {
    const result = stripUnsupportedMarkdown(richSignature, 'Channel::Api');
    expect(result).toContain('**Bold**');
    expect(result).toContain('_italic_');
    expect(result).toContain('link'); // link text kept
    expect(result).not.toContain('[link]('); // link syntax removed
    expect(result).not.toContain('![]('); // image removed
  });
  it('strips images but keeps bold/italic/link for Telegram channel', () => {
    const result = stripUnsupportedMarkdown(richSignature, 'Channel::Telegram');
    expect(result).toContain('**Bold**');
    expect(result).toContain('_italic_');
    expect(result).toContain('[link](http://example.com)');
    expect(result).not.toContain('![](');
  });
  it('strips all formatting for SMS channel', () => {
    const result = stripUnsupportedMarkdown(richSignature, 'Channel::Sms');
    expect(result).toContain('Bold');
    expect(result).toContain('italic');
    expect(result).toContain('link');
    expect(result).not.toContain('**');
    expect(result).not.toContain('_');
    expect(result).not.toContain('[');
    expect(result).not.toContain('![](');
  });
  it('returns empty string for empty input', () => {
    expect(stripUnsupportedMarkdown('', 'Channel::Api')).toBe('');
    expect(stripUnsupportedMarkdown(null, 'Channel::Api')).toBe('');
  });

  describe('with cleanWhitespace parameter', () => {
    const textWithWhitespace =
      '**Bold** text\n\nWith multiple\n\nLine breaks\n\n  And spaces  ';

    it('cleans whitespace when cleanWhitespace=true (default)', () => {
      const result = stripUnsupportedMarkdown(
        textWithWhitespace,
        'Channel::Api',
        true
      );
      expect(result).toBe(
        '**Bold** text\nWith multiple\nLine breaks\nAnd spaces'
      );
      expect(result).not.toContain('\n\n');
      expect(result).not.toContain('  ');
    });

    it('preserves whitespace when cleanWhitespace=false', () => {
      const result = stripUnsupportedMarkdown(
        textWithWhitespace,
        'Channel::Api',
        false
      );
      expect(result).toContain('\n\n');
      expect(result).toContain('  And spaces  ');
      expect(result).toBe(
        '**Bold** text\n\nWith multiple\n\nLine breaks\n\n  And spaces  '
      );
    });

    it('strips formatting but preserves whitespace for messages', () => {
      const messageWithFormatting = '**Bold**\n\n`code`\n\nNormal text';
      const result = stripUnsupportedMarkdown(
        messageWithFormatting,
        'Channel::Sms',
        false
      );
      expect(result).toBe('Bold\n\ncode\n\nNormal text');
      expect(result).toContain('\n\n');
      expect(result).not.toContain('**');
      expect(result).not.toContain('`');
    });
  });
});

describe.skip('appendSignature with channelType - SKIP(#78): Due to changes on append signature logic', () => {
  const signatureWithImage =
    'Thanks\n![](http://localhost:3000/image.png?cw_image_height=24px)';

  it('keeps images for Email channel', () => {
    const result = appendSignature(
      'Hello',
      signatureWithImage,
      'Channel::Email'
    );
    expect(result).toContain('![](http://localhost:3000/image.png');
  });
  it('keeps images for WebWidget channel', () => {
    const result = appendSignature(
      'Hello',
      signatureWithImage,
      'Channel::WebWidget'
    );
    expect(result).toContain('![](http://localhost:3000/image.png');
  });
  it('strips images but keeps text for Api channel', () => {
    const result = appendSignature('Hello', signatureWithImage, 'Channel::Api');
    expect(result).not.toContain('![](');
    expect(result).toContain('Thanks');
  });
  it('strips images but keeps text for WhatsApp channel', () => {
    const result = appendSignature(
      'Hello',
      signatureWithImage,
      'Channel::Whatsapp'
    );
    expect(result).not.toContain('![](');
    expect(result).toContain('Thanks');
  });
  it('keeps images when channelType is not provided', () => {
    const result = appendSignature('Hello', signatureWithImage);
    expect(result).toContain('![](http://localhost:3000/image.png');
  });
  it('keeps bold/italic for channels that support them', () => {
    const boldSignature = '**Bold** *italic* Thanks';
    const result = appendSignature('Hello', boldSignature, 'Channel::Api');
    // Api supports strong and em
    expect(result).toContain('**Bold**');
    expect(result).toContain('*italic*');
  });
});

describe('cleanSignature', () => {
  it('removes any instance of horizontal rule', () => {
    const options = [
      '---',
      '***',
      '___',
      '- - -',
      '* * *',
      '_ _ _',
      ' ---',
      '--- ',
      ' --- ',
      '-----',
      '*****',
      '_____',
      '- - - -',
      '* * * * *',
      '_ _ _ _ _ _',
      ' - - - - ',
      ' * * * * * ',
      ' _ _ _ _ _ _',
      '- - - - -',
      '* * * * * *',
      '_ _ _ _ _ _ _',
    ];
    options.forEach(option => {
      expect(cleanSignature(option)).toBe('');
    });
  });
});

describe.skip('removeSignature - SKIP(#78): Due to changes on append signature logic', () => {
  it('does not remove signature if not present', () => {
    Object.keys(DOES_NOT_HAVE_SIGNATURE).forEach(key => {
      const { body, signature } = DOES_NOT_HAVE_SIGNATURE[key];
      expect(removeSignature(body, signature)).toBe(body);
    });
  });
  it('removes signature if present at the end', () => {
    const { body, signature } = HAS_SIGNATURE['signature at end'];
    expect(removeSignature(body, signature, '--')).toBe('This is a test');
  });
  it('removes signature if present with spaces and new lines', () => {
    const { body, signature } =
      HAS_SIGNATURE['signature at end with spaces and new lines'];
    expect(removeSignature(body, signature, '--')).toBe('This is a test');
  });
  it('removes signature if present without text before it', () => {
    const { body, signature } = HAS_SIGNATURE['no text before signature'];
    expect(removeSignature(body, signature)).toBe('\n\n');
  });
  it('removes just the delimiter if no signature is present', () => {
    expect(removeSignature('This is a test\n\n--', 'This is a signature')).toBe(
      'This is a test\n\n'
    );
  });
});

describe.skip('replaceSignature - SKIP(#78): Due to changes on append signature logic', () => {
  it('appends the new signature if not present', () => {
    Object.keys(DOES_NOT_HAVE_SIGNATURE).forEach(key => {
      const { body, signature } = DOES_NOT_HAVE_SIGNATURE[key];
      expect(replaceSignature(body, signature, NEW_SIGNATURE)).toBe(
        `${body}\n\n--\n\n${NEW_SIGNATURE}`
      );
    });
  });
  it('removes signature if present at the end', () => {
    const { body, signature } = HAS_SIGNATURE['signature at end'];
    expect(replaceSignature(body, signature, NEW_SIGNATURE)).toBe(
      `This is a test\n\n--\n\n${NEW_SIGNATURE}`
    );
  });
  it('removes signature if present with spaces and new lines', () => {
    const { body, signature } =
      HAS_SIGNATURE['signature at end with spaces and new lines'];
    expect(replaceSignature(body, signature, NEW_SIGNATURE)).toBe(
      `This is a test\n\n--\n\n${NEW_SIGNATURE}`
    );
  });
  it('removes signature if present without text before it', () => {
    const { body, signature } = HAS_SIGNATURE['no text before signature'];
    expect(replaceSignature(body, signature, NEW_SIGNATURE)).toBe(
      `\n\n--\n\n${NEW_SIGNATURE}`
    );
  });
});

describe('extractTextFromMarkdown', () => {
  it('should extract text from markdown and remove all images, code blocks, links, headers, bold, italic, lists etc.', () => {
    const markdown = `
      # Hello World

      This is a **bold** text with a [link](https://example.com).

      \`\`\`javascript
      const foo = 'bar';
      console.log(foo);
      \`\`\`

      Here's an image: ![alt text](https://example.com/image.png)

      - List item 1
      - List item 2

      *Italic text*
      `;

    const expected =
      "Hello World\nThis is a bold text with a link.\nHere's an image:\nList item 1\nList item 2\nItalic text";
    expect(extractTextFromMarkdown(markdown)).toEqual(expected);
  });
});

describe('insertAtCursor', () => {
  it('should return undefined if editorView is not provided', () => {
    const result = insertAtCursor(undefined, schema.text('Hello'), 0);
    expect(result).toBeUndefined();
  });

  it('should insert text node at cursor position', () => {
    const editorState = createEditorState();
    const editorView = new EditorView(document.body, { state: editorState });

    insertAtCursor(editorView, schema.text('Hello'), 0);

    // Check if node was unwrapped and inserted correctly
    expect(editorView.state.doc.firstChild.firstChild.text).toBe('Hello');
  });

  it('should insert node without replacing any content if "to" is not provided', () => {
    const editorState = createEditorState();
    const editorView = new EditorView(document.body, { state: editorState });

    insertAtCursor(editorView, schema.text('Hello'), 0);

    // Check if node was inserted correctly
    expect(editorView.state.doc.firstChild.firstChild.text).toBe('Hello');
  });

  it('should replace content between "from" and "to" with the provided node', () => {
    const editorState = createEditorState('ReplaceMe');
    const editorView = new EditorView(document.body, { state: editorState });

    insertAtCursor(editorView, schema.text('Hello'), 0, 8);

    // Check if content was replaced correctly
    expect(editorView.state.doc.firstChild.firstChild.text).toBe('Hello Me');
  });
});

describe('findNodeToInsertImage', () => {
  let mockEditorState;

  beforeEach(() => {
    mockEditorState = {
      selection: {
        $from: {
          node: vi.fn(() => ({})),
        },
        from: 0,
      },
      schema: {
        nodes: {
          image: {
            create: vi.fn(attrs => ({ type: { name: 'image' }, attrs })),
          },
          paragraph: {
            create: vi.fn((_, node) => ({
              type: { name: 'paragraph' },
              content: [node],
            })),
          },
        },
      },
    };
  });

  it('should insert image directly into an empty paragraph', () => {
    const mockNode = {
      type: { name: 'paragraph' },
      content: { size: 0, content: [] },
    };
    mockEditorState.selection.$from.node.mockReturnValueOnce(mockNode);

    const result = findNodeToInsertImage(mockEditorState, 'image-url');
    expect(result).toEqual({
      node: { type: { name: 'image' }, attrs: { src: 'image-url' } },
      pos: 0,
    });
  });

  it('should insert image directly into a paragraph without an image but with other content', () => {
    const mockNode = {
      type: { name: 'paragraph' },
      content: {
        size: 1,
        content: [
          {
            type: { name: 'text' },
          },
        ],
      },
    };
    mockEditorState.selection.$from.node.mockReturnValueOnce(mockNode);
    mockEditorState.selection.from = 1;

    const result = findNodeToInsertImage(mockEditorState, 'image-url');
    expect(result).toEqual({
      node: { type: { name: 'image' }, attrs: { src: 'image-url' } },
      pos: 2, // Because it should insert after the text, on a new line.
    });
  });

  it("should wrap image in a new paragraph when the current node isn't a paragraph", () => {
    const mockNode = {
      type: { name: 'not-a-paragraph' },
      content: { size: 0, content: [] },
    };
    mockEditorState.selection.$from.node.mockReturnValueOnce(mockNode);

    const result = findNodeToInsertImage(mockEditorState, 'image-url');
    expect(result.node.type.name).toBe('paragraph');
    expect(result.node.content[0].type.name).toBe('image');
    expect(result.node.content[0].attrs.src).toBe('image-url');
    expect(result.pos).toBe(0);
  });

  it('should insert a new image directly into the paragraph that already contains an image', () => {
    const mockNode = {
      type: { name: 'paragraph' },
      content: {
        size: 1,
        content: [
          {
            type: { name: 'image', attrs: { src: 'existing-image-url' } },
          },
        ],
      },
    };
    mockEditorState.selection.$from.node.mockReturnValueOnce(mockNode);
    mockEditorState.selection.from = 1;

    const result = findNodeToInsertImage(mockEditorState, 'image-url');
    expect(result.node.type.name).toBe('image');
    expect(result.node.attrs.src).toBe('image-url');
    expect(result.pos).toBe(1);
  });
});

describe('setURLWithQueryAndSize', () => {
  let selectedNode;
  let editorView;

  beforeEach(() => {
    selectedNode = {
      setAttribute: vi.fn(),
    };

    const tr = {
      setNodeMarkup: vi.fn().mockReturnValue({
        docChanged: true,
      }),
    };

    const state = {
      selection: { from: 0 },
      tr,
    };

    editorView = {
      state,
      dispatch: vi.fn(),
    };
  });

  it('updates the URL with the given size and updates the editor view', () => {
    const size = { height: '20px' };

    setURLWithQueryAndSize(selectedNode, size, editorView);

    // Check if the editor view is updated
    expect(editorView.dispatch).toHaveBeenCalledTimes(1);
  });

  it('updates the URL with the given size and updates the editor view with original size', () => {
    const size = { height: 'auto' };

    setURLWithQueryAndSize(selectedNode, size, editorView);

    // Check if the editor view is updated
    expect(editorView.dispatch).toHaveBeenCalledTimes(1);
  });

  it('does not update the editor view if the document has not changed', () => {
    editorView.state.tr.setNodeMarkup = vi.fn().mockReturnValue({
      docChanged: false,
    });

    const size = { height: '20px' };

    setURLWithQueryAndSize(selectedNode, size, editorView);

    // Check if the editor view dispatch was not called
    expect(editorView.dispatch).not.toHaveBeenCalled();
  });

  it('does not perform any operations if selectedNode is not provided', () => {
    setURLWithQueryAndSize(null, { height: '20px' }, editorView);

    // Ensure the dispatch method wasn't called
    expect(editorView.dispatch).not.toHaveBeenCalled();
  });
});

describe('getContentNode', () => {
  let mockEditorView;

  beforeEach(() => {
    mockEditorView = {
      state: {
        schema: {
          nodes: {
            mention: {
              create: vi.fn(attrs => ({
                type: { name: 'mention' },
                attrs,
              })),
            },
          },
          text: vi.fn(content => ({ type: { name: 'text' }, text: content })),
        },
      },
    };
  });

  describe('mention node creation', () => {
    it('creates a user mention node with correct attributes', () => {
      const userContent = {
        id: '123',
        name: 'John Doe',
        type: 'user',
      };

      const result = getContentNode(mockEditorView, 'mention', userContent, {
        from: 0,
        to: 5,
      });

      expect(
        mockEditorView.state.schema.nodes.mention.create
      ).toHaveBeenCalledWith({
        userId: '123',
        userFullName: 'John Doe',
        mentionType: 'user',
      });

      expect(result).toEqual({
        node: {
          type: { name: 'mention' },
          attrs: {
            userId: '123',
            userFullName: 'John Doe',
            mentionType: 'user',
          },
        },
        from: 0,
        to: 5,
      });
    });

    it('creates a team mention node with correct attributes', () => {
      const teamContent = {
        id: '456',
        name: 'Support Team',
        type: 'team',
      };

      const result = getContentNode(mockEditorView, 'mention', teamContent, {
        from: 0,
        to: 5,
      });

      expect(
        mockEditorView.state.schema.nodes.mention.create
      ).toHaveBeenCalledWith({
        userId: '456',
        userFullName: 'Support Team',
        mentionType: 'team',
      });

      expect(result).toEqual({
        node: {
          type: { name: 'mention' },
          attrs: {
            userId: '456',
            userFullName: 'Support Team',
            mentionType: 'team',
          },
        },
        from: 0,
        to: 5,
      });
    });

    it('defaults to user mention type when type is not specified', () => {
      const contentWithoutType = {
        id: '789',
        name: 'Jane Smith',
      };

      getContentNode(mockEditorView, 'mention', contentWithoutType, {
        from: 0,
        to: 5,
      });

      expect(
        mockEditorView.state.schema.nodes.mention.create
      ).toHaveBeenCalledWith({
        userId: '789',
        userFullName: 'Jane Smith',
        mentionType: 'user',
      });
    });

    it('uses displayName over name when both are provided', () => {
      const contentWithDisplayName = {
        id: '101',
        name: 'john_doe',
        displayName: 'John Doe (Admin)',
        type: 'user',
      };

      getContentNode(mockEditorView, 'mention', contentWithDisplayName, {
        from: 0,
        to: 5,
      });

      expect(
        mockEditorView.state.schema.nodes.mention.create
      ).toHaveBeenCalledWith({
        userId: '101',
        userFullName: 'John Doe (Admin)',
        mentionType: 'user',
      });
    });

    it('handles missing displayName by falling back to name', () => {
      const contentWithoutDisplayName = {
        id: '102',
        name: 'jane_smith',
        type: 'user',
      };

      getContentNode(mockEditorView, 'mention', contentWithoutDisplayName, {
        from: 0,
        to: 5,
      });

      expect(
        mockEditorView.state.schema.nodes.mention.create
      ).toHaveBeenCalledWith({
        userId: '102',
        userFullName: 'jane_smith',
        mentionType: 'user',
      });
    });
  });

  describe('unsupported node types', () => {
    it('returns null node for unsupported type', () => {
      const result = getContentNode(mockEditorView, 'unsupported', 'content', {
        from: 0,
        to: 5,
      });

      expect(result).toEqual({
        node: null,
        from: 0,
        to: 5,
      });
    });
  });
});

describe('getFormattingForEditor', () => {
  describe('context-specific formatting', () => {
    it('returns default formatting for Context::Default', () => {
      const result = getFormattingForEditor('Context::Default');

      expect(result).toEqual(FORMATTING['Context::Default']);
    });

    it('returns signature formatting for Context::MessageSignature', () => {
      const result = getFormattingForEditor('Context::MessageSignature');

      expect(result).toEqual(FORMATTING['Context::MessageSignature']);
    });

    it('returns widget builder formatting for Context::InboxSettings', () => {
      const result = getFormattingForEditor('Context::InboxSettings');

      expect(result).toEqual(FORMATTING['Context::InboxSettings']);
    });
  });

  describe('fallback behavior', () => {
    it('returns default formatting for unknown channel type', () => {
      const result = getFormattingForEditor('Channel::Unknown');

      expect(result).toEqual(FORMATTING['Context::Default']);
    });

    it('returns default formatting for null channel type', () => {
      const result = getFormattingForEditor(null);

      expect(result).toEqual(FORMATTING['Context::Default']);
    });

    it('returns default formatting for undefined channel type', () => {
      const result = getFormattingForEditor(undefined);

      expect(result).toEqual(FORMATTING['Context::Default']);
    });

    it('returns default formatting for empty string', () => {
      const result = getFormattingForEditor('');

      expect(result).toEqual(FORMATTING['Context::Default']);
    });
  });

  describe('return value structure', () => {
    it('always returns an object with marks, nodes, and menu properties', () => {
      const result = getFormattingForEditor('Channel::Email');

      expect(result).toHaveProperty('marks');
      expect(result).toHaveProperty('nodes');
      expect(result).toHaveProperty('menu');
      expect(Array.isArray(result.marks)).toBe(true);
      expect(Array.isArray(result.nodes)).toBe(true);
      expect(Array.isArray(result.menu)).toBe(true);
    });
  });
});

describe('stripUnsupportedFormatting', () => {
  describe('when schema supports all formatting', () => {
    const fullSchema = {
      marks: { strong: {}, em: {}, code: {}, strike: {}, link: {} },
      nodes: { bulletList: {}, orderedList: {}, codeBlock: {}, blockquote: {} },
    };

    it('preserves all formatting when schema supports it', () => {
      const content = '**bold** and *italic* and `code`';
      expect(stripUnsupportedFormatting(content, fullSchema)).toBe(content);
    });

    it('preserves links when schema supports them', () => {
      const content = 'Check [this link](https://example.com)';
      expect(stripUnsupportedFormatting(content, fullSchema)).toBe(content);
    });

    it('preserves autolinks when schema supports links', () => {
      const content = 'Check out <https://cegrafic.com/catalogo/>';
      expect(stripUnsupportedFormatting(content, fullSchema)).toBe(content);
    });

    it('preserves various URI scheme autolinks', () => {
      const content =
        'Email <mailto:user@example.com> or call <tel:+1234567890>';
      expect(stripUnsupportedFormatting(content, fullSchema)).toBe(content);
    });

    it('preserves email autolinks', () => {
      const content = 'Contact us at <support@chatwoot.com>';
      expect(stripUnsupportedFormatting(content, fullSchema)).toBe(content);
    });

    it('preserves lists when schema supports them', () => {
      const content = '- item 1\n- item 2\n1. first\n2. second';
      expect(stripUnsupportedFormatting(content, fullSchema)).toBe(content);
    });
  });

  describe('when schema has no formatting support (eg:SMS channel)', () => {
    const emptySchema = {
      marks: {},
      nodes: {},
    };

    it('strips bold formatting', () => {
      expect(stripUnsupportedFormatting('**bold text**', emptySchema)).toBe(
        'bold text'
      );
      expect(stripUnsupportedFormatting('__bold text__', emptySchema)).toBe(
        'bold text'
      );
    });

    it('strips italic formatting', () => {
      expect(stripUnsupportedFormatting('*italic text*', emptySchema)).toBe(
        'italic text'
      );
      expect(stripUnsupportedFormatting('_italic text_', emptySchema)).toBe(
        'italic text'
      );
    });

    it('preserves underscores in URLs and mid-word positions', () => {
      // Underscores in URLs should not be stripped as italic formatting
      expect(
        stripUnsupportedFormatting(
          'https://www.chatwoot.com/new_first_second-third/ssd',
          emptySchema
        )
      ).toBe('https://www.chatwoot.com/new_first_second-third/ssd');

      // Underscores in variable names should not be stripped
      expect(
        stripUnsupportedFormatting('some_variable_name', emptySchema)
      ).toBe('some_variable_name');

      // But actual italic formatting with spaces should still be stripped
      expect(
        stripUnsupportedFormatting('hello _world_ there', emptySchema)
      ).toBe('hello world there');
    });

    it('strips inline code formatting', () => {
      expect(stripUnsupportedFormatting('`inline code`', emptySchema)).toBe(
        'inline code'
      );
    });

    it('strips strikethrough formatting', () => {
      expect(stripUnsupportedFormatting('~~strikethrough~~', emptySchema)).toBe(
        'strikethrough'
      );
    });

    it('strips links but keeps text', () => {
      expect(
        stripUnsupportedFormatting(
          'Check [this link](https://example.com)',
          emptySchema
        )
      ).toBe('Check this link');
    });

    it('converts autolinks to plain URLs when schema does not support links', () => {
      const content = 'Visit <https://cegrafic.com/catalogo/> for more info';
      const expected = 'Visit https://cegrafic.com/catalogo/ for more info';
      expect(stripUnsupportedFormatting(content, emptySchema)).toBe(expected);
    });

    it('handles multiple autolinks in content', () => {
      const content = 'Check <https://example.com> and <https://test.com>';
      const expected = 'Check https://example.com and https://test.com';
      expect(stripUnsupportedFormatting(content, emptySchema)).toBe(expected);
    });

    it('converts URI scheme autolinks to plain text', () => {
      const content =
        'Email <mailto:support@example.com> or call <tel:+1234567890>';
      const expected =
        'Email mailto:support@example.com or call tel:+1234567890';
      expect(stripUnsupportedFormatting(content, emptySchema)).toBe(expected);
    });

    it('converts email autolinks to plain text', () => {
      const content = 'Reach us at <admin@chatwoot.com> for help';
      const expected = 'Reach us at admin@chatwoot.com for help';
      expect(stripUnsupportedFormatting(content, emptySchema)).toBe(expected);
    });

    it('handles mixed autolink types', () => {
      const content = 'Visit <https://example.com> or email <info@example.com>';
      const expected = 'Visit https://example.com or email info@example.com';
      expect(stripUnsupportedFormatting(content, emptySchema)).toBe(expected);
    });

    it('strips bullet list markers', () => {
      expect(
        stripUnsupportedFormatting('- item 1\n- item 2', emptySchema)
      ).toBe('item 1\nitem 2');
      expect(
        stripUnsupportedFormatting('* item 1\n* item 2', emptySchema)
      ).toBe('item 1\nitem 2');
    });

    it('strips ordered list markers', () => {
      expect(
        stripUnsupportedFormatting('1. first\n2. second', emptySchema)
      ).toBe('first\nsecond');
    });

    it('strips code block markers', () => {
      expect(
        stripUnsupportedFormatting('```javascript\ncode here\n```', emptySchema)
      ).toBe('code here\n');
    });

    it('strips blockquote markers', () => {
      expect(stripUnsupportedFormatting('> quoted text', emptySchema)).toBe(
        'quoted text'
      );
    });

    it('handles complex content with multiple formatting types', () => {
      const content =
        '**Bold** and *italic* with `code` and [link](url)\n- list item';
      const expected = 'Bold and italic with code and link\nlist item';
      expect(stripUnsupportedFormatting(content, emptySchema)).toBe(expected);
    });
  });

  describe('when schema has partial support', () => {
    const partialSchema = {
      marks: { strong: {}, em: {} },
      nodes: {},
    };

    it('preserves supported marks and strips unsupported ones', () => {
      const content = '**bold** and `code`';
      expect(stripUnsupportedFormatting(content, partialSchema)).toBe(
        '**bold** and code'
      );
    });

    it('strips unsupported nodes but keeps supported marks', () => {
      const content = '**bold** text\n- list item';
      expect(stripUnsupportedFormatting(content, partialSchema)).toBe(
        '**bold** text\nlist item'
      );
    });
  });

  describe('edge cases', () => {
    it('returns content unchanged if content is empty', () => {
      expect(stripUnsupportedFormatting('', {})).toBe('');
    });

    it('returns content unchanged if content is null', () => {
      expect(stripUnsupportedFormatting(null, {})).toBe(null);
    });

    it('returns content unchanged if content is undefined', () => {
      expect(stripUnsupportedFormatting(undefined, {})).toBe(undefined);
    });

    it('returns content unchanged if schema is null', () => {
      expect(stripUnsupportedFormatting('**bold**', null)).toBe('**bold**');
    });

    it('handles nested formatting correctly', () => {
      const emptySchema = { marks: {}, nodes: {} };
      // After stripping bold (**), the remaining *and italic* becomes italic and is stripped too
      expect(
        stripUnsupportedFormatting('**bold *and italic***', emptySchema)
      ).toBe('bold and italic');
    });
  });
});

describe('Menu positioning helpers', () => {
  const mockEditorView = {
    coordsAtPos: vi.fn((pos, bias) => {
      // Return different coords based on position
      if (bias === 1) return { top: 100, bottom: 120, left: 50, right: 100 };
      return { top: 100, bottom: 120, left: 150, right: 200 };
    }),
  };

  const wrapperRect = { top: 50, bottom: 300, left: 0, right: 400, width: 400 };

  describe('getSelectionCoords', () => {
    it('returns selection coordinates with onTop flag', () => {
      const selection = { from: 0, to: 10 };
      const result = getSelectionCoords(mockEditorView, selection, wrapperRect);

      expect(result).toHaveProperty('start');
      expect(result).toHaveProperty('end');
      expect(result).toHaveProperty('selTop');
      expect(result).toHaveProperty('onTop');
    });
  });

  describe('getMenuAnchor', () => {
    it('returns end.left when menu is below selection', () => {
      const coords = { start: { left: 50 }, end: { left: 150 }, onTop: false };
      expect(getMenuAnchor(coords, wrapperRect, false)).toBe(150);
    });

    it('returns start.left for LTR when menu is above and visible', () => {
      const coords = { start: { top: 100, left: 50 }, end: {}, onTop: true };
      expect(getMenuAnchor(coords, wrapperRect, false)).toBe(50);
    });

    it('returns start.right for RTL when menu is above and visible', () => {
      const coords = { start: { top: 100, right: 100 }, end: {}, onTop: true };
      expect(getMenuAnchor(coords, wrapperRect, true)).toBe(100);
    });
  });

  describe('calculateMenuPosition', () => {
    it('returns bounded left and top positions', () => {
      const coords = {
        start: { top: 100, bottom: 120, left: 50 },
        end: { top: 100, bottom: 120, left: 150 },
        selTop: 100,
        onTop: false,
      };
      const result = calculateMenuPosition(coords, wrapperRect, false);

      expect(result).toHaveProperty('left');
      expect(result).toHaveProperty('top');
      expect(result).toHaveProperty('width', 300);
      expect(result.left).toBeGreaterThanOrEqual(0);
    });
  });
});

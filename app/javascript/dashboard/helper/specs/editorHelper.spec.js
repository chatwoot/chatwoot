import {
  findSignatureInBody,
  appendSignature,
  removeSignature,
  replaceSignature,
  cleanSignature,
  extractTextFromMarkdown,
  insertAtCursor,
  findNodeToInsertImage,
  setURLWithQueryAndSize,
} from '../editorHelper';
import { EditorState } from 'prosemirror-state';
import { EditorView } from 'prosemirror-view';
import { Schema } from 'prosemirror-model';

// Define a basic ProseMirror schema
const schema = new Schema({
  nodes: {
    doc: { content: 'paragraph+' },
    paragraph: {
      content: 'text*',
      toDOM: () => ['p', 0], // Represents a paragraph as a <p> tag in the DOM.
    },
    text: {
      toDOM: node => node.text, // Represents text as its actual string value.
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

describe('findSignatureInBody', () => {
  it('returns -1 if there is no signature', () => {
    Object.keys(DOES_NOT_HAVE_SIGNATURE).forEach(key => {
      const { body, signature } = DOES_NOT_HAVE_SIGNATURE[key];
      expect(findSignatureInBody(body, signature)).toBe(-1);
    });
  });
  it('returns the index of the signature if there is one', () => {
    Object.keys(HAS_SIGNATURE).forEach(key => {
      const { body, signature } = HAS_SIGNATURE[key];
      expect(findSignatureInBody(body, signature)).toBeGreaterThan(0);
    });
  });
});

describe('appendSignature', () => {
  it('appends the signature if it is not present', () => {
    Object.keys(DOES_NOT_HAVE_SIGNATURE).forEach(key => {
      const { body, signature } = DOES_NOT_HAVE_SIGNATURE[key];
      const cleanedSignature = cleanSignature(signature);
      expect(
        appendSignature(body, signature).includes(cleanedSignature)
      ).toBeTruthy();
    });
  });
  it('does not append signature if already present', () => {
    Object.keys(HAS_SIGNATURE).forEach(key => {
      const { body, signature } = HAS_SIGNATURE[key];
      expect(appendSignature(body, signature)).toBe(body);
    });
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

describe('removeSignature', () => {
  it('does not remove signature if not present', () => {
    Object.keys(DOES_NOT_HAVE_SIGNATURE).forEach(key => {
      const { body, signature } = DOES_NOT_HAVE_SIGNATURE[key];
      expect(removeSignature(body, signature)).toBe(body);
    });
  });
  it('removes signature if present at the end', () => {
    const { body, signature } = HAS_SIGNATURE['signature at end'];
    expect(removeSignature(body, signature)).toBe('This is a test\n\n');
  });
  it('removes signature if present with spaces and new lines', () => {
    const { body, signature } =
      HAS_SIGNATURE['signature at end with spaces and new lines'];
    expect(removeSignature(body, signature)).toBe('This is a test\n\n');
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

describe('replaceSignature', () => {
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

  it('should unwrap doc nodes that are wrapped in a paragraph', () => {
    const docNode = schema.node('doc', null, [
      schema.node('paragraph', null, [schema.text('Hello')]),
    ]);

    const editorState = createEditorState();
    const editorView = new EditorView(document.body, { state: editorState });

    insertAtCursor(editorView, docNode, 0);

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

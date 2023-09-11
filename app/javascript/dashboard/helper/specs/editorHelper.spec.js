import {
  findSignatureInBody,
  appendSignature,
  removeSignature,
  replaceSignature,
  extractTextFromMarkdown,
} from '../editorHelper';

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
  signature_has_images: {
    body: 'This is a test',
    signature:
      'Testing \n![](http://localhost:3000/rails/active_storage/blobs/redirect/some-hash/image.png)',
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
      expect(appendSignature(body, signature)).toBe(
        `${body}\n\n--\n\n${signature}`
      );
    });
  });
  it('does not append signature if already present', () => {
    Object.keys(HAS_SIGNATURE).forEach(key => {
      const { body, signature } = HAS_SIGNATURE[key];
      expect(appendSignature(body, signature)).toBe(body);
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
    const { body, signature } = HAS_SIGNATURE[
      'signature at end with spaces and new lines'
    ];
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
    const { body, signature } = HAS_SIGNATURE[
      'signature at end with spaces and new lines'
    ];
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

import { findNodeToInsertImage } from '../messageEditorHelper';

describe('findNodeToInsertImage', () => {
  let mockEditorState;

  beforeEach(() => {
    mockEditorState = {
      selection: {
        $from: {
          node: jest.fn(() => ({})),
        },
        from: 0,
      },
      schema: {
        nodes: {
          image: {
            create: jest.fn(attrs => ({ type: { name: 'image' }, attrs })),
          },
          paragraph: {
            create: jest.fn((_, node) => ({
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

/**
 * Determines the appropriate node and position to insert an image in the editor.
 *
 * Based on the current editor state and the provided image URL, this function finds out the correct node (either
 * a standalone image node or an image wrapped in a paragraph) and its respective position in the editor.
 *
 * 1. If the current node is a paragraph and doesn't contain an image or text, the image is inserted directly into it.
 * 2. If the current node isn't a paragraph or it's a paragraph containing text, the image will be wrapped
 *    in a new paragraph and then inserted.
 * 3. If the current node is a paragraph containing an image, the new image will be inserted directly into it.
 *
 * @param {Object} editorState - The current state of the editor. It provides necessary details like selection, schema, etc.
 * @param {string} fileUrl - The URL of the image to be inserted into the editor.
 * @returns {Object|null} An object containing details about the node to be inserted and its position. It returns null if no image node can be created.
 * @property {Node} node - The ProseMirror node to be inserted (either an image node or a paragraph containing the image).
 * @property {number} pos - The position where the new node should be inserted in the editor.
 */

export const findNodeToInsertImage = (editorState, fileUrl) => {
  const { selection, schema } = editorState;
  const { nodes } = schema;
  const currentNode = selection.$from.node();
  const {
    type: { name: typeName },
    content: { size, content },
  } = currentNode;

  const imageNode = nodes.image.create({ src: fileUrl });

  if (!imageNode) return null;

  const isInParagraph = typeName === 'paragraph';
  const needsNewLine =
    !content.some(n => n.type.name === 'image') && size !== 0 ? 1 : 0;

  return {
    node: isInParagraph ? imageNode : nodes.paragraph.create({}, imageNode),
    pos: selection.from + needsNewLine,
  };
};

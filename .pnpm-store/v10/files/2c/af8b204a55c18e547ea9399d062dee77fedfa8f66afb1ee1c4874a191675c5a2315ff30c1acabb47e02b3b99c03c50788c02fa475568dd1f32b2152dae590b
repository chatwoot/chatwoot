import { Plugin } from "prosemirror-state";

/**
 * Check if URL is valid HTTP/HTTPS.
 * @param {string} url - URL to validate
 * @returns {boolean} True if valid HTTP/HTTPS URL
 */
function isValidImageUrl(url) {
  if (!url) return false;
  try {
    const { protocol } = new URL(url);
    return protocol === "http:" || protocol === "https:";
  } catch {
    return false;
  }
}

/**
 * Update or remove an image in the editor.
 * @param {string} oldUrl - Current image URL
 * @param {string|null} newUrl - New URL to replace with, or null to remove
 * @param {EditorView} view - ProseMirror editor view
 */
function modifyImage(oldUrl, newUrl, view) {
  const tr = view.state.tr;

  view.state.doc.descendants((node, pos) => {
    if (node.type.name === "image" && node.attrs.src === oldUrl) {
      newUrl
        ? tr.setNodeMarkup(pos, null, { ...node.attrs, src: newUrl })
        : tr.delete(pos, pos + node.nodeSize);
    }
  });

  if (tr.docChanged) view.dispatch(tr);
}

/**
 * Creates a ProseMirror plugin that handles image pasting and uploading.
 *
 * @param {Function} uploadImage - A function that takes an image URL and returns a Promise
 * that resolves to the new URL after uploading.
 * @returns {Plugin} A ProseMirror plugin that handles image pasting.
 */
const imagePastePlugin = (uploadImage) =>
  new Plugin({
    props: {
      /**
       * Handles the paste event in the editor.
       *
       * @param {EditorView} view - The ProseMirror editor view.
       * @param {Event} event - The paste event.
       * @param {Slice} slice - The ProseMirror Slice object representing the pasted content.
       */
      handlePaste(view, event, slice) {
        const valid = [];
        const invalid = [];

        // Collect image URLs
        slice.content.descendants((node) => {
          if (node.type.name === "image") {
            const url = node.attrs.src;
            const isValid = isValidImageUrl(url);
            isValid ? valid.push(url) : invalid.push(url);
          }
        });

        // Process after paste completes
        setTimeout(() => {
          // Remove invalid images
          invalid.forEach((url) => modifyImage(url, null, view));

          // Upload valid images
          valid.forEach(async (url) => {
            try {
              const newUrl = await uploadImage(url);
              modifyImage(url, newUrl, view);
            } catch (error) {
              console.error("Error uploading image:", error);
            }
          });
        }, 0);
      },
    },
  });

export default imagePastePlugin;

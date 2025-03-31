import { Plugin } from "prosemirror-state";

/**
 * Replaces an image node in the editor with a new image URL.
 *
 * @param {string} currentUrl - The current URL of the image to be replaced.
 * @param {string} newUrl - The new URL to replace the current image with.
 * @param {EditorView} view - The ProseMirror editor view.
 */
function replaceImage(currentUrl, newUrl, view) {
  view.state.doc.descendants((node, pos) => {
    if (node.type.name === "image" && node.attrs.src === currentUrl) {
      const tr = view.state.tr.setNodeMarkup(pos, null, {
        ...node.attrs,
        src: newUrl,
      });
      view.dispatch(tr);
    }
  });
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
        const imageUrls = [];
        slice.content.descendants((node) => {
          if (node.type.name === "image") {
            imageUrls.push(node.attrs.src);
          }
        });
        Promise.all(imageUrls.map(async (url) => {
          try {
            const newUrl = await uploadImage(url);
            replaceImage(url, newUrl, view);
          } catch (error) {
            console.error("Error uploading image:", error);
          }
        }));
      },
    },
  });

export default imagePastePlugin;

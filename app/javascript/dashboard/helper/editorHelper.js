import {
  messageSchema,
  MessageMarkdownTransformer,
  MessageMarkdownSerializer,
} from '@chatwoot/prosemirror-schema';
import { replaceVariablesInMessage } from '@chatwoot/utils';
import * as Sentry from '@sentry/vue';
import { FORMATTING, MARKDOWN_PATTERNS } from 'dashboard/constants/editor';
import { INBOX_TYPES, TWILIO_CHANNEL_MEDIUM } from 'dashboard/helper/inbox';
import camelcaseKeys from 'camelcase-keys';

/**
 * Extract text from markdown, and remove all images, code blocks, links, headers, bold, italic, lists etc.
 * Links will be converted to text, and not removed.
 *
 * @param {string} markdown - markdown text to be extracted
 * @returns {string} - The extracted text.
 */
export function extractTextFromMarkdown(markdown) {
  if (!markdown) return '';
  return markdown
    .replace(/```[\s\S]*?```/g, '') // Remove code blocks
    .replace(/`.*?`/g, '') // Remove inline code
    .replace(/!\[.*?\]\(.*?\)/g, '') // Remove images before removing links
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1') // Remove links but keep the text
    .replace(/#+\s*|[*_-]{1,3}/g, '') // Remove headers, bold, italic, lists etc.
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)
    .join('\n') // Trim each line & remove any lines only having spaces
    .replace(/\n{2,}/g, '\n') // Remove multiple consecutive newlines (blank lines)
    .trim(); // Trim any extra space
}

/**
 * Strip unsupported markdown formatting based on channel capabilities.
 * Uses MARKDOWN_PATTERNS from editor constants.
 *
 * @param {string} markdown - markdown text to process
 * @param {string} channelType - The channel type to check supported formatting
 * @param {boolean} cleanWhitespace - Whether to clean up extra whitespace and blank lines (default: true for signatures)
 * @returns {string} - The markdown with unsupported formatting removed
 */
export function stripUnsupportedMarkdown(
  markdown,
  channelType,
  cleanWhitespace = true
) {
  if (!markdown) return '';

  const { marks = [], nodes = [] } = FORMATTING[channelType] || {};
  const supported = [...marks, ...nodes];

  // Apply patterns from MARKDOWN_PATTERNS for unsupported types
  const result = MARKDOWN_PATTERNS.reduce((text, { type, patterns }) => {
    if (supported.includes(type)) return text;
    return patterns.reduce(
      (t, { pattern, replacement }) => t.replace(pattern, replacement),
      text
    );
  }, markdown);

  if (!cleanWhitespace) return result;

  // Clean whitespace for signatures
  return result
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)
    .join('\n')
    .replace(/\n{2,}/g, '\n')
    .trim();
}

/**
 * The delimiter used to separate the signature from the rest of the body.
 * @type {string}
 */
export const SIGNATURE_DELIMITER = '--';

/**
 * Parse and Serialize the markdown text to remove any extra spaces or new lines
 */
export function cleanSignature(signature) {
  try {
    // remove any horizontal rule tokens
    signature = signature
      .replace(/^( *\* *){3,} *$/gm, '')
      .replace(/^( *- *){3,} *$/gm, '')
      .replace(/^( *_ *){3,} *$/gm, '');

    const nodes = new MessageMarkdownTransformer(messageSchema).parse(
      signature
    );
    return MessageMarkdownSerializer.serialize(nodes);
  } catch (e) {
    // eslint-disable-next-line no-console
    console.warn(e);
    Sentry.captureException(e);
    // The parser can break on some cases
    // for example, Token type `hr` not supported by Markdown parser
    return signature;
  }
}

/**
 * Check if there's an unedited signature at the end of the body
 * If there is, return the index of the signature, If there isn't, return -1
 *
 * @param {string} body - The body to search for the signature.
 * @param {string} signature - The signature to search for.
 * @returns {number} - The index of the last occurrence of the signature in the body, or -1 if not found.
 */
export function findSignatureInBody(body, signature) {
  const trimmedBody = body.trimEnd();
  const cleanedSignature = cleanSignature(signature);

  // check if body ends with signature
  if (trimmedBody.endsWith(cleanedSignature)) {
    return body.lastIndexOf(cleanedSignature);
  }

  return -1;
}

/**
 * Gets the effective channel type for formatting purposes.
 * For Twilio channels, returns WhatsApp or Twilio based on medium.
 *
 * @param {string} channelType - The channel type
 * @param {string} medium - Optional. The medium for Twilio channels (sms/whatsapp)
 * @returns {string} - The effective channel type for formatting
 */
export function getEffectiveChannelType(channelType, medium) {
  if (channelType === INBOX_TYPES.TWILIO) {
    return medium === TWILIO_CHANNEL_MEDIUM.WHATSAPP
      ? INBOX_TYPES.WHATSAPP
      : INBOX_TYPES.TWILIO;
  }
  return channelType;
}

/**
 * Appends the signature to the body, separated by the signature delimiter.
 * Automatically strips unsupported formatting based on channel capabilities.
 *
 * @param {string} body - The body to append the signature to.
 * @param {string} signature - The signature to append.
 * @param {Object} settings - The signature settings (position, separator).
 * @returns {string} - The body with the signature appended.
 */
export function appendSignature(body, signature, settings = {}) {
  const position = settings.position || 'top';
  const separator = settings.separator || 'blank';
  const cleanedSignature = cleanSignature(signature);
  // if signature is already present, return body
  if (findSignatureInBody(body, cleanedSignature).index > -1) {
    return body;
  }

  const delimiter =
    {
      blank: '\n\n',
      '--': '\n\n--\n\n',
    }[separator] || separator;

  if (position === 'top') {
    return `${cleanedSignature}${delimiter}${body.trimStart()}`;
  }
  return `${body.trimEnd()}${delimiter}${cleanedSignature}`;
}

/**
 * Removes the signature from the body, along with the signature delimiter.
 * Tries multiple signature variants: original, channel-stripped, and fully stripped.
 *
 * @param {string} body - The body to remove the signature from.
 * @param {string} signature - The signature to remove.
 * @param {string} channelType - Optional. The effective channel type for channel-specific stripping.
 * @returns {string} - The body with the signature removed.
 */
export function removeSignature(body, signature, channelType) {
  // Build unique list of signature variants to try
  const channelStripped = channelType
    ? cleanSignature(stripUnsupportedMarkdown(signature, channelType))
    : null;
  const signaturesToTry = [
    cleanSignature(signature),
    channelStripped,
    cleanSignature(extractTextFromMarkdown(signature)),
  ].filter((sig, i, arr) => sig && arr.indexOf(sig) === i); // Remove nulls and duplicates

  // Find the first matching signature
  const signatureIndex = signaturesToTry.reduce(
    (index, sig) => (index === -1 ? findSignatureInBody(body, sig) : index),
    -1
  );

  // no need to trim the ends here, because it will simply be removed in the next method
  let newBody = body;

  // if signature is present, remove it and trim it
  // trimming will ensure any spaces or new lines before the signature are removed
  // This means we will have the delimiter at the end
  if (signatureIndex > -1) {
    newBody = newBody.substring(0, signatureIndex).trimEnd();
  }

  // Remove delimiter if it's at the end
  if (newBody.endsWith(SIGNATURE_DELIMITER)) {
    // if the delimiter is at the end, remove it
    newBody = newBody.slice(0, -SIGNATURE_DELIMITER.length);
  }

  return newBody;
}

/**
 * Replaces the old signature with the new signature.
 * If the old signature is not present, it will append the new signature.
 *
 * @param {string} body - The body to replace the signature in.
 * @param {string} oldSignature - The signature to replace.
 * @param {string} newSignature - The signature to replace the old signature with.
 * @returns {string} - The body with the old signature replaced with the new signature.
 *
 */
export function replaceSignature(body, oldSignature, newSignature) {
  const withoutSignature = removeSignature(body, oldSignature);
  return appendSignature(withoutSignature, newSignature);
}

/**
 * Scrolls the editor view into current cursor position
 *
 * @param {EditorView} view - The Prosemirror EditorView
 *
 */
export const scrollCursorIntoView = view => {
  // Get the current selection's head position (where the cursor is).
  const pos = view.state.selection.head;

  // Get the corresponding DOM node for that position.
  const domAtPos = view.domAtPos(pos);
  const node = domAtPos.node;

  // Scroll the node into view.
  if (node && node.scrollIntoView) {
    node.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }
};

/**
 * Returns a transaction that inserts a node into editor at the given position
 * Has an optional param 'content' to check if the
 *
 * @param {Node} node - The prosemirror node that needs to be inserted into the editor
 * @param {number} from - Position in the editor where the node needs to be inserted
 * @param {number} to - Position in the editor where the node needs to be replaced
 *
 */
export function insertAtCursor(editorView, node, from, to) {
  if (!editorView) {
    return undefined;
  }

  // This is a workaround to prevent inserting content into new line rather than on the exiting line
  // If the node is of type 'doc' and has only one child which is a paragraph,
  // then extract its inline content to be inserted as inline.
  const isWrappedInParagraph =
    node.type.name === 'doc' &&
    node.childCount === 1 &&
    node.firstChild.type.name === 'paragraph';

  if (isWrappedInParagraph) {
    node = node.firstChild.content;
  }

  let tr;
  if (to) {
    tr = editorView.state.tr.replaceWith(from, to, node).insertText(` `);
  } else {
    tr = editorView.state.tr.insert(from, node);
  }
  const state = editorView.state.apply(tr);
  editorView.updateState(state);
  editorView.focus();

  return state;
}

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

/**
 * Set URL with query and size.
 *
 * @param {Object} selectedImageNode - The current selected node.
 * @param {Object} size - The size to set.
 * @param {Object} editorView - The editor view.
 */
export function setURLWithQueryAndSize(selectedImageNode, size, editorView) {
  if (selectedImageNode) {
    // Create and apply the transaction
    const tr = editorView.state.tr.setNodeMarkup(
      editorView.state.selection.from,
      null,
      {
        src: selectedImageNode.src,
        height: size.height,
      }
    );

    if (tr.docChanged) {
      editorView.dispatch(tr);
    }
  }
}

/**
 * Strips unsupported markdown formatting from content based on the editor schema.
 * This ensures canned responses with rich formatting can be inserted into channels
 * that don't support certain formatting (e.g., API channels don't support bold).
 *
 * @param {string} content - The markdown content to sanitize
 * @param {Object} schema - The ProseMirror schema with supported marks and nodes
 * @returns {string} - Content with unsupported formatting stripped
 */
export function stripUnsupportedFormatting(content, schema) {
  if (!content || typeof content !== 'string') return content;
  if (!schema) return content;

  let sanitizedContent = content;

  // Get supported marks and nodes from the schema
  // Note: ProseMirror uses snake_case internally (code_block, bullet_list, etc.)
  // but our FORMATTING constant uses camelCase (codeBlock, bulletList, etc.)
  // We use camelcase-keys to normalize node names for comparison
  const supportedMarks = Object.keys(schema.marks || {});
  const nodeKeys = Object.keys(schema.nodes || {});
  const nodeKeysObj = Object.fromEntries(nodeKeys.map(k => [k, true]));
  const supportedNodes = Object.keys(camelcaseKeys(nodeKeysObj));

  // Process each formatting type in order (codeBlock before code is important!)
  MARKDOWN_PATTERNS.forEach(({ type, patterns }) => {
    // Check if this format type is supported by the schema
    const isMarkSupported = supportedMarks.includes(type);
    const isNodeSupported = supportedNodes.includes(type);

    // If not supported, strip the formatting
    if (!isMarkSupported && !isNodeSupported) {
      patterns.forEach(({ pattern, replacement }) => {
        sanitizedContent = sanitizedContent.replace(pattern, replacement);
      });
    }
  });

  return sanitizedContent;
}

/**
 * Content Node Creation Helper Functions for
 * - mention
 * - canned response
 * - variable
 * - emoji
 */

/**
 * Centralized node creation function that handles the creation of different types of nodes based on the specified type.
 * @param {Object} editorView - The editor view instance.
 * @param {string} nodeType - The type of node to create ('mention', 'cannedResponse', 'variable', 'emoji').
 * @param {Object|string} content - The content needed to create the node, which varies based on node type.
 * @returns {Object|null} - The created ProseMirror node or null if the type is not supported.
 */
const createNode = (editorView, nodeType, content) => {
  const { state } = editorView;
  switch (nodeType) {
    case 'mention': {
      const mentionType = content.type || 'user';
      const displayName = content.displayName || content.name;

      const mentionNode = state.schema.nodes.mention.create({
        userId: content.id,
        userFullName: displayName,
        mentionType,
      });

      return mentionNode;
    }
    case 'cannedResponse': {
      // Strip unsupported formatting before parsing to ensure content can be inserted
      // into channels that don't support certain markdown features (e.g., API channels)
      const sanitizedContent = stripUnsupportedFormatting(
        content,
        state.schema
      );
      return new MessageMarkdownTransformer(state.schema).parse(
        sanitizedContent
      );
    }
    case 'variable':
      return state.schema.text(`{{${content}}}`);
    case 'emoji':
      return state.schema.text(content);
    case 'tool': {
      return state.schema.nodes.tools.create({
        id: content.id,
        name: content.title,
      });
    }
    default:
      return null;
  }
};

/**
 * Object mapping types to their respective node creation functions.
 */
const nodeCreators = {
  mention: (editorView, content, from, to) => ({
    node: createNode(editorView, 'mention', content),
    from,
    to,
  }),
  cannedResponse: (editorView, content, from, to, variables) => {
    const updatedMessage = replaceVariablesInMessage({
      message: content,
      variables,
    });
    const node = createNode(editorView, 'cannedResponse', updatedMessage);
    return {
      node,
      from: node.textContent === updatedMessage ? from : from - 1,
      to,
    };
  },
  variable: (editorView, content, from, to) => ({
    node: createNode(editorView, 'variable', content),
    from,
    to,
  }),
  emoji: (editorView, content, from, to) => ({
    node: createNode(editorView, 'emoji', content),
    from,
    to,
  }),
  tool: (editorView, content, from, to) => ({
    node: createNode(editorView, 'tool', content),
    from,
    to,
  }),
};

/**
 * Retrieves a content node based on the specified type and content, using a functional approach to select the appropriate node creation function.
 * @param {Object} editorView - The editor view instance.
 * @param {string} type - The type of content node to create ('mention', 'cannedResponse', 'variable', 'emoji').
 * @param {string|Object} content - The content to be transformed into a node.
 * @param {Object} range - An object containing 'from' and 'to' properties indicating the range in the document where the node should be placed.
 * @param {Object} variables - Optional. Variables to replace in the content, used for 'cannedResponse' type.
 * @returns {Object} - An object containing the created node and the updated 'from' and 'to' positions.
 */
export const getContentNode = (
  editorView,
  type,
  content,
  { from, to },
  variables
) => {
  const creator = nodeCreators[type];
  return creator
    ? creator(editorView, content, from, to, variables)
    : { node: null, from, to };
};

/**
 * Get the formatting configuration for a specific channel type.
 * Returns the appropriate marks, nodes, and menu items for the editor.
 * TODO: We're hiding captain, enable it back when we add selection improvements
 *
 * @param {string} channelType - The channel type (e.g., 'Channel::FacebookPage', 'Channel::WebWidget')
 * @returns {Object} The formatting configuration with marks, nodes, and menu properties
 */
export function getFormattingForEditor(channelType, showCaptain = false) {
  const formatting = FORMATTING[channelType] || FORMATTING['Context::Default'];
  return {
    ...formatting,
    menu: showCaptain
      ? formatting.menu
      : formatting.menu.filter(item => item !== 'copilot'),
  };
}

/**
 * Menu Positioning Helpers
 * Handles floating menu bar positioning for text selection in the editor.
 */

const MENU_CONFIG = { H: 46, W: 300, GAP: 10 };

/**
 * Calculate selection coordinates with bias to handle line-wraps correctly.
 * @param {EditorView} editorView - ProseMirror editor view
 * @param {Selection} selection - Current text selection
 * @param {DOMRect} rect - Container bounding rect
 * @returns {{start: Object, end: Object, selTop: number, onTop: boolean}}
 */
export function getSelectionCoords(editorView, selection, rect) {
  const start = editorView.coordsAtPos(selection.from, 1);
  const end = editorView.coordsAtPos(selection.to, -1);

  const selTop = Math.min(start.top, end.top);
  const spaceAbove = selTop - rect.top;
  const onTop =
    spaceAbove > MENU_CONFIG.H + MENU_CONFIG.GAP || end.bottom > rect.bottom;

  return { start, end, selTop, onTop };
}

/**
 * Calculate anchor position based on selection visibility and RTL direction.
 * @param {Object} coords - Selection coordinates from getSelectionCoords
 * @param {DOMRect} rect - Container bounding rect
 * @param {boolean} isRtl - Whether text direction is RTL
 * @returns {number} Anchor x-position for menu
 */
export function getMenuAnchor(coords, rect, isRtl) {
  const { start, end, onTop } = coords;

  if (!onTop) return end.left;

  // If start of selection is visible, align to text. Else stick to container edge.
  if (start.top >= rect.top) return isRtl ? start.right : start.left;

  return isRtl ? rect.right - MENU_CONFIG.GAP : rect.left + MENU_CONFIG.GAP;
}

/**
 * Calculate final menu position (left, top) within container bounds.
 * @param {Object} coords - Selection coordinates from getSelectionCoords
 * @param {DOMRect} rect - Container bounding rect
 * @param {boolean} isRtl - Whether text direction is RTL
 * @returns {{left: number, top: number, width: number}}
 */
export function calculateMenuPosition(coords, rect, isRtl) {
  const { start, end, selTop, onTop } = coords;

  const anchor = getMenuAnchor(coords, rect, isRtl);

  // Calculate Left: shift by width if RTL, then make relative to container
  const rawLeft = (isRtl ? anchor - MENU_CONFIG.W : anchor) - rect.left;

  // Ensure menu stays within container bounds
  const left = Math.min(Math.max(0, rawLeft), rect.width - MENU_CONFIG.W);

  // Calculate Top: align to selection or bottom of selection
  const top = onTop
    ? Math.max(-26, selTop - rect.top - MENU_CONFIG.H - MENU_CONFIG.GAP)
    : Math.max(start.bottom, end.bottom) - rect.top + MENU_CONFIG.GAP;
  return { left, top, width: MENU_CONFIG.W };
}

/* End Menu Positioning Helpers */

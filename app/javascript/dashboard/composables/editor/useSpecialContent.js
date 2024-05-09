import { replaceVariablesInMessage } from '@chatwoot/utils';
import {
  MessageMarkdownTransformer,
  messageSchema,
} from '@chatwoot/prosemirror-schema';

/**
 * Provides utility functions for creating special content nodes (mentions, canned responses, variables) in the editor state.
 *
 * @module useSpecialContent
 * @returns {Object} - An object containing the `getContentNode` function.
 */
export default function useSpecialContent() {
  /**
   * Creates a mention node for the editor state
   * @param {Object} editorView - The editor view instance
   * @param {Object} content - The content object containing user id and name
   * @param {number} from - The start position of the mention in the document
   * @param {number} to - The end position of the mention in the document
   * @returns {Object} - The created mention node and the updated from and to positions
   */
  const getMentionNode = (editorView, content, from, to) => {
    const node = editorView.state.schema.nodes.mention.create({
      userId: content.id,
      userFullName: content.name,
    });
    return { node, from, to };
  };

  /**
   * Creates a canned response node for the editor state
   * @param {Object} editorView - The editor view instance
   * @param {string} content - The canned response content
   * @param {number} from - The start position of the canned response in the document
   * @param {number} to - The end position of the canned response in the document
   * @param {Object} variables - The variables to replace in the canned response
   * @returns {Object} - The created canned response node and the updated from and to positions
   */
  const getCannedResponseNode = (editorView, content, from, to, variables) => {
    const updatedMessage = replaceVariablesInMessage({
      message: content,
      variables: variables,
    });

    const node = new MessageMarkdownTransformer(messageSchema).parse(
      updatedMessage
    );

    from = node.textContent === updatedMessage ? from : from - 1;

    return { node, from, to };
  };

  /**
   * Creates a variable node for the editor state
   * @param {Object} editorView - The editor view instance
   * @param {string} content - The variable content
   * @param {number} from - The start position of the variable in the document
   * @param {number} to - The end position of the variable in the document
   * @returns {Object} - The created variable node and the updated from and to positions
   */
  const getVariableNode = (editorView, content, from, to) => {
    const node = editorView.state.schema.text(`{{${content}}}`);
    return { node, from, to };
  };

  /**
   * Creates a content node based on the type (mention, canned response, or variable)
   * @param {Object} editorView - The editor view instance
   * @param {string} type - The type of content (mention, cannedResponse, or variable)
   * @param {string|Object} content - The content to create the node from
   * @param {Object} range - The range object containing the from and to positions
   * @param {Object} variables - The variables to replace in the canned response (optional)
   * @returns {Object} - The created content node and the updated from and to positions
   */
  const getContentNode = (editorView, type, content, range, variables) => {
    const methodMap = {
      mention: getMentionNode,
      cannedResponse: getCannedResponseNode,
      variable: getVariableNode,
    };

    if (!methodMap[type]) {
      return { node: null, from: range.from, to: range.to };
    }

    let { node, from, to } = methodMap[type](
      editorView,
      content,
      range.from,
      range.to,
      variables
    );

    return { node, from, to };
  };

  return {
    getContentNode,
  };
}

import { replaceVariablesInMessage } from '@chatwoot/utils';
import {
  MessageMarkdownTransformer,
  messageSchema,
} from '@chatwoot/prosemirror-schema';

export default function useSpecialContent() {
  const getMentionNode = (editorView, content, from, to) => {
    const node = editorView.state.schema.nodes.mention.create({
      userId: content.id,
      userFullName: content.name,
    });
    return { node, from, to };
  };

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

  const getVariableNode = (editorView, content, from, to) => {
    const node = editorView.state.schema.text(`{{${content}}}`);
    return { node, from, to };
  };

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

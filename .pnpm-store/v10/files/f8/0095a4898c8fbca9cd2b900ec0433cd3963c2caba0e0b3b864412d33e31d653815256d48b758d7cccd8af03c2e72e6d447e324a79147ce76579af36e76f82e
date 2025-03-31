import { history } from "prosemirror-history";
import { Plugin } from "prosemirror-state";
import { dropCursor } from "prosemirror-dropcursor";
import { gapCursor } from "prosemirror-gapcursor";
import { menuBar } from "prosemirror-menu";

import Placeholder from "./Placeholder";
import {
  listInputRules,
  linksInputRules,
  hrInputRules,
  blocksInputRule,
  baseKeyMaps,
  textFormattingInputRules,
} from "./rules/index";
import buildMenuOptions from "./menu/menuOptions";

export { EditorState, Selection } from "prosemirror-state";
export { EditorView } from "prosemirror-view";

export { MessageMarkdownTransformer } from "./schema/markdown/messageParser";
export { ArticleMarkdownTransformer } from "./schema/markdown/articleParser";

export { ArticleMarkdownSerializer } from "./schema/markdown/articleSerializer";
export { MessageMarkdownSerializer } from "./schema/markdown/messageSerializer";

export { fullSchema } from "./schema/article";
export { messageSchema } from "./schema/message";

export const buildEditor = ({
  schema,
  placeholder,
  methods: { onImageUpload } = {},
  plugins = [],
  enabledMenuOptions,
}) => [
  ...(plugins || []),
  history(),
  baseKeyMaps(schema),
  blocksInputRule(schema),
  textFormattingInputRules(schema),
  linksInputRules(schema),
  hrInputRules(schema),
  listInputRules(schema),
  dropCursor(),
  gapCursor(),
  Placeholder(placeholder),
  menuBar({
    floating: true,
    content: buildMenuOptions(schema, {
      enabledMenuOptions,
      onImageUpload,
    }),
  }),
  new Plugin({
    props: {
      attributes: { class: "ProseMirror-woot-style" },
    },
  }),
];

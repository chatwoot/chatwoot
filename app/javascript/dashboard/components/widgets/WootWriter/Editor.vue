<template>
  <div ref="editor" class="editor-root"></div>
</template>

<script>
import { EditorState } from 'prosemirror-state';
import { EditorView } from 'prosemirror-view';
import {
  schema,
  defaultMarkdownParser,
  defaultMarkdownSerializer,
  MarkdownParser,
  MarkdownSerializer,
} from 'prosemirror-markdown';
import { wootWriterSetup } from '@chatwoot/prosemirror-schema';

const TYPING_INDICATOR_IDLE_TIME = 4000;
import { Schema } from 'prosemirror-model';

const mentionParser = () => ({
  node: 'mention',
  getAttrs: ({ mention }) => {
    const { userId, userFullName } = mention;
    return { userId, userFullName };
  },
});

const markdownSerializer = () => (state, node) => {
  const userFullName = state.esc(node.attrs.userFullName || '');
  const uri = state.esc(
    `mention://${node.attrs.userFullName}/${node.attrs.userId}`
  );
  state.write(`@[${userFullName}](${uri})`);
};

const addMentionsToMarkdownSerializer = serializer =>
  new MarkdownSerializer(
    { mention: markdownSerializer(), ...serializer.nodes },
    serializer.marks
  );

const mentionNode = {
  attrs: { userFullName: { default: '' }, userId: { default: '' } },
  group: 'inline',
  inline: true,
  selectable: true,
  draggable: true,
  atom: true,
  toDOM: node => [
    'span',
    {
      class: 'prosemirror-mention-node',
      'mention-user-id': node.attrs.userId,
      'mention-user-full-name': node.attrs.userFullName,
    },
    `@${node.attrs.userFullName}`,
  ],
  parseDOM: [
    {
      tag: 'span[mention-user-id][mention-user-full-name]',
      getAttrs: dom => {
        const userId = dom.getAttribute('mention-user-id');
        const userFullName = dom.getAttribute('mention-user-full-name');
        return { userId, userFullName };
      },
    },
  ],
};

const addMentionNodes = nodes => nodes.append({ mention: mentionNode });

const schemaWithMentions = new Schema({
  nodes: addMentionNodes(schema.spec.nodes),
  marks: schema.spec.marks,
});

const addMentionsToMarkdownParser = parser => {
  return new MarkdownParser(schemaWithMentions, parser.tokenizer, {
    ...parser.tokens,
    mention: mentionParser(),
  });
};

const createState = (content, placeholder) =>
  EditorState.create({
    doc: addMentionsToMarkdownParser(defaultMarkdownParser).parse(content),
    plugins: wootWriterSetup({ schema: schemaWithMentions, placeholder }),
  });

export default {
  name: 'WootMessageEditor',
  props: {
    value: { type: String, default: '' },
    placeholder: { type: String, default: '' },
  },
  data() {
    return {
      lastValue: null,
    };
  },
  watch: {
    value(newValue) {
      if (newValue !== this.lastValue) {
        this.state = createState(newValue, this.placeholder);
        this.view.updateState(this.state);
      }
    },
  },
  created() {
    this.state = createState(this.value, this.placeholder);
  },
  mounted() {
    this.view = new EditorView(this.$refs.editor, {
      state: this.state,
      dispatchTransaction: tx => {
        this.state = this.state.apply(tx);
        this.view.updateState(this.state);
        this.lastValue = addMentionsToMarkdownSerializer(
          defaultMarkdownSerializer
        ).serialize(this.state.doc);
        console.log(tx, this.state, this.lastValue);
        this.$emit('input', this.lastValue);
      },
      handleDOMEvents: {
        keyup: () => {
          this.onKeyup();
        },
        focus: () => {
          this.onFocus();
        },
        blur: () => {
          this.onBlur();
        },
      },
    });
    console.log(this.view, this.$refs.editor);
  },
  methods: {
    resetTyping() {
      this.$emit('typing-off');
      this.idleTimer = null;
    },
    turnOffIdleTimer() {
      if (this.idleTimer) {
        clearTimeout(this.idleTimer);
      }
    },
    onKeyup() {
      if (!this.idleTimer) {
        this.$emit('typing-on');
      }
      this.turnOffIdleTimer();
      this.idleTimer = setTimeout(
        () => this.resetTyping(),
        TYPING_INDICATOR_IDLE_TIME
      );
    },
    onBlur() {
      this.turnOffIdleTimer();
      this.resetTyping();
      this.$emit('blur');
    },
    onFocus() {
      this.$emit('focus');
    },
  },
};
</script>

<style lang="scss">
.ProseMirror-menubar-wrapper {
  display: flex;
  flex-direction: column;

  > .ProseMirror {
    padding: 0;
  }
}

.editor-root {
  width: 100%;
}

.ProseMirror-woot-style {
  min-height: 8rem;
  max-height: 12rem;
  overflow: auto;
}
</style>

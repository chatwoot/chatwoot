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
} from 'prosemirror-markdown';
import { wootWriterSetup } from '@chatwoot/prosemirror-schema';

const createState = (content, placeholder) =>
  EditorState.create({
    doc: defaultMarkdownParser.parse(content),
    plugins: wootWriterSetup({ schema, placeholder }),
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
        this.lastValue = defaultMarkdownSerializer.serialize(this.state.doc);
        this.$emit('input', this.lastValue);
      },
    });
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

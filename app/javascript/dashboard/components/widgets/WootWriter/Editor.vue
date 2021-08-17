<template>
  <div class="editor-root" :class="{ 'without-format-menu': !isFormatMode }">
    <tag-agents
      v-if="showUserMentions && isPrivate"
      :search-key="mentionSearchKey"
      @click="insertMentionNode"
    />
    <canned-response
      v-if="showCannedMenu"
      :search-key="cannedSearchTerm"
      @click="insertTextIntoEditor"
    />
    <div id="woot-editor" ref="editor"></div>
  </div>
</template>

<script>
import {
  plainTextParser,
  addMentionsToMarkdownSerializer,
  addMentionsToMarkdownParser,
  defaultPlainTextSchema,
  schemaWithMentions,
} from '@chatwoot/prosemirror-schema/src/mentions/schema';

import {
  suggestionsPlugin,
  triggerCharacters,
} from '@chatwoot/prosemirror-schema/src/mentions/plugin';
import {
  wootWriterSetup,
  EditorState,
  EditorView,
} from '@chatwoot/prosemirror-schema';
import { Selection } from 'prosemirror-state';

import TagAgents from '../conversation/TagAgents';
import CannedResponse from '../conversation/CannedResponse';

const TYPING_INDICATOR_IDLE_TIME = 4000;

import '@chatwoot/prosemirror-schema/src/woot-editor.css';

const createState = (
  content,
  placeholder,
  plugins = [],
  isFormatMode = false
) => {
  const schema = isFormatMode ? schemaWithMentions : defaultPlainTextSchema;
  const parser = isFormatMode
    ? addMentionsToMarkdownParser()
    : plainTextParser();

  const htmlNode = document.createElement('span');
  htmlNode.innerHTML = content;

  const parsable = isFormatMode ? content : htmlNode;
  const doc = parser.parse(parsable);

  return EditorState.create({
    doc,
    plugins: wootWriterSetup({
      schema,
      placeholder,
      plugins,
    }),
  });
};

export default {
  name: 'WootMessageEditor',
  components: { TagAgents, CannedResponse },
  props: {
    value: { type: String, default: '' },
    placeholder: { type: String, default: '' },
    isPrivate: { type: Boolean, default: false },
    isFormatMode: { type: Boolean, default: false },
  },
  data() {
    return {
      lastValue: null,
      showUserMentions: false,
      showCannedMenu: false,
      mentionSearchKey: '',
      cannedSearchTerm: '',
      editorView: null,
      range: null,
      view: null,
    };
  },
  computed: {
    plugins() {
      return [
        suggestionsPlugin({
          matcher: triggerCharacters('@'),
          onEnter: args => {
            this.showUserMentions = true;
            this.range = args.range;
            this.editorView = args.view;
            return false;
          },
          onChange: args => {
            this.editorView = args.view;
            this.range = args.range;

            this.mentionSearchKey = args.text.replace('@', '');
            return false;
          },
          onExit: () => {
            this.mentionSearchKey = '';
            this.showUserMentions = false;
            this.editorView = null;
            return false;
          },
          onKeyDown: ({ event }) => {
            return event.keyCode === 13 && this.showUserMentions;
          },
        }),
        suggestionsPlugin({
          matcher: triggerCharacters('/'),
          suggestionClass: '',
          onEnter: args => {
            if (this.isPrivate) {
              return false;
            }
            this.showCannedMenu = true;
            this.range = args.range;
            this.editorView = args.view;
            return false;
          },
          onChange: args => {
            this.editorView = args.view;
            this.range = args.range;

            this.cannedSearchTerm = args.text.replace('/', '');
            return false;
          },
          onExit: () => {
            this.cannedSearchTerm = '';
            this.showCannedMenu = false;
            this.editorView = null;
            return false;
          },
          onKeyDown: ({ event }) => {
            return event.keyCode === 13 && this.showCannedMenu;
          },
        }),
      ];
    },
  },
  watch: {
    showUserMentions(updatedValue) {
      this.$emit('toggle-user-mention', this.isPrivate && updatedValue);
    },
    showCannedMenu(updatedValue) {
      this.$emit('toggle-canned-menu', !this.isPrivate && updatedValue);
    },
    value(newValue = '') {
      if (newValue !== this.lastValue) {
        const { tr } = this.state;
        if (this.isFormatMode) {
          this.state = createState(
            newValue,
            this.placeholder,
            this.plugins,
            this.isFormatMode
          );
        } else {
          tr.insertText(newValue, 0, tr.doc.content.size);
          this.state = this.view.state.apply(tr);
        }
        this.view.updateState(this.state);
      }
    },
    isFormatMode() {
      this.view.destroy();
      this.state = createState(
        this.value,
        this.placeholder,
        this.plugins,
        this.isFormatMode
      );
      this.initView();

      this.view.updateState(this.state);
      this.setFocusToLast();
    },
  },
  created() {
    this.state = createState(
      this.value,
      this.placeholder,
      this.plugins,
      this.isFormatMode
    );
  },
  mounted() {
    this.initView();
  },
  methods: {
    initView() {
      this.view = new EditorView(this.$refs.editor, {
        state: this.state,
        dispatchTransaction: tx => {
          this.state = this.state.apply(tx);
          this.emitOnChange();
        },
        transformPastedHTML: pastedHTML => {
          if (!this.isFormatMode) return '';
          return pastedHTML;
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
      // TODO - 07/2021
      // This is a fix for converting the html pasted into editor to plain text.
      // There could be a solution with https://prosemirror.net/docs/ref/#view.EditorProps.handlePaste
      const wootWriterDOM = document.querySelector('[contenteditable]');
      wootWriterDOM.addEventListener('paste', e => {
        if (this.isFormatMode) return;
        e.preventDefault();
        const text = e.clipboardData.getData('text/plain');
        document.execCommand('insertText', false, text);
      });
    },
    insertMentionNode(mentionItem) {
      if (!this.view) {
        return null;
      }
      const node = this.view.state.schema.nodes.mention.create({
        userId: mentionItem.key,
        userFullName: mentionItem.label,
      });

      const tr = this.view.state.tr.replaceWith(
        this.range.from,
        this.range.to,
        node
      );
      this.state = this.view.state.apply(tr);
      return this.emitOnChange();
    },

    insertTextIntoEditor(cannedItem) {
      if (!this.view) {
        return null;
      }

      const tr = this.view.state.tr.insertText(
        cannedItem,
        this.range.from,
        this.range.to
      );
      this.state = this.view.state.apply(tr);
      return this.emitOnChange();
    },

    emitOnChange() {
      this.view.updateState(this.state);
      this.lastValue = addMentionsToMarkdownSerializer().serialize(
        this.state.doc
      );
      this.$emit('input', this.lastValue);
    },
    hideMentions() {
      this.showUserMentions = false;
    },
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
    setFocusToLast() {
      const selection = Selection.atEnd(this.view.docView.node);
      const tr = this.view.state.tr.setSelection(selection);
      this.state = this.view.state.apply(tr);
      this.view.updateState(this.state);

      this.view.focus();
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
    word-break: break-word;
  }
}

.editor-root {
  width: 100%;
}

.without-format-menu {
  .ProseMirror-menubar {
    display: none;
  }
  .ProseMirror-woot-style {
    padding-top: var(--space-small);
  }
}

.ProseMirror-woot-style {
  min-height: 8rem;
  max-height: 12rem;
  overflow: auto;

  * {
    font-size: var(--font-size-default);
  }
}

.is-private {
  .prosemirror-mention-node {
    font-weight: var(--font-weight-medium);
    background: var(--s-50);
    color: var(--s-900);
    padding: 0 var(--space-smaller);
  }
}

.editor-wrap {
  margin-bottom: var(--space-normal);
}

.message-editor {
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-normal);
  padding: 0 var(--space-slab);
  margin-bottom: 0;
}

.editor_warning {
  border: 1px solid var(--r-400);
}

.editor-warning__message {
  color: var(--r-400);
  font-weight: var(--font-weight-normal);
  padding: var(--space-smaller) 0 0 0;
}
</style>

<template>
  <div class="editor-root">
    <tag-agents
      v-if="showUserMentions && isPrivate"
      :search-key="mentionSearchKey"
      @click="insertMentionNode"
    />
    <canned-response
      v-if="shouldShowCannedResponses"
      :search-key="cannedSearchTerm"
      @click="insertCannedResponse"
    />
    <variable-list
      v-if="shouldShowVariables"
      :search-key="variableSearchTerm"
      @click="insertVariable"
    />
    <div ref="editor" />
  </div>
</template>

<script>
import {
  messageSchema,
  wootMessageWriterSetup,
  EditorView,
  MessageMarkdownTransformer,
  MessageMarkdownSerializer,
  EditorState,
  Selection,
} from '@chatwoot/prosemirror-schema';
import {
  suggestionsPlugin,
  triggerCharacters,
} from '@chatwoot/prosemirror-schema/src/mentions/plugin';

import TagAgents from '../conversation/TagAgents';
import CannedResponse from '../conversation/CannedResponse';
import VariableList from '../conversation/VariableList';

const TYPING_INDICATOR_IDLE_TIME = 4000;

import {
  hasPressedEnterAndNotCmdOrShift,
  hasPressedCommandAndEnter,
  hasPressedAltAndPKey,
  hasPressedAltAndLKey,
} from 'shared/helpers/KeyboardHelpers';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import { isEditorHotKeyEnabled } from 'dashboard/mixins/uiSettings';
import { replaceVariablesInMessage } from '@chatwoot/utils';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';

const createState = (content, placeholder, plugins = []) => {
  return EditorState.create({
    doc: new MessageMarkdownTransformer(messageSchema).parse(content),
    plugins: wootMessageWriterSetup({
      schema: messageSchema,
      placeholder,
      plugins,
    }),
  });
};

export default {
  name: 'WootMessageEditor',
  components: { TagAgents, CannedResponse, VariableList },
  mixins: [eventListenerMixins, uiSettingsMixin],
  props: {
    value: { type: String, default: '' },
    editorId: { type: String, default: '' },
    placeholder: { type: String, default: '' },
    isPrivate: { type: Boolean, default: false },
    enableSuggestions: { type: Boolean, default: true },
    overrideLineBreaks: { type: Boolean, default: false },
    updateSelectionWith: { type: String, default: '' },
    enableVariables: { type: Boolean, default: false },
    enableCannedResponses: { type: Boolean, default: true },
    variables: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      showUserMentions: false,
      showCannedMenu: false,
      showVariables: false,
      mentionSearchKey: '',
      cannedSearchTerm: '',
      variableSearchTerm: '',
      editorView: null,
      range: null,
      state: undefined,
    };
  },
  computed: {
    contentFromEditor() {
      return MessageMarkdownSerializer.serialize(this.editorView.state.doc);
    },
    shouldShowVariables() {
      return this.enableVariables && this.showVariables && !this.isPrivate;
    },
    shouldShowCannedResponses() {
      return (
        this.enableCannedResponses && this.showCannedMenu && !this.isPrivate
      );
    },
    plugins() {
      if (!this.enableSuggestions) {
        return [];
      }

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
            return false;
          },
          onKeyDown: ({ event }) => {
            return event.keyCode === 13 && this.showCannedMenu;
          },
        }),
        suggestionsPlugin({
          matcher: triggerCharacters('{{'),
          suggestionClass: '',
          onEnter: args => {
            if (this.isPrivate) {
              return false;
            }
            this.showVariables = true;
            this.range = args.range;
            this.editorView = args.view;
            return false;
          },
          onChange: args => {
            this.editorView = args.view;
            this.range = args.range;

            this.variableSearchTerm = args.text.replace('{{', '');
            return false;
          },
          onExit: () => {
            this.variableSearchTerm = '';
            this.showVariables = false;
            return false;
          },
          onKeyDown: ({ event }) => {
            return event.keyCode === 13 && this.showVariables;
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
    showVariables(updatedValue) {
      this.$emit('toggle-variables-menu', !this.isPrivate && updatedValue);
    },
    value(newValue = '') {
      if (newValue !== this.contentFromEditor) {
        this.reloadState();
      }
    },
    editorId() {
      this.showCannedMenu = false;
      this.cannedSearchTerm = '';
      this.reloadState();
    },
    isPrivate() {
      this.reloadState();
    },

    updateSelectionWith(newValue, oldValue) {
      if (!this.editorView) {
        return null;
      }
      if (newValue !== oldValue) {
        if (this.updateSelectionWith !== '') {
          const node = this.editorView.state.schema.text(
            this.updateSelectionWith
          );
          const tr = this.editorView.state.tr.replaceSelectionWith(node);
          this.editorView.focus();
          this.state = this.editorView.state.apply(tr);
          this.emitOnChange();
          this.$emit('clear-selection');
        }
      }
      return null;
    },
  },
  created() {
    this.state = createState(this.value, this.placeholder, this.plugins);
  },
  mounted() {
    this.createEditorView();
    this.editorView.updateState(this.state);
    this.focusEditorInputField();
  },
  methods: {
    reloadState() {
      this.state = createState(this.value, this.placeholder, this.plugins);
      this.editorView.updateState(this.state);
      this.focusEditorInputField();
    },
    createEditorView() {
      this.editorView = new EditorView(this.$refs.editor, {
        state: this.state,
        dispatchTransaction: tx => {
          this.state = this.state.apply(tx);
          this.emitOnChange();
        },
        handleDOMEvents: {
          keyup: () => {
            this.onKeyup();
          },
          keydown: (view, event) => {
            this.onKeydown(event);
          },
          focus: () => {
            this.onFocus();
          },
          blur: () => {
            this.onBlur();
          },
          paste: (view, event) => {
            const data = event.clipboardData.files;
            if (data.length > 0) {
              event.preventDefault();
            }
          },
        },
      });
    },
    isEnterToSendEnabled() {
      return isEditorHotKeyEnabled(this.uiSettings, 'enter');
    },
    isCmdPlusEnterToSendEnabled() {
      return isEditorHotKeyEnabled(this.uiSettings, 'cmd_enter');
    },
    handleKeyEvents(e) {
      if (hasPressedAltAndPKey(e)) {
        this.focusEditorInputField();
      }
      if (hasPressedAltAndLKey(e)) {
        this.focusEditorInputField();
      }
    },
    focusEditorInputField() {
      const { tr } = this.editorView.state;
      const selection = Selection.atEnd(tr.doc);

      this.editorView.dispatch(tr.setSelection(selection));
      this.editorView.focus();
    },
    insertMentionNode(mentionItem) {
      if (!this.editorView) {
        return null;
      }
      const node = this.editorView.state.schema.nodes.mention.create({
        userId: mentionItem.id,
        userFullName: mentionItem.name,
      });

      const tr = this.editorView.state.tr.replaceWith(
        this.range.from,
        this.range.to,
        node
      );
      this.state = this.editorView.state.apply(tr);
      this.emitOnChange();
      this.$track(CONVERSATION_EVENTS.USED_MENTIONS);

      return false;
    },
    insertCannedResponse(cannedItem) {
      const updatedMessage = replaceVariablesInMessage({
        message: cannedItem,
        variables: this.variables,
      });
      if (!this.editorView) {
        return null;
      }

      let from = this.range.from - 1;
      let node = new MessageMarkdownTransformer(messageSchema).parse(
        updatedMessage
      );

      if (node.textContent === updatedMessage) {
        node = this.editorView.state.schema.text(updatedMessage);
        from = this.range.from;
      }

      const tr = this.editorView.state.tr.replaceWith(
        from,
        this.range.to,
        node
      );

      this.state = this.editorView.state.apply(tr);
      this.emitOnChange();

      tr.scrollIntoView();
      this.$track(CONVERSATION_EVENTS.INSERTED_A_CANNED_RESPONSE);
      return false;
    },
    insertVariable(variable) {
      if (!this.editorView) {
        return null;
      }
      let node = this.editorView.state.schema.text(`{{${variable}}}`);
      const from = this.range.from;

      const tr = this.editorView.state.tr.replaceWith(
        from,
        this.range.to,
        node
      );

      this.state = this.editorView.state.apply(tr);
      this.emitOnChange();

      // The `{{ }}` are added to the message, but the cursor is placed
      // and onExit of suggestionsPlugin is not called. So we need to manually hide
      this.showVariables = false;
      this.$track(CONVERSATION_EVENTS.INSERTED_A_VARIABLE);
      tr.scrollIntoView();
      return false;
    },

    emitOnChange() {
      this.editorView.updateState(this.state);

      this.$emit('input', this.contentFromEditor);
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
    handleLineBreakWhenEnterToSendEnabled(event) {
      if (
        hasPressedEnterAndNotCmdOrShift(event) &&
        this.isEnterToSendEnabled() &&
        !this.overrideLineBreaks
      ) {
        event.preventDefault();
      }
    },
    handleLineBreakWhenCmdAndEnterToSendEnabled(event) {
      if (
        hasPressedCommandAndEnter(event) &&
        this.isCmdPlusEnterToSendEnabled() &&
        !this.overrideLineBreaks
      ) {
        event.preventDefault();
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
    onKeydown(event) {
      if (this.isEnterToSendEnabled()) {
        this.handleLineBreakWhenEnterToSendEnabled(event);
      }
      if (this.isCmdPlusEnterToSendEnabled()) {
        this.handleLineBreakWhenCmdAndEnterToSendEnabled(event);
      }
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
@import '~@chatwoot/prosemirror-schema/src/styles/base.scss';

.ProseMirror-menubar-wrapper {
  display: flex;
  flex-direction: column;

  .ProseMirror-menubar {
    min-height: var(--space-two) !important;
    margin-left: var(--space-minus-one);
    padding-bottom: 0;
  }

  > .ProseMirror {
    padding: 0;
    word-break: break-word;
  }
}

.editor-root {
  width: 100%;
  position: relative;
}

.ProseMirror-woot-style {
  min-height: 8rem;
  max-height: 12rem;
  overflow: auto;
}

.ProseMirror-prompt {
  z-index: var(--z-index-highest);
  background: var(--color-background-light);
  border-radius: var(--border-radius-normal);
  border: 1px solid var(--color-border);
}

.is-private {
  .prosemirror-mention-node {
    font-weight: var(--font-weight-medium);
    background: var(--s-50);
    color: var(--s-900);
    padding: 0 var(--space-smaller);
  }
  .ProseMirror-menubar {
    background: var(--y-50);
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

<script setup>
import { ref, computed, watch, onMounted, useTemplateRef } from 'vue';

import {
  buildMessageSchema,
  buildEditor,
  EditorView,
  MessageMarkdownTransformer,
  MessageMarkdownSerializer,
  EditorState,
  Selection,
} from '@chatwoot/prosemirror-schema';

import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  modelValue: { type: String, default: '' },
  editorId: { type: String, default: '' },
  placeholder: {
    type: String,
    default: 'Give copilot additional prompts, or ask anything else...',
  },
  generatedContent: { type: String, default: '' },
  autofocus: {
    type: Boolean,
    default: true,
  },
  isPopout: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'blur',
  'input',
  'update:modelValue',
  'keyup',
  'focus',
  'keydown',
  'send',
]);

const { formatMessage } = useMessageFormatter();

// Minimal schema with no marks or nodes for copilot input
const copilotSchema = buildMessageSchema([], []);

const handleSubmit = () => emit('send');

const createState = (
  content,
  placeholder,
  plugins = [],
  enabledMenuOptions = []
) => {
  return EditorState.create({
    doc: new MessageMarkdownTransformer(copilotSchema).parse(content),
    plugins: buildEditor({
      schema: copilotSchema,
      placeholder,
      plugins,
      enabledMenuOptions,
    }),
  });
};

// we don't need them to be reactive
// It cases weird issues where the objects are proxied
// and then the editor doesn't work as expected
let editorView = null;
let state = null;

// reactive data
const isTextSelected = ref(false); // Tracks text selection and prevents unnecessary re-renders on mouse selection

// element refs
const editor = useTemplateRef('editor');

function contentFromEditor() {
  if (editorView) {
    return MessageMarkdownSerializer.serialize(editorView.state.doc);
  }
  return '';
}

function focusEditorInputField() {
  const { tr } = editorView.state;
  const selection = Selection.atEnd(tr.doc);

  editorView.dispatch(tr.setSelection(selection));
  editorView.focus();
}

function emitOnChange() {
  emit('update:modelValue', contentFromEditor());
  emit('input', contentFromEditor());
}

function onKeyup() {
  emit('keyup');
}

function onKeydown(view, event) {
  emit('keydown');

  // Handle Enter key to send message (Shift+Enter for new line)
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    handleSubmit();
    return true; // Prevent ProseMirror's default Enter handling
  }

  return false; // Allow other keys to work normally
}

function onBlur() {
  emit('blur');
}

function onFocus() {
  emit('focus');
}

function checkSelection(editorState) {
  const hasSelection = editorState.selection.from !== editorState.selection.to;
  if (hasSelection === isTextSelected.value) return;
  isTextSelected.value = hasSelection;
}

// computed properties
const plugins = computed(() => {
  return [];
});

const enabledMenuOptions = computed(() => {
  return [];
});

function reloadState() {
  state = createState(
    props.modelValue,
    props.placeholder,
    plugins.value,
    enabledMenuOptions.value
  );
  editorView.updateState(state);
  focusEditorInputField();
}

function createEditorView() {
  editorView = new EditorView(editor.value, {
    state: state,
    dispatchTransaction: tx => {
      state = state.apply(tx);
      editorView.updateState(state);
      if (tx.docChanged) {
        emitOnChange();
      }
      checkSelection(state);
    },
    handleDOMEvents: {
      keyup: onKeyup,
      focus: onFocus,
      blur: onBlur,
      keydown: onKeydown,
    },
  });
}

// watchers
watch(
  computed(() => props.modelValue),
  (newValue = '') => {
    if (newValue !== contentFromEditor()) {
      reloadState();
    }
  }
);

watch(
  computed(() => props.editorId),
  () => {
    reloadState();
  }
);

// lifecycle
onMounted(() => {
  state = createState(
    props.modelValue,
    props.placeholder,
    plugins.value,
    enabledMenuOptions.value
  );

  createEditorView();
  editorView.updateState(state);

  if (props.autofocus) {
    focusEditorInputField();
  }
});
</script>

<template>
  <div class="space-y-2 mb-4">
    <div
      class="overflow-y-auto"
      :class="{ 'max-h-96': isPopout, 'max-h-56': !isPopout }"
    >
      <p
        v-dompurify-html="formatMessage(generatedContent, false)"
        class="text-n-iris-12 text-sm prose-sm font-normal !mb-4"
      />
    </div>
    <div class="editor-root relative editor--copilot space-x-2">
      <div ref="editor" />
      <div class="flex items-center justify-end absolute right-2 bottom-2">
        <NextButton
          class="bg-n-iris-9 text-white !rounded-full"
          icon="i-lucide-arrow-up"
          solid
          sm
          @click="handleSubmit"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss">
@import '@chatwoot/prosemirror-schema/src/styles/base.scss';

.editor--copilot {
  @apply bg-n-iris-5 rounded;

  .ProseMirror-woot-style {
    min-height: 5rem;
    max-height: 7.5rem !important;
    overflow: auto;
    @apply px-2 !important;

    .empty-node {
      &::before {
        @apply text-n-iris-9 dark:text-n-iris-11;
      }
    }
  }
}
</style>

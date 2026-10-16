<script setup>
import {
  ref,
  computed,
  watch,
  inject,
  nextTick,
  onMounted,
  onBeforeUnmount,
  useTemplateRef,
} from 'vue';

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

const SUGGESTION_GAP = 8; // gap-2
const MAX_HEIGHT = 350;

// Not provided in the compose modal, which sizes itself
const requestEditorHeight = inject('requestEditorHeight', () => {});

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
const suggestion = useTemplateRef('suggestion');
const followUp = useTemplateRef('followUp');

// The wait matters: the markdown lands in the pane through a directive, so
// measuring any earlier reads an empty pane and the suggestion stays clipped
async function requestRoomForSuggestion() {
  await nextTick();
  const height =
    suggestion.value.scrollHeight +
    SUGGESTION_GAP +
    followUp.value.offsetHeight;
  requestEditorHeight(Math.min(height, MAX_HEIGHT));
}

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
  // Skip if IME composition is active (CJK character confirmation)
  if (event.key === 'Enter' && !event.shiftKey && !event.isComposing) {
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

  requestRoomForSuggestion();
});

onBeforeUnmount(() => {
  requestEditorHeight(0);
});
</script>

<template>
  <div class="resizable-editor-body flex flex-col gap-2 mb-3">
    <div
      ref="suggestion"
      class="copilot-suggestion flex-1 min-h-0 overflow-y-auto"
    >
      <p
        v-dompurify-html="formatMessage(generatedContent, false)"
        class="text-n-iris-12 text-sm prose-sm font-normal"
      />
    </div>
    <div ref="followUp" class="editor-root relative editor--copilot shrink-0">
      <div ref="editor" />
      <div class="flex items-center justify-end absolute end-2 bottom-2">
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

.copilot-suggestion:not(:where(.resizable-editor-wrapper *)) {
  @apply max-h-56;
}

.editor--copilot {
  @apply bg-n-iris-5 rounded;

  .ProseMirror-woot-style {
    min-height: 5rem;
    max-height: 7.5rem;
    overflow: auto;
    @apply ps-2 pe-10 !important;

    .empty-node {
      &::before {
        @apply text-n-iris-9 dark:text-n-iris-11;
      }
    }
  }
}

.resizable-editor-wrapper .editor--copilot .ProseMirror-woot-style {
  min-height: min(5rem, calc(var(--editor-height) - 2.5rem));
  max-height: min(7.5rem, calc(var(--editor-height) - 2.5rem));
}
</style>

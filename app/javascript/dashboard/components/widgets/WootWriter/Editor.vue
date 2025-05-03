<script setup>
// TODO This is a huge component, we should split this up into separate composables
// like `useSignature`, `useImageHandling`, `useFileUpload`, `useSpecialContent``
import {
  ref,
  unref,
  computed,
  watch,
  onMounted,
  useTemplateRef,
  nextTick,
} from 'vue';

import CannedResponse from '../conversation/CannedResponse.vue';
import KeyboardEmojiSelector from './keyboardEmojiSelector.vue';
import TagAgents from '../conversation/TagAgents.vue';
import VariableList from '../conversation/VariableList.vue';

import { useEmitter } from 'dashboard/composables/emitter';
import { useI18n } from 'vue-i18n';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useTrack } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { CONVERSATION_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import {
  MESSAGE_EDITOR_MENU_OPTIONS,
  MESSAGE_EDITOR_IMAGE_RESIZES,
} from 'dashboard/constants/editor';

import {
  messageSchema,
  buildEditor,
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

import {
  appendSignature,
  findNodeToInsertImage,
  getContentNode,
  insertAtCursor,
  removeSignature as removeSignatureHelper,
  scrollCursorIntoView,
  setURLWithQueryAndSize,
} from 'dashboard/helper/editorHelper';
import {
  hasPressedEnterAndNotCmdOrShift,
  hasPressedCommandAndEnter,
} from 'shared/helpers/KeyboardHelpers';
import { createTypingIndicator } from '@chatwoot/utils';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { uploadFile } from 'dashboard/helper/uploadHelper';

const props = defineProps({
  modelValue: { type: String, default: '' },
  editorId: { type: String, default: '' },
  placeholder: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  isPrivate: { type: Boolean, default: false },
  enableSuggestions: { type: Boolean, default: true },
  overrideLineBreaks: { type: Boolean, default: false },
  updateSelectionWith: { type: String, default: '' },
  enableVariables: { type: Boolean, default: false },
  enableCannedResponses: { type: Boolean, default: true },
  variables: { type: Object, default: () => ({}) },
  enabledMenuOptions: { type: Array, default: () => [] },
  signature: { type: String, default: '' },
  // allowSignature is a kill switch, ensuring no signature methods
  // are triggered except when this flag is true
  allowSignature: { type: Boolean, default: false },
  channelType: { type: String, default: '' },
  showImageResizeToolbar: { type: Boolean, default: false }, // A kill switch to show or hide the image toolbar
  focusOnMount: { type: Boolean, default: true },
});

const emit = defineEmits([
  'typingOn',
  'typingOff',
  'toggleUserMention',
  'toggleCannedMenu',
  'toggleVariablesMenu',
  'clearSelection',
  'blur',
  'focus',
  'input',
  'update:modelValue',
]);

const { t } = useI18n();

const TYPING_INDICATOR_IDLE_TIME = 4000;
const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB

const createState = (
  content,
  placeholder,
  plugins = [],
  methods = {},
  enabledMenuOptions = []
) => {
  return EditorState.create({
    doc: new MessageMarkdownTransformer(messageSchema).parse(content),
    plugins: buildEditor({
      schema: messageSchema,
      placeholder,
      methods,
      plugins,
      enabledMenuOptions,
    }),
  });
};

const { isEditorHotKeyEnabled, fetchSignatureFlagFromUISettings } =
  useUISettings();

const typingIndicator = createTypingIndicator(
  () => emit('typingOn'),
  () => emit('typingOff'),
  TYPING_INDICATOR_IDLE_TIME
);

// we don't need them to be reactive
// It cases weird issues where the objects are proxied
// and then the editor doesn't work as expected
// We have to wrap them in closures or use toRaw to get the actual values
let editorView = null;
let state = null;

const showUserMentions = ref(false);
const showCannedMenu = ref(false);
const showVariables = ref(false);
const showEmojiMenu = ref(false);
const mentionSearchKey = ref('');
const cannedSearchTerm = ref('');
const variableSearchTerm = ref('');
const emojiSearchTerm = ref('');
const range = ref(null);
const isImageNodeSelected = ref(false);
const toolbarPosition = ref({ top: 0, left: 0 });
const selectedImageNode = ref(null);
const sizes = MESSAGE_EDITOR_IMAGE_RESIZES;

// element ref
const editorRoot = useTemplateRef('editorRoot');
const imageUpload = useTemplateRef('imageUpload');
const editor = useTemplateRef('editor');

const contentFromEditor = () => {
  return MessageMarkdownSerializer.serialize(editorView.state.doc);
};

const shouldShowVariables = computed(() => {
  return props.enableVariables && showVariables.value && !props.isPrivate;
});

const shouldShowCannedResponses = computed(() => {
  return (
    props.enableCannedResponses && showCannedMenu.value && !props.isPrivate
  );
});

const editorMenuOptions = computed(() => {
  return props.enabledMenuOptions.length
    ? props.enabledMenuOptions
    : MESSAGE_EDITOR_MENU_OPTIONS;
});

function createSuggestionPlugin({
  trigger,
  minChars = 0,
  showMenu,
  searchTerm,
  isAllowed = () => true,
}) {
  return suggestionsPlugin({
    matcher: triggerCharacters(trigger, minChars),
    suggestionClass: '',
    onEnter: args => {
      if (!isAllowed()) return false;
      showMenu.value = true;
      range.value = args.range;
      editorView = args.view;
      if (searchTerm) searchTerm.value = args.text || '';
      return false;
    },
    onChange: args => {
      editorView = args.view;
      range.value = args.range;
      if (searchTerm) searchTerm.value = args.text;
      return false;
    },
    onExit: () => {
      if (searchTerm) searchTerm.value = '';
      showMenu.value = false;
      return false;
    },
    onKeyDown: ({ event }) => {
      return event.keyCode === 13 && showMenu.value;
    },
  });
}

const plugins = computed(() => {
  if (!props.enableSuggestions) {
    return [];
  }

  return [
    createSuggestionPlugin({
      trigger: '@',
      showMenu: showUserMentions,
      searchTerm: mentionSearchKey,
      isAllowed: () => props.isPrivate,
    }),
    createSuggestionPlugin({
      trigger: '/',
      showMenu: showCannedMenu,
      searchTerm: cannedSearchTerm,
      isAllowed: () => !props.isPrivate,
    }),
    createSuggestionPlugin({
      trigger: '{{',
      showMenu: showVariables,
      searchTerm: variableSearchTerm,
      isAllowed: () => !props.isPrivate,
    }),
    createSuggestionPlugin({
      trigger: ':',
      minChars: 2,
      showMenu: showEmojiMenu,
      searchTerm: emojiSearchTerm,
    }),
  ];
});

const sendWithSignature = computed(() => {
  // this is considered the source of truth, we watch this property
  // on change, we toggle the signature in the editor
  if (props.allowSignature && !props.isPrivate && props.channelType) {
    return fetchSignatureFlagFromUISettings(props.channelType);
  }

  return false;
});

watch(showUserMentions, updatedValue => {
  emit('toggleUserMention', props.isPrivate && updatedValue);
});
watch(showCannedMenu, updatedValue => {
  emit('toggleCannedMenu', !props.isPrivate && updatedValue);
});
watch(showVariables, updatedValue => {
  emit('toggleVariablesMenu', !props.isPrivate && updatedValue);
});

function focusEditorInputField(pos = 'end') {
  const { tr } = editorView.state;

  const selection =
    pos === 'end' ? Selection.atEnd(tr.doc) : Selection.atStart(tr.doc);

  editorView.dispatch(tr.setSelection(selection));
  editorView.focus();
}

function isBodyEmpty(content) {
  // if content is undefined, we assume that the body is empty
  if (!content) return true;

  // if the signature is present, we need to remove it before checking
  // note that we don't update the editorView, so this is safe
  const bodyWithoutSignature = props.signature
    ? removeSignatureHelper(content, props.signature)
    : content;

  // trimming should remove all the whitespaces, so we can check the length
  return bodyWithoutSignature.trim().length === 0;
}

function handleEmptyBodyWithSignature() {
  const { schema, tr } = state;

  // create a paragraph node and
  // start a transaction to append it at the end
  const paragraph = schema.nodes.paragraph.create();
  const paragraphTransaction = tr.insert(0, paragraph);
  editorView.dispatch(paragraphTransaction);

  // Set the focus at the start of the input field
  focusEditorInputField('start');
}

function focusEditor(content) {
  if (props.disabled) return;

  const unrefContent = unref(content);
  if (isBodyEmpty(unrefContent) && sendWithSignature.value) {
    // reload state can be called when switching between conversations, or when drafts is loaded
    // these drafts can also have a signature, so we need to check if the body is empty
    // and handle things accordingly
    handleEmptyBodyWithSignature();
  } else if (props.focusOnMount) {
    // this is in the else block, handleEmptyBodyWithSignature also has a call to the focus method
    // the position is set to start, because the signature is added at the end of the body
    focusEditorInputField('end');
  }
}

function openFileBrowser() {
  imageUpload.value.click();
}

function reloadState(content = props.modelValue) {
  const unrefContent = unref(content);
  state = createState(
    unrefContent,
    props.placeholder,
    plugins.value,
    { onImageUpload: openFileBrowser },
    editorMenuOptions.value
  );

  editorView.updateState(state);
  focusEditor(unrefContent);
}

function addSignature() {
  let content = props.modelValue;
  // see if the content is empty, if it is before appending the signature
  // we need to add a paragraph node and move the cursor at the start of the editor
  const contentWasEmpty = isBodyEmpty(content);
  content = appendSignature(content, props.signature);
  // need to reload first, ensuring that the editorView is updated
  reloadState(content);

  if (contentWasEmpty) {
    handleEmptyBodyWithSignature();
  }
}

function removeSignature() {
  if (!props.signature) return;
  let content = props.modelValue;
  content = removeSignatureHelper(content, props.signature);
  // reload the state, ensuring that the editorView is updated
  reloadState(content);
}

function toggleSignatureInEditor(signatureEnabled) {
  // The toggleSignatureInEditor gets the new value from the
  // watcher, this means that if the value is true, the signature
  // is supposed to be added, else we remove it.
  if (signatureEnabled) {
    addSignature();
  } else {
    removeSignature();
  }
}

function setToolbarPosition() {
  const editorRect = editorRoot.value.getBoundingClientRect();
  const rect = selectedImageNode.value.getBoundingClientRect();

  toolbarPosition.value = {
    top: `${rect.top - editorRect.top - 30}px`,
    left: `${rect.left - editorRect.left - 4}px`,
  };
}

function setURLWithQueryAndImageSize(size) {
  if (!props.showImageResizeToolbar) {
    return;
  }
  setURLWithQueryAndSize(selectedImageNode.value, size, editorView);
  isImageNodeSelected.value = false;
}

function isEditorMouseFocusedOnAnImage() {
  if (!props.showImageResizeToolbar) {
    return;
  }
  selectedImageNode.value = document.querySelector(
    'img.ProseMirror-selectednode'
  );
  if (selectedImageNode.value) {
    isImageNodeSelected.value = !!selectedImageNode.value;
    // Get the position of the selected node
    setToolbarPosition();
  } else {
    isImageNodeSelected.value = false;
  }
}

function emitOnChange() {
  emit('input', contentFromEditor());
  emit('update:modelValue', contentFromEditor());
}

function updateImgToolbarOnDelete() {
  // check if the selected node is present or not on keyup
  // this is needed because the user can select an image and then delete it
  // in that case, the selected node will be null and we need to hide the toolbar
  // otherwise, the toolbar will be visible even when the image is deleted and cause some errors
  if (selectedImageNode.value) {
    const hasImgSelectedNode = document.querySelector(
      'img.ProseMirror-selectednode'
    );
    if (!hasImgSelectedNode) {
      isImageNodeSelected.value = false;
    }
  }
}

function isEnterToSendEnabled() {
  return isEditorHotKeyEnabled('enter');
}

function isCmdPlusEnterToSendEnabled() {
  return isEditorHotKeyEnabled('cmd_enter');
}

useKeyboardEvents({
  'Alt+KeyP': {
    action: focusEditorInputField,
    allowOnFocusedInput: true,
  },
  'Alt+KeyL': {
    action: focusEditorInputField,
    allowOnFocusedInput: true,
  },
});

function onImageInsertInEditor(fileUrl) {
  const { tr } = editorView.state;

  const insertData = findNodeToInsertImage(editorView.state, fileUrl);

  if (insertData) {
    editorView.dispatch(
      tr.insert(insertData.pos, insertData.node).scrollIntoView()
    );
    focusEditorInputField();
  }
}

async function uploadImageToStorage(file) {
  try {
    const { fileUrl } = await uploadFile(file);
    if (fileUrl) {
      onImageInsertInEditor(fileUrl);
    }
    useAlert(
      t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_SUCCESS')
    );
  } catch (error) {
    useAlert(
      t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_ERROR')
    );
  }
}

function onFileChange() {
  const file = imageUpload.value.files[0];
  if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
    uploadImageToStorage(file);
  } else {
    useAlert(
      t(
        'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_SIZE_ERROR',
        {
          size: MAXIMUM_FILE_UPLOAD_SIZE,
        }
      )
    );
  }

  imageUpload.value = '';
}

function handleLineBreakWhenEnterToSendEnabled(event) {
  if (
    hasPressedEnterAndNotCmdOrShift(event) &&
    isEnterToSendEnabled() &&
    !props.overrideLineBreaks
  ) {
    event.preventDefault();
  }
}

async function insertNodeIntoEditor(node, from = 0, to = 0) {
  state = insertAtCursor(editorView, node, from, to);
  emitOnChange();
  await nextTick();
  scrollCursorIntoView(editorView);
}

function insertContentIntoEditor(content, defaultFrom = 0) {
  const from = defaultFrom || editorView.state.selection.from || 0;
  let node = new MessageMarkdownTransformer(messageSchema).parse(content);

  insertNodeIntoEditor(node, from, undefined);
}

/**
 * Inserts special content (mention, canned response, variable, emoji) into the editor.
 * @param {string} type - The type of special content to insert. Possible values: 'mention', 'canned_response', 'variable', 'emoji'.
 * @param {Object|string} content - The content to insert, depending on the type.
 */
function insertSpecialContent(type, content) {
  if (!editorView) {
    return;
  }

  let { node, from, to } = getContentNode(
    editorView,
    type,
    content,
    range.value,
    props.variables
  );

  if (!node) return;

  insertNodeIntoEditor(node, from, to);

  const event_map = {
    mention: CONVERSATION_EVENTS.USED_MENTIONS,
    cannedResponse: CONVERSATION_EVENTS.INSERTED_A_CANNED_RESPONSE,
    variable: CONVERSATION_EVENTS.INSERTED_A_VARIABLE,
    emoji: CONVERSATION_EVENTS.INSERTED_AN_EMOJI,
  };

  useTrack(event_map[type]);
}

function handleLineBreakWhenCmdAndEnterToSendEnabled(event) {
  if (
    hasPressedCommandAndEnter(event) &&
    isCmdPlusEnterToSendEnabled() &&
    !props.overrideLineBreaks
  ) {
    event.preventDefault();
  }
}

function onKeydown(event) {
  if (isEnterToSendEnabled()) {
    handleLineBreakWhenEnterToSendEnabled(event);
  }
  if (isCmdPlusEnterToSendEnabled()) {
    handleLineBreakWhenCmdAndEnterToSendEnabled(event);
  }
}

function createEditorView() {
  editorView = new EditorView(editor.value, {
    state: state,
    editable: () => !props.disabled,
    dispatchTransaction: tx => {
      state = state.apply(tx);
      editorView.updateState(state);
      if (tx.docChanged) {
        emitOnChange();
      }
    },
    handleDOMEvents: {
      keyup: () => {
        if (!props.disabled) {
          if (props.modelValue.length) {
            typingIndicator.start();
          } else {
            typingIndicator.stop();
          }
          updateImgToolbarOnDelete();
        }
      },
      keydown: (view, event) => !props.disabled && onKeydown(event),
      focus: () => !props.disabled && emit('focus'),
      click: () => !props.disabled && isEditorMouseFocusedOnAnImage(),
      blur: () => {
        if (props.disabled) return;
        typingIndicator.stop();
        emit('blur');
      },
      paste: (_view, event) => {
        if (props.disabled) return;
        const data = event.clipboardData.files;
        if (data.length > 0) {
          event.preventDefault();
        }
      },
    },
  });
}

watch(
  computed(() => props.modelValue),
  (newVal = '') => {
    if (newVal !== contentFromEditor()) {
      reloadState(newVal);
    }
  }
);

watch(
  computed(() => props.editorId),
  () => {
    showCannedMenu.value = false;
    showEmojiMenu.value = false;
    showVariables.value = false;
    cannedSearchTerm.value = '';
    reloadState(props.modelValue);
  }
);

watch(
  computed(() => props.isPrivate),
  () => {
    reloadState(props.modelValue);
  }
);

watch(
  computed(() => props.updateSelectionWith),
  (newValue, oldValue) => {
    if (!editorView) return;

    if (newValue !== oldValue) {
      if (props.updateSelectionWith !== '') {
        const node = editorView.state.schema.text(props.updateSelectionWith);

        const tr = editorView.state.tr.replaceSelectionWith(node);
        editorView.focus();
        state = editorView.state.apply(tr);
        editorView.updateState(state);
        emitOnChange();
        emit('clearSelection');
      }
    }
  }
);

watch(sendWithSignature, newValue => {
  // see if the allowSignature flag is true
  if (props.allowSignature) {
    toggleSignatureInEditor(newValue);
  }
});

onMounted(() => {
  // [VITE] state assignment was done in created before
  state = createState(
    props.modelValue,
    props.placeholder,
    plugins.value,
    { onImageUpload: openFileBrowser },
    editorMenuOptions.value
  );

  createEditorView();
  editorView.updateState(state);
  if (props.focusOnMount) {
    focusEditorInputField();
  }
});

// BUS Event to insert text or markdown into the editor at the
// current cursor position.
// Components using this
// 1. SearchPopover.vue
useEmitter(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, insertContentIntoEditor);
</script>

<template>
  <div ref="editorRoot" class="relative w-full">
    <TagAgents
      v-if="showUserMentions && isPrivate"
      :search-key="mentionSearchKey"
      @select-agent="content => insertSpecialContent('mention', content)"
    />
    <CannedResponse
      v-if="shouldShowCannedResponses"
      :search-key="cannedSearchTerm"
      @replace="content => insertSpecialContent('cannedResponse', content)"
    />
    <VariableList
      v-if="shouldShowVariables"
      :search-key="variableSearchTerm"
      @select-variable="content => insertSpecialContent('variable', content)"
    />
    <KeyboardEmojiSelector
      v-if="showEmojiMenu"
      :search-key="emojiSearchTerm"
      @select-emoji="emoji => insertSpecialContent('emoji', emoji)"
    />
    <input
      ref="imageUpload"
      type="file"
      accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
      hidden
      @change="onFileChange"
    />
    <div ref="editor" />
    <div
      v-show="isImageNodeSelected && showImageResizeToolbar"
      class="absolute shadow-md rounded-[4px] flex gap-1 py-1 px-1 bg-slate-50 dark:bg-slate-700 text-slate-800 dark:text-slate-50"
      :style="{
        top: toolbarPosition.top,
        left: toolbarPosition.left,
      }"
    >
      <button
        v-for="size in sizes"
        :key="size.name"
        class="text-xs font-medium rounded-[4px] border border-solid border-slate-200 dark:border-slate-600 px-1.5 py-0.5 hover:bg-slate-100 dark:hover:bg-slate-800"
        @click="setURLWithQueryAndImageSize(size)"
      >
        {{ size.name }}
      </button>
    </div>
    <slot name="footer" />
  </div>
</template>

<style lang="scss">
@import '@chatwoot/prosemirror-schema/src/styles/base.scss';

.ProseMirror-menubar-wrapper {
  @apply flex flex-col;

  .ProseMirror-menubar {
    min-height: var(--space-two) !important;
    @apply -ml-2.5 pb-0 bg-transparent text-n-slate-11;

    .ProseMirror-menu-active {
      @apply bg-slate-75 dark:bg-slate-800;
    }
  }

  > .ProseMirror {
    @apply p-0 break-words text-slate-800 dark:text-slate-100;

    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    p {
      @apply text-slate-800 dark:text-slate-100;
    }

    blockquote {
      @apply border-slate-400 dark:border-slate-500;

      p {
        @apply text-slate-600 dark:text-slate-400;
      }
    }

    ol li {
      @apply list-item list-decimal;
    }
  }
}

.ProseMirror-woot-style {
  @apply overflow-auto min-h-[5rem] max-h-[7.5rem];
}

.ProseMirror-prompt {
  @apply z-[9999] bg-n-alpha-3 backdrop-blur-[100px] border border-n-strong p-6 shadow-xl rounded-xl;

  h5 {
    @apply text-n-slate-12 mb-1.5;
  }

  .ProseMirror-prompt-buttons {
    button {
      @apply h-8 px-3;

      &[type='submit'] {
        @apply bg-n-brand text-white hover:bg-n-brand/90;
      }

      &[type='button'] {
        @apply bg-n-slate-9/10 text-n-slate-12 hover:bg-n-slate-9/20;
      }
    }
  }
}

.is-private {
  .prosemirror-mention-node {
    @apply font-medium bg-n-amber-2/80 dark:bg-n-amber-2/80 text-n-slate-12 py-0 px-1;
  }

  .ProseMirror-menubar-wrapper {
    > .ProseMirror {
      @apply text-n-slate-12;

      p {
        @apply text-n-slate-12;
      }
    }
  }
}

.editor-wrap {
  @apply mb-4;
}

.message-editor {
  @apply rounded-lg outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 bg-n-alpha-black2 py-0 px-1 mb-0;
}

.editor_warning {
  @apply outline outline-1 outline-n-ruby-8 dark:outline-n-ruby-8 hover:outline-n-ruby-9 dark:hover:outline-n-ruby-9;
}

.editor-warning__message {
  @apply text-red-400 dark:text-red-400 font-normal text-sm pt-1 pb-0 px-0;
}
</style>

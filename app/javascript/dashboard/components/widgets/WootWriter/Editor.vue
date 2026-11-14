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
import TagGroupMembers from '../conversation/TagGroupMembers.vue';
import VariableList from '../conversation/VariableList.vue';
import MacroList from '../conversation/MacroList.vue';
import TagTools from '../conversation/TagTools.vue';
import TagConversations from '../conversation/TagConversations.vue';
import CopilotMenuBar from './CopilotMenuBar.vue';

import { useEmitter } from 'dashboard/composables/emitter';
import { useI18n } from 'vue-i18n';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useTrack } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { vOnClickOutside } from '@vueuse/components';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  CONVERSATION_EVENTS,
  CAPTAIN_EVENTS,
} from 'dashboard/helper/AnalyticsHelper/events';

import {
  messageSchema,
  buildMessageSchema,
  buildEditor,
  EditorView,
  MessageMarkdownTransformer,
  MessageMarkdownSerializer,
  EditorState,
  Selection,
  imageResizeView,
} from '@chatwoot/prosemirror-schema';
import {
  suggestionsPlugin,
  triggerCharacters,
} from '@chatwoot/prosemirror-schema/src/mentions/plugin';

import {
  collapseSelection,
  findNodeToInsertImage,
  getContentNode,
  insertAtCursor,
  scrollCursorIntoView,
  getFormattingForEditor,
  getSelectionCoords,
  calculateMenuPosition,
  getEffectiveChannelType,
  stripUnsupportedFormatting,
  createVariableInputRule,
  releasedSearchTransaction,
} from 'dashboard/helper/editorHelper';
import {
  hasPressedEnterAndNotCmdOrShift,
  hasPressedCommandAndEnter,
  isComposing,
  isEscape,
} from 'shared/helpers/KeyboardHelpers';
import { createTypingIndicator } from '@chatwoot/utils';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { findSignatureSeparator } from 'dashboard/constants/signatureSeparators';

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
  // Offers the variables only an automation rule can render (`conversation.before.*`).
  enableAutomationVariables: { type: Boolean, default: false },
  enableCannedResponses: { type: Boolean, default: true },
  enableCaptainTools: { type: Boolean, default: false },
  enableMacros: { type: Boolean, default: false },
  variables: { type: Object, default: () => ({}) },
  signature: { type: String, default: '' },
  // allowSignature is a kill switch, ensuring no signature methods
  // are triggered except when this flag is true
  allowSignature: { type: Boolean, default: false },
  // Per-inbox overrides; when empty, falls back to currentUser.ui_settings
  signaturePositionOverride: { type: String, default: '' },
  signatureSeparatorOverride: { type: String, default: '' },
  channelType: { type: String, default: '' },
  conversationId: { type: Number, default: null },
  medium: { type: String, default: '' },
  focusOnMount: { type: Boolean, default: true },
  enableCopilot: { type: Boolean, default: true },
  isGroupConversation: { type: Boolean, default: false },
  groupContactId: { type: [Number, String], default: null },
  inboxPhoneNumber: { type: String, default: null },
  enableMentionDropdown: { type: Boolean, default: false },
  enableConversationMention: { type: Boolean, default: false },
  // Global INSERT_INTO_RICH_EDITOR bus events (Copilot "Use this", article
  // links) are meant for the conversation reply editor only — other mounted
  // editors (canned responses, signature, etc.) must not consume them.
  enableInsertEvents: { type: Boolean, default: false },
});

const emit = defineEmits([
  'typingOn',
  'typingOff',
  'toggleUserMention',
  'toggleCannedMenu',
  'toggleVariablesMenu',
  'toggleToolsMenu',
  'toggleMacrosMenu',
  'executeMacro',
  'clearSelection',
  'blur',
  'focus',
  'input',
  'update:modelValue',
  'executeCopilotAction',
  'toggleConversationMention',
]);

const { t } = useI18n();
const { captainTasksEnabled: rawCaptainTasksEnabled } = useCaptain();
const captainTasksEnabled = computed(
  () => props.enableCopilot && rawCaptainTasksEnabled.value
);

const TYPING_INDICATOR_IDLE_TIME = 4000;
const MAXIMUM_FILE_UPLOAD_SIZE = 4; // in MB
const DEFAULT_FORMATTING = 'Context::Default';
const PRIVATE_NOTE_FORMATTING = 'Context::PrivateNote';
const MESSAGE_SIGNATURE_FORMATTING = 'Context::MessageSignature';
const INLINE_IMAGE_PASTE_TYPES = [
  'image/png',
  'image/jpeg',
  'image/jpg',
  'image/gif',
  'image/webp',
];

const effectiveChannelType = computed(() =>
  getEffectiveChannelType(props.channelType, props.medium)
);

const editorSchema = computed(() => {
  if (!props.channelType) return messageSchema;

  const formatType = props.isPrivate
    ? PRIVATE_NOTE_FORMATTING
    : effectiveChannelType.value;
  const formatting = getFormattingForEditor(
    formatType,
    captainTasksEnabled.value
  );
  return buildMessageSchema(formatting.marks, formatting.nodes);
});

const editorMenuOptions = computed(() => {
  const formatType = props.isPrivate
    ? PRIVATE_NOTE_FORMATTING
    : effectiveChannelType.value || DEFAULT_FORMATTING;
  const formatting = getFormattingForEditor(
    formatType,
    captainTasksEnabled.value
  );

  return formatting.menu;
});

const createState = (content, placeholder, plugins = [], methods = {}) => {
  const schema = editorSchema.value;
  // Strip unsupported formatting before parsing to prevent "Token type not supported" errors
  const sanitizedContent = stripUnsupportedFormatting(content, schema);
  return EditorState.create({
    doc: new MessageMarkdownTransformer(schema).parse(sanitizedContent),
    plugins: buildEditor({
      schema,
      placeholder,
      methods,
      plugins,
      enabledMenuOptions: editorMenuOptions.value,
      resizableTableColumns: false,
    }),
  });
};

const { isEditorHotKeyEnabled, fetchSignatureFlagFromUISettings } =
  useUISettings();

const { formatMessage } = useMessageFormatter();

const currentUser = useMapGetter('getCurrentUser');

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
const showToolsMenu = ref(false);
const showMacroMenu = ref(false);
const toolSearchKey = ref('');
const showConversationMenu = ref(false);
const conversationSearchKey = ref('');
const mentionSearchKey = ref('');
const cannedSearchKey = ref('');
const variableSearchKey = ref('');
const emojiSearchKey = ref('');
const macroSearchKey = ref('');
const range = ref(null);
const isTextSelected = ref(false); // Tracks text selection and prevents unnecessary re-renders on mouse selection
const showSelectionMenu = ref(false);

// element ref
const editorRoot = useTemplateRef('editorRoot');
const imageUpload = useTemplateRef('imageUpload');
const editor = useTemplateRef('editor');

// Anchors the picker to the trigger character, since editors can be much taller than the
// line being typed on. Offsets are relative to the editor so the picker can sit on that
// line and track it from there.
const caretPosition = computed(() => {
  if (!editorView || !range.value || !editorRoot.value) return null;
  const from = Math.min(range.value.from, editorView.state.doc.content.size);
  const { top, bottom } = editorView.coordsAtPos(from);
  const editorTop = editorRoot.value.getBoundingClientRect().top;
  return { top: top - editorTop, height: bottom - top };
});

const isEditorMenuPopover = computed(
  () =>
    editorRoot.value?.classList.contains('popover-prosemirror-menu') ?? false
);

const handleCopilotAction = actionKey => {
  if (actionKey === 'improve_selection' && editorView?.state) {
    const { from, to } = editorView.state.selection;
    const selectedText = editorView.state.doc.textBetween(from, to).trim();

    if (from !== to && selectedText) {
      emit('executeCopilotAction', 'improve', selectedText);
    }
  } else {
    emit('executeCopilotAction', actionKey, props.modelValue);
  }

  showSelectionMenu.value = false;
};

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

const shouldShowMacros = computed(() => {
  return props.enableMacros && showMacroMenu.value;
});

const shouldShowUserMentions = computed(() => {
  return (
    showUserMentions.value &&
    (props.isPrivate ||
      props.isGroupConversation ||
      props.enableMentionDropdown)
  );
});

// The picker owns the search field, so it takes focus while open. Dismissing it hands
// focus back; selecting one does so through the insert itself. The suggestion stays
// active in the document, so the picker only reopens once the trigger is typed afresh.
const dismissPicker = showMenu => {
  showMenu.value = false;
  editorView?.focus();
};

const dismissUserMentions = () => dismissPicker(showUserMentions);
const dismissCannedResponses = () => dismissPicker(showCannedMenu);
const dismissVariables = () => dismissPicker(showVariables);

// A picker gave up on its search: what was typed in it belongs in the editor, after the trigger
// that opened it.
const releasePickerSearch = (showMenu, trigger) => released => {
  showMenu.value = false;
  const transaction =
    editorView &&
    releasedSearchTransaction(editorView.state, range.value, released, trigger);
  if (transaction) editorView.dispatch(transaction);
  editorView?.focus();
};
const releaseUserMentions = releasePickerSearch(showUserMentions, '@');
const releaseCannedResponses = releasePickerSearch(showCannedMenu, '/');
const releaseVariables = releasePickerSearch(showVariables, '{{');
const releaseMacros = releasePickerSearch(showMacroMenu, '#');
const releaseEmojiMenu = releasePickerSearch(showEmojiMenu, ':');
const dismissEmojiMenu = () => dismissPicker(showEmojiMenu);
const dismissMacros = () => dismissPicker(showMacroMenu);

// Deleting the trigger drops the suggestion, so the plugin closes the picker through
// `onExit` on its own.
const removeSuggestionTrigger = () => {
  if (!editorView || !range.value) return;
  const { from, to } = range.value;
  const end = Math.min(to, editorView.state.doc.content.size);
  editorView.dispatch(editorView.state.tr.delete(from, end));
  editorView.focus();
};

const onSelectMacro = macro => {
  removeSuggestionTrigger();
  emit('executeMacro', macro);
};

function createSuggestionPlugin({
  trigger,
  minChars = 0,
  showMenu,
  searchTerm,
  isAllowed = () => true,
  interceptEnter = false,
}) {
  return suggestionsPlugin({
    matcher: triggerCharacters(trigger, minChars),
    suggestionClass: '',
    onEnter: args => {
      if (!isAllowed()) return false;
      range.value = args.range;
      editorView = args.view;
      if (searchTerm) searchTerm.value = args.text || '';
      showMenu.value = true;
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
      return event.keyCode === 13 && showMenu.value && interceptEnter;
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
      showMenu: showToolsMenu,
      searchTerm: toolSearchKey,
      isAllowed: () => props.enableCaptainTools,
      interceptEnter: true,
    }),
    createSuggestionPlugin({
      trigger: '@',
      showMenu: showUserMentions,
      searchTerm: mentionSearchKey,
      isAllowed: () =>
        props.isPrivate ||
        props.isGroupConversation ||
        !props.enableCaptainTools,
    }),
    createSuggestionPlugin({
      trigger: '/',
      showMenu: showCannedMenu,
      searchTerm: cannedSearchKey,
      isAllowed: () => !props.isPrivate,
    }),
    createSuggestionPlugin({
      trigger: '{{',
      showMenu: showVariables,
      searchTerm: variableSearchKey,
      isAllowed: () => !props.isPrivate,
    }),
    createVariableInputRule({
      isPrivate: () => props.isPrivate,
      getVariables: () => props.variables,
    }),
    createSuggestionPlugin({
      trigger: '#',
      showMenu: showMacroMenu,
      searchTerm: macroSearchKey,
      isAllowed: () => props.enableMacros,
    }),
    createSuggestionPlugin({
      trigger: ':',
      minChars: 2,
      showMenu: showEmojiMenu,
      searchTerm: emojiSearchKey,
    }),
    createSuggestionPlugin({
      trigger: '#',
      minChars: 0,
      showMenu: showConversationMenu,
      searchTerm: conversationSearchKey,
      isAllowed: () => props.enableConversationMention,
    }),
  ];
});

const sendWithSignature = computed(() => {
  // this is considered the source of truth for signature display
  if (props.allowSignature && !props.isPrivate && props.channelType) {
    return fetchSignatureFlagFromUISettings(props.channelType);
  }

  return false;
});

const signaturePosition = computed(() => {
  return (
    props.signaturePositionOverride ||
    currentUser.value?.ui_settings?.signature_position ||
    'top'
  );
});

const signatureEditorLine = computed(
  () =>
    findSignatureSeparator(
      props.signatureSeparatorOverride ||
        currentUser.value?.ui_settings?.signature_separator
    ).editorLine
);

const shouldShowSignaturePreview = computed(() => {
  return sendWithSignature.value && props.signature;
});

const formattedSignature = computed(() => {
  if (!props.signature) return '';
  return formatMessage(props.signature, false, false);
});

watch(shouldShowUserMentions, updatedValue => {
  emit('toggleUserMention', updatedValue);
});
watch(shouldShowCannedResponses, updatedValue => {
  emit('toggleCannedMenu', updatedValue);
});
watch(shouldShowVariables, updatedValue => {
  emit('toggleVariablesMenu', updatedValue);
});
watch(shouldShowMacros, updatedValue => {
  emit('toggleMacrosMenu', updatedValue);
});
watch(showToolsMenu, updatedValue => {
  emit('toggleToolsMenu', props.enableCaptainTools && updatedValue);
});

watch(showConversationMenu, updatedValue => {
  emit(
    'toggleConversationMention',
    props.enableConversationMention && updatedValue
  );
});

function focusEditorInputField(pos = 'end') {
  const { tr } = editorView.state;

  // Signature is now displayed as read-only preview outside the editor,
  // so cursor positioning is straightforward
  const selection =
    pos === 'end' ? Selection.atEnd(tr.doc) : Selection.atStart(tr.doc);

  editorView.dispatch(tr.setSelection(selection));
  editorView.focus();
}

function isBodyEmpty(content) {
  // if content is undefined, we assume that the body is empty
  if (!content) return true;

  // trimming should remove all the whitespaces, so we can check the length
  return content.trim().length === 0;
}

function handleEmptyBodyWithSignature() {
  const { schema, tr, doc } = state;

  const isEmptyParagraph = node =>
    node && node.type === schema.nodes.paragraph && node.content.size === 0;

  // Check if empty paragraph already exists to prevent duplicates when toggling signatures
  if (isEmptyParagraph(doc.firstChild)) {
    focusEditorInputField('start');
    return;
  }

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

function handleCopilotClick() {
  const isOpening = !showSelectionMenu.value;
  if (isOpening) {
    useTrack(CAPTAIN_EVENTS.EDITOR_AI_MENU_OPENED, {
      conversationId: props.conversationId,
      entryPoint: 'inline',
    });
  }
  showSelectionMenu.value = isOpening;
}

function handleClickOutside(event) {
  // Check if the clicked element or its parents have the ignored class
  if (event.target.closest('.ProseMirror-copilot')) return;
  showSelectionMenu.value = false;
}

function reloadState(content = props.modelValue) {
  range.value = null;
  showUserMentions.value = false;
  showCannedMenu.value = false;
  showVariables.value = false;
  showEmojiMenu.value = false;
  showToolsMenu.value = false;
  showMacroMenu.value = false;

  const unrefContent = unref(content);
  state = createState(
    unrefContent,
    props.placeholder,
    plugins.value,
    { onImageUpload: openFileBrowser, onCopilotClick: handleCopilotClick },
    editorMenuOptions.value
  );

  editorView.updateState(state);
  focusEditor(unrefContent);
}

function setMenubarPosition({ selection } = {}) {
  const wrapper = editorRoot.value;
  if (!selection || !wrapper) return;
  if (!isEditorMenuPopover.value) return;

  const rect = wrapper.getBoundingClientRect();
  const isRtl = getComputedStyle(wrapper).direction === 'rtl';

  // Calculate coords and final position
  const coords = getSelectionCoords(editorView, selection, rect);
  const { left, top, width } = calculateMenuPosition(coords, rect, isRtl);

  wrapper.style.setProperty('--selection-left', `${left}px`);
  wrapper.style.setProperty(
    '--selection-right',
    `${rect.width - left - width}px`
  );
  wrapper.style.setProperty('--selection-top', `${top}px`);
}

function checkSelection(editorState) {
  showSelectionMenu.value = false;
  const { selection } = editorState;
  // Skip NodeSelection (from Esc -> selectParentNode); only text ranges count.
  const hasSelection = !selection.empty && !selection.node;
  if (hasSelection === isTextSelected.value) return;

  isTextSelected.value = hasSelection;
  const wrapper = editorRoot.value;
  if (!wrapper) return;

  wrapper.classList.toggle('has-selection', hasSelection);
  if (hasSelection) setMenubarPosition(editorState);
}

function emitOnChange() {
  emit('input', contentFromEditor());
  emit('update:modelValue', contentFromEditor());
}

function isEnterToSendEnabled() {
  return isEditorHotKeyEnabled('enter');
}

function isCmdPlusEnterToSendEnabled() {
  return isEditorHotKeyEnabled('cmd_enter');
}

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
      props.channelType === MESSAGE_SIGNATURE_FORMATTING
        ? t(
            'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_SUCCESS'
          )
        : t('CONVERSATION.REPLYBOX.IMAGE_UPLOAD_SUCCESS')
    );
  } catch (error) {
    useAlert(
      t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.IMAGE_UPLOAD_ERROR')
    );
  }
}

function uploadImageIfWithinSizeLimit(file) {
  if (!file) return;
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
}

function onFileChange() {
  const input = imageUpload.value;
  uploadImageIfWithinSizeLimit(input.files[0]);
  input.value = '';
}

const allowsInlineImagePaste = computed(
  () =>
    !props.isPrivate &&
    (props.channelType === INBOX_TYPES.EMAIL ||
      props.channelType === INBOX_TYPES.WEB)
);

// Shift+Cmd/Ctrl+V on email/website: upload a clipboard image inline. This
// gesture's native paste event carries no image, so clipboard.read() is the
// only way to get the bytes. No preventDefault: text still pastes natively.
async function pasteInlineImageFromClipboard() {
  if (!editorView?.hasFocus()) return;
  if (!allowsInlineImagePaste.value || !navigator.clipboard?.read) return;
  try {
    const items = await navigator.clipboard.read();
    const imageItem = items.find(item =>
      item.types.some(type => INLINE_IMAGE_PASTE_TYPES.includes(type))
    );
    if (!imageItem) return;
    const imageType = imageItem.types.find(type =>
      INLINE_IMAGE_PASTE_TYPES.includes(type)
    );
    const blob = await imageItem.getType(imageType);
    uploadImageIfWithinSizeLimit(
      new File([blob], 'pasted-image', { type: imageType })
    );
  } catch (error) {
    // clipboard-read denied/unfocused (NotAllowedError): image can't be read.
    // Text paste is unaffected — ProseMirror handles it from the native event.
  }
}

useKeyboardEvents({
  'Alt+KeyP': {
    action: focusEditorInputField,
    allowOnFocusedInput: false,
  },
  'Alt+KeyL': {
    action: focusEditorInputField,
    allowOnFocusedInput: false,
  },
  '$mod+Shift+KeyV': {
    action: pasteInlineImageFromClipboard,
    allowOnFocusedInput: true,
  },
});

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
  // Use the editor's current schema to ensure compatibility with buildMessageSchema
  const currentSchema = editorView.state.schema;
  // Strip unsupported formatting before parsing to ensure content can be inserted
  // into channels that don't support certain markdown features (e.g., API channels)
  const sanitizedContent = stripUnsupportedFormatting(content, currentSchema);
  let node = new MessageMarkdownTransformer(currentSchema).parse(
    sanitizedContent
  );

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
    tool: CONVERSATION_EVENTS.INSERTED_A_TOOL,
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
  if (isComposing(event)) return false;
  if (isEscape(event)) {
    collapseSelection(editorView);
    return true;
  }
  if (isEnterToSendEnabled()) {
    handleLineBreakWhenEnterToSendEnabled(event);
  }
  if (isCmdPlusEnterToSendEnabled()) {
    handleLineBreakWhenCmdAndEnterToSendEnabled(event);
  }
  return false;
}

function createEditorView() {
  editorView = new EditorView(editor.value, {
    state: state,
    editable: () => !props.disabled,
    attributes: { class: 'resizable-editor-body' },
    nodeViews: {
      image: imageResizeView,
    },
    dispatchTransaction: tx => {
      state = state.apply(tx);
      editorView.updateState(state);
      if (tx.docChanged) {
        emitOnChange();
      }
      checkSelection(state);
    },
    handleDOMEvents: {
      keyup: () => {
        if (!props.disabled) {
          if (props.modelValue.length) {
            typingIndicator.start();
          } else {
            typingIndicator.stop();
          }
        }
      },
      keydown: (view, event) => !props.disabled && onKeydown(event),
      focus: () => !props.disabled && emit('focus'),
      blur: () => {
        if (props.disabled) return;
        typingIndicator.stop();
        // PM keeps its selection on blur — clear the menu flags manually.
        isTextSelected.value = false;
        editorRoot.value?.classList.remove('has-selection');
        emit('blur');
      },
      paste: (view, event) => {
        if (props.disabled) return;
        const { files } = event.clipboardData;
        if (!files.length) return;
        event.preventDefault();
        // Paste text content alongside files (e.g., spreadsheet data from Numbers app)
        // Numbers app includes invalid 0-byte attachments with text, so we paste the text here
        // while ReplyBox filters and handles valid file attachments
        const text = event.clipboardData.getData('text/plain');
        if (text) {
          view.dispatch(view.state.tr.insertText(text));
          emitOnChange();
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
    reloadState(props.modelValue);
  }
);

watch(
  computed(() => props.isPrivate),
  () => {
    reloadState(props.modelValue);
  }
);

watch(effectiveChannelType, () => {
  reloadState(props.modelValue);
});

watch(
  computed(() => props.disabled),
  () => editorView?.setProps({})
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

onMounted(() => {
  // [VITE] state assignment was done in created before
  state = createState(
    props.modelValue,
    props.placeholder,
    plugins.value,
    { onImageUpload: openFileBrowser, onCopilotClick: handleCopilotClick },
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
useEmitter(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, content => {
  if (!props.enableInsertEvents) return;
  insertContentIntoEditor(content);
});

function insertMentionTrigger(char) {
  if (!editorView) return;
  focusEditorInputField('end');
  const editorState = editorView.state;
  const { from, to } = editorState.selection;
  const textBefore =
    from > 0
      ? editorState.doc.textBetween(Math.max(0, from - 1), from, '\0', '\0')
      : '';
  const prefix = textBefore && !/\s/.test(textBefore) ? ' ' : '';
  const tr = editorState.tr.insertText(`${prefix}${char}`, from, to);
  editorView.dispatch(tr);
}

defineExpose({ focusEditorInputField, insertMentionTrigger });
</script>

<template>
  <div
    ref="editorRoot"
    class="relative w-full"
    :class="{
      'opacity-50 cursor-not-allowed pointer-events-none': disabled,
    }"
  >
    <TagGroupMembers
      v-if="showUserMentions && isGroupConversation && !isPrivate"
      :search-key="mentionSearchKey"
      :group-contact-id="groupContactId"
      :exclude-phone-number="inboxPhoneNumber"
      @select-agent="content => insertSpecialContent('mention', content)"
    />
    <TagAgents
      v-if="showUserMentions && (isPrivate || enableMentionDropdown)"
      :caret-position="caretPosition"
      :search-key="mentionSearchKey"
      :exclude-user-id="enableMentionDropdown ? currentUser?.id : null"
      @close="dismissUserMentions"
      @release="releaseUserMentions"
      @remove-trigger="removeSuggestionTrigger"
      @select-agent="content => insertSpecialContent('mention', content)"
    />
    <CannedResponse
      v-if="shouldShowCannedResponses"
      :caret-position="caretPosition"
      :search-key="cannedSearchKey"
      :variables="variables"
      :schema="editorSchema"
      @close="dismissCannedResponses"
      @release="releaseCannedResponses"
      @remove-trigger="removeSuggestionTrigger"
      @replace="content => insertSpecialContent('cannedResponse', content)"
    />
    <VariableList
      v-if="shouldShowVariables"
      :caret-position="caretPosition"
      :search-key="variableSearchKey"
      :variables="variables"
      :automation="enableAutomationVariables"
      @close="dismissVariables"
      @release="releaseVariables"
      @remove-trigger="removeSuggestionTrigger"
      @select-variable="content => insertSpecialContent('variable', content)"
    />
    <MacroList
      v-if="shouldShowMacros"
      :caret-position="caretPosition"
      :search-key="macroSearchKey"
      @close="dismissMacros"
      @release="releaseMacros"
      @remove-trigger="removeSuggestionTrigger"
      @select-macro="onSelectMacro"
    />
    <KeyboardEmojiSelector
      v-if="showEmojiMenu"
      :caret-position="caretPosition"
      :search-key="emojiSearchKey"
      @close="dismissEmojiMenu"
      @release="releaseEmojiMenu"
      @remove-trigger="removeSuggestionTrigger"
      @select-emoji="emoji => insertSpecialContent('emoji', emoji)"
    />
    <TagTools
      v-if="showToolsMenu"
      :search-key="toolSearchKey"
      @select-tool="content => insertSpecialContent('tool', content)"
    />
    <TagConversations
      v-if="showConversationMenu && enableConversationMention"
      :search-key="conversationSearchKey"
      @select-conversation="content => insertSpecialContent('mention', content)"
    />
    <CopilotMenuBar
      v-if="showSelectionMenu"
      v-on-click-outside="handleClickOutside"
      :has-selection="isTextSelected"
      :is-editor-menu-popover="isEditorMenuPopover"
      :has-content="!isBodyEmpty(modelValue)"
      :conversation-id="conversationId"
      :show-selection-menu="showSelectionMenu"
      :show-general-menu="false"
      class="copilot-editor-menu"
      @execute-copilot-action="handleCopilotAction"
    />
    <input
      ref="imageUpload"
      type="file"
      accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
      hidden
      @change="onFileChange"
    />
    <!-- Signature preview at top -->
    <div
      v-if="shouldShowSignaturePreview && signaturePosition === 'top'"
      v-tooltip="t('CONVERSATION.FOOTER.SIGNATURE_LABEL_TOP_TOOLTIP')"
      class="signature-preview signature-preview--top"
    >
      <div class="signature-label">
        {{ t('CONVERSATION.FOOTER.SIGNATURE_LABEL_TOP') }}
      </div>
      <div v-dompurify-html="formattedSignature" class="signature-content" />
      <div v-if="signatureEditorLine" class="signature-separator">
        {{ signatureEditorLine }}
      </div>
    </div>
    <div ref="editor" class="editor-mount" />
    <!-- Signature preview at bottom -->
    <div
      v-if="shouldShowSignaturePreview && signaturePosition === 'bottom'"
      v-tooltip="t('CONVERSATION.FOOTER.SIGNATURE_LABEL_BOTTOM_TOOLTIP')"
      class="signature-preview signature-preview--bottom"
    >
      <div class="signature-label">
        {{ t('CONVERSATION.FOOTER.SIGNATURE_LABEL_BOTTOM') }}
      </div>
      <div v-if="signatureEditorLine" class="signature-separator">
        {{ signatureEditorLine }}
      </div>
      <div v-dompurify-html="formattedSignature" class="signature-content" />
    </div>
    <slot name="footer" />
  </div>
</template>

<style lang="scss">
@import '@chatwoot/prosemirror-schema/src/styles/base.scss';

// The resizable reply box gives the editor a fixed height, and the signature preview sits next to
// the text area inside it, so a tall signature spilled over the bottom bar and covered the send
// button. With a preview, the editor may stretch past the dragged height, up to room for the
// preview's cap plus 3rem of typing, so a signature fits even in a small box. The preview takes
// what it needs up to that cap, which grows with the box, and scrolls past it; the text area
// gets the rest and scrolls on its own. When something else shares the box (the quoted email,
// the preview's margin), the preview is what gives way, so nothing spills over the bottom bar.
.resizable-editor-wrapper .resizable-editor-split:has(> .signature-preview) {
  --editor-applied-height: clamp(
    var(--editor-min-allowed, 5rem),
    var(--editor-height, 5rem),
    var(--editor-max-allowed, 7.5rem)
  );
  --signature-preview-max: max(
    10rem,
    calc(var(--editor-applied-height) - 3rem)
  );

  height: auto;
  min-height: var(--editor-applied-height);
  max-height: calc(var(--signature-preview-max) + 3rem);

  > .signature-preview {
    @apply min-h-0 shrink overflow-y-auto;

    max-height: var(--signature-preview-max);

    // Only a reminder of what gets appended, so images show as thumbnails. The sent message
    // keeps them at full size.
    img {
      @apply max-h-12 w-auto;
    }
  }
}

.signature-preview {
  @apply px-1 py-1 text-n-slate-10 text-sm select-none opacity-70 cursor-default;

  &--top {
    @apply border-b border-n-weak pb-1;

    .signature-separator {
      @apply text-n-slate-9 mt-1 mb-0;
    }
  }

  &--bottom {
    @apply border-t border-n-weak pt-1 mt-2;

    .signature-separator {
      @apply text-n-slate-9 mb-1 mt-0;
    }
  }

  .signature-label {
    @apply text-xs text-n-slate-9 mb-1;
  }

  .signature-content {
    @apply break-words;

    :deep(p) {
      @apply m-0 text-n-slate-10;
    }

    :deep(a) {
      @apply text-n-slate-10 no-underline;
    }
  }
}

.ProseMirror-menubar-wrapper {
  @apply flex flex-col gap-3;

  .ProseMirror-menubar {
    min-height: 1.25rem !important;
    @apply items-center gap-4 flex pb-0 bg-transparent text-n-slate-11 relative ltr:-left-[3px] rtl:-right-[3px];

    .ProseMirror-menu-active {
      @apply bg-n-slate-5 dark:bg-n-solid-3 !important;
    }

    .ProseMirror-menuitem {
      @apply mr-0 size-4 flex items-center justify-center;

      .ProseMirror-icon {
        @apply size-4 flex items-center justify-center flex-shrink-0;

        svg {
          @apply size-full;
        }
      }

      .ProseMirror-copilot svg {
        @apply fill-n-violet-9 text-n-violet-9 stroke-none;
      }
    }
  }

  .ProseMirror-menubar:not(:has(*)) {
    max-height: none !important;
    min-height: 0 !important;
    padding: 0 !important;
    display: none !important;
  }

  > .ProseMirror {
    @apply p-0 break-words text-n-slate-12;

    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    p {
      @apply text-n-slate-12;
    }

    blockquote {
      @apply border-n-slate-7;

      p {
        @apply text-n-slate-11;
      }
    }
  }
}

// Room for the table grips and add buttons, which sit outside the table.
// .editor-mount keeps this off the article editor.
.editor-mount .ProseMirror .tableWrapper {
  @apply m-0 pt-4 pb-5 ps-5 pe-6;
}

.ProseMirror-woot-style {
  @apply overflow-auto;
}

.ProseMirror-woot-style:not(
    :where(.resizable-editor-wrapper .resizable-editor-body)
  ) {
  @apply min-h-[5rem] max-h-[7.5rem];
}

.ProseMirror-prompt-backdrop::backdrop {
  @apply bg-n-alpha-black1 backdrop-blur-[4px];
}

.ProseMirror-prompt {
  @apply bg-n-alpha-3 border border-n-strong p-6 shadow-xl rounded-xl w-96 !important;

  h5 {
    @apply text-n-slate-12 mb-3;
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

.prosemirror-mention-node[mention-type='conversation'] {
  font-size: 0;

  &::before {
    font-size: 0.875rem;
    content: '#' attr(mention-user-full-name);
  }
}

.prosemirror-tools-node {
  @apply font-medium text-n-slate-12 py-0;
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
  @apply text-n-ruby-9 dark:text-n-ruby-9 font-normal text-sm pt-1 pb-0 px-0;
}

// Default copilot menu position (non-popover editors like components-next/Editor)
// When popover-prosemirror-menu is NOT on the wrapper, anchor below the menubar
:not(.popover-prosemirror-menu) > .copilot-editor-menu {
  top: 1.5rem !important;

  [dir='rtl'] & {
    left: auto !important;
    right: 0 !important;
  }
}

// Float editor menu
.popover-prosemirror-menu {
  position: relative;

  .ProseMirror p:last-child:not(:is(th, td) > p) {
    margin-bottom: 10px !important;
  }

  .ProseMirror-menubar {
    display: none; // Hide by default
  }

  &.has-selection {
    // Hide menu completely when it has no items
    .ProseMirror-menubar:not(:has(*)) {
      display: none !important;
    }

    .ProseMirror-menubar {
      @apply rounded-lg !px-3 !py-1.5 z-50 bg-n-background items-center gap-4 ml-0 mb-0 shadow-md outline outline-1 outline-n-weak;
      display: flex;
      width: fit-content !important;
      position: absolute !important;

      // Default/LTR: position from left
      top: var(--selection-top);
      left: var(--selection-left);

      // RTL: position from right instead
      [dir='rtl'] & {
        left: auto;
        right: var(--selection-right);
      }

      .ProseMirror-menuitem {
        @apply mr-0 size-4 flex items-center;

        .ProseMirror-icon {
          @apply p-0.5 flex-shrink-0;
        }

        .ProseMirror-copilot svg {
          @apply fill-n-violet-9 text-n-violet-9 stroke-none;
        }
      }

      .ProseMirror-menu-active {
        @apply bg-n-slate-3;
      }
    }
  }
}
</style>

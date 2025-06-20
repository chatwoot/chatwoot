<script setup>
import { computed, ref, onMounted } from 'vue';
import { debounce } from '@chatwoot/utils';
import { useI18n } from 'vue-i18n';

import FullEditor from 'dashboard/components/widgets/WootWriter/FullEditor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  prompt: {
    type: Object,
    default: () => ({}),
  },
  isUpdating: {
    type: Boolean,
    default: false,
  },
  isSaved: {
    type: Boolean,
    default: false,
  },
  isReadonly: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['savePrompt', 'savePromptAsync', 'goBack']);

const { t } = useI18n();

// Local state for the prompt being edited
const localPrompt = ref({});

onMounted(() => {
  // Initialize local state with the prop value
  localPrompt.value = { ...props.prompt };
});

// Custom menu options for prompt editor (without image upload)
const PROMPT_EDITOR_MENU_OPTIONS = [
  'strong',
  'em',
  'link',
  'undo',
  'redo',
  'bulletList',
  'orderedList',
  'h1',
  'h2',
  'h3',
  'code',
];

const isNewPrompt = computed(() => !props.prompt?.id);

const saveAndSync = value => {
  emit('savePrompt', value);
};

// this will only send the data to the backend
// but will not update the local state preventing unnecessary re-renders
// since the data is already saved and we keep the editor text as the source of truth
const quickSave = debounce(value => emit('savePromptAsync', value), 400, false);

// 2.5 seconds is enough to know that the user has stopped typing and is taking a pause
// so we can save the data to the backend and retrieve the updated data
// this will update the local state with response data
// Only use to save for existing prompts
const saveAndSyncDebounced = debounce(saveAndSync, 2500, false);

// Debounced save for new prompts
const quickSaveNewPrompt = debounce(saveAndSync, 400, false);

const handleSave = value => {
  // Update local state immediately
  localPrompt.value = { ...localPrompt.value, ...value };

  if (isNewPrompt.value) {
    quickSaveNewPrompt(localPrompt.value);
  } else {
    quickSave(localPrompt.value);
    saveAndSyncDebounced(localPrompt.value);
  }
};

const promptKey = computed({
  get: () => localPrompt.value.prompt_key || '',
  set: value => {
    handleSave({ prompt_key: value });
  },
});

const promptText = computed({
  get: () => localPrompt.value.text || '',
  set: text => {
    handleSave({ text });
  },
});

const onClickGoBack = () => {
  emit('goBack');
};

const onClickUpdate = () => {
  // Emit the data from the local state
  emit('savePrompt', localPrompt.value);
};
</script>

<template>
  <div class="flex flex-col w-full h-full bg-white dark:bg-slate-900">
    <!-- Header -->
    <div
      class="flex items-center justify-between px-6 py-4 border-b border-slate-200 dark:border-slate-700"
    >
      <div class="flex items-center gap-3">
        <NextButton
          icon="i-lucide-arrow-left"
          variant="clear"
          size="sm"
          @click="onClickGoBack"
        />
        <div class="text-sm text-slate-600 dark:text-slate-400">
          {{ localPrompt.prompt_key || t('PROMPTS_PAGE.EDIT.TITLE') }}
        </div>
      </div>
      <div class="flex items-center gap-3">
        <span
          v-if="isUpdating"
          class="inline-flex items-center gap-1 text-sm text-slate-600 dark:text-slate-400"
        >
          <i class="i-lucide-loader-2 animate-spin w-4 h-4" />
          {{ t('PROMPTS_PAGE.EDITOR.SAVING') }}
        </span>
        <span
          v-else-if="isSaved"
          class="inline-flex items-center gap-1 text-sm text-green-600 dark:text-green-400"
        >
          <i class="i-lucide-check w-4 h-4" />
          {{ t('PROMPTS_PAGE.EDITOR.SAVED') }}
        </span>
        <NextButton
          v-if="!isReadonly"
          :label="$t('PROMPTS_PAGE.EDITOR.UPDATE_BUTTON_TEXT')"
          size="sm"
          :is-loading="isUpdating"
          :disabled="isUpdating"
          @click="onClickUpdate"
        />
      </div>
    </div>

    <!-- Content -->
    <div class="flex-1 overflow-auto">
      <!-- Rich Text Editor -->
      <FullEditor
        :key="localPrompt.prompt_key || 'new-prompt'"
        v-model="promptText"
        class="py-0 pb-10 pl-4 rtl:pr-4 rtl:pl-0 h-fit"
        :placeholder="t('PROMPTS_PAGE.FORM.TEXT.PLACEHOLDER')"
        :enabled-menu-options="PROMPT_EDITOR_MENU_OPTIONS"
        autofocus
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
::v-deep {
  .ProseMirror .empty-node::before {
    @apply text-slate-200 dark:text-slate-500 text-base;
  }

  .ProseMirror-menubar-wrapper {
    .ProseMirror-woot-style {
      @apply min-h-[15rem] max-h-full;
    }
  }

  .ProseMirror-menubar {
    display: none; // Hide by default
  }

  .editor-root .has-selection {
    .ProseMirror-menubar {
      @apply h-8 rounded-lg !px-2 z-50 bg-slate-50 dark:bg-slate-800 items-center gap-4 ml-0 mb-0 shadow-md border border-slate-75 dark:border-slate-700/50;
      display: flex;
      top: var(--selection-top, auto) !important;
      left: var(--selection-left, 0) !important;
      width: fit-content !important;
      position: absolute !important;

      .ProseMirror-menuitem {
        @apply mr-0;

        .ProseMirror-icon {
          @apply p-0 mt-1 !mr-0;

          svg {
            width: 20px !important;
            height: 20px !important;
          }
        }
      }
    }
  }
}
</style>

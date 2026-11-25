<script setup>
import { ref, inject } from 'vue';
import CopilotEditor from 'dashboard/components/widgets/WootWriter/CopilotEditor.vue';
import CaptainLoader from 'dashboard/components/widgets/conversation/copilot/CaptainLoader.vue';

const props = defineProps({
  showCopilotEditor: {
    type: Boolean,
    default: false,
  },
  isGeneratingContent: {
    type: Boolean,
    default: false,
  },
  generatedContent: {
    type: String,
    default: '',
  },
  placeholder: {
    type: String,
    default: undefined,
  },
});

const emit = defineEmits([
  'focus',
  'blur',
  'clearSelection',
  'contentReady',
  'send',
]);

const requestEditorHeight = inject('requestEditorHeight', () => {});

const copilotEditorContent = ref('');

// The loader needs no room of its own, the suggestion asks for its own
const onStateEnter = () => {
  if (props.isGeneratingContent) requestEditorHeight(0);
};

const onFocus = () => {
  emit('focus');
};

const onBlur = () => {
  emit('blur');
};

const clearEditorSelection = () => {
  emit('clearSelection');
};

const onSend = () => {
  emit('send', copilotEditorContent.value);
  copilotEditorContent.value = '';
};
</script>

<template>
  <div class="relative">
    <Transition
      enter-active-class="transition-opacity duration-200 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="absolute inset-x-0 top-0 pointer-events-none transition-opacity duration-200 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
      @enter="onStateEnter"
      @after-enter="emit('contentReady')"
    >
      <CopilotEditor
        v-if="showCopilotEditor && !isGeneratingContent"
        key="copilot-editor"
        v-model="copilotEditorContent"
        class="copilot-editor"
        :generated-content="generatedContent"
        :placeholder="placeholder"
        :min-height="4"
        :enabled-menu-options="[]"
        @focus="onFocus"
        @blur="onBlur"
        @clear-selection="clearEditorSelection"
        @send="onSend"
      />
      <div
        v-else-if="isGeneratingContent"
        key="loading-state"
        class="resizable-editor-body flex flex-col justify-end mb-3"
      >
        <div
          class="bg-n-iris-5 rounded min-h-[4.75rem] w-full p-4 flex items-start"
        >
          <div class="flex items-center gap-2">
            <CaptainLoader class="text-n-iris-10 size-4" />
            <span class="text-sm text-n-iris-10">
              {{ $t('CONVERSATION.REPLYBOX.COPILOT_THINKING') }}
            </span>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style lang="scss">
.copilot-editor {
  .ProseMirror-menubar {
    display: none;
  }
}
</style>

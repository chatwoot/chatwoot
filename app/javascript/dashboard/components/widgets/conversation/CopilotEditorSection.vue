<script setup>
import { ref } from 'vue';
import CopilotEditor from 'dashboard/components/widgets/WootWriter/CopilotEditor.vue';
import Icon from 'next/icon/Icon.vue';

defineProps({
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
  isPopout: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['focus', 'blur', 'clearSelection']);

const copilotEditorContent = ref('');

const onFocus = () => {
  emit('focus');
};

const onBlur = () => {
  emit('blur');
};

const clearEditorSelection = () => {
  emit('clearSelection');
};
</script>

<template>
  <CopilotEditor
    v-if="showCopilotEditor && !isGeneratingContent"
    v-model="copilotEditorContent"
    class="copilot-editor"
    :generated-content="generatedContent"
    :min-height="4"
    :enabled-menu-options="[]"
    :is-popout="isPopout"
    @focus="onFocus"
    @blur="onBlur"
    @clear-selection="clearEditorSelection"
  />
  <div
    v-else-if="isGeneratingContent"
    class="bg-n-iris-5 rounded min-h-16 w-full mb-4 p-4 flex items-start animate-pulse-scale"
  >
    <div class="flex items-center gap-2">
      <Icon
        icon="i-fluent-bubble-multiple-20-filled"
        class="text-n-iris-10 size-4 animate-spin"
      />
      <span class="text-sm text-n-iris-10">
        {{ $t('CONVERSATION.REPLYBOX.COPILOT_THINKING') }}
      </span>
    </div>
  </div>
</template>

<style lang="scss">
.copilot-editor {
  .ProseMirror-menubar {
    display: none;
  }
}

@keyframes pulse-scale {
  0%,
  100% {
    transform: scale(1);
    opacity: 0.9;
  }
  50% {
    transform: scale(1.005);
    opacity: 1;
  }
}

.animate-pulse-scale {
  animation: pulse-scale 1.5s ease-in-out infinite;
}
</style>

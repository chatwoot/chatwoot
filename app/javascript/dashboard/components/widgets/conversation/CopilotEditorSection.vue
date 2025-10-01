<script setup>
import { computed } from 'vue';
import CopilotEditor from 'dashboard/components/widgets/WootWriter/CopilotEditor.vue';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  showCopilotEditor: {
    type: Boolean,
    default: false,
  },
  isGeneratingContent: {
    type: Boolean,
    default: false,
  },
  copilotEditorContent: {
    type: String,
    default: '',
  },
  generatedContent: {
    type: String,
    default: '',
  },
  updateEditorSelectionWith: {
    type: String,
    default: '',
  },
});

const emit = defineEmits([
  'update:copilotEditorContent',
  'focus',
  'blur',
  'clearSelection',
]);

const copilotContent = computed({
  get: () => props.copilotEditorContent,
  set: value => emit('update:copilotEditorContent', value),
});

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
    v-model="copilotContent"
    class="copilot-editor"
    :generated-content="generatedContent"
    :update-selection-with="updateEditorSelectionWith"
    :min-height="4"
    :enabled-menu-options="[]"
    @focus="onFocus"
    @blur="onBlur"
    @clear-selection="clearEditorSelection"
  />
  <div
    v-else-if="isGeneratingContent"
    class="bg-n-iris-5 rounded min-h-28 w-full mb-4 p-4 flex items-start"
  >
    <div class="flex items-center gap-2">
      <Icon
        icon="i-fluent-bubble-multiple-20-filled"
        class="text-n-iris-10 size-4 animate-spin"
      />
      <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
      <span class="text-sm text-n-iris-9"> Copilot is thinking </span>
    </div>
  </div>
</template>

<style lang="scss">
.copilot-editor {
  .ProseMirror-menubar {
    display: none;
  }
}
</style>

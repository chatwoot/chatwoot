<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Editor from 'dashboard/components-next/Editor/Editor.vue';
import CopilotEditorSection from 'dashboard/components/widgets/conversation/CopilotEditorSection.vue';

const props = defineProps({
  hasErrors: { type: Boolean, default: false },
  sendWithSignature: { type: Boolean, default: false },
  messageSignature: { type: String, default: '' },
  channelType: { type: String, default: '' },
  medium: { type: String, default: '' },
  copilot: { type: Object, default: null },
});

const editorKey = computed(() => `editor-${props.channelType}-${props.medium}`);

const { t } = useI18n();

const modelValue = defineModel({
  type: String,
  default: '',
});

const isCopilotActive = computed(() => props.copilot?.isActive?.value ?? false);

const executeCopilotAction = (action, data) => {
  if (props.copilot) {
    props.copilot.execute(action, data);
  }
};
</script>

<template>
  <div class="flex-1 h-full px-4 py-4">
    <Transition
      mode="out-in"
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0 translate-y-2 scale-[0.98]"
      enter-to-class="opacity-100 translate-y-0 scale-100"
      leave-active-class="transition-all duration-200 ease-in"
      leave-from-class="opacity-100 translate-y-0 scale-100"
      leave-to-class="opacity-0 translate-y-2 scale-[0.98]"
    >
      <div
        :key="copilot ? copilot.editorTransitionKey.value : 'rich'"
        class="h-full"
      >
        <CopilotEditorSection
          v-if="isCopilotActive"
          :show-copilot-editor="copilot.showEditor.value"
          :is-generating-content="copilot.isGenerating.value"
          :generated-content="copilot.generatedContent.value"
          class="!mb-0"
          @focus="() => {}"
          @blur="() => {}"
          @clear-selection="() => {}"
          @content-ready="copilot.setContentReady"
          @send="copilot.sendFollowUp"
        />
        <Editor
          v-else
          v-model="modelValue"
          :editor-key="editorKey"
          :placeholder="
            t('COMPOSE_NEW_CONVERSATION.FORM.MESSAGE_EDITOR.PLACEHOLDER')
          "
          class="[&>div]:!border-transparent [&>div]:px-0 [&>div]:py-0 [&>div]:!bg-transparent h-full [&_.ProseMirror-woot-style]:!max-h-[12.5rem] [&_.ProseMirror-woot-style]:!min-h-[12rem] [&_.ProseMirror-menubar]:!pt-0 [&_.mention--box]:-top-[7.5rem] [&_.mention--box]:bottom-[unset]"
          :class="
            hasErrors
              ? '[&_.empty-node]:before:!text-n-ruby-9 [&_.empty-node]:dark:before:!text-n-ruby-9'
              : ''
          "
          enable-variables
          enable-captain-tools
          :show-character-count="false"
          :signature="messageSignature"
          allow-signature
          :send-with-signature="sendWithSignature"
          :channel-type="channelType"
          :medium="medium"
          @execute-copilot-action="executeCopilotAction"
        />
      </div>
    </Transition>
  </div>
</template>

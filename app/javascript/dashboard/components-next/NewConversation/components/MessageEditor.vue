<script setup>
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

defineProps({
  modelValue: {
    type: String,
    required: true,
  },
  isEmailOrWebWidgetInbox: {
    type: Boolean,
    required: true,
  },
  isWhatsappInbox: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits(['update:modelValue']);
</script>

<template>
  <div v-if="isEmailOrWebWidgetInbox" class="flex-1 h-full">
    <Editor
      :model-value="modelValue"
      placeholder="Write your message here..."
      class="[&>div]:!border-transparent [&>div]:px-4 [&>div]:py-4 [&>div]:!bg-transparent h-full [&_.ProseMirror-woot-style]:!max-h-[200px]"
      :show-character-count="false"
      @update:model-value="emit('update:modelValue', $event)"
    />
  </div>
  <div v-else-if="!isWhatsappInbox" class="flex-1 h-full">
    <TextArea
      :model-value="modelValue"
      placeholder="Write your message here..."
      class="!px-0 [&>div]:!px-4 [&>div]:!border-transparent [&>div]:!bg-transparent"
      auto-height
      @update:model-value="emit('update:modelValue', $event)"
    />
  </div>
</template>

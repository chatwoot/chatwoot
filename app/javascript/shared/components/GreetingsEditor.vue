<script setup>
import { computed } from 'vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';

const props = defineProps({
  modelValue: { type: String, default: '' },
  richtext: { type: Boolean, default: false },
  label: { type: String, default: '' },
  placeholder: { type: String, default: '' },
});

const emit = defineEmits(['update:modelValue']);

const greetingsMessage = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value),
});
</script>

<template>
  <section class="w-3/4">
    <div
      v-if="richtext"
      class="px-4 py-0 mx-0 mt-0 mb-4 bg-white border border-solid rounded-md border-slate-200 dark:border-slate-600 dark:bg-slate-900"
    >
      <WootMessageEditor
        v-model="greetingsMessage"
        is-format-mode
        enable-variables
        class="bg-white input dark:bg-slate-900"
        :placeholder="placeholder"
        :min-height="4"
      />
    </div>
    <ResizableTextArea
      v-else
      v-model="greetingsMessage"
      :rows="4"
      type="text"
      class="greetings--textarea"
      :label="label"
      :placeholder="placeholder"
      @input="handleInput"
    />
  </section>
</template>

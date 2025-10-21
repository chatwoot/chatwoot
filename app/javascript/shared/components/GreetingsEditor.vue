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
  <section>
    <div
      v-if="richtext"
      class="px-4 py-0 mx-0 mt-0 mb-4 rounded-lg outline outline-1 outline-n-weak hover:outline-n-slate-6 dark:hover:outline-n-slate-6 bg-n-alpha-black2"
    >
      <WootMessageEditor
        v-model="greetingsMessage"
        is-format-mode
        enable-variables
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

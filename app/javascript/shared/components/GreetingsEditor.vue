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
    <div v-if="richtext">
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
      :min-height="4"
      type="text"
      class="bg-transparent p-0 !outline-0 !outline-none !mb-0 mt-1 text-sm"
      :label="label"
      :placeholder="placeholder"
      @input="handleInput"
    />
  </section>
</template>

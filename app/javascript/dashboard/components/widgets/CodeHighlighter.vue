<template>
  <VAceEditor
    v-model:value="internalCode"
    @init="editorInit"
    lang="html"
    theme="monokai"
    style="height: 200px"
  />
</template>

<script setup>
import { ref, watch } from 'vue';
import { VAceEditor } from 'vue3-ace-editor';

const editorInit = () => {};

const props = defineProps({
  modelValue: String, // Prop passed from parent (via v-model)
});

const emit = defineEmits(['update:modelValue']);

const internalCode = ref(props.modelValue || '');

// Emit changes to parent
watch(internalCode, newVal => {
  emit('update:modelValue', newVal);
});
</script>

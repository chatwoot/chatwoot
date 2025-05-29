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
import ace from 'ace-builds';

import modeJsonUrl from 'ace-builds/src-noconflict/mode-html?url';
ace.config.setModuleUrl('ace/mode/html', modeJsonUrl);

import themeChromeUrl from 'ace-builds/src-noconflict/theme-monokai?url';
ace.config.setModuleUrl('ace/theme/monokai', themeChromeUrl);

const editorInit = () => {};

const props = defineProps({
  modelValue: String, // Prop passed from parent (via v-model)
});

const emit = defineEmits(['update:modelValue', 'changeVal']);

const internalCode = ref(props.modelValue || '');

// Emit changes to parent
watch(internalCode, newVal => {
  emit('update:modelValue', newVal);

});
</script>

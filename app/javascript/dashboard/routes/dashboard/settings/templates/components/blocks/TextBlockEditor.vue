<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  properties: {
    type: Object,
    required: true,
  },
  parameters: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['update:properties']);

const { t } = useI18n();

const localContent = ref(props.properties.content || '');

// Example placeholder text to avoid nested template syntax issues
const examplePlaceholder = '{{parameter_name}}';

// Computed list of available parameters for autocomplete/hint
const parametersList = computed(() => {
  return Object.keys(props.parameters).map(name => ({
    name,
    ...props.parameters[name],
  }));
});

watch(localContent, newValue => {
  emit('update:properties', {
    ...props.properties,
    content: newValue,
  });
});

const insertParameter = paramName => {
  const cursorPos = document.getElementById('textContent').selectionStart;
  const textBefore = localContent.value.substring(0, cursorPos);
  const textAfter = localContent.value.substring(cursorPos);
  localContent.value = `${textBefore}{{${paramName}}}${textAfter}`;
};

const formatParameterDisplay = paramName => {
  return `{{${paramName}}}`;
};
</script>

<template>
  <div class="space-y-4">
    <div>
      <label class="block text-sm font-medium text-n-slate-12 mb-2">
        {{ t('TEMPLATES.BUILDER.TEXT_BLOCK.CONTENT.LABEL') }}
      </label>
      <textarea
        id="textContent"
        v-model="localContent"
        rows="6"
        :placeholder="t('TEMPLATES.BUILDER.TEXT_BLOCK.CONTENT.PLACEHOLDER')"
        class="w-full px-4 py-3 border border-n-slate-7 rounded-lg focus:outline-none focus:ring-2 focus:ring-n-blue-7 font-mono text-sm"
      />
      <p class="text-xs text-n-slate-10 mt-1">
        {{ t('TEMPLATES.BUILDER.TEXT_BLOCK.CONTENT.HELP') }}
        <code class="px-1 bg-n-slate-2 rounded">{{ examplePlaceholder }}</code>
      </p>
    </div>

    <!-- Available Parameters -->
    <div v-if="parametersList.length > 0" class="bg-n-slate-2 rounded-lg p-4">
      <div class="text-xs font-medium text-n-slate-11 mb-2">
        {{ t('TEMPLATES.BUILDER.TEXT_BLOCK.PARAMETERS.LABEL') }}
      </div>
      <div class="flex flex-wrap gap-2">
        <button
          v-for="param in parametersList"
          :key="param.name"
          class="px-2 py-1 bg-white border border-n-slate-7 rounded text-xs font-mono hover:bg-n-blue-2 hover:border-n-blue-7 transition-colors"
          @click="insertParameter(param.name)"
        >
          {{ formatParameterDisplay(param.name) }}
        </button>
      </div>
    </div>
  </div>
</template>

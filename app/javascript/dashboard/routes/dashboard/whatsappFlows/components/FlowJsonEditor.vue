<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const props = defineProps({
  flowJson: { type: Object, required: true },
});

const emit = defineEmits(['apply', 'close']);

const jsonText = ref(JSON.stringify(props.flowJson, null, 2));
const parseError = ref('');

function validate() {
  try {
    JSON.parse(jsonText.value);
    parseError.value = '';
    return true;
  } catch (e) {
    parseError.value = e.message;
    return false;
  }
}

function apply() {
  if (validate()) {
    emit('apply', jsonText.value);
  }
}
</script>

<template>
  <div class="flex flex-col flex-1 overflow-hidden">
    <div class="flex items-center justify-between px-4 py-2 border-b border-n-weak bg-n-slate-2">
      <div class="flex items-center gap-2">
        <span class="i-lucide-code size-4 text-n-slate-9" />
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('WHATSAPP_FLOWS.JSON_EDITOR.TITLE') }}
        </span>
      </div>
      <div class="flex items-center gap-2">
        <button
          class="px-3 py-1.5 text-xs rounded-lg border border-n-weak hover:bg-white"
          @click="emit('close')"
        >
          {{ t('WHATSAPP_FLOWS.JSON_EDITOR.CLOSE') }}
        </button>
        <button
          class="px-3 py-1.5 text-xs rounded-lg bg-n-brand text-white hover:bg-n-brand-dark"
          @click="apply"
        >
          {{ t('WHATSAPP_FLOWS.JSON_EDITOR.APPLY') }}
        </button>
      </div>
    </div>
    <div v-if="parseError" class="px-4 py-2 bg-n-ruby-2 text-n-ruby-11 text-xs">
      {{ parseError }}
    </div>
    <textarea
      v-model="jsonText"
      class="flex-1 p-4 font-mono text-xs bg-n-slate-1 resize-none outline-none"
      spellcheck="false"
      @input="validate"
    />
  </div>
</template>

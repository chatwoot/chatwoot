<script setup>
import { computed, onMounted } from 'vue';

const props = defineProps({
  modelValue: {
    type: String,
    default: 'en',
  },
});

const emit = defineEmits(['update:modelValue', 'change']);

// Get enabled languages from window config
const enabledLanguages = computed(() => {
  return (
    window.chatwootConfig?.enabledLanguages || [
      { iso_639_1_code: 'en', name: 'English' },
    ]
  );
});

// Get browser default language and match to available languages
function getBrowserDefaultLocale() {
  const browserLang = navigator.language || navigator.userLanguage || 'en';
  const normalizedLang = browserLang.replace('-', '_');

  // Try exact match first (e.g., pt_BR)
  const exactMatch = enabledLanguages.value.find(
    lang => lang.iso_639_1_code === normalizedLang
  );
  if (exactMatch) return exactMatch.iso_639_1_code;

  // Try base language match (e.g., pt)
  const baseLang = normalizedLang.split('_')[0];
  const baseMatch = enabledLanguages.value.find(
    lang => lang.iso_639_1_code === baseLang
  );
  if (baseMatch) return baseMatch.iso_639_1_code;

  // Default to English
  return 'en';
}

// Sort languages alphabetically by name
const sortedLanguages = computed(() => {
  return [...enabledLanguages.value].sort((a, b) =>
    a.name.localeCompare(b.name)
  );
});

const selectedLocale = computed({
  get: () => props.modelValue,
  set: value => {
    emit('update:modelValue', value);
    emit('change', value);
  },
});

// Set browser default on mount if no value is set
onMounted(() => {
  if (!props.modelValue) {
    const defaultLocale = getBrowserDefaultLocale();
    emit('update:modelValue', defaultLocale);
  }
});
</script>

<template>
  <div class="relative">
    <select
      v-model="selectedLocale"
      class="appearance-none w-full px-3 py-2 pr-8 text-sm rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-n-brand/50 focus:border-n-brand cursor-pointer"
    >
      <option
        v-for="lang in sortedLanguages"
        :key="lang.iso_639_1_code"
        :value="lang.iso_639_1_code"
      >
        {{ lang.name }}
      </option>
    </select>
    <div
      class="absolute inset-y-0 right-0 flex items-center pr-2 pointer-events-none"
    >
      <svg
        class="w-4 h-4 text-n-slate-10"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M8 9l4-4 4 4m0 6l-4 4-4-4"
        />
      </svg>
    </div>
  </div>
</template>

<script setup>
import { ref, useTemplateRef, onMounted, onUnmounted } from 'vue';
import { debounce } from '@chatwoot/utils';

const emit = defineEmits(['search']);

const searchQuery = ref('');
const isInputFocused = ref(false);

const searchInput = useTemplateRef('searchInput');

const handler = e => {
  if (e.key === '/' && document.activeElement.tagName !== 'INPUT') {
    e.preventDefault();
    searchInput.value.focus();
  } else if (e.key === 'Escape' && document.activeElement.tagName === 'INPUT') {
    e.preventDefault();
    searchInput.value.blur();
  }
};

const debouncedEmit = debounce(
  value =>
    emit('search', value.length > 1 || value.match(/^[0-9]+$/) ? value : ''),
  500
);

const onInput = e => {
  searchQuery.value = e.target.value;
  debouncedEmit(searchQuery.value);
};

const onFocus = () => {
  isInputFocused.value = true;
};

const onBlur = () => {
  isInputFocused.value = false;
};

onMounted(() => {
  searchInput.value.focus();
  document.addEventListener('keydown', handler);
});

onUnmounted(() => {
  document.removeEventListener('keydown', handler);
});
</script>

<template>
  <div
    class="input-container rounded-xl transition-[border-bottom] duration-[0.2s] ease-[ease-in-out] relative flex items-center py-2 px-4 h-14 gap-2 border border-solid bg-n-alpha-black2"
    :class="{
      'border-n-brand': isInputFocused,
      'border-n-weak': !isInputFocused,
    }"
  >
    <div class="flex items-center">
      <fluent-icon
        icon="search"
        class="icon"
        aria-hidden="true"
        :class="{
          'text-n-blue-text': isInputFocused,
          'text-n-slate-10': !isInputFocused,
        }"
      />
    </div>
    <input
      ref="searchInput"
      type="search"
      class="reset-base outline-none w-full m-0 bg-transparent border-transparent shadow-none text-n-slate-12 dark:text-n-slate-12 active:border-transparent active:shadow-none hover:border-transparent hover:shadow-none focus:border-transparent focus:shadow-none"
      :placeholder="$t('SEARCH.INPUT_PLACEHOLDER')"
      :value="searchQuery"
      @focus="onFocus"
      @blur="onBlur"
      @input="onInput"
    />
    <woot-label
      :title="$t('SEARCH.PLACEHOLDER_KEYBINDING')"
      :show-close="false"
      small
      class="!m-0 whitespace-nowrap !bg-n-slate-3 dark:!bg-n-solid-3 !border-n-weak dark:!border-n-strong"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  title: {
    type: String,
    default: 'Converso',
  },
});

const emit = defineEmits(['search', 'close']);

const searchInputRef = ref(null);
const searchQuery = ref('');

onMounted(() => {
  searchInputRef.value.focus();
});

const onInput = e => {
  emit('search', e.target.value);
};

const onClose = () => {
  emit('close');
};

const keyboardEvents = {
  Slash: {
    action: e => {
      e.preventDefault();
      searchInputRef.value.focus();
    },
  },
  Escape: {
    action: () => {
      onClose();
    },
    allowOnFocusedInput: true,
  },
};
useKeyboardEvents(keyboardEvents);
</script>

<template>
  <div class="flex flex-col py-1">
    <div class="flex items-center justify-between py-2 mb-1">
      <h3 class="text-base font-semibold text-on-surface">
        {{ title }}
      </h3>
      <Button ghost xs slate icon="i-lucide-x" @click="onClose" />
    </div>

    <div class="relative">
      <div
        class="absolute ltr:left-0 rtl:right-0 w-8 top-0.5 h-8 flex justify-center items-center"
      >
        <fluent-icon icon="search" class="" size="18" />
      </div>
      <input
        ref="searchInputRef"
        type="text"
        :placeholder="$t('HELP_CENTER.ARTICLE_SEARCH.PLACEHOLDER')"
        class="!mb-0 block !h-9 w-full rounded-lg border border-solid border-outline-variant/30 bg-surface-container-lowest text-sm leading-8 text-on-surface shadow-sm ring-0 transition-colors placeholder:text-on-primary-container/70 focus:border-secondary focus:outline-none focus:ring-1 focus:ring-secondary focus:ring-offset-0 ltr:!pl-8 rtl:!pr-8"
        :value="searchQuery"
        @input="onInput"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  title: {
    type: String,
    default: 'Chatwoot',
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
      <h3 class="text-base text-n-slate-12">
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
        class="block w-full !h-9 ltr:!pl-8 rtl:!pr-8 dark:!bg-n-slate-2 !border-n-weak !bg-n-slate-2 text-sm rounded-md leading-8 text-n-slate-12 shadow-sm ring-2 ring-transparent ring-n-weak border border-solid placeholder:text-n-slate-10 focus:border-n-brand focus:ring-n-brand !mb-0"
        :value="searchQuery"
        @input="onInput"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useToggle } from '@vueuse/core';

defineProps({
  text: {
    type: String,
    default: '',
  },
});

const contentElement = ref(null);
const [isExpanded, toggleExpanded] = useToggle(false);
const needsToggle = ref(false);

const checkOverflow = () => {
  if (!contentElement.value) return;

  const element = contentElement.value;
  const computedStyle = window.getComputedStyle(element);
  const lineHeight = parseFloat(computedStyle.lineHeight) || 20;
  const maxHeight = lineHeight * 2;

  needsToggle.value = element.scrollHeight > maxHeight;
};

onMounted(() => {
  setTimeout(checkOverflow, 0);
});
</script>

<template>
  <span class="py-2 text-xs font-medium">
    {{ $t('SEARCH.TRANSCRIPT') }}
  </span>
  <div
    class="text-n-slate-11 pt-1 text-sm rounded-lg w-full break-words grid items-center"
    :class="needsToggle && !isExpanded ? 'grid-cols-[1fr_auto]' : 'grid-cols-1'"
  >
    <div
      ref="contentElement"
      class="min-w-0"
      :class="{ 'overflow-hidden line-clamp-1': !isExpanded && needsToggle }"
    >
      {{ text }}
      <button
        v-if="needsToggle && isExpanded"
        class="text-sm text-n-slate-11 underline cursor-pointer bg-transparent border-0 p-0 hover:text-n-slate-12 font-medium ltr:ml-0.5 rtl:mr-0.5"
        @click.prevent.stop="toggleExpanded(false)"
      >
        {{ $t('SEARCH.READ_LESS') }}
      </button>
    </div>
    <button
      v-if="needsToggle && !isExpanded"
      class="text-sm text-n-slate-11 underline cursor-pointer bg-transparent border-0 p-0 hover:text-n-slate-12 font-medium justify-self-end ltr:ml-0.5 rtl:mr-0.5"
      @click.prevent.stop="toggleExpanded(true)"
    >
      {{ $t('SEARCH.READ_MORE') }}
    </button>
  </div>
</template>

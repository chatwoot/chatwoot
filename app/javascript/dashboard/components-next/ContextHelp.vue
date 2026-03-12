<script setup>
import { computed, ref } from 'vue';
import { vOnClickOutside } from '@vueuse/components';
import { getContextHelpByKey } from 'dashboard/helper/contextHelpContent';

const props = defineProps({
  helpKey: { type: String, required: true },
  position: { type: String, default: 'right' },
});

const isOpen = ref(false);
const helpContent = computed(() => getContextHelpByKey(props.helpKey));
const isLeftAligned = computed(() => props.position === 'left');
const formattedBody = computed(
  () => helpContent.value?.body?.split('\n') || []
);

const toggle = () => {
  if (!helpContent.value) return;
  isOpen.value = !isOpen.value;
};

const close = () => {
  isOpen.value = false;
};
</script>

<template>
  <div class="relative inline-flex">
    <template v-if="helpContent">
      <button
        v-on-click-outside="close"
        type="button"
        class="inline-flex items-center justify-center rounded-full size-8 border border-n-weak bg-n-solid-2 text-n-slate-11 hover:text-n-brand hover:border-n-brand transition-colors"
        :title="helpContent.title"
        @click="toggle"
      >
        <span class="i-lucide-circle-help size-4" />
      </button>

      <div
        v-if="isOpen"
        class="absolute z-50 w-80 max-w-[90vw] p-4 mt-2 text-sm rounded-xl border border-n-weak bg-n-solid-1 shadow-lg"
        :class="isLeftAligned ? 'left-0' : 'right-0'"
      >
        <p class="font-medium text-n-slate-12 mb-2">{{ helpContent.title }}</p>
        <p
          v-for="(line, index) in formattedBody"
          :key="`${helpKey}-${index}`"
          class="text-n-slate-11 leading-5"
        >
          {{ line }}
        </p>
      </div>
    </template>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  currentPage: {
    type: Number,
    default: 1,
  },
  totalPages: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['pageChange']);
const hasLastPage = computed(
  () => props.currentPage === props.totalPages || props.totalPages === 1
);
const hasFirstPage = computed(() => props.currentPage === 1);
const hasNextPage = computed(() => props.currentPage === props.totalPages);
const hasPrevPage = computed(() => props.currentPage === 1);

function onPageChange(newPage) {
  emit('pageChange', newPage);
}

const onNextPage = () => {
  if (!onNextPage.value) {
    onPageChange(props.currentPage + 1);
  }
};
const onPrevPage = () => {
  if (!hasPrevPage.value) {
    onPageChange(props.currentPage - 1);
  }
};
const onFirstPage = () => {
  if (!hasFirstPage.value) {
    onPageChange(1);
  }
};
const onLastPage = () => {
  if (!hasLastPage.value) {
    onPageChange(props.totalPages);
  }
};
</script>

<template>
  <div
    class="flex items-center h-8 outline outline-1 outline-n-weak rounded-lg"
  >
    <NextButton
      faded
      sm
      slate
      icon="i-lucide-chevrons-left"
      class="ltr:rounded-l-lg ltr:rounded-r-none rtl:rounded-r-lg rtl:rounded-l-none"
      :disabled="hasFirstPage"
      @click="onFirstPage"
    />
    <div class="flex items-center justify-center bg-n-slate-9/10 h-full">
      <div class="w-px h-4 rounded-sm bg-n-strong" />
    </div>
    <NextButton
      faded
      sm
      slate
      icon="i-lucide-chevron-left"
      class="rounded-none"
      :disabled="hasPrevPage"
      @click="onPrevPage"
    />
    <div
      class="flex items-center gap-3 px-3 tabular-nums bg-n-slate-9/10 h-full"
    >
      <span class="text-sm text-n-slate-12">
        {{ currentPage }}
      </span>
      <span class="text-n-slate-11">/</span>
      <span class="text-sm text-n-slate-11">
        {{ totalPages }}
      </span>
    </div>
    <NextButton
      faded
      sm
      slate
      icon="i-lucide-chevron-right"
      class="rounded-none"
      :disabled="hasNextPage"
      @click="onNextPage"
    />
    <div class="flex items-center justify-center bg-n-slate-9/10 h-full">
      <div class="w-px h-4 rounded-sm bg-n-strong" />
    </div>
    <NextButton
      faded
      sm
      slate
      icon="i-lucide-chevrons-right"
      class="ltr:rounded-r-lg ltr:rounded-l-none rtl:rounded-l-lg rtl:rounded-r-none"
      :disabled="hasLastPage"
      @click="onLastPage"
    />
  </div>
</template>

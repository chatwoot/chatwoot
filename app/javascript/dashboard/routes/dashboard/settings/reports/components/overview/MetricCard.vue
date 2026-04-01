<script setup>
import Spinner from 'shared/components/Spinner.vue';

defineProps({
  header: {
    type: String,
    default: '',
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  loadingMessage: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div
    class="m-0.5 flex min-h-[10rem] flex-grow flex-col rounded-xl border border-outline-variant/10 bg-surface-container-low px-6 py-5 text-on-surface shadow-lg"
  >
    <div
      class="card-header grid w-full mb-6 grid-cols-[repeat(auto-fit,minmax(max-content,50%))] gap-y-2"
    >
      <slot name="header">
        <div class="flex items-center gap-2 flex-row">
          <h5 class="mb-0 text-on-surface font-medium text-lg">
            {{ header }}
          </h5>
          <span
            class="flex flex-row items-center rounded-md border border-secondary/25 bg-secondary/10 px-2 py-0.5 text-xs"
          >
            <span
              class="mr-1 size-1 rounded-full bg-secondary rtl:ml-0 rtl:mr-0"
            />
            <span class="text-xs font-medium text-secondary">
              {{ $t('OVERVIEW_REPORTS.LIVE') }}
            </span>
          </span>
        </div>
        <div class="flex flex-row items-center justify-end gap-2">
          <slot name="control" />
        </div>
      </slot>
    </div>
    <div
      v-if="!isLoading"
      class="card-body max-w-full w-full ml-auto mr-auto justify-between flex"
    >
      <slot />
    </div>
    <div
      v-else-if="isLoading"
      class="items-center flex text-base justify-center px-12 py-6"
    >
      <Spinner />
      <span class="text-on-surface-variant">
        {{ loadingMessage }}
      </span>
    </div>
  </div>
</template>

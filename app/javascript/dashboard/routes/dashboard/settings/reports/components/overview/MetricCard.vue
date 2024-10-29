<script>
import Spinner from 'shared/components/Spinner.vue';

export default {
  name: 'MetricCard',
  components: {
    Spinner,
  },
  props: {
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
  },
};
</script>

<template>
  <div
    class="metric-card mb-2 p flex flex-col m-2 p-4 border border-solid overflow-hidden rounded-md flex-grow shadow-sm text-slate-700 dark:text-slate-100 bg-white dark:bg-slate-800 border-slate-75 dark:border-slate-700 min-h-[10rem]"
  >
    <div
      class="card-header grid w-full mb-6 grid-cols-[repeat(auto-fit,minmax(max-content,50%))] gap-y-2"
    >
      <slot name="header">
        <div class="flex items-center gap-0.5 flex-row">
          <h5
            class="mb-0 text-slate-800 dark:text-slate-100 font-medium text-xl"
          >
            {{ header }}
          </h5>
          <span
            class="flex flex-row items-center pr-2 pl-2 m-1 rounded-sm text-green-400 dark:text-green-400 text-xs bg-green-100/30 dark:bg-green-100/20"
          >
            <span
              class="bg-green-500 dark:bg-green-500 h-1 w-1 rounded-full mr-1 rtl:mr-0 rtl:ml-0"
            />
            <span>
              {{ $t('OVERVIEW_REPORTS.LIVE') }}
            </span>
          </span>
        </div>
        <div
          class="transition-opacity duration-200 ease-in-out opacity-20 hover:opacity-100 flex flex-row items-center justify-end gap-2"
        >
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
      <span class="text-slate-300 dark:text-slate-200">
        {{ loadingMessage }}
      </span>
    </div>
  </div>
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';
export default {
  name: 'MetricCardFull',
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
    class="flex flex-col m-0.5 px-6 py-5 overflow-hidden rounded-xl flex-grow text-n-slate-12 shadow outline-1 outline outline-n-container bg-n-solid-2 min-h-[10rem]"
  >
    <div
    >
      <slot name="header">
        <div class="flex items-center gap-2 flex-row">
          <h5 class="mb-0 text-n-slate-12 font-medium text-lg">
            {{ header }}
          </h5>
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
      class="card-body max-w-full w-full ml-auto mr-auto justify-between"
    >
      <slot />
    </div>
    <div
      v-else-if="isLoading"
      class="items-center flex text-base justify-center px-12 py-6"
    >
      <Spinner />
      <span class="text-n-slate-11">
        {{ loadingMessage }}
      </span>
    </div>
  </div>
</template>
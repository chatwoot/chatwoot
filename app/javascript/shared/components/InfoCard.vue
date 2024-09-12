<template>
  <div
    class="order-card flex flex-col m-2 p-4 border border-solid overflow-hidden rounded-md flex-grow shadow-sm text-slate-700 dark:text-slate-100 bg-white dark:bg-slate-800 border-slate-75 dark:border-slate-700 min-h-[10rem]"
  >
    <div class="card-header">
      <slot name="header">
        <div class="flex gap-0.5">
          <h5
            class="mb-0 text-slate-800 dark:text-slate-100 font-medium text-xl"
          >
            {{ header }}
          </h5>
        </div>
        <div class="card-header--control-area">
          <slot name="control" />
        </div>
      </slot>
    </div>
    <div
      class="card-body max-w-full w-full ml-auto mr-auto flex gap-9 flex-grow items-end"
    >
      <slot />
    </div>
  </div>
</template>
<script>
export default {
  props: {
    header: {
      type: String,
      default: '',
    },
  },
};
</script>

<style lang="scss" scoped>
.order-card {
  @apply flex flex-col mb-2 p-4 border border-solid overflow-hidden rounded-md flex-grow shadow-sm text-slate-700 dark:text-slate-100 bg-white dark:bg-slate-800 border-slate-75 dark:border-slate-700 min-h-[10rem];

  .card-header--control-area {
    transition: opacity 0.2s ease-in-out;
    @apply opacity-20;
  }

  &:hover {
    .card-header--control-area {
      @apply opacity-100;
    }
  }
}

.card-header {
  grid-template-columns: repeat(auto-fit, minmax(max-content, 50%));
  gap: var(--space-small) 0px;
  @apply grid w-full mb-6;

  .card-header--control-area {
    @apply flex items-center justify-end gap-2;
  }
}

.card-body {
  .metric-content {
    @apply pb-2;
    .heading {
      @apply text-base text-slate-700 dark:text-slate-100;
    }
    .metric {
      @apply text-woot-800 dark:text-woot-300 text-3xl mb-0 mt-1;
    }
  }
}
</style>

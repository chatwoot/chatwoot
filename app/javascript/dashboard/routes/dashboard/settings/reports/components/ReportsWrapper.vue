<template>
  <div
    class="reports--wrapper overflow-auto bg-n-background w-full px-8 xl:px-0"
  >
    <div class="max-w-[960px] mx-auto pb-12">
      <router-view />
    </div>
  </div>
</template>

<style scoped lang="scss">
.reports--wrapper {
  ::v-deep {
    .multiselect--disabled {
      @apply opacity-50 border border-n-weak rounded-md cursor-not-allowed;
    }

    .multiselect__content-wrapper {
      @apply bg-n-solid-2 border border-n-weak text-n-slate-12;
    }

    .multiselect__tags {
      @apply bg-n-slate-1 border border-n-weak m-0 min-h-[2.875rem] pt-0;

      input[type='text'] {
        @apply bg-n-alpha-3 border-n-weak !min-h-[2.375rem] !h-[2.375rem] !ps-0.5 !py-0 !text-sm;
      }
    }

    .multiselect__placeholder {
      @apply text-n-slate-11;
    }

    .multiselect__select {
      @apply min-h-0;
    }

    .multiselect__single {
      @apply bg-n-alpha-3 text-n-slate-11;
    }

    .multiselect__input {
      @apply text-sm !h-[2.375rem] mb-0 !py-0;
    }

    .multiselect__tags,
    .multiselect__input,
    .multiselect {
      @apply bg-n-alpha-3 !border-n-weak text-n-slate-12 rounded-lg text-sm min-h-[2.5rem];
    }

    .mx-input-wrapper {
      @apply bg-n-alpha-3 !border-n-weak text-n-slate-12 rounded-lg text-sm;

      input {
        @apply border-n-weak text-sm;
      }
    }

    .multiselect__option {
      @apply flex items-center;
    }

    .mx-datepicker {
      .mx-input {
        @apply bg-n-alpha-3;
      }

      .mx-input-wrapper input::placeholder {
        @apply text-n-slate-11;
      }

      .mx-input-wrapper input {
        @apply text-n-slate-11;
      }
    }

    .multiselect--active:not(.multiselect--above) .multiselect__current,
    .multiselect--active:not(.multiselect--above) .multiselect__input,
    .multiselect--active:not(.multiselect--above) .multiselect__tags {
      @apply rounded-b-none;
    }
  }
}
</style>

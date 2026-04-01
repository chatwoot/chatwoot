<template>
  <div class="reports--wrapper overflow-auto bg-surface w-full px-6">
    <div class="max-w-[60rem] mx-auto pb-12">
      <router-view />
    </div>
  </div>
</template>

<style scoped lang="scss">
.reports--wrapper {
  :deep() {
    .multiselect--disabled {
      @apply opacity-50 border border-outline-variant/15 rounded-md cursor-not-allowed;
    }

    .multiselect__content-wrapper {
      @apply bg-surface-container-low border border-outline-variant/15 text-on-surface;
    }

    .multiselect__tags {
      @apply bg-surface-container-lowest border border-outline-variant/15 m-0 min-h-[2.875rem] pt-0;

      input[type='text'] {
        @apply bg-surface-container-lowest border-outline-variant/15 placeholder:text-on-surface-variant min-h-[2.375rem] h-[2.375rem] px-0.5 py-0 text-sm;
      }
    }

    .multiselect__placeholder {
      @apply text-on-surface-variant;
    }

    .multiselect__select {
      @apply min-h-0;
    }

    .multiselect__single {
      @apply bg-surface-container-lowest text-on-surface-variant;
    }

    .multiselect__input {
      @apply text-sm h-[2.375rem] mb-0 py-0;
    }

    .multiselect__tags,
    .multiselect__input,
    .multiselect {
      @apply bg-surface-container-lowest !border-outline-variant/15 text-on-surface rounded-lg text-sm min-h-[2.5rem];
    }

    .mx-input-wrapper {
      @apply bg-surface-container-lowest border-outline-variant/15 text-on-surface rounded-lg text-sm;

      input {
        @apply border-outline-variant/15 text-sm;
      }
    }

    .multiselect__option {
      @apply flex items-center;
    }

    .mx-datepicker {
      .mx-input {
        background-color: transparent !important;
      }

      .mx-input-wrapper input::placeholder {
        @apply text-on-surface-variant;
      }

      .mx-input-wrapper input {
        @apply text-on-surface-variant;
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

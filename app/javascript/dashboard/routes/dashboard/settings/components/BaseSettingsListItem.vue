<script setup>
defineProps({
  title: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div
    class="flex relative flex-col sm:flex-row p-4 gap-4 sm:p-6 justify-between group outline outline-outline-variant/15 outline-1 bg-surface-container-low rounded-2xl shadow w-full"
  >
    <slot name="leftSection">
      <div class="flex flex-col min-w-0 items-start gap-3 max-w-[480px] w-full">
        <div
          class="flex items-center justify-between w-full gap-3 sm:justify-normal whitespace-nowrap"
        >
          <h3
            class="justify-between tracking-tight font-medium truncate w-fit sm:justify-normal text-on-surface"
          >
            <slot name="title">
              {{ title }}
            </slot>
          </h3>
          <slot name="label" />
        </div>
        <p
          class="text-base text-on-surface-variant max-w-[25rem] w-full line-clamp-2"
        >
          <slot name="description">
            {{ description }}
          </slot>
        </p>
      </div>
    </slot>

    <!-- right side section -->
    <slot name="rightSection" />

    <!-- actions section -->
    <div
      v-if="$slots.actions"
      class="absolute flex-col items-center hidden gap-1 border-none ltr:-right-3 rtl:-left-3 top-3 group-hover:flex"
    >
      <slot name="actions" />
    </div>
  </div>
</template>

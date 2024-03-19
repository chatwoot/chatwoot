<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  iconName: {
    type: String,
    required: true,
  },
  href: {
    type: String,
    default: '',
  },
  linkText: {
    type: String,
    default: '',
  },
});
</script>
<template>
  <div class="flex flex-col items-start w-full gap-4">
    <div class="flex flex-row items-center justify-between w-full gap-16 gap">
      <div class="flex flex-row items-center gap-3">
        <div
          class="flex items-center w-10 h-10 p-1 rounded-full bg-woot-25/60 dark:bg-woot-900/60"
        >
          <div
            class="flex items-center justify-center w-full h-full rounded-full bg-woot-75/70 dark:bg-woot-800/40"
          >
            <fluent-icon
              size="14"
              :icon="iconName"
              type="outline"
              class="flex-shrink-0 text-woot-500 dark:text-woot-500"
            />
          </div>
        </div>
        <h1
          class="text-2xl font-medium tracking-[-1.5%] text-slate-900 dark:text-slate-25"
        >
          {{ title }}
        </h1>
      </div>
      <div class="flex-row hidden gap-2 sm:flex">
        <slot name="actions" />
      </div>
    </div>
    <div
      class="flex flex-col gap-2 text-slate-600 dark:text-slate-300 max-w-[721px] min-w-0 w-full"
    >
      <p class="text-sm font-normal tracking-[0.5%] mb-0">
        <slot name="description">{{ description }}</slot>
      </p>
      <a
        v-if="href && linkText"
        :href="href"
        class="sm:inline-flex hidden gap-1 w-fit items-center text-woot-500 dark:text-woot-500 text-sm font-medium tracking=[-0.6%] hover:underline"
      >
        {{ linkText }}
        <fluent-icon
          size="16"
          icon="chevron-right"
          type="outline"
          class="flex-shrink-0 text-woot-500 dark:text-woot-500"
        />
      </a>
    </div>
    <!-- Mobile view action button -->
    <div class="flex items-start gap-3 sm:hidden">
      <slot name="actions" />
      <a v-if="href && linkText" :href="href">
        <woot-button
          color-scheme="secondary"
          icon="arrow-up-right"
          class="flex-row-reverse rounded-xl !bg-slate-50 !text-slate-900 dark:!text-white dark:!bg-slate-800"
        >
          {{ linkText }}
        </woot-button>
      </a>
    </div>
  </div>
</template>

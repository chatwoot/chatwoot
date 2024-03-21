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

const openInNewTab = url => {
  if (!url) return;
  window.open(url, '_blank', 'noopener noreferrer');
};
</script>

<template>
  <div class="flex flex-col items-start w-full gap-4">
    <!-- Header section with icon, title and action button -->
    <div class="flex items-center justify-between w-full gap-4">
      <!-- Icon and title container -->
      <div class="flex items-center gap-3">
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
      <!-- Slot for additional actions on larger screens -->
      <div class="hidden gap-2 sm:flex">
        <slot name="actions" />
      </div>
    </div>
    <!-- Description and optional link -->
    <div
      class="flex flex-col gap-2 text-slate-600 dark:text-slate-300 max-w-[721px] w-full"
    >
      <p
        class="mb-0 text-sm font-normal tracking-[0.5%] line-clamp-5 sm:line-clamp-none"
      >
        <slot name="description">{{ description }}</slot>
      </p>
      <!-- Conditional link -->
      <a
        v-if="href && linkText"
        :href="href"
        target="_blank"
        rel="noopener noreferrer"
        class="sm:inline-flex hidden tracking-[-0.6%] gap-1 w-fit items-center text-woot-500 dark:text-woot-500 text-sm font-medium tracking=[-0.6%] hover:underline"
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
    <!-- Mobile view for actions and link -->
    <div class="flex items-start justify-start w-full gap-3 sm:hidden">
      <slot name="actions" />
      <woot-button
        v-if="href && linkText"
        color-scheme="secondary"
        icon="arrow-outwards"
        class="flex-row-reverse rounded-xl min-w-0 !bg-slate-50 !text-slate-900 dark:!text-white dark:!bg-slate-800"
        @click="openInNewTab(href)"
      >
        {{ linkText }}
      </woot-button>
    </div>
  </div>
</template>

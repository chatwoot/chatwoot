<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  title: { type: String, required: true },
  description: { type: String, required: true },
  withBorder: { type: Boolean, default: false },
  hideContent: { type: Boolean, default: false },
  beta: { type: Boolean, default: false },
  /** Card container (Cybros settings panels) */
  asCard: { type: Boolean, default: false },
});
const { t } = useI18n();
</script>

<template>
  <section
    class="grid grid-cols-1 gap-5 [interpolate-size:allow-keywords]"
    :class="[
      asCard
        ? 'p-6 bg-surface-container-low rounded-xl border border-outline-variant/5 shadow-sm'
        : 'pt-8',
      !asCard && withBorder ? 'border-t border-outline-variant/15' : '',
      !hideContent && !asCard ? 'pb-8' : '',
    ]"
  >
    <header
      v-if="asCard"
      class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between"
    >
      <div class="min-w-0 flex-1">
        <h4
          class="text-lg font-semibold text-on-surface flex items-center gap-2"
        >
          <slot name="title">{{ title }}</slot>
          <div
            v-if="beta"
            v-tooltip.top="t('GENERAL.BETA_DESCRIPTION')"
            class="text-xs uppercase text-n-iris-11 border border-1 border-n-iris-10 leading-none rounded-lg px-1 py-0.5"
          >
            {{ t('GENERAL.BETA') }}
          </div>
        </h4>
        <p
          v-if="description || $slots.description"
          class="text-sm mt-1 text-on-primary-container"
        >
          <slot name="description">{{ description }}</slot>
        </p>
      </div>
      <div v-if="$slots.headerActions" class="flex justify-end shrink-0">
        <slot name="headerActions" />
      </div>
    </header>
    <header v-else class="grid grid-cols-4">
      <div class="col-span-3">
        <h4 class="text-lg font-medium text-on-surface flex items-center gap-2">
          <slot name="title">{{ title }}</slot>
          <div
            v-if="beta"
            v-tooltip.top="t('GENERAL.BETA_DESCRIPTION')"
            class="text-xs uppercase text-n-iris-11 border border-1 border-n-iris-10 leading-none rounded-lg px-1 py-0.5"
          >
            {{ t('GENERAL.BETA') }}
          </div>
        </h4>
        <p
          v-if="description || $slots.description"
          class="text-on-surface-variant text-sm mt-2"
        >
          <slot name="description">{{ description }}</slot>
        </p>
      </div>
      <div class="col-span-1">
        <slot name="headerActions" />
      </div>
    </header>
    <div
      class="transition-[height] duration-300 ease-in-out text-on-surface"
      :class="{ 'overflow-hidden h-0': hideContent, 'h-auto': !hideContent }"
    >
      <slot />
    </div>
  </section>
</template>

<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  title: { type: String, required: true },
  description: { type: String, required: true },
  withBorder: { type: Boolean, default: false },
  hideContent: { type: Boolean, default: false },
  beta: { type: Boolean, default: false },
});
const { t } = useI18n();
</script>

<template>
  <section
    class="grid grid-cols-1 pt-8 gap-5 [interpolate-size:allow-keywords]"
    :class="{
      'border-t border-n-weak': withBorder,
      'pb-8': !hideContent,
    }"
  >
    <header class="grid grid-cols-4">
      <div class="col-span-3">
        <h4 class="text-lg font-medium text-n-slate-12 flex items-center gap-2">
          <slot name="title">{{ title }}</slot>
          <div
            v-if="beta"
            v-tooltip.top="t('GENERAL.BETA_DESCRIPTION')"
            class="text-xs uppercase text-n-iris-11 border border-1 border-n-iris-10 leading-none rounded-lg px-1 py-0.5"
          >
            {{ t('GENERAL.BETA') }}
          </div>
        </h4>
        <p class="text-n-slate-11 text-sm mt-2">
          <slot name="description">{{ description }}</slot>
        </p>
      </div>
      <div class="col-span-1">
        <slot name="headerActions" />
      </div>
    </header>
    <div
      class="transition-[height] duration-300 ease-in-out text-n-slate-12"
      :class="{ 'overflow-hidden h-0': hideContent, 'h-auto': !hideContent }"
    >
      <slot />
    </div>
  </section>
</template>

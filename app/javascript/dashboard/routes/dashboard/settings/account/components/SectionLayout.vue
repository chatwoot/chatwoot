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
      'border-t border-s-border': withBorder,
      'pb-8': !hideContent,
    }"
  >
    <header class="grid grid-cols-4">
      <div
        v-if="
          title || beta || $slots.title || description || $slots.description
        "
        class="col-span-3"
      >
        <h4
          v-if="title || beta || $slots.title"
          class="text-heading-2 text-s-primary flex items-center gap-2"
        >
          <slot name="title">{{ title }}</slot>
          <div
            v-if="beta"
            v-tooltip.top="t('GENERAL.BETA_DESCRIPTION')"
            class="text-xs uppercase text-s-brand-text border border-1 border-s-brand-text leading-none rounded-lg px-1 py-0.5"
          >
            {{ t('GENERAL.BETA') }}
          </div>
        </h4>
        <p
          v-if="description || $slots.description"
          class="text-s-muted text-body-main mt-2"
        >
          <slot name="description">{{ description }}</slot>
        </p>
      </div>
      <div class="col-span-1">
        <slot name="headerActions" />
      </div>
    </header>
    <div
      class="transition-[height] duration-300 ease-in-out text-s-primary"
      :class="{ 'overflow-hidden h-0': hideContent, 'h-auto': !hideContent }"
    >
      <slot />
    </div>
  </section>
</template>

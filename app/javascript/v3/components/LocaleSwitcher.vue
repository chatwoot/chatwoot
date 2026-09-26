<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useConfig } from 'dashboard/composables/useConfig';

import Button from 'dashboard/components-next/button/Button.vue';

const STORAGE_KEY = 'cw.auth.locale';

const { t, locale } = useI18n();
const { enabledLanguages } = useConfig();

const isOpen = ref(false);

const options = computed(() => enabledLanguages ?? []);
const currentLabel = computed(() => {
  const match = options.value.find(o => o.iso_639_1_code === locale.value);
  return match?.name ?? t('LOGIN.LANGUAGE_SELECTOR_LABEL');
});

const toggleMenu = () => {
  isOpen.value = !isOpen.value;
};

const handleSelect = code => {
  locale.value = code;
  try {
    localStorage.setItem(STORAGE_KEY, code);
  } catch (_) {
    // localStorage unavailable (private mode, SSR) — fall back to in-memory only.
  }
  isOpen.value = false;
};
</script>

<template>
  <div
    v-if="options.length > 1"
    class="fixed bottom-4 inset-x-0 flex justify-center pointer-events-none z-50"
  >
    <div
      v-on-clickaway="() => (isOpen = false)"
      class="relative pointer-events-auto"
    >
      <Button
        icon="i-lucide-globe"
        size="sm"
        color="slate"
        variant="faded"
        trailing-icon
        class="!w-fit max-w-64"
        :class="{ 'dark:!bg-n-alpha-2 !bg-n-slate-9/20': isOpen }"
        :label="currentLabel"
        :aria-label="t('LOGIN.LANGUAGE_SELECTOR_LABEL')"
        @click="toggleMenu"
      />
      <div
        v-if="isOpen"
        class="absolute bottom-full mb-1 ltr:left-1/2 rtl:right-1/2 ltr:-translate-x-1/2 rtl:translate-x-1/2 select-none max-w-64 flex flex-col gap-1 bg-n-alpha-3 backdrop-blur-[100px] p-1 shadow-lg z-40 rounded-lg border border-n-weak dark:border-n-strong/50"
      >
        <Button
          v-for="lang in options"
          :key="lang.iso_639_1_code"
          :label="lang.name"
          :icon="lang.iso_639_1_code === locale ? 'i-lucide-check' : ''"
          size="sm"
          variant="ghost"
          color="slate"
          trailing-icon
          class="!justify-end !px-2.5 !h-7"
          :class="{ '!bg-n-alpha-2': lang.iso_639_1_code === locale }"
          @click="handleSelect(lang.iso_639_1_code)"
        />
      </div>
    </div>
  </div>
</template>

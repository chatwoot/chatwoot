<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  password: { type: String, default: '' },
});
const MIN_PASSWORD_LENGTH = 6;
const SPECIAL_CHAR_REGEX = /[!@#$%^&*()_+\-=[\]{}|'"/\\.,`<>:;?~]/;

const { t } = useI18n();

const requirements = computed(() => {
  const password = props.password || '';
  return [
    {
      id: 'length',
      met: password.length >= MIN_PASSWORD_LENGTH,
      label: t('REGISTER.PASSWORD.REQUIREMENTS_LENGTH', {
        min: MIN_PASSWORD_LENGTH,
      }),
    },
    {
      id: 'uppercase',
      met: /[A-Z]/.test(password),
      label: t('REGISTER.PASSWORD.REQUIREMENTS_UPPERCASE'),
    },
    {
      id: 'lowercase',
      met: /[a-z]/.test(password),
      label: t('REGISTER.PASSWORD.REQUIREMENTS_LOWERCASE'),
    },
    {
      id: 'number',
      met: /[0-9]/.test(password),
      label: t('REGISTER.PASSWORD.REQUIREMENTS_NUMBER'),
    },
    {
      id: 'special',
      met: SPECIAL_CHAR_REGEX.test(password),
      label: t('REGISTER.PASSWORD.REQUIREMENTS_SPECIAL'),
    },
  ];
});
</script>

<template>
  <div
    class="absolute top-0 z-50 w-64 text-xs rounded-lg px-4 py-3 bg-white dark:bg-n-solid-3 shadow-lg outline outline-1 outline-n-weak start-full ms-4"
  >
    <ul role="list" class="space-y-1.5">
      <li
        v-for="item in requirements"
        :key="item.id"
        class="inline-flex gap-1.5 items-start"
      >
        <Icon
          class="flex-none flex-shrink-0 w-3 mt-0.5"
          :icon="item.met ? 'i-lucide-circle-check-big' : 'i-lucide-circle'"
          :class="item.met ? 'text-n-teal-10' : 'text-n-slate-10'"
        />
        <span :class="item.met ? 'text-n-slate-11' : 'text-n-slate-10'">
          {{ item.label }}
        </span>
      </li>
    </ul>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  status: { type: String, default: 'error' },
  isAdmin: { type: Boolean, default: false },
  inboxId: { type: Number, default: undefined },
});

const emit = defineEmits(['close']);

const { t } = useI18n();

const guides = computed(() => ({
  no_catalog: {
    title: t('CATALOG.SETUP_GUIDE.NO_CATALOG.TITLE'),
    description: t('CATALOG.SETUP_GUIDE.NO_CATALOG.DESCRIPTION'),
    steps: [
      t('CATALOG.SETUP_GUIDE.NO_CATALOG.STEPS.ONE'),
      t('CATALOG.SETUP_GUIDE.NO_CATALOG.STEPS.TWO'),
      t('CATALOG.SETUP_GUIDE.NO_CATALOG.STEPS.THREE'),
    ],
  },
  missing_permission: {
    title: t('CATALOG.SETUP_GUIDE.MISSING_PERMISSION.TITLE'),
    description: t('CATALOG.SETUP_GUIDE.MISSING_PERMISSION.DESCRIPTION'),
    steps: [
      t('CATALOG.SETUP_GUIDE.MISSING_PERMISSION.STEPS.ONE'),
      t('CATALOG.SETUP_GUIDE.MISSING_PERMISSION.STEPS.TWO'),
      t('CATALOG.SETUP_GUIDE.MISSING_PERMISSION.STEPS.THREE'),
    ],
  },
  error: {
    title: t('CATALOG.SETUP_GUIDE.ERROR.TITLE'),
    description: t('CATALOG.SETUP_GUIDE.ERROR.DESCRIPTION'),
    steps: [
      t('CATALOG.SETUP_GUIDE.ERROR.STEPS.ONE'),
      t('CATALOG.SETUP_GUIDE.ERROR.STEPS.TWO'),
    ],
  },
}));

const guide = computed(() => guides.value[props.status] || guides.value.error);
</script>

<template>
  <div class="flex flex-col gap-4" data-testid="catalog-setup-guide">
    <div class="flex flex-col gap-1">
      <h4 class="mb-0 text-base font-medium text-n-slate-12">
        {{ guide.title }}
      </h4>
      <p class="mb-0 text-sm text-n-slate-11">
        {{ guide.description }}
      </p>
    </div>
    <ol
      class="flex flex-col gap-2 mb-0 ms-5 text-sm list-decimal text-n-slate-12"
    >
      <li v-for="step in guide.steps" :key="step">
        {{ step }}
      </li>
    </ol>
    <div class="flex flex-wrap items-center gap-3">
      <router-link
        v-if="isAdmin"
        :to="{ name: 'settings_inbox_show', params: { inboxId } }"
        data-testid="catalog-open-settings"
        @click="emit('close')"
      >
        <Button
          type="button"
          color="blue"
          :label="$t('CATALOG.SETUP_GUIDE.OPEN_SETTINGS')"
        />
      </router-link>
      <p v-else class="mb-0 text-sm text-n-slate-11">
        {{ $t('CATALOG.SETUP_GUIDE.ADMIN_ONLY') }}
      </p>
    </div>
  </div>
</template>

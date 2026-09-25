<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAdmin } from 'dashboard/composables/useAdmin';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const emit = defineEmits(['create']);

const { t } = useI18n();
const { isAdmin } = useAdmin();

const examples = computed(() => [
  {
    name: t('MONITORS.EXAMPLES.LOGIN_PROBLEMS.NAME'),
    condition: t('MONITORS.EXAMPLES.LOGIN_PROBLEMS.CONDITION'),
    audience: t('MONITORS.EXAMPLES.LOGIN_PROBLEMS.AUDIENCE'),
    benefit: t('MONITORS.EXAMPLES.LOGIN_PROBLEMS.BENEFIT'),
    icon: 'i-lucide-key-round',
    iconClass: 'bg-n-amber-3 text-n-amber-11',
  },
  {
    name: t('MONITORS.EXAMPLES.MISSING_ORDER_UPDATES.NAME'),
    condition: t('MONITORS.EXAMPLES.MISSING_ORDER_UPDATES.CONDITION'),
    audience: t('MONITORS.EXAMPLES.MISSING_ORDER_UPDATES.AUDIENCE'),
    benefit: t('MONITORS.EXAMPLES.MISSING_ORDER_UPDATES.BENEFIT'),
    icon: 'i-lucide-package',
    iconClass: 'bg-n-ruby-3 text-n-ruby-11',
  },
  {
    name: t('MONITORS.EXAMPLES.COMPETITOR_MENTIONS.NAME'),
    condition: t('MONITORS.EXAMPLES.COMPETITOR_MENTIONS.CONDITION'),
    audience: t('MONITORS.EXAMPLES.COMPETITOR_MENTIONS.AUDIENCE'),
    benefit: t('MONITORS.EXAMPLES.COMPETITOR_MENTIONS.BENEFIT'),
    icon: 'i-lucide-swords',
    iconClass: 'bg-n-blue-3 text-n-blue-11',
  },
  {
    name: t('MONITORS.EXAMPLES.FEATURE_REQUESTS.NAME'),
    condition: t('MONITORS.EXAMPLES.FEATURE_REQUESTS.CONDITION'),
    audience: t('MONITORS.EXAMPLES.FEATURE_REQUESTS.AUDIENCE'),
    benefit: t('MONITORS.EXAMPLES.FEATURE_REQUESTS.BENEFIT'),
    icon: 'i-lucide-lightbulb',
    iconClass: 'bg-n-teal-3 text-n-teal-11',
  },
  {
    name: t('MONITORS.EXAMPLES.REFUND_REQUESTS.NAME'),
    condition: t('MONITORS.EXAMPLES.REFUND_REQUESTS.CONDITION'),
    audience: t('MONITORS.EXAMPLES.REFUND_REQUESTS.AUDIENCE'),
    benefit: t('MONITORS.EXAMPLES.REFUND_REQUESTS.BENEFIT'),
    icon: 'i-lucide-receipt',
    iconClass: 'bg-n-iris-3 text-n-iris-11',
  },
  {
    name: t('MONITORS.EXAMPLES.CANCELLATION_INTENT.NAME'),
    condition: t('MONITORS.EXAMPLES.CANCELLATION_INTENT.CONDITION'),
    audience: t('MONITORS.EXAMPLES.CANCELLATION_INTENT.AUDIENCE'),
    benefit: t('MONITORS.EXAMPLES.CANCELLATION_INTENT.BENEFIT'),
    icon: 'i-lucide-user-x',
    iconClass: 'bg-n-ruby-3 text-n-ruby-11',
  },
]);
</script>

<template>
  <section class="flex flex-col gap-6 pb-12">
    <div class="flex flex-col gap-2">
      <h2 class="m-0 text-xl font-medium text-n-slate-12">
        {{ t('MONITORS.EXAMPLES_TITLE') }}
      </h2>
      <p class="m-0 text-sm leading-6 text-n-slate-11">
        {{ t('MONITORS.EMPTY_DESCRIPTION') }}
      </p>
      <p v-if="!isAdmin" class="m-0 text-sm text-n-slate-11">
        {{ t('MONITORS.ADMIN_HELP') }}
      </p>
    </div>
    <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
      <button
        v-for="example in examples"
        :key="example.name"
        type="button"
        :disabled="!isAdmin"
        class="group flex h-full min-w-0 flex-col gap-5 rounded-2xl border border-n-weak bg-n-solid-1 p-5 text-start transition-colors enabled:hover:border-n-blue-7 enabled:hover:bg-n-slate-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-n-brand disabled:cursor-not-allowed disabled:opacity-60"
        @click="
          emit('create', { name: example.name, condition: example.condition })
        "
      >
        <span class="flex items-center gap-3">
          <span
            :class="example.iconClass"
            class="flex size-11 shrink-0 items-center justify-center rounded-xl"
          >
            <Icon :icon="example.icon" class="size-5" />
          </span>
          <span class="flex min-w-0 flex-col gap-0.5">
            <span class="text-base font-medium text-n-slate-12">{{
              example.name
            }}</span>
            <span class="text-xs text-n-slate-10">{{ example.audience }}</span>
          </span>
        </span>
        <span class="text-sm leading-6 text-n-slate-11">{{
          example.condition
        }}</span>
        <span class="text-sm text-n-slate-12">{{ example.benefit }}</span>
        <span
          class="mt-auto flex items-center gap-2 pt-1 text-sm font-medium text-n-blue-11"
        >
          {{ t('MONITORS.USE_TEMPLATE') }}
          <Icon
            icon="i-lucide-arrow-right"
            class="size-4 transition-transform group-hover:translate-x-0.5"
          />
        </span>
      </button>
    </div>
  </section>
</template>

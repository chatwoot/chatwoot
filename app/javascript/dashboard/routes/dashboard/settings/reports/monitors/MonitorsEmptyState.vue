<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAdmin } from 'dashboard/composables/useAdmin';
import Button from 'dashboard/components-next/button/Button.vue';
import EmojiIcon from 'dashboard/components-next/emoji-icon-picker/EmojiIcon.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const emit = defineEmits(['create']);

const { t } = useI18n();
const { isAdmin } = useAdmin();

const examples = computed(() => [
  {
    name: t('MONITORS.EXAMPLES.MISSING_ORDER_UPDATES.NAME'),
    condition: t('MONITORS.EXAMPLES.MISSING_ORDER_UPDATES.CONDITION'),
    benefit: t('MONITORS.EXAMPLES.MISSING_ORDER_UPDATES.BENEFIT'),
    icon: 'truck-line',
    icon_color: '#3B82F6',
  },
  {
    name: t('MONITORS.EXAMPLES.FEATURE_REQUESTS.NAME'),
    condition: t('MONITORS.EXAMPLES.FEATURE_REQUESTS.CONDITION'),
    benefit: t('MONITORS.EXAMPLES.FEATURE_REQUESTS.BENEFIT'),
    icon: 'lightbulb-line',
    icon_color: '#8B5CF6',
  },
  {
    name: t('MONITORS.EXAMPLES.REFUND_REQUESTS.NAME'),
    condition: t('MONITORS.EXAMPLES.REFUND_REQUESTS.CONDITION'),
    benefit: t('MONITORS.EXAMPLES.REFUND_REQUESTS.BENEFIT'),
    icon: 'money-dollar-circle-line',
    icon_color: '#22C55E',
  },
  {
    name: t('MONITORS.EXAMPLES.CANCELLATION_INTENT.NAME'),
    condition: t('MONITORS.EXAMPLES.CANCELLATION_INTENT.CONDITION'),
    benefit: t('MONITORS.EXAMPLES.CANCELLATION_INTENT.BENEFIT'),
    icon: 'logout-box-line',
    icon_color: '#EF4444',
  },
]);
</script>

<template>
  <section class="flex flex-col items-center gap-8 pb-12">
    <div
      inert
      aria-hidden="true"
      class="w-full select-none opacity-70 [mask-image:linear-gradient(to_bottom,black,transparent)]"
    >
      <div class="flex flex-col divide-y divide-n-weak border-t border-n-weak">
        <div
          v-for="example in examples.slice(0, 3)"
          :key="example.name"
          class="flex min-w-0 items-center gap-4 py-4"
        >
          <span
            class="flex size-10 shrink-0 items-center justify-center rounded-xl outline outline-1 -outline-offset-1 outline-n-weak"
          >
            <EmojiIcon
              :value="example.icon"
              :color="example.icon_color"
              class="size-5"
            />
          </span>
          <span class="flex min-w-0 flex-col gap-0.5">
            <span class="truncate text-heading-3 text-n-slate-12">{{
              example.name
            }}</span>
            <span class="truncate text-body-main text-n-slate-11">{{
              example.condition
            }}</span>
          </span>
        </div>
      </div>
    </div>
    <div class="flex flex-col items-center gap-3 text-center">
      <h2 class="m-0 text-3xl font-medium text-n-slate-12">
        {{ t('MONITORS.EMPTY_TITLE') }}
      </h2>
      <p class="m-0 max-w-xl text-base tracking-[0.3px] text-n-slate-11">
        {{ t('MONITORS.EMPTY_DESCRIPTION') }}
      </p>
    </div>
    <Button
      v-if="isAdmin"
      icon="i-lucide-plus"
      :label="t('MONITORS.CREATE')"
      @click="emit('create')"
    />
    <p v-else class="m-0 text-sm text-n-slate-11">
      {{ t('MONITORS.ADMIN_HELP') }}
    </p>
    <div class="flex w-full max-w-xl flex-col gap-2">
      <span class="text-xs text-n-slate-10">
        {{ t('MONITORS.EXAMPLES_TITLE') }}
      </span>
      <button
        v-for="example in examples"
        :key="example.name"
        type="button"
        :disabled="!isAdmin"
        class="flex w-full items-center gap-2 rounded-lg border border-n-weak bg-n-slate-2 px-3 py-2 text-start text-sm text-n-slate-11 transition-colors enabled:hover:bg-n-slate-3 enabled:hover:text-n-slate-12 disabled:cursor-not-allowed disabled:opacity-60"
        @click="
          emit('create', {
            name: example.name,
            condition: example.condition,
            icon: example.icon,
            icon_color: example.icon_color,
          })
        "
      >
        <span
          class="flex size-9 shrink-0 items-center justify-center rounded-lg bg-n-surface-1 outline outline-1 -outline-offset-1 outline-n-weak"
        >
          <EmojiIcon
            :value="example.icon"
            :color="example.icon_color"
            class="size-5"
          />
        </span>
        <span class="flex min-w-0 flex-1 flex-col gap-0.5">
          <span class="font-medium text-n-slate-12">{{ example.name }}</span>
          <span class="truncate">{{ example.benefit }}</span>
        </span>
        <Icon
          icon="i-lucide-chevron-right"
          class="size-4 shrink-0 rtl:rotate-180"
        />
      </button>
    </div>
  </section>
</template>

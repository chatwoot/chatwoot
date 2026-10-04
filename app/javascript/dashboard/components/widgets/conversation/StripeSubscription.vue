<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useClipboard } from '@vueuse/core';
import { dateFormat } from 'shared/helpers/timeHelper';
import {
  formatStripeAmount,
  STRIPE_STATUS_COLORS,
} from 'dashboard/helper/stripeHelper';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({ subscription: { type: Object, required: true } });

const { t } = useI18n();
const { copy, copied } = useClipboard();
const panel = ref(null);

const title = computed(
  () =>
    props.subscription.items
      ?.map(item => item.name)
      .filter(Boolean)
      .join(', ') || t('STRIPE_INTEGRATION.SUBSCRIPTION')
);

const statusLabel = computed(() =>
  props.subscription.status.replaceAll('_', ' ')
);

const statusColor = computed(
  () => STRIPE_STATUS_COLORS[props.subscription.status] || 'slate'
);

const isTrialing = computed(() => props.subscription.status === 'trialing');

const isRenewing = computed(
  () =>
    ['active', 'trialing'].includes(props.subscription.status) &&
    !props.subscription.cancel_at_period_end &&
    !props.subscription.cancel_at
);

const trialMessage = computed(() =>
  isTrialing.value && props.subscription.trial_end
    ? t('STRIPE_INTEGRATION.TRIAL_ENDS', {
        date: dateFormat(props.subscription.trial_end),
      })
    : ''
);

const cancellationMessage = computed(() => {
  if (props.subscription.status === 'canceled') return '';
  if (props.subscription.cancel_at)
    return t('STRIPE_INTEGRATION.CANCELS', {
      date: dateFormat(props.subscription.cancel_at),
    });
  return props.subscription.cancel_at_period_end
    ? t('STRIPE_INTEGRATION.CANCELS_AT_PERIOD_END')
    : '';
});

const periodEndLabel = timestamp =>
  isRenewing.value
    ? t('STRIPE_INTEGRATION.RENEWS', { date: dateFormat(timestamp) })
    : t('STRIPE_INTEGRATION.PERIOD_END', { date: dateFormat(timestamp) });

// The card only has room for one period, so it is shown for single item subscriptions
const cardPeriodEnd = computed(() => {
  const [item, ...otherItems] = props.subscription.items || [];
  if (isTrialing.value || otherItems.length || !item?.current_period_end)
    return '';
  return periodEndLabel(item.current_period_end);
});

const priceLabel = item => {
  if (
    item.unit_amount == null ||
    item.billing_scheme === 'tiered' ||
    item.recurring?.usage_type === 'metered'
  )
    return t('STRIPE_INTEGRATION.VARIABLE_PRICE');
  const amount = formatStripeAmount(item.unit_amount, item.currency, {
    preservePrecision: true,
  });
  if (!item.recurring) return amount;
  const count = item.recurring.interval_count;
  return t('STRIPE_INTEGRATION.PRICE_INTERVAL', {
    amount,
    interval: {
      day: t('STRIPE_INTEGRATION.INTERVAL.day', count),
      week: t('STRIPE_INTEGRATION.INTERVAL.week', count),
      month: t('STRIPE_INTEGRATION.INTERVAL.month', count),
      year: t('STRIPE_INTEGRATION.INTERVAL.year', count),
    }[item.recurring.interval],
  });
};
</script>

<template>
  <button
    type="button"
    class="flex items-center gap-2 w-full rounded-lg bg-n-alpha-1 p-3 text-start hover:bg-n-alpha-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand"
    :aria-label="$t('STRIPE_INTEGRATION.VIEW_SUBSCRIPTION', { name: title })"
    @click="panel.open()"
  >
    <span class="flex flex-col flex-1 gap-1 min-w-0 text-xs text-n-slate-11">
      <span class="flex items-start justify-between gap-2">
        <span class="text-sm font-medium break-words text-n-slate-12">
          {{ title }}
        </span>
        <Label
          :label="statusLabel"
          :color="statusColor"
          compact
          class="capitalize"
        />
      </span>
      <span v-for="item in subscription.items" :key="item.id">
        {{ priceLabel(item) }}
        <span
          v-if="item.quantity != null"
          class="ms-2 ps-2 border-s border-n-strong"
        >
          {{ $t('STRIPE_INTEGRATION.QUANTITY', { count: item.quantity }) }}
        </span>
      </span>
      <span v-if="trialMessage">{{ trialMessage }}</span>
      <span v-if="cancellationMessage" class="text-n-amber-11">
        {{ cancellationMessage }}
      </span>
      <span v-else-if="cardPeriodEnd">{{ cardPeriodEnd }}</span>
    </span>
    <span
      class="i-lucide-chevron-right size-4 shrink-0 text-n-slate-10"
      aria-hidden="true"
    />
  </button>
  <SidePanel ref="panel" :title="title" width="md">
    <div class="flex flex-col gap-5 text-sm text-n-slate-12">
      <div class="flex items-center gap-2">
        <Label
          :label="statusLabel"
          :color="statusColor"
          compact
          class="capitalize"
        />
        <span class="flex-1 min-w-0 font-mono text-xs truncate text-n-slate-11">
          {{ subscription.id }}
        </span>
        <Button
          :label="
            copied
              ? $t('STRIPE_INTEGRATION.COPIED')
              : $t('STRIPE_INTEGRATION.COPY_ID')
          "
          :icon="copied ? 'i-lucide-check' : 'i-lucide-copy'"
          xs
          ghost
          slate
          @click="copy(subscription.id)"
        />
      </div>
      <p v-if="trialMessage" class="m-0">{{ trialMessage }}</p>
      <p
        v-if="cancellationMessage"
        class="flex items-center gap-2 px-3 py-2 m-0 rounded-lg bg-n-amber-2 text-n-amber-11"
      >
        <span class="i-lucide-calendar-x size-4 shrink-0" aria-hidden="true" />
        {{ cancellationMessage }}
      </p>
      <p
        v-if="subscription.status === 'canceled' && subscription.canceled_at"
        class="m-0"
      >
        {{
          $t('STRIPE_INTEGRATION.CANCELED_ON', {
            date: dateFormat(subscription.canceled_at),
          })
        }}
      </p>
      <section
        v-for="item in subscription.items"
        :key="item.id"
        class="flex flex-col gap-1.5 pt-4 border-t border-n-weak text-n-slate-11"
      >
        <h4
          v-if="subscription.items.length > 1"
          class="m-0 text-sm font-medium text-n-slate-12"
        >
          {{ item.name || $t('STRIPE_INTEGRATION.SUBSCRIPTION') }}
        </h4>
        <p class="m-0 text-n-slate-12">{{ priceLabel(item) }}</p>
        <p v-if="item.quantity != null" class="m-0">
          {{ $t('STRIPE_INTEGRATION.QUANTITY', { count: item.quantity }) }}
        </p>
        <p v-if="item.current_period_start" class="m-0">
          {{
            $t('STRIPE_INTEGRATION.PERIOD_START', {
              date: dateFormat(item.current_period_start),
            })
          }}
        </p>
        <p v-if="item.current_period_end" class="m-0">
          {{ periodEndLabel(item.current_period_end) }}
        </p>
      </section>
      <p v-if="subscription.has_more_items" class="m-0 text-n-slate-11">
        {{ $t('STRIPE_INTEGRATION.MORE_ITEMS') }}
      </p>
      <p class="pt-4 m-0 text-xs border-t border-n-weak text-n-slate-11">
        {{ $t('STRIPE_INTEGRATION.PRICE_NOTE') }}
      </p>
    </div>
  </SidePanel>
</template>

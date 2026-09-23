<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useClipboard } from '@vueuse/core';
import SidePanel from 'dashboard/components-next/side-panel/SidePanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({ subscription: { type: Object, required: true } });
const { t } = useI18n();
const panel = ref(null);
const { copy, copied } = useClipboard();
const TWO_DECIMAL_API_CURRENCIES = ['ISK', 'UGX'];
const title = computed(
  () =>
    props.subscription.items
      ?.map(item => item.name)
      .filter(Boolean)
      .join(', ') || t('STRIPE_INTEGRATION.SUBSCRIPTION')
);
const statusColor = computed(
  () =>
    ({ active: 'teal', trialing: 'blue', past_due: 'ruby', unpaid: 'ruby' })[
      props.subscription.status
    ] || 'slate'
);
const date = value =>
  new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' }).format(
    new Date(value * 1000)
  );
const priceLabel = item => {
  if (
    item.unit_amount == null ||
    item.billing_scheme === 'tiered' ||
    item.recurring?.usage_type === 'metered'
  )
    return t('STRIPE_INTEGRATION.VARIABLE_PRICE');
  const formatter = new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: item.currency,
  });
  const digits = TWO_DECIMAL_API_CURRENCIES.includes(
    item.currency.toUpperCase()
  )
    ? 2
    : formatter.resolvedOptions().maximumFractionDigits;
  const amount = formatter.format(Number(item.unit_amount) / 10 ** digits);
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
const cancellationMessage = computed(() => {
  if (props.subscription.status === 'canceled') return '';
  if (props.subscription.cancel_at)
    return t('STRIPE_INTEGRATION.CANCELS', {
      date: date(props.subscription.cancel_at),
    });
  return props.subscription.cancel_at_period_end
    ? t('STRIPE_INTEGRATION.CANCELS_AT_PERIOD_END')
    : '';
});
const periodEnd = timestamp =>
  ['active', 'trialing'].includes(props.subscription.status) &&
  !props.subscription.cancel_at_period_end &&
  !props.subscription.cancel_at
    ? t('STRIPE_INTEGRATION.RENEWS', { date: date(timestamp) })
    : t('STRIPE_INTEGRATION.PERIOD_END', { date: date(timestamp) });
</script>

<template>
  <button
    type="button"
    class="flex flex-col gap-2 w-full rounded-lg bg-n-alpha-1 p-3 text-start hover:bg-n-alpha-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand"
    :aria-label="$t('STRIPE_INTEGRATION.VIEW_SUBSCRIPTION', { name: title })"
    @click="panel.open()"
  >
    <span class="flex items-center justify-between gap-3 w-full">
      <span class="text-xs font-medium break-words">{{ title }}</span>
      <Label
        :label="subscription.status.replaceAll('_', ' ')"
        :color="statusColor"
        compact
        class="capitalize shrink-0"
      />
    </span>
    <span
      v-for="item in subscription.items"
      :key="item.id"
      class="text-xs text-n-slate-11"
    >
      {{ priceLabel(item) }}
      <span v-if="item.quantity != null" class="ms-2">
        {{ $t('STRIPE_INTEGRATION.QUANTITY', { count: item.quantity }) }}
      </span>
    </span>
    <span
      v-if="subscription.trial_end && subscription.status === 'trialing'"
      class="text-xs text-n-slate-11"
    >
      {{
        $t('STRIPE_INTEGRATION.TRIAL_ENDS', {
          date: date(subscription.trial_end),
        })
      }}
    </span>
    <span v-if="cancellationMessage" class="text-xs text-n-amber-11">{{
      cancellationMessage
    }}</span>
    <span
      v-else-if="
        subscription.status !== 'trialing' &&
        subscription.items?.length === 1 &&
        subscription.items[0].current_period_end
      "
      class="text-xs text-n-slate-11"
    >
      {{ periodEnd(subscription.items[0].current_period_end) }}
    </span>
    <span
      class="flex items-center justify-between gap-2 w-full text-n-slate-11"
    >
      <span class="truncate font-mono text-[0.625rem]">{{
        subscription.id
      }}</span>
      <span class="i-lucide-chevron-right size-4 shrink-0" aria-hidden="true" />
    </span>
  </button>
  <SidePanel ref="panel" :title="title" width="md">
    <div class="flex flex-col gap-5 text-sm text-n-slate-12">
      <Label
        :label="subscription.status.replaceAll('_', ' ')"
        :color="statusColor"
        class="capitalize self-start"
      />
      <div class="flex items-center justify-between gap-2">
        <span class="font-mono text-xs break-all">{{ subscription.id }}</span>
        <Button
          :label="
            copied
              ? $t('STRIPE_INTEGRATION.COPIED')
              : $t('STRIPE_INTEGRATION.COPY_ID')
          "
          icon="i-lucide-copy"
          sm
          ghost
          @click="copy(subscription.id)"
        />
      </div>
      <p v-if="subscription.trial_end" class="m-0">
        {{
          $t('STRIPE_INTEGRATION.TRIAL_ENDS', {
            date: date(subscription.trial_end),
          })
        }}
      </p>
      <p v-if="cancellationMessage" class="m-0 text-n-amber-11">
        {{ cancellationMessage }}
      </p>
      <p
        v-if="subscription.status === 'canceled' && subscription.canceled_at"
        class="m-0"
      >
        {{
          $t('STRIPE_INTEGRATION.CANCELED_ON', {
            date: date(subscription.canceled_at),
          })
        }}
      </p>
      <section
        v-for="item in subscription.items"
        :key="item.id"
        class="flex flex-col gap-2 border-t border-n-weak pt-4"
      >
        <h4 class="m-0 text-sm font-medium">
          {{ item.name || $t('STRIPE_INTEGRATION.SUBSCRIPTION') }}
        </h4>
        <p class="m-0">{{ priceLabel(item) }}</p>
        <p v-if="item.quantity != null" class="m-0 text-n-slate-11">
          {{ $t('STRIPE_INTEGRATION.QUANTITY', { count: item.quantity }) }}
        </p>
        <p v-if="item.current_period_start" class="m-0 text-n-slate-11">
          {{
            $t('STRIPE_INTEGRATION.PERIOD_START', {
              date: date(item.current_period_start),
            })
          }}
        </p>
        <p v-if="item.current_period_end" class="m-0 text-n-slate-11">
          {{ periodEnd(item.current_period_end) }}
        </p>
      </section>
      <p v-if="subscription.has_more_items" class="m-0 text-n-slate-11">
        {{ $t('STRIPE_INTEGRATION.MORE_ITEMS') }}
      </p>
      <p class="m-0 text-xs text-n-slate-11">
        {{ $t('STRIPE_INTEGRATION.PRICE_NOTE') }}
      </p>
    </div>
  </SidePanel>
</template>

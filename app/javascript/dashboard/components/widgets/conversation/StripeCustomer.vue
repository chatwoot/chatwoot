<script setup>
import { ref, watch } from 'vue';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import StripeAPI from 'dashboard/api/integrations/stripe';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  conversationId: { type: [Number, String], required: true },
});
const summary = ref(null);
const customerId = ref('');
const error = ref(false);
const { run, isPending } = useAbortableRequest();
// Stripe retains two-decimal API amounts for these otherwise zero-decimal currencies.
const TWO_DECIMAL_API_CURRENCIES = ['ISK', 'UGX'];
const STATUS_COLORS = {
  active: 'teal',
  paid: 'teal',
  trialing: 'blue',
  open: 'amber',
  past_due: 'ruby',
  unpaid: 'ruby',
  uncollectible: 'ruby',
};
const formatDate = timestamp =>
  new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  }).format(new Date(timestamp * 1000));

const load = async () => {
  error.value = false;
  summary.value = null;
  try {
    const response = await run(signal =>
      StripeAPI.customer(
        props.conversationId,
        customerId.value || undefined,
        signal
      )
    );
    if (response) summary.value = response.data;
  } catch {
    error.value = true;
  }
};

const formatAmount = invoice => {
  const formatter = new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: invoice.currency,
  });
  const digits = TWO_DECIMAL_API_CURRENCIES.includes(
    invoice.currency.toUpperCase()
  )
    ? 2
    : formatter.resolvedOptions().maximumFractionDigits;
  return formatter.format(invoice.total / 10 ** digits);
};

watch(
  () => props.conversationId,
  () => {
    customerId.value = '';
    load();
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-4 px-4 py-3 text-sm text-n-slate-12">
    <Spinner v-if="isPending" />
    <p v-else-if="error" role="alert" class="text-n-ruby-11">
      {{ $t('STRIPE_INTEGRATION.ERROR') }}
    </p>
    <template v-else-if="summary">
      <p v-if="summary.missing_email">
        {{ $t('STRIPE_INTEGRATION.NO_EMAIL') }}
      </p>
      <p v-else-if="!summary.customers.length">
        {{ $t('STRIPE_INTEGRATION.EMPTY') }}
      </p>
      <template v-else>
        <label v-if="summary.customers.length > 1" class="flex flex-col gap-2">
          {{ $t('STRIPE_INTEGRATION.SELECT') }}
          <select v-model="customerId" @change="load">
            <option value="" disabled>
              {{ $t('STRIPE_INTEGRATION.SELECT') }}
            </option>
            <option
              v-for="customer in summary.customers"
              :key="customer.id"
              :value="customer.id"
            >
              {{
                $t('STRIPE_INTEGRATION.CUSTOMER_OPTION', {
                  name: customer.name || customer.email,
                  id: customer.id,
                })
              }}
            </option>
          </select>
        </label>
        <p v-if="summary.has_more_customers">
          {{ $t('STRIPE_INTEGRATION.MORE') }}
        </p>
        <template v-if="summary.customer">
          <div class="flex items-center gap-3 min-w-0">
            <span
              class="flex items-center justify-center size-9 shrink-0 rounded-lg bg-n-alpha-2 text-n-slate-11"
            >
              <span class="i-lucide-user-round size-4" aria-hidden="true" />
            </span>
            <div
              class="flex flex-col gap-0.5 min-w-0"
              :title="summary.customer.id"
            >
              <span class="font-medium truncate">{{
                summary.customer.name
              }}</span>
              <span class="text-xs text-n-slate-11 break-all">{{
                summary.customer.email
              }}</span>
              <span
                v-if="summary.customer.phone"
                class="text-xs text-n-slate-11"
              >
                {{ summary.customer.phone }}
              </span>
            </div>
          </div>
          <section class="flex flex-col gap-2 border-t border-n-weak pt-3">
            <h4 class="m-0 text-xs font-medium text-n-slate-11">
              {{ $t('STRIPE_INTEGRATION.SUBSCRIPTIONS') }}
            </h4>
            <p
              v-if="!summary.subscriptions.length"
              class="m-0 text-xs text-n-slate-11"
            >
              {{ $t('STRIPE_INTEGRATION.NO_SUBSCRIPTIONS') }}
            </p>
            <div
              v-for="subscription in summary.subscriptions"
              :key="subscription.id"
              class="flex items-center justify-between gap-3 rounded-lg bg-n-alpha-1 p-2.5"
            >
              <div class="flex flex-col gap-1 min-w-0">
                <span class="text-xs font-medium">{{
                  $t('STRIPE_INTEGRATION.SUBSCRIPTION')
                }}</span>
                <span
                  class="truncate font-mono text-[0.625rem] text-n-slate-11"
                  :title="subscription.id"
                >
                  {{ subscription.id }}
                </span>
              </div>
              <Label
                :label="subscription.status.replaceAll('_', ' ')"
                :color="STATUS_COLORS[subscription.status] || 'slate'"
                compact
                class="capitalize"
              />
            </div>
          </section>
          <section class="flex flex-col gap-2 border-t border-n-weak pt-3">
            <h4 class="m-0 text-xs font-medium text-n-slate-11">
              {{ $t('STRIPE_INTEGRATION.INVOICES') }}
            </h4>
            <p
              v-if="!summary.invoices.length"
              class="m-0 text-xs text-n-slate-11"
            >
              {{ $t('STRIPE_INTEGRATION.NO_INVOICES') }}
            </p>
            <div
              v-for="invoice in summary.invoices"
              :key="invoice.id"
              class="flex items-center justify-between gap-3 py-2 border-b border-n-weak last:border-b-0"
            >
              <div class="flex min-w-0 flex-col items-start gap-1.5">
                <span
                  class="max-w-full truncate text-xs font-medium"
                  :title="invoice.number || invoice.id"
                >
                  {{ invoice.number || invoice.id }}
                </span>
                <span class="text-xs text-n-slate-11">{{
                  formatDate(invoice.created)
                }}</span>
              </div>
              <div class="flex flex-col items-end gap-1.5">
                <span class="shrink-0 text-sm font-medium tabular-nums">{{
                  formatAmount(invoice)
                }}</span>
                <Label
                  :label="invoice.status"
                  :color="STATUS_COLORS[invoice.status] || 'slate'"
                  compact
                  class="capitalize"
                />
              </div>
            </div>
          </section>
        </template>
      </template>
    </template>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue';
import { dateFormat } from 'shared/helpers/timeHelper';
import { useAbortableRequest } from 'dashboard/composables/useAbortableRequest';
import {
  formatStripeAmount,
  STRIPE_STATUS_COLORS,
} from 'dashboard/helper/stripeHelper';
import StripeAPI from 'dashboard/api/integrations/stripe';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import StripeSubscription from './StripeSubscription.vue';

const props = defineProps({
  conversationId: { type: [Number, String], required: true },
  contactEmail: { type: String, default: '' },
});

const { run, isPending } = useAbortableRequest();
const summary = ref(null);
const customerId = ref('');
const error = ref(false);

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

watch(
  [() => props.conversationId, () => props.contactEmail],
  () => {
    customerId.value = '';
    load();
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-4 px-4 py-3 text-sm text-n-slate-12">
    <Spinner v-if="isPending" class="mx-auto" />
    <p v-else-if="error" role="alert" class="m-0 text-n-ruby-11">
      {{ $t('STRIPE_INTEGRATION.ERROR') }}
    </p>
    <template v-else-if="summary">
      <p v-if="summary.missing_email" class="m-0 text-n-slate-11">
        {{ $t('STRIPE_INTEGRATION.NO_EMAIL') }}
      </p>
      <p v-else-if="!summary.customers.length" class="m-0 text-n-slate-11">
        {{ $t('STRIPE_INTEGRATION.EMPTY') }}
      </p>
      <template v-else>
        <label v-if="summary.customers.length > 1" class="flex flex-col gap-2">
          {{ $t('STRIPE_INTEGRATION.SELECT') }}
          <select v-model="customerId" class="!mb-0" @change="load">
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
        <p
          v-if="summary.has_more_customers"
          class="m-0 text-xs text-n-slate-11"
        >
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
              class="flex flex-col gap-0.5 min-w-0 text-xs text-n-slate-11"
              :title="summary.customer.id"
            >
              <span class="text-sm font-medium truncate text-n-slate-12">
                {{ summary.customer.name }}
              </span>
              <span class="truncate">{{ summary.customer.email }}</span>
              <span v-if="summary.customer.phone">
                {{ summary.customer.phone }}
              </span>
            </div>
          </div>
          <section class="flex flex-col gap-2 pt-3 border-t border-n-weak">
            <h4 class="m-0 text-xs font-medium text-n-slate-11">
              {{ $t('STRIPE_INTEGRATION.SUBSCRIPTIONS') }}
            </h4>
            <p
              v-if="!summary.subscriptions.length"
              class="m-0 text-xs text-n-slate-11"
            >
              {{ $t('STRIPE_INTEGRATION.NO_SUBSCRIPTIONS') }}
            </p>
            <StripeSubscription
              v-for="subscription in summary.subscriptions"
              :key="subscription.id"
              :subscription="subscription"
            />
          </section>
          <section class="flex flex-col pt-3 border-t border-n-weak">
            <h4 class="m-0 text-xs font-medium text-n-slate-11">
              {{ $t('STRIPE_INTEGRATION.INVOICES') }}
            </h4>
            <p
              v-if="!summary.invoices.length"
              class="mt-2 mb-0 text-xs text-n-slate-11"
            >
              {{ $t('STRIPE_INTEGRATION.NO_INVOICES') }}
            </p>
            <div
              v-for="invoice in summary.invoices"
              :key="invoice.id"
              class="flex items-center justify-between gap-3 py-2.5 border-b border-n-weak last:border-b-0 last:pb-0"
            >
              <div class="flex flex-col gap-1 min-w-0">
                <span
                  class="text-sm font-medium truncate"
                  :title="invoice.number || invoice.id"
                >
                  {{ invoice.number || invoice.id }}
                </span>
                <span class="text-xs text-n-slate-11">
                  {{ dateFormat(invoice.created) }}
                </span>
              </div>
              <div class="flex flex-col items-end gap-1 shrink-0">
                <span class="text-sm font-medium tabular-nums">
                  {{ formatStripeAmount(invoice.total, invoice.currency) }}
                </span>
                <Label
                  :label="invoice.status"
                  :color="STRIPE_STATUS_COLORS[invoice.status] || 'slate'"
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

<script setup>
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue';
import { debounce } from '@chatwoot/utils';
import { BUS_EVENTS } from '../../../../shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import currency_codes from 'shared/constants/currency_codes';
import SimpleDivider from 'v3/components/Divider/SimpleDivider.vue';
import useVuelidate from '@vuelidate/core';
import { maxValue, minValue, required } from '@vuelidate/validators';
import QuantityField from './QuantityField.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import OrdersAPI from 'dashboard/api/shopify/orders';
import ShopifyLocationsAPI from 'dashboard/api/shopify/locations';
import { isAxiosError } from 'axios';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  order: {
    type: Object,
    required: true,
  },
});

const reasons = [
  'Wrong item received',
  'Item was damaged or defective',
  'Item not as described',
  'Order arrived late',
  'Duplicate or accidental order',
];

// const item_restock_options = ['no_restock', 'cancel', 'return'];

const onClose = () => {
  emitter.emit(BUS_EVENTS.REFUND_ORDER, null);
};

const totalLineItemsQuantity = computed(() => {
  return Object.fromEntries(
    props.order?.line_items.map(e => [e.id, e.quantity]) ?? []
  );
});

const refundedLineItemsQuantity = computed(() => {
  if (!props.order?.refunds.length || props.order?.refunds.length === 0) {
    return {};
  }

  const allRefundLineItems =
    props.order?.refunds.flatMap(refund => refund.refund_line_items) ?? {};

  const mergedLineItems = {};

  allRefundLineItems.forEach(item => {
    const lineItemId = item.line_item.id;
    if (!mergedLineItems[lineItemId]) {
      mergedLineItems[lineItemId] = {
        ...item.line_item,
        quantity: item.quantity,
      };
    } else {
      mergedLineItems[lineItemId].quantity += item.quantity;
    }
  });

  const entries = Object.entries(mergedLineItems).map(([id, e]) => [
    id,
    e.quantity,
  ]);

  return Object.fromEntries(entries);
});

const refundableLineItemsQuantity = computed(() => {
  console.log('Total: ', totalLineItemsQuantity.value);
  console.log('Refunded: ', refundedLineItemsQuantity.value);

  let entries = Object.entries(totalLineItemsQuantity.value).map(
    ([id, quant]) => {
      if (refundedLineItemsQuantity.value[id]) {
        return [id, quant - refundedLineItemsQuantity.value[id] ?? 0];
      } else {
        return [id, quant];
      }
    }
  );

  console.log('Mapped: ', entries);
  // entries = entries.filter(([, qty]) => qty > 0);
  // console.log('Filtered: ', entries);

  return Object.fromEntries(entries);
});

const refundQuantityStates = ref();

watch(
  refundableLineItemsQuantity,
  newLimits => {
    console.log('NEW LIMITS: ', newLimits);
    refundQuantityStates.value = Object.fromEntries(
      Object.keys(newLimits).map(id => [id, 0])
    );
  },
  { immediate: true }
);

const initialFormState = {
  refundAmount: 0,
  refundNote: null,
  customRefundReason: null,
  restockItem: true,
  sendNotification: true,
  quantity: computed(() => refundQuantityStates.value),
};

const formState = reactive(initialFormState);

const rules = computed(() => {
  const quantityRules = {};

  console.log('All limits: ', refundableLineItemsQuantity.value);
  props.order?.line_items.forEach(item => {
    const max = refundableLineItemsQuantity.value[item.id];
    console.log('Validate against: ', max, ' and id: ', item.id);
    quantityRules[item.id] = {
      required,
      minValue: minValue(0),
      maxValue: maxValue(max),
    };
  });

  return {
    refundAmount: { required },
    refundNote: { required },
    quantity: quantityRules,
  };
});

const v$ = useVuelidate(rules, formState);

const item_total_price = item => {
  return (
    item.price_set.shop_money.amount * item.quantity -
    item.total_discount_set.shop_money.amount
  );
};

let cancellationTimeout = null;

const onOrderUpdate = data => {
  if (data.order.id != props.order.id) return;

  onClose();
  emitter.emit('newToastMessage', {
    message: 'Refund create successfully',
    action: null,
  });

  clearTimeout(cancellationTimeout);
};

const locations = ref([]);
const fulfillments = ref([]);

const getAvailableLocations = async () => {
  try {
    const result = await ShopifyLocationsAPI.get();
    locations.value = result.data.locations;
  } catch (e) {
  }
};

const getFulfillmentsForTheOrder = async () => {
  const result = await OrdersAPI.orderFulfillments()
  console.log(result.data.fulfillments)
}

onMounted(() => {
  emitter.on(BUS_EVENTS.ORDER_UPDATE, onOrderUpdate);
  getAvailableLocations();
  calculateRefund();
  refundQuantityStates.value = Object.fromEntries(
    props.order.line_items.map(e => [e.id, 0])
  );
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.ORDER_UPDATE, onOrderUpdate);
  clearTimeout(cancellationTimeout);
});

const debouncedRefund = debounce(value => {
  console.log('HI THERE');
  calculateRefund();
}, 2000);

const currentSubtotal = computed(() => {
  return (
    currentRefund.value?.refund_line_items.reduce(
      (acc, curr) => acc + Number(curr.subtotal),
      0
    ) ?? 0
  );
});

const currentDiscountApplied = computed(() => {
  return (
    currentRefund.value?.refund_line_items.reduce(
      (acc, curr) => acc + Number(curr.price) - Number(curr.discounted_price),
      0
    ) ?? 0
  );
});

const currentTax = computed(() => {
  return (
    currentRefund.value?.refund_line_items.reduce(
      (acc, curr) => acc + Number(curr.total_tax),
      0
    ) ?? 0
  );
});

const availableRefund = computed(() => {
  return Number(currentRefund.value?.transactions[0].maximum_refundable) ?? 0;
});

const currentRefund = ref(null);

const calculateRefund = async () => {
  const payload = {
    orderId: props.order.id,
    currency: props.order.currency,
    refundLineItems: Object.entries(refundQuantityStates.value)
      .filter(([, qty]) => qty > 0)
      .map(([e, qty]) => ({
        line_item_id: e,
        quantity: qty,
        restock_type: 'no_restock',
      })),
  };

  console.log(`making request: `, payload);

  const res = await OrdersAPI.calculateRefund(payload);

  console.log(res);
  currentRefund.value = res.data.refund;
};

watch(
  availableRefund,
  value => {
    formState.refundAmount = value ?? 0;
  },
  { immediate: true }
);

// Only allow numbers with up to 2 decimals
function onInput(e) {
  let val = e.target.value;

  // Remove all characters except digits and dot
  val = val.replace(/[^0-9.]/g, '');

  // Only allow one dot
  const parts = val.split('.');
  if (parts.length > 2) {
    val = parts[0] + '.' + parts.slice(1).join('');
  }

  // Limit to 2 decimal places
  if (parts[1]?.length > 2) {
    val = parts[0] + '.' + parts[1].slice(0, 2);
  }

  // Prevent leading dot (".5" -> "0.5")
  if (val.startsWith('.')) {
    val = '0' + val;
  }

  formState.refundAmount = val;
}

function onBlur() {
  // Format to 2 decimals if not empty
  if (formState.refundAmount && !isNaN(formState.refundAmount)) {
    formState.refundAmount = parseFloat(formState.refundAmount).toFixed(2);
  }
}

const cancellationState = ref(null);

const refundOrder = async $t => {
  v$.value.$touch();

  if (v$.value.$invalid || currentRefund.value === null) {
    console.log('ERRORS: ', v$.value.$errors);
    return;
  }

  try {
    cancellationState.value = 'processing';

    const response = await OrdersAPI.refundOrder({
      orderId: props.order.id,
      transactions: [
        {
          ...currentRefund.value.transactions[0],
          amount: Number(formState.refundAmount),
          kind: 'refund',
        },
      ],
      note: formState.refundNote,
      notify: formState.sendNotification,
      currency: currentRefund.value.currency,
      shipping: currentRefund.value.shipping,
      refundLineItems: currentRefund.value.refund_line_items,
    });

    console.log('RESPONSE BODY: ', response);

    cancellationState.value = null;

    cancellationTimeout = setTimeout(() => {
      onClose();
      useAlert($t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.API_TIMEOUT'));
    }, 30 * 1000);
  } catch (e) {
    console.log('Error occured: ', e);
    cancellationState.value = null;
    let message = $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.API_FAILURE');
    if (isAxiosError(e)) {
      const errors = e.response.data.errors;
      if (errors && errors[0].message) {
        message = errors[0].message;
      }
    }
    useAlert(message);
  }
};

const buttonText = () => {
  return cancellationState.value === 'processing'
    ? 'CONVERSATION_SIDEBAR.SHOPIFY.REFUND.PROCESSING'
    : 'CONVERSATION_SIDEBAR.SHOPIFY.REFUND.REFUND_ORDER';
};
</script>

<template>
  <woot-modal :show="true" :on-close="onClose">
    <woot-modal-header
      :header-title="$t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TITLE')"
      :header-content="$t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.DESC')"
    />
    <form>
      <table class="woot-table items-table overflow-auto max-h-2 table-fixed">
        <thead>
          <tr>
            <th class="overflow-auto max-w-xs">
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TABLE.PRODUCT') }}
            </th>
            <th>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TABLE.ITEM_PRICE') }}
            </th>
            <th>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TABLE.QUANTITY') }}
            </th>
            <th>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TABLE.TOTAL') }}
            </th>

            <!-- <th>
              <div class="flex flex-row w-full justify-end gap-2">
                {{
                  $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TABLE.RESTOCK_ITEMS')
                }}

                <input
                  class="justify-end"
                  type="checkbox"
                  :checked="formState.restockItem"
                  @change="formState.restockItem = !formState.restockItem"
                />
              </div>
            </th> -->
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in [...order.line_items]" :key="item.id">
            <td>
              <div class="overflow-auto max-w-xs">{{ item.name }}</div>
            </td>
            <td>
              <div>
                {{
                  currency_codes[item.price_set.presentment_money.currency_code]
                }}
                {{ item.price_set.shop_money.amount }}
              </div>
            </td>
            <td class="text-center align-middle">
              <!-- <div>{{ item.quantity }}</div> -->
              <div class="inline-block">
                <QuantityField
                  v-model="formState.quantity[item.id]"
                  :min="0"
                  :max="refundableLineItemsQuantity[item.id]"
                  @input_val="debouncedRefund"
                ></QuantityField>
              </div>
            </td>
            <td>
              <div>
                {{ currency_codes[item.price_set.shop_money.currency_code] }}
                {{ item_total_price(item) }}
              </div>
            </td>
            <!-- <td>
              <div class="flex flex-row w-full justify-end">
                <input
                  type="checkbox"
                  :checked="formState.restockItem"
                  @change="formState.restockItem = !formState.restockItem"
                />
              </div>
            </td> -->
          </tr>
        </tbody>
      </table>
      <SimpleDivider></SimpleDivider>
      <div class="h-4"></div>

      <div class="flex flex-row pr-16 items-start justify-start content-start">
        <div
          class="flex flex-col items-start justify-start content-start gap-2"
        >
          <div
            class="select-visible-checkbox gap-2"
            :style="selectVisibleCheckboxStyle"
          >
            <input
              type="checkbox"
              :checked="formState.sendNotification"
              @change="formState.sendNotification = !formState.sendNotification"
            />

            <span>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.SEND_NOTIFICATION') }}
            </span>
          </div>
        </div>

        <div class="flex-1 flex-row"></div>

        <div class="flex flex-col">
          <div class="flex flex-row justify-between items-center gap-10">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.SUBTOTAL') }}
            </label>
            <span class="text-sm"
              >{{ currency_codes[order.currency] }}
              {{ /* order.subtotal_price*/ currentSubtotal }}</span
            >
          </div>

          <div class="flex flex-row justify-between gap-10">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.DISCOUNT') }}
            </label>
            <span class="text-sm"
              >{{ currency_codes[order.currency] }}
              {{ /* order.total_discount */ currentDiscountApplied }}</span
            >
          </div>

          <div class="flex flex-row justify-between gap-10">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TAX') }}
            </label>
            <span class="text-sm"
              >{{ currency_codes[order.currency] }}
              {{ /* order.total_tax */ currentTax }}</span
            >
          </div>

          <div class="flex flex-row justify-between gap-10">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.AMOUNT_REFUNDABLE') }}
            </label>
            <span class="text-sm"
              >{{ currency_codes[order.currency] }}
              {{ /* refundableAmount */ availableRefund }}</span
            >
          </div>
        </div>
      </div>

      <div class="flex flex-row justify-start items-start gap-4 mt-4">
        <div class="flex flex-col gap-2">
          <div class="flex flex-row gap-2">
            <h5>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.REFUND_AMOUNT') }}
            </h5>
            <span v-if="formState.refundAmount !== availableRefund"
              >(manual)</span
            >
          </div>

          <!-- <CurrencyInput v-model="formState.refundAmount" :currency-symbol="currency_codes[order.currency]" /> -->

          <input
            type="text"
            :value="currency_codes[order.currency] + formState.refundAmount"
            inputmode="decimal"
            placeholder="0.00"
            @input="onInput"
            @blur="onBlur"
            style="width: 200px; font-size: 1.1em"
            autocomplete="off"
          />
        </div>

        <div class="flex flex-col gap-1">
          <h5>
            {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.REFUND_REASON') }}
            <!-- {{ add marker for manual }}  -->
          </h5>

          <select
            v-model="formState.refundNote"
            class="w-full p-2 mt-1 border-0 selectInbox"
            :class="{ 'border-red-500': v$.refundNote.$error }"
          >
            <option v-for="reason in reasons" :value="reason">
              {{ reason }}
            </option>
          </select>
        </div>
      </div>

      <div class="flex flex-row justify-end mt-4">
        <Button
          type="button"
          :disabled="
            v$.$error ||
            cancellationState === 'processing' ||
            currentRefund === null
          "
          variant="primary"
          @click="() => refundOrder($t)"
        >
          {{ $t(buttonText()) }}
        </Button>
      </div>
    </form>
  </woot-modal>
</template>

<style lang="scss">
.items-table {
  > tbody {
    > tr {
      @apply cursor-pointer;

      &:hover {
        @apply bg-slate-50 dark:bg-slate-800;
      }

      &.is-active {
        @apply bg-slate-100 dark:bg-slate-700;
      }

      > td {
        &.conversation-count-item {
          @apply pl-6 rtl:pl-0 rtl:pr-6;
        }
      }

      &:last-child {
        @apply border-b-0;
      }
    }
  }
}

.select-visible-checkbox {
  @apply flex items-center text-sm text-slate-700 dark:text-white;

  input[type='checkbox'] {
    @apply w-4 h-4 cursor-pointer accent-black-600;
  }
}
</style>

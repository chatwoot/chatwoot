<script setup>
import FormSelect from 'v3/components/Form/Select.vue';
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue';
import { debounce } from '@chatwoot/utils';
import { BUS_EVENTS } from '../../../../shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import currency_codes from 'shared/constants/currency_codes';
import SimpleDivider from 'v3/components/Divider/SimpleDivider.vue';
import useVuelidate from '@vuelidate/core';
import {
  maxValue,
  minValue,
  required,
  or,
  requiredIf,
} from '@vuelidate/validators';
import QuantityField from './QuantityField.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import OrdersAPI from 'dashboard/api/shopify/orders';
import ShopifyLocationsAPI from 'dashboard/api/shopify/locations';
import { isAxiosError } from 'axios';
import { useAlert } from 'dashboard/composables';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  order: {
    type: Object,
    required: true,
  },
});

const reasons = {
  COLOR: 'Color',
  DEFECTIVE: 'Damaged or defective',
  NOT_AS_DESCRIBED: 'Item not as described',
  SIZE_TOO_LARGE: 'Size was too large',
  SIZE_TOO_SMALL: 'Size was too small',
  STYLE: 'Style',
  UNKNOWN: 'Unknown',
  UNWANTED: 'Customer changed their mind',
  WRONG_ITEM: 'Received the wrong item',
  OTHER: 'Other',
};

const reasonOptions = Object.entries(reasons).map(([key, value]) => ({
  key,
  value,
}));

const item_restock_options = {
  no_restock: 'NO_RESTOCK',
  cancel: 'CANCEL',
  return: 'RETURN',
};

const onClose = () => {
  emitter.emit(BUS_EVENTS.RETURN_ORDER, null);
};

const initialFormState = {
  shippingFees: 0,
  sendNotification: true,
  quantity: computed(() => returnQuantityStates.value),
  reasons: computed(() => returnReasonStates.value),
  notes: computed(() => returnNoteStates.value),
  restockingFees: computed(() => returnStockingFeesStates.value),
};

const formState = reactive(initialFormState);

/**
 * @typedef {Object} FulfillmentLineItem
 * @property {string} id
 * @property {number} quantity
 * @property {Object} lineItem
 * @property {string} lineItem.id
 */

/**
 * @typedef {Object} Fulfillment
 * @property {FulfillmentLineItem[]} fulfillmentLineItems
 */

/**
 * @type {import('vue').Ref<Fulfillment[]>}
 */
const fulfillments = ref([]);

const returnableLineItemsQuantity = ref(null);

const rules = computed(() => {
  const quantityRules = {};
  const reasonRules = {};
  const reasonNoteRules = {};
  const restockFeeRules = {};

  fulfillments.value
    .flatMap(e => e.fulfillmentLineItems)
    .forEach(item => {
      if (!returnableLineItemsQuantity.value) {
        return;
      }
      const max = returnableLineItemsQuantity.value[item.id];
      quantityRules[item.id] = {
        required,
        validRestockFee: or(value => value === 0, minValue(1)),
        maxValue: maxValue(max),
      };

      restockFeeRules[item.id] = {
        required,
        minValue: minValue(1),
        maxValue: maxValue(99),
      };

      reasonNoteRules[item.id] = {
        required: requiredIf(() => formState.reasons[item.id] === 'OTHER'),
      };

      if (returnQuantityStates.value[item.id] > 0) {
        reasonRules[item.id] = {
          required,
        };
      }
    });
  const notZero = value => value !== 0;

  return {
    shippingFees: {},
    quantity: quantityRules,
    reasons: reasonRules,
    notes: reasonNoteRules,
    restockingFees: restockFeeRules,
  };
});

const v$ = useVuelidate(rules, formState);

const item_total_price = item => {
  return calculatedRefundForLineItems.value[item.id].refund;
};

let cancellationTimeout = null;

// const refundedLineItemsQuantity = computed(() => {
//   if (!props.order?.refunds.length || props.order?.refunds.length === 0) {
//     return {};
//   }

//   const allRefundLineItems =
//     props.order?.refunds.flatMap(refund => refund.refund_line_items) ?? {};

//   const mergedLineItems = {};

//   allRefundLineItems.forEach(item => {
//     const lineItemId = item.line_item.id;
//     if (!mergedLineItems[lineItemId]) {
//       mergedLineItems[lineItemId] = {
//         ...item.line_item,
//         quantity: item.quantity,
//       };
//     } else {
//       mergedLineItems[lineItemId].quantity += item.quantity;
//     }
//   });

//   const entries = Object.entries(mergedLineItems).map(([id, e]) => [
//     id,
//     e.quantity,
//   ]);

//   return Object.fromEntries(entries);
// });

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

const getAvailableLocations = async () => {
  try {
    const result = await ShopifyLocationsAPI.get();
    locations.value = result.data.locations;
  } catch (e) {}
};

/**
 * @typedef {Object} Money
 * @property {string} amount
 * @property {string} currencyCode
 */

/**
 * @typedef {Object} MaximumRefundableSet
 * @property {Money} presentmentMoney
 * @property {Money} shopMoney
 */

/**
 * @typedef {Object} ParentTransaction
 * @property {string} id
 */

/**
 * @typedef {Object} SuggestedTransaction
 * @property {string} gateway
 * @property {ParentTransaction} parentTransaction
 */

/**
 * @typedef {Object} SuggestedRefund
 * @property {MaximumRefundableSet} maximumRefundableSet
 * @property {SuggestedTransaction[]} suggestedTransactions
 */

/** @type {import('vue').Ref<SuggestedRefund|null>} */
const suggestedRefund = ref(null);

const reverseFulfillmentLineItems = ref([]);

const getOrderInfo = async () => {
  const result = await OrdersAPI.orderDetails({ orderId: props.order.id });

  suggestedRefund.value = result.data.order.suggestedRefund;

  fulfillments.value = result.data.order.fulfillments.map(e => ({
    ...e,
    fulfillmentLineItems: e.fulfillmentLineItems.nodes,
  }));

  console.log('ORDER: ', result.data.order);

  reverseFulfillmentLineItems.value = result.data.order.returns.nodes.flatMap(
    e =>
      e.reverseFulfillmentOrders.nodes.flatMap(e =>
        e.lineItems.nodes.flatMap(e => e.fulfillmentLineItem)
      )
  );

  for (const reverseFLI of reverseFulfillmentLineItems.value) {
    for (const fulfillment of fulfillments.value) {
      console.log('FULFILLMENT: ', fulfillment);
      const index = fulfillment.fulfillmentLineItems.findIndex(
        e => e.id === reverseFLI.id
      );
      if (index != -1) {
        fulfillment.fulfillmentLineItems[index].quantity -= reverseFLI.quantity;
        if (fulfillment.fulfillmentLineItems[index].quantity === 0) {
          fulfillment.fulfillmentLineItems = [
            ...fulfillment.fulfillmentLineItems.slice(0, index),
            ...fulfillment.fulfillmentLineItems.slice(index + 1),
          ];
        }
      }
    }
  }

  fulfillments.value = fulfillments.value.filter(
    e => e.fulfillmentLineItems.length > 0
  );

  fulfillments.value = fulfillments.value.map(e => ({
    ...e,
    fulfillmentLineItems: e.fulfillmentLineItems.map(fli => ({
      ...fli,
      lineItem: props.order.line_items.find(
        e => `gid://shopify/LineItem/${e.id}` === fli.lineItem.id
      ),
    })),
  }));

  returnableLineItemsQuantity.value = Object.fromEntries(
    fulfillments.value.flatMap(e =>
      e.fulfillmentLineItems.map(e => [e.id, e.quantity])
    )
  );

  console.log('REVERSE: ', reverseFulfillmentLineItems.value);
  console.log('FINAL: ', fulfillments.value);
};

onMounted(() => {
  emitter.on(BUS_EVENTS.ORDER_UPDATE, onOrderUpdate);
  getAvailableLocations();
  getOrderInfo();
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.ORDER_UPDATE, onOrderUpdate);
  clearTimeout(cancellationTimeout);
});

const returnQuantityStates = ref({});

const returnReasonStates = ref({});

const returnNoteStates = ref({});

const returnStockingFeesStates = ref({});

watch(
  returnableLineItemsQuantity,
  newLimits => {
    if (newLimits == null) {
      return;
    }
    returnQuantityStates.value = Object.fromEntries(
      Object.keys(newLimits).map(id => [id, 0])
    );
  },
  { immediate: true }
);

watch(
  returnQuantityStates,
  (newValue, oldValue) => {
    if (newValue == null) {
      return;
    }
    for (const id of Object.keys(newValue)) {
      if (newValue[id] > 0 && oldValue[id] === 0) {
        returnReasonStates.value[id] = '';
        returnNoteStates.value[id] = '';
        returnStockingFeesStates.value[id] = 0;
      } else if (newValue[id] === 0) {
        if (returnReasonStates.value[id]) {
          delete returnReasonStates.value[id];
        }
        if (returnNoteStates.value[id]) {
          delete returnNoteStates.value[id];
        }
        if (returnStockingFeesStates.value[id]) {
          delete returnStockingFeesStates.value[id];
        }
      }
    }
  },
  { immediate: true, deep: true }
);

const debouncedRefund = debounce(value => {
  console.log('HI THERE');
  calculateReturn();
}, 2000);

const calculatedRefundForLineItems = ref(
  Object.fromEntries(
    props.order.line_items.map(e => [e.id, { refund: 0, tax: 0 }])
  )
);

/**
 * @typedef {Object} ShopMoney
 * @property {string} amount
 * @property {string} currencyCode
 */

/**
 * @typedef {Object} AmountSet
 * @property {ShopMoney} shopMoney
 */

/**
 * @typedef {Object} FulfillmentLineItem
 * @property {string} id
 */

/**
 * @typedef {Object} RestockingFee
 * @property {AmountSet} amountSet
 */

/**
 * @typedef {Object} ReturnLineItem
 * @property {string} id
 * @property {FulfillmentLineItem} fulfillmentLineItem
 * @property {number} quantity
 * @property {AmountSet} subtotalSet
 * @property {RestockingFee} restockingFee
 * @property {AmountSet} totalTaxSet
 */

/**
 * @typedef {Object} ReturnShippingFee
 * @property {AmountSet} amountSet
 */

/**
 * @typedef {Object} OrderReturn
 * @property {string} id
 * @property {ReturnLineItem[]} returnLineItems
 * @property {ReturnShippingFee} returnShippingFee
 */

/** @type {import('vue').Ref<OrderReturn|null>} */
const currentRefund = ref(null);

const currentSubtotal = computed(
  () =>
    currentRefund.value?.returnLineItems.reduce(
      (acc, cur) => acc + Number(cur.subtotalSet.shopMoney.amount),
      0
    ) ?? 0
);

const currentTax = computed(
  () =>
    currentRefund.value?.returnLineItems.reduce(
      (acc, cur) => acc + Number(cur.totalTaxSet.shopMoney.amount),
      0
    ) ?? 0
);

const currentRestockingFee = computed(
  () =>
    currentRefund.value?.returnLineItems.reduce(
      (acc, cur) =>
        acc + !cur.restockingFee
          ? 0
          : Number(cur.restockingFee.amountSet.shopMoney.amount),
      0
    ) ?? 0
);

const currentShipping = computed(() =>
  currentRefund.value?.returnShippingFee != null
    ? Number(currentRefund.value?.returnShippingFee.amountSet.shopMoney.amount)
    : 0
);

const currentTotal = computed(
  () =>
    currentSubtotal.value +
    currentTax.value +
    currentRestockingFee.value +
    currentShipping.value
);

const buttonState = ref(null);

const calculateReturn = async () => {
  const payload = {
    orderId: props.order.id,
    returnLineItems: Object.entries(returnQuantityStates.value)
      .filter(([, qty]) => qty > 0)
      .map(([e, qty]) => ({
        fulfillmentLineItemId: e,
        quantity: qty,
        restockingFeePercentage: Number(formState.restockingFees[e] ?? 0),
      })),
    returnShippingFee: {
      amount: Number(formState.shippingFees),
      currencyCode: props.order.currency,
    },
  };

  console.log(`making request: `, payload);

  const res = await OrdersAPI.returnCalculate(payload);

  console.log(res);
  currentRefund.value = res.data.refundable;
};

const createReturn = async $t => {
  v$.value.$touch();

  if (v$.value.$invalid) {
    console.log('ERRORS: ', v$.value.$errors);
    return;
  }

  try {
    buttonState.value = 'processing';

    const payload = {
      orderId: props.order.id,
      returnLineItems: Object.entries(returnQuantityStates.value)
        .filter(([, qty]) => qty > 0)
        .map(([e, qty]) => ({
          fulfillmentLineItemId: e,
          quantity: qty,
          restockingFeePercentage: Number(formState.restockingFees[e] ?? 0), //REVIEW: This shouldn't be null anyways
          returnReason: returnReasonStates.value[e],
          returnReasonNote: returnNoteStates.value[e],
        })),
      returnShippingFee: {
        amount: Number(formState.shippingFees),
        currencyCode: props.order.currency,
      },
    };

    console.log('Payload for return create: ', payload);

    const response = await OrdersAPI.returnCreate(payload);

    console.log('RESPONSE BODY: ', response);

    buttonState.value = null;

    cancellationTimeout = setTimeout(() => {
      onClose();
      useAlert($t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.API_TIMEOUT'));
    }, 30 * 1000);
  } catch (e) {
    console.log('Error occured: ', e);
    buttonState.value = null;
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
  return buttonState.value === 'processing'
    ? 'CONVERSATION_SIDEBAR.SHOPIFY.RETURN.PROCESSING'
    : 'CONVERSATION_SIDEBAR.SHOPIFY.RETURN.BUTTON_TEXT';
};

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

  formState.shippingFees = val;
  debouncedRefund();
}

function onBlur() {
  // Format to 2 decimals if not empty
  if (formState.shippingFees && !isNaN(formState.shippingFees)) {
    formState.shippingFees = parseFloat(formState.shippingFees).toFixed(2);
  }
}
</script>

<template>
  <woot-modal :show="true" :on-close="onClose" size="w-[50.4rem] h-[50.4rem]">
    <woot-modal-header
      :header-title="$t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.TITLE')"
      :header-content="$t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.DESC')"
    />
    <form>
      <div class="h-[27.4rem] overflow-scroll">
        <div v-for="fulfillment in fulfillments">
          <h3 class="text-base font-semibold text-gray-900 p-2">
            {{ fulfillment.name }}
          </h3>
          <div
            v-for="fli in fulfillment.fulfillmentLineItems.filter(
              e => e.quantity > 0
            )"
            class="flex flex-col border rounded-lg shadow-sm p-4 m-2"
          >
            <div class="flex flex-row justify-between">
              <div class="flex flex-col">
                <h6>
                  {{ fli.lineItem.name }}
                </h6>
                <div class="flex flex-row gap-2">
                  <span>
                    {{
                      currency_codes[
                        fli.lineItem.price_set.shop_money.currency_code
                      ]
                    }}
                    {{ fli.lineItem.price_set.shop_money.amount }}
                  </span>
                  <span> x{{ fli.quantity }} </span>
                </div>
              </div>
              <div class="flex flex-row gap-4 items-center">
                <label class="text-base">
                  {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.Quantity') }}
                </label>
                <QuantityField
                  v-model="formState.quantity[fli.id]"
                  :min="0"
                  :max="
                    returnableLineItemsQuantity
                      ? returnableLineItemsQuantity[fli.id]
                      : 0
                  "
                  @input_val="debouncedRefund"
                ></QuantityField>

                <span class="pl-10 text-sm w-[100px]">
                  {{
                    currency_codes[
                      currentRefund?.returnLineItems.find(
                        e => e.fulfillmentLineItem.id === fli.id
                      )?.subtotalSet.shopMoney.currencyCode ?? order.currency
                    ]
                  }}
                  {{
                    (currentRefund?.returnLineItems.find(
                      e => e.fulfillmentLineItem.id === fli.id
                    )?.quantity ?? 0) *
                    Math.abs(
                      Number(
                        currentRefund?.returnLineItems.find(
                          e => e.fulfillmentLineItem.id == fli.id
                        )?.subtotalSet.shopMoney.amount ?? 0
                      )
                    )
                  }}
                </span>
              </div>
            </div>

            <div
              v-if="formState.quantity[fli.id] > 0"
              class="flex flex-row items-start justify-between"
            >
              <div class="flex flex-col">
                <label>
                  {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.RETURN_REASON') }}
                </label>

                <FormSelect
                  v-model="formState.reasons[fli.id]"
                  name="returnReason"
                  spacing="compact"
                  class="flex-grow"
                  :options="reasonOptions"
                  :placeholder="
                    $t('CONVERSATION_SIDEBAR.SHOPIFY.CANCEL.REASON')
                  "
                  :has-error="v$.reasons[fli.id].$error"
                  :error-message="v$.reasons[fli.id].$errors[0]?.$message || ''"
                >
                  <option
                    v-for="reason in reasonOptions"
                    :key="reason.key"
                    :value="reason.key"
                  >
                    {{ reason.value }}
                  </option>
                </FormSelect>
              </div>

              <div
                class="flex flex-row pt-6 w-[25rem] h-[2.5rem] gap-4 items-start justify-end"
              >
                <div class="text-center">
                  <Input
                    type="number"
                    spacing="base"
                    :message="
                      v$.restockingFees[fli.id].$errors[0]?.$message || ''
                    "
                    :message-type="
                      v$.restockingFees[fli.id].$error ? 'error' : 'message'
                    "
                    v-model="formState.restockingFees[fli.id]"
                    inputmode="decimal"
                    placeholder="0.00"
                    autocomplete="off"
                    class="w-[10rem] leading-none"
                    @input="() => debouncedRefund()"
                  >
                    <template #input-prefix>
                      <span class="text-gray-500">
                        {{
                          $t(
                            'CONVERSATION_SIDEBAR.SHOPIFY.RETURN.RESTOCKING_FEES'
                          )
                        }}
                        %
                      </span>
                    </template>
                  </Input>
                </div>

                <span class="pl-10 pt-3 text-sm w-[100px]">
                  {{
                    currency_codes[
                      currentRefund?.returnLineItems.find(
                        e => e.fulfillmentLineItem.id === fli.id
                      )?.restockingFee?.amountSet.shopMoney.currencyCode ??
                        order.currency
                    ]
                  }}
                  {{
                    Math.abs(
                      Number(
                        currentRefund?.returnLineItems.find(
                          e => e.fulfillmentLineItem.id === fli.id
                        )?.restockingFee?.amountSet.shopMoney.amount ?? 0
                      )
                    )
                  }}
                </span>
              </div>
            </div>
            <div
              v-if="formState.reasons[fli.id] === 'OTHER'"
              class="flex flex-col gap-2"
            >
              <label class="text-sm">
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.RESTOCKING_FEES') }}
              </label>

              <div class="w-[250px]">
                <input
                  v-model="formState.notes[fli.id]"
                  type="text"
                  maxlength="255"
                />
              </div>

              <span
                v-if="v$.notes[fli.id].$error"
                class="text-xs text-red-500 pl-2"
              >
                {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.NOTE_REQUIRED') }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <SimpleDivider></SimpleDivider>

      <div class="h-4"></div>

      <div
        class="flex flex-row pr-2 pt-2 items-start justify-start content-start"
      >
        <div class="flex flex-col gap-2">
          <div class="flex flex-row gap-2">
            <h5>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.SHIPPING_FEES') }}
            </h5>
          </div>

          <Input
            type="text"
            spacing="base"
            v-model="formState.shippingFees"
            :message-type="v$.shippingFees.$error ? 'error' : 'info'"
            :message="
              v$.shippingFees.$error
                ? $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.INVALID_AMOUNT')
                : ''
            "
            @blur="v$.shippingFees.$touch"
            inputmode="decimal"
            placeholder="0.00"
            style="width: 200px; font-size: 1.1em"
            autocomplete="off"
          >
            <template #input-prefix>
              <span class="text-gray-500">
                {{ currency_codes[order.currency] }}
              </span>
            </template>
          </Input>
        </div>

        <div class="flex-1 flex-row"></div>

        <div class="flex flex-col items-end justify-end">
          <div class="flex flex-row items-center gap-8">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.SUBTOTAL') }}
            </label>
            <span class="text-sm w-[100px] text-right"
              >{{ currency_codes[order.currency] }} {{ currentSubtotal }}</span
            >
          </div>

          <div class="flex flex-row items-center gap-8">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.SHIPPING_FEES') }}
            </label>
            <span class="text-sm w-[100px] text-right"
              >{{ currency_codes[order.currency] }} {{ currentShipping }}</span
            >
          </div>

          <div class="flex flex-row items-center gap-8">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.RESTOCKING_FEES') }}
            </label>
            <span class="text-sm w-[100px] text-right"
              >{{ currency_codes[order.currency] }}
              {{ currentRestockingFee }}</span
            >
          </div>

          <div class="flex flex-row items-center gap-8">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.TAX') }}
            </label>
            <span class="text-sm w-[100px] text-right"
              >{{ currency_codes[order.currency] }} {{ currentTax }}</span
            >
          </div>

          <div class="flex flex-row items-center gap-8">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.TOTAL') }}
            </label>
            <span class="text-sm w-[100px] text-right"
              >{{ currency_codes[order.currency] }}
              {{ Math.abs(currentTotal) }}</span
            >
          </div>
        </div>
      </div>

      <div class="flex flex-row justify-end absolute bottom-4 right-4 items-center gap-4">
        <label class="text-base">
          {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.RETURN.REFUND_LATER_HINT') }}
        </label>
        <Button
          type="button"
          :disabled="v$.$error || buttonState === 'processing'"
          variant="primary"
          @click="() => createReturn($t)"
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

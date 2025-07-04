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

const item_restock_options = {
  no_restock: 'NO_RESTOCK',
  cancel: 'CANCEL',
  return: 'RETURN',
};

const onClose = () => {
  emitter.emit(BUS_EVENTS.REFUND_ORDER, null);
};

const stockParameters = ref(
  Object.fromEntries(
    props.order.line_items
      .map(e => [
        [
          `ful_${e.id}`,
          {
            restock: false,
            fulfilled: true,
            location: null,
          },
        ],
        [
          `unful_${e.id}`,
          {
            restock: false,
            fulfilled: false,
            location: null,
          },
        ],
      ])
      .flatMap(e => e)
  )
);

const initialFormState = {
  refundAmount: 0,
  refundNote: null,
  customRefundReason: null,
  sendNotification: true,
  unfulfilledQuantity: computed(() => unfulfilledQuantityStates.value),
  fulfilledQuantity: computed(() => fulfilledQuantityStates.value),
  stockParameters: computed(() => stockParameters.value),
};

const formState = reactive(initialFormState);

watch(
  stockParameters,
  (newVal, oldVal) => {
    for (var key of Object.keys(newVal)) {
      var newStockParam = newVal[key];

      var oldStockParam = oldVal ? oldVal[key] : null;
      if (
        newStockParam.fulfilled &&
        newStockParam.restock &&
        (!oldVal || !oldStockParam.restock)
      ) {
        formState.stockParameters[stockParam].location = locations[0].id;
      }
    }
  },
  { immediate: true, deep: true }
);

const lineItemsSegmentedByFulfillType = ref({});

const rules = computed(() => {
  const unfulfilledQuantitiesRules = {};
  const fulfilledQuantitiesRules = {};

  props.order?.line_items.forEach(item => {
    if (Object.keys(lineItemsSegmentedByFulfillType.value).length === 0) {
      return;
    }

    const segment =
      lineItemsSegmentedByFulfillType.value[
        `gid://shopify/LineItem/${item.id}`
      ];

    console.log('SEGMENT: ', segment);

    if (
      segment.unfulfilled_and_refundable > 0 &&
      unfulfilledQuantityStates[item.id] > 0
    ) {
      unfulfilledQuantitiesRules[item.id] = {
        required,
        minValue: minValue(0),
        maxValue: maxValue(segment.unfulfilled_and_refundable),
      };
    }

    if (
      segment.fulfilled_and_refundable > 0 &&
      unfulfilledQuantityStates[item.id] > 0
    ) {
      fulfilledQuantitiesRules[item.id] = {
        required,
        minValue: minValue(0),
        maxValue: maxValue(segment.fulfilled_and_refundable),
      };
    }
  });

  const notZero = value => value !== 0;

  return {
    refundAmount: { required, notZero },
    refundNote: { required },
    unfulfilledQuantities: unfulfilledQuantitiesRules,
    fulfilledQuantities: fulfilledQuantitiesRules,
  };
});

const v$ = useVuelidate(rules, formState);

const item_total_price = (item, pref) => {
  console.log(
    'CALCULATEDREFUNDFORLINEITEMS: ',
    calculatedRefundForLineItems,
    ' ,',
    item,
    ' , ',
    pref
  );
  return calculatedRefundForLineItems.value[`${pref}_${item.id}`].refund;
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

/**
 * @typedef {Object} LineItem
 * @property {string} id
 * @property {number} refundableQuantity
 */

/**
 * @type {import('vue').Ref<LineItem[]>}
 */
const orderLineItems = ref([]);

const getOrderInfo = async () => {
  const result = await OrdersAPI.orderFulfillments({ orderId: props.order.id });

  suggestedRefund.value = result.data.order.suggestedRefund;

  fulfillments.value = result.data.order.fulfillments.map(
    e => e.fulfillmentLineItems.nodes
  );

  for (var e of result.data.order.lineItems.nodes) {
    const refundableQuantity = e.refundableQuantity;
    const unfulfilledQuantity = e.unfulfilledQuantity;

    const fulfilled_and_refundable = Math.max(
      refundableQuantity - unfulfilledQuantity,
      0
    );

    const unfulfilled_and_refundable = Math.min(
      refundableQuantity,
      unfulfilledQuantity
    );

    lineItemsSegmentedByFulfillType.value[e.id] = {
      fulfilled_and_refundable,
      unfulfilled_and_refundable,
      ...props.order.line_items.find(
        i => e.id === `gid://shopify/LineItem/${i.id}`
      ),
    };
  }

  console.log('All segments: ', lineItemsSegmentedByFulfillType);

  orderLineItems.value = result.data.order.lineItems.nodes;
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

const unfulfilledQuantityStates = ref(
  Object.fromEntries(props.order.line_items.map(e => [e.id, 0]))
);

const fulfilledQuantityStates = ref(
  Object.fromEntries(props.order.line_items.map(e => [e.id, 0]))
);

watch(
  lineItemsSegmentedByFulfillType,
  newVal => {
    for (const segmentKey in lineItemsSegmentedByFulfillType.keys) {
      const segment = lineItemsSegmentedByFulfillType[segmentKey];
      if (segment.unfulfilled_and_refundable > 0) {
        unfulfilledQuantityStates.value[key] =
          segment.unfulfilled_and_refundable;
      }
      if (segment.fulfilled_and_refundable > 0) {
        fulfilledQuantityStates.value[key] = segment.fulfilled_and_refundable;
      }

      if (
        segment.unfulfilled_and_refundable > 0 ||
        segment.fulfilled_and_refundable > 0
      ) {
        stockParameters.value[`ful_${segment.id}`] = {
          fulfilled: true,
          restock: true,
          location: locations.value[0].id,
        };

        stockParameters.value[`unful_${segment.id}`] = {
          fulfilled: true,
          restock: true,
          location: locations.value[0].id,
        };
      }
    }
  },
  {
    immediate: true,
    deep: true,
  }
);

// watch(
//   refundableLineItemsQuantity,
//   newLimits => {
//     if (newLimits == null) {
//       return;
//     }
//     refundQuantityStates.value = Object.fromEntries(
//       Object.keys(newLimits).map(id => [id, 0])
//     );
//   },
//   { immediate: true }
// );

// watch(
//   fulfilledRefundableLineItemsQuantity,
//   newLimits => {
//     if (newLimits == null) {
//       return;
//     }
//     fulfilledRefundQuantityStates.value = Object.fromEntries(
//       Object.keys(newLimits).map(id => [id, 0])
//     );
//   },
//   { immediate: true }
// );

const debouncedRefund = debounce(value => {
  console.log('HI THERE');
  calculateRefund();
}, 2000);

const calculatedRefundForLineItems = ref(
  Object.fromEntries(
    props.order.line_items
      .map(e => [
        [`ful_${e.id}`, { refund: 0, tax: 0 }],
        [`unful_${e.id}`, { refund: 0, tax: 0 }],
      ])
      .flatMap(e => e)
  )
);

const calculateRefund = async () => {
  const payload = {
    orderId: props.order.id,
    currency: props.order.currency,
    refundLineItems: [
      ...Object.entries(unfulfilledQuantityStates.value)
        // .filter(([, qty]) => qty > 0)
        .map(([e, qty]) => ({
          line_item_id: e,
          quantity: qty,
          restock_type: 'cancel',
          pref: 'unful',
        })),
      ...Object.entries(fulfilledQuantityStates.value)
        // .filter(([, qty]) => qty > 0)
        .map(([e, qty]) => ({
          line_item_id: e,
          quantity: qty,
          restock_type: 'no_stock',
          pref: 'ful',
        })),
    ],
  };

  console.log('PYLOD: ', payload);

  for (const refundItem of payload.refundLineItems) {
    const lid = Number(refundItem.line_item_id);
    console.log('LID: ', typeof lid);
    console.log('PROPS lis: ', props.order.line_items);
    const li = props.order.line_items.find(e => e.id === lid);

    const tax = li.tax_lines.reduce(
      (acc, curr) => Number(curr.price_set.shop_money.amount) + acc,
      0
    );

    console.log('Calc tax: ', tax);

    calculatedRefundForLineItems.value[`${refundItem.pref}_${lid}`] = {
      refund: Number(li.price_set.shop_money.amount) * refundItem.quantity,
      tax: Number((tax / Number(li.quantity)) * Number(refundItem.quantity)),
    };
  }
};

const currentSubtotal = computed(() => {
  return Object.values(calculatedRefundForLineItems.value).reduce(
    (acc, cur) => cur.refund + acc,
    0
  );
});

watch(
  calculatedRefundForLineItems,
  newVal => {
    console.log('CHANGED THERE ', newVal);
    formState.refundAmount = Object.values(newVal).reduce(
      (acc, cur) => acc + cur.refund + cur.tax,
      0
    );
  },
  { deep: true, immediate: true }
);

const currentTax = computed(() => {
  return Object.values(calculatedRefundForLineItems.value).reduce(
    (acc, cur) => cur.tax + acc,
    0
  );
});

/**
 * @typedef {[string, string]} AvailableRefundTuple
 * A tuple containing the refund amount and the currency string.
 */

/**
 * The available refund as a tuple of [amount, currency], or null if unavailable.
 * @type {import('vue').ComputedRef<AvailableRefundTuple|null>}
 */
const availableRefund = computed(() => {
  const suggestedRefundShopAmount =
    suggestedRefund.value?.maximumRefundableSet.shopMoney.amount;
  if (suggestedRefund.value == null) {
    return null;
  }
  const suggestedRefundShopCurrency =
    suggestedRefund.value?.maximumRefundableSet.shopMoney.currencyCode;
  return [
    suggestedRefundShopAmount,
    currency_codes[suggestedRefundShopCurrency],
  ];
});

// const currentRefund = ref(null);

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

  if (v$.value.$invalid) {
    console.log('ERRORS: ', v$.value.$errors);
    return;
  }

  try {
    cancellationState.value = 'processing';

    const response = await OrdersAPI.refundOrder({
      orderId: props.order.id,
      transactions: [
        {
          amount: Number(formState.refundAmount),
          order_id: props.order.id,
          parent_id:
            suggestedRefund.value.suggestedTransactions[0].parentTransaction.id,
          gateway: suggestedRefund.value.suggestedTransactions[0].gateway,
          kind: 'refund',
        },
      ],
      note: formState.refundNote,
      notify: formState.sendNotification,
      currency:
        suggestedRefund.value.maximumRefundableSet.shopMoney.currencyCode,
      shipping: {}, //currentRefund.value.shipping,
      // refundLineItems: currentRefund.value.refund_line_items,

      refundLineItems: [
        ...Object.entries(unfulfilledQuantityStates.value)
          .filter(([, qty]) => qty > 0)
          .map(([e, qty]) => ({
            line_item_id: e,
            quantity: qty,
            restock_type: stockParameters.value[`unful_${e}`].restock
              ? item_restock_options.cancel
              : item_restock_options.no_restock,
          })),
        ...Object.entries(fulfilledQuantityStates.value)
          .filter(([, qty]) => qty > 0)
          .map(([e, qty]) => ({
            line_item_id: e,
            quantity: qty,
            location_id: !stockParameters.value[`ful_${e}`].restock
              ? null
              : stockParameters.value[`ful_${e}`].location,
            restock_type: stockParameters.value[`ful_${e}`].restock
              ? item_restock_options.return
              : item_restock_options.no_restock,
          })),
      ],
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

const allUnfulfilledRestockState = computed({
  // Getter: returns true if all relevant items are enabled
  get() {
    Object.values(stockParameters.value).every(e =>
      !e.fulfilled ? e.restock : true
    );
  },
  // Setter: sets all relevant items to the new value
  set(value) {
    Object.values(stockParameters.value).forEach(e => {
      if (!e.fulfilled) {
        e.restock = value;
      }
    });
  },
});

const allFulfilledRestockState = computed({
  // Getter: returns true if all relevant items are enabled
  get() {
    Object.values(stockParameters.value).every(e =>
      e.fulfilled ? e.restock : true
    );
  },
  // Setter: sets all relevant items to the new value
  set(value) {
    Object.values(stockParameters.value).forEach(e => {
      console.log('Stock params: ', stockParameters.value);
      console.log('Setting e: ', e);
      if (e.fulfilled) {
        e.restock = value;
      }
    });
  },
});

const buttonText = () => {
  return cancellationState.value === 'processing'
    ? 'CONVERSATION_SIDEBAR.SHOPIFY.REFUND.PROCESSING'
    : 'CONVERSATION_SIDEBAR.SHOPIFY.REFUND.REFUND_ORDER';
};
</script>

<template>
  <woot-modal :show="true" :on-close="onClose" size="w-[60.4rem]">
    <woot-modal-header
      :header-title="$t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TITLE')"
      :header-content="$t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.DESC')"
    />
    <form>
      <div
        v-if="
          Object.values(lineItemsSegmentedByFulfillType).filter(
            e => e.unfulfilled_and_refundable > 0
          ).length > 0
        "
        class="flex flex-col gap-2"
      >
        <h3>Unfulfilled</h3>
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

              <th>
                <div class="flex flex-row w-full justify-end gap-2">
                  {{
                    $t(
                      'CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TABLE.RESTOCK_ITEMS'
                    )
                  }}

                  <input
                    class="justify-end"
                    type="checkbox"
                    v-model="allUnfulfilledRestockState"
                  />
                </div>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="item in Object.values(
                lineItemsSegmentedByFulfillType
              ).filter(e => e.unfulfilled_and_refundable > 0)"
              :key="item.id"
            >
              <td>
                <div class="overflow-auto max-w-xs">{{ item.name }}</div>
              </td>
              <td>
                <div>
                  {{
                    currency_codes[
                      item.price_set.presentment_money.currency_code
                    ]
                  }}
                  {{ item.price_set.shop_money.amount }}
                </div>
              </td>
              <td class="text-center align-middle">
                <!-- <div>{{ item.quantity }}</div> -->
                <div class="inline-block">
                  <QuantityField
                    v-model="formState.unfulfilledQuantity[item.id]"
                    :min="0"
                    :max="item.unfulfilled_and_refundable"
                    @input_val="debouncedRefund"
                  ></QuantityField>
                </div>
              </td>
              <td>
                <div>
                  {{ currency_codes[item.price_set.shop_money.currency_code] }}
                  {{ item_total_price(item, 'unful') }}
                </div>
              </td>
              <td>
                <div class="flex flex-row w-full justify-end gap-4">
                  <input
                    type="checkbox"
                    v-model="
                      formState.stockParameters[`unful_${item.id}`].restock
                    "
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <SimpleDivider></SimpleDivider>

      <div
        v-if="
          Object.values(lineItemsSegmentedByFulfillType).filter(
            e => e.fulfilled_and_refundable > 0
          ).length > 0
        "
        class="flex flex-col gap-2"
      >
        <h3>Fulfilled</h3>
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

              <th>
                <div class="flex flex-row w-full justify-end gap-2">
                  {{
                    $t(
                      'CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TABLE.RESTOCK_ITEMS'
                    )
                  }}

                  <input
                    class="justify-end"
                    type="checkbox"
                    v-model="allFulfilledRestockState"
                  />
                </div>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="item in Object.values(
                lineItemsSegmentedByFulfillType
              ).filter(e => e.fulfilled_and_refundable > 0)"
              :key="item.id"
            >
              <td>
                <div class="overflow-auto max-w-xs">{{ item.name }}</div>
              </td>
              <td>
                <div>
                  {{
                    currency_codes[
                      item.price_set.presentment_money.currency_code
                    ]
                  }}
                  {{ item.price_set.shop_money.amount }}
                </div>
              </td>
              <td class="text-center align-middle">
                <!-- <div>{{ item.quantity }}</div> -->
                <div class="inline-block">
                  <QuantityField
                    v-model="formState.fulfilledQuantity[item.id]"
                    :min="0"
                    :max="item.fulfilled_and_refundable"
                    @input_val="debouncedRefund"
                  ></QuantityField>
                </div>
              </td>
              <td>
                <div>
                  {{ currency_codes[item.price_set.shop_money.currency_code] }}
                  {{ item_total_price(item, 'ful') }}
                </div>
              </td>
              <td>
                <div
                  class="flex flex-row w-full items-center justify-end gap-4"
                >
                  <div
                    v-if="formState.stockParameters[`ful_${item.id}`].restock"
                    class="flex flex-col"
                  >
                    <select
                      v-model="
                        formState.stockParameters[`ful_${item.id}`].location
                      "
                      class="thin-select"
                      :class="{ 'border-red-500': v$.refundNote.$error }"
                    >
                      <option
                        v-for="location in locations"
                        :value="location.id"
                      >
                        {{ location.name }}
                      </option>
                    </select>
                  </div>
                  <div>
                    <input
                      type="checkbox"
                      v-model="
                        formState.stockParameters[`ful_${item.id}`].restock
                      "
                    />
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <SimpleDivider></SimpleDivider>
      <div class="h-4"></div>

      <div
        class="flex flex-row pr-[10px] pt-2 items-start justify-start content-start"
      >
        <div class="flex-1 flex-row"></div>

        <div class="flex flex-col">
          <div class="flex flex-row justify-start items-center gap-10">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.SUBTOTAL') }}
            </label>
            <span class="text-sm"
              >{{ currency_codes[order.currency] }}
              {{ /* order.subtotal_price*/ currentSubtotal }}</span
            >
          </div>

          <div class="flex flex-row justify-start items-center gap-[72px]">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TAX') }}
            </label>
            <span class="text-sm"
              >{{ currency_codes[order.currency] }}
              {{ /* order.total_tax */ currentTax }}</span
            >
          </div>

          <div class="flex flex-row justify-start items-center gap-[64px]">
            <label>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TOTAL') }}
            </label>
            <span class="text-sm"
              >{{ currency_codes[order.currency] }}
              {{ /* order.total_tax */ currentSubtotal + currentTax }}</span
            >
          </div>
        </div>
      </div>

      <div
        v-if="availableRefund"
        class="flex flex-row justify-end items-center gap-10 pt-4 pr-[10px]"
      >
        <h4>
          {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.TOTAL_REFUNDABLE') }}
        </h4>
        <span class="text-base"
          >{{ availableRefund[1] }}
          {{ /* refundableAmount */ availableRefund[0] }}</span
        >
      </div>

      <div class="flex flex-row justify-start items-start gap-4 mt-4">
        <div class="flex flex-col">
          <div class="flex flex-row gap-2 pb-2">
            <h5>
              {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.REFUND_AMOUNT') }}
            </h5>
            <span v-if="formState.refundAmount !== availableRefund"
              >(manual)</span
            >
          </div>

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

          <p
            v-if="v$.refundAmount.$error"
            class="mb-0 text-xs truncate transition-all duration-500 ease-in-out"
            :style="{
              color: '#ef4444',
            }"
          >
            {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.INVALID_AMOUNT') }}
          </p>
        </div>

        <div class="flex flex-col">
          <h5 class="pb-1">
            {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.REFUND_REASON') }}
            <!-- {{ add marker for manual }}  -->
          </h5>

          <select
            v-model="formState.refundNote"
            class="w-full mt-1 border-0 selectInbox"
            :class="{ 'border-red-500': v$.refundNote.$error }"
          >
            <option v-for="reason in reasons" :value="reason">
              {{ reason }}
            </option>
          </select>

          <span v-if="v$.refundNote.$error" class="text-xs text-red-500 pl-2">
            {{ $t('CONVERSATION_SIDEBAR.SHOPIFY.REFUND.NOTE_REQUIRED') }}
          </span>
        </div>
      </div>

      <div class="flex flex-col items-start justify-center content-start gap-2">
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

      <div class="flex flex-row justify-end mt-4">
        <Button
          type="button"
          :disabled="v$.$error || cancellationState === 'processing'"
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

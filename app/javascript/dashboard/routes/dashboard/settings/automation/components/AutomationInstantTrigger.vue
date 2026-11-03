<script setup>
import { computed, nextTick, useTemplateRef } from 'vue';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';
import FilterDescribeStatus from 'dashboard/components-next/filter/FilterDescribeStatus.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useFilterRecommendations } from 'dashboard/components-next/filter/useFilterRecommendations';
import { toAutomationCondition } from 'dashboard/helper/automationHelper';

const props = defineProps({
  events: {
    type: Array,
    required: true,
  },
  filterTypes: {
    type: Array,
    required: true,
  },
  errors: {
    type: Object,
    default: () => ({}),
  },
  showResetMessage: {
    type: Boolean,
    default: false,
  },
  appendNewCondition: {
    type: Function,
    required: true,
  },
  removeFilter: {
    type: Function,
    required: true,
  },
  onEventChange: {
    type: Function,
    required: true,
  },
  // [{ key, label }] conditions recommended from the rule's name and description.
  recommendations: {
    type: Array,
    default: () => [],
  },
  // Applies a recommendation to a row and returns whether more remain.
  applyRecommendation: {
    type: Function,
    default: () => false,
  },
  // Whether Captain set the current event from the rule's name and description.
  eventSetByCaptain: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['undoEvent']);
const eventName = defineModel('eventName', { type: String, required: true });
const conditions = defineModel('conditions', { type: Array, required: true });

const { canDescribeFilters, describeStatus, describeFilters } =
  useFilterRecommendations(
    'automation',
    computed(() => props.filterTypes),
    conditions,
    { toRow: toAutomationCondition }
  );

const eventLabel = computed(
  () => props.events.find(event => event.key === eventName.value)?.value
);

const conditionsRef = useTemplateRef('conditionsRef');

// Replaces the row with the recommendation. While more remain, a new row opens its picker on them.
const onRecommend = async (rowIndex, key) => {
  if (!props.applyRecommendation(rowIndex, key)) return;
  props.appendNewCondition();
  await nextTick();
  conditionsRef.value?.at(-1)?.openAttributePicker();
};

const hasConditionErrors = computed(() =>
  Object.keys(props.errors).some(key => key.startsWith('condition_'))
);

// Set the event and reset its conditions in one listener. With v-model plus @change the browser
// renders between the two, showing the new event with the old event's conditions.
const selectedEvent = computed({
  get: () => eventName.value,
  set: value => {
    eventName.value = value;
    props.onEventChange();
  },
});

const validate = () => {
  if (!conditionsRef.value) return true;
  return conditionsRef.value.every(condition => condition.validate());
};

const resetValidation = () => {
  conditionsRef.value?.forEach(condition => condition.resetValidation());
};

defineExpose({ validate, resetValidation });
</script>

<template>
  <div class="flex flex-col gap-5">
    <div>
      <label :class="{ error: errors.event_name }">
        {{ $t('AUTOMATION.ADD.FORM.EVENT.LABEL') }}
        <select v-model="selectedEvent" class="m-0">
          <option v-for="event in events" :key="event.key" :value="event.key">
            {{ event.value }}
          </option>
        </select>
        <span v-if="errors.event_name" class="message">
          {{ $t('AUTOMATION.ADD.FORM.EVENT.ERROR') }}
        </span>
      </label>
      <p
        v-if="eventSetByCaptain"
        class="flex flex-wrap items-center gap-1 pt-1.5 mb-0 text-xs text-n-slate-11"
      >
        <Icon icon="i-ph-sparkle-fill" class="size-3 text-n-iris-9" />
        {{ $t('AUTOMATION.FORM.EVENT_SET_BY_CAPTAIN', { event: eventLabel }) }}
        <NextButton
          link
          blue
          xs
          :label="$t('AUTOMATION.FORM.UNDO_EVENT')"
          @click="emit('undoEvent')"
        />
      </p>
      <p v-if="showResetMessage" class="pt-1 text-xs text-right text-n-teal-10">
        {{ $t('AUTOMATION.FORM.RESET_MESSAGE') }}
      </p>
    </div>
    <slot />
    <section>
      <label>
        {{ $t('AUTOMATION.ADD.FORM.CONDITIONS.LABEL') }}
      </label>
      <ul
        class="grid gap-4 p-3 list-none outline outline-1 rounded-xl -outline-offset-1"
        :class="
          hasConditionErrors
            ? 'outline-n-ruby-5 bg-n-ruby-2/50'
            : 'outline-n-weak dark:outline-n-strong'
        "
      >
        <template v-for="(condition, i) in conditions" :key="i">
          <ConditionRow
            v-if="i === 0"
            ref="conditionsRef"
            v-model:attribute-key="conditions[i].attribute_key"
            v-model:filter-operator="conditions[i].filter_operator"
            v-model:values="conditions[i].values"
            :filter-types="filterTypes"
            :show-query-operator="false"
            :describable="canDescribeFilters"
            :recommendations="recommendations"
            @describe="query => describeFilters(i, query)"
            @recommend="key => onRecommend(i, key)"
            @remove="removeFilter(i)"
          />
          <ConditionRow
            v-else
            ref="conditionsRef"
            v-model:attribute-key="conditions[i].attribute_key"
            v-model:filter-operator="conditions[i].filter_operator"
            v-model:query-operator="conditions[i - 1].query_operator"
            v-model:values="conditions[i].values"
            :filter-types="filterTypes"
            show-query-operator
            :describable="canDescribeFilters"
            :recommendations="recommendations"
            @describe="query => describeFilters(i, query)"
            @recommend="key => onRecommend(i, key)"
            @remove="removeFilter(i)"
          />
        </template>
        <div>
          <NextButton
            icon="i-lucide-plus"
            blue
            faded
            sm
            :label="$t('AUTOMATION.ADD.CONDITION_BUTTON_LABEL')"
            @click="appendNewCondition"
          />
        </div>
      </ul>
      <FilterDescribeStatus
        v-if="describeStatus"
        :status="describeStatus"
        class="mt-3"
      />
    </section>
  </div>
</template>

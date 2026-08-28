<script setup>
import { computed, useTemplateRef } from 'vue';
import ConditionRow from 'dashboard/components-next/filter/ConditionRow.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

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
});

const eventName = defineModel('eventName', { type: String, required: true });
const conditions = defineModel('conditions', { type: Array, required: true });

const conditionsRef = useTemplateRef('conditionsRef');

const hasConditionErrors = computed(() =>
  Object.keys(props.errors).some(key => key.startsWith('condition_'))
);

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
        <select v-model="eventName" class="m-0" @change="onEventChange()">
          <option v-for="event in events" :key="event.key" :value="event.key">
            {{ event.value }}
          </option>
        </select>
        <span v-if="errors.event_name" class="message">
          {{ $t('AUTOMATION.ADD.FORM.EVENT.ERROR') }}
        </span>
      </label>
      <p v-if="showResetMessage" class="pt-1 text-xs text-right text-n-teal-10">
        {{ $t('AUTOMATION.FORM.RESET_MESSAGE') }}
      </p>
    </div>
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
    </section>
  </div>
</template>

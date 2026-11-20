<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import AddDataDropdown from 'dashboard/components-next/AssignmentPolicy/components/AddDataDropdown.vue';
import LabelItem from 'dashboard/components-next/label/LabelItem.vue';
import DurationInput from 'dashboard/components-next/input/DurationInput.vue';
import { DURATION_UNITS } from 'dashboard/components-next/input/constants';

const props = defineProps({
  tagsList: {
    type: Array,
    default: () => [],
  },
});

const excludedLabels = defineModel('excludedLabels', {
  type: Array,
  default: () => [],
});

const excludeOlderThanHours = defineModel('excludeOlderThanHours', {
  type: Number,
  default: null,
});

// DurationInput works in minutes; the policy stores whole hours, so bridge the two
const excludeOlderThanMinutes = computed({
  get() {
    return excludeOlderThanHours.value == null
      ? null
      : excludeOlderThanHours.value * 60;
  },
  set(minutes) {
    excludeOlderThanHours.value =
      minutes == null ? null : Math.round(minutes / 60);
  },
});

// Duration limits: 1 hour to 999 days (in minutes)
const MIN_DURATION_MINUTES = 60;
const MAX_DURATION_MINUTES = 1438560; // 999 days * 24 hours * 60 minutes
const UNITS = [DURATION_UNITS.HOURS, DURATION_UNITS.DAYS];

const { t } = useI18n();

const detectUnit = hours => {
  if (hours && hours % 24 === 0) return DURATION_UNITS.DAYS;
  return DURATION_UNITS.HOURS;
};

const hoveredLabel = ref(null);
// Set at setup: a unit change after mount makes DurationInput clamp the saved value
const windowUnit = ref(detectUnit(excludeOlderThanHours.value));

const addedTags = computed(() =>
  props.tagsList
    .filter(label => excludedLabels.value.includes(label.name))
    .map(label => ({ id: label.id, title: label.name, ...label }))
);

const filteredTags = computed(() =>
  props.tagsList.filter(
    label => !addedTags.value.some(tag => tag.id === label.id)
  )
);

const onClickAddTag = tag => {
  excludedLabels.value = [...excludedLabels.value, tag.name];
};

const onClickRemoveTag = tag => {
  excludedLabels.value = excludedLabels.value.filter(
    name => name !== tag.title
  );
};
</script>

<template>
  <div class="py-4 flex-col flex gap-6">
    <div class="flex flex-col items-start gap-1 py-1">
      <label class="text-sm font-medium text-n-slate-12 py-1">
        {{
          t(
            'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.FORM.EXCLUSION_RULES.LABEL'
          )
        }}
      </label>
      <p class="mb-0 text-n-slate-11 text-sm">
        {{
          t(
            'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.FORM.EXCLUSION_RULES.DESCRIPTION'
          )
        }}
      </p>
    </div>

    <div class="flex flex-col items-start gap-4">
      <label class="text-sm font-medium text-n-slate-12 py-1">
        {{
          t(
            'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.FORM.EXCLUSION_RULES.TAGS.LABEL'
          )
        }}
      </label>
      <div
        class="flex items-start gap-2 flex-wrap"
        @mouseleave="hoveredLabel = null"
      >
        <LabelItem
          v-for="tag in addedTags"
          :key="tag.id"
          :label="tag"
          :is-hovered="hoveredLabel === tag.id"
          class="h-8"
          @remove="onClickRemoveTag"
          @hover="hoveredLabel = tag.id"
        />
        <AddDataDropdown
          :label="
            t(
              'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.FORM.EXCLUSION_RULES.TAGS.ADD_TAG'
            )
          "
          :search-placeholder="
            t(
              'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.FORM.EXCLUSION_RULES.TAGS.DROPDOWN.SEARCH_PLACEHOLDER'
            )
          "
          :items="filteredTags"
          class="[&>button]:!text-n-blue-11 [&>div]:min-w-64"
          @add="onClickAddTag"
        />
      </div>
    </div>

    <div class="flex flex-col items-start gap-4">
      <label class="text-sm font-medium text-n-slate-12 py-1">
        {{
          t(
            'ASSIGNMENT_POLICY.AGENT_CAPACITY_POLICY.FORM.EXCLUSION_RULES.DURATION.LABEL'
          )
        }}
      </label>
      <div
        class="flex items-center gap-2 flex-1 [&>select]:!bg-n-alpha-2 [&>select]:!outline-none [&>select]:hover:brightness-110"
      >
        <DurationInput
          v-model:unit="windowUnit"
          v-model:model-value="excludeOlderThanMinutes"
          :min="MIN_DURATION_MINUTES"
          :max="MAX_DURATION_MINUTES"
          :units="UNITS"
        />
      </div>
    </div>
  </div>
</template>

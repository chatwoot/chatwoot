<script setup>
import { computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import AddDataDropdown from 'dashboard/components-next/AssignmentPolicy/components/AddDataDropdown.vue';
import LabelItem from 'dashboard/components-next/Label/LabelItem.vue';
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
  default: 10,
});

const { t } = useI18n();

const hoveredLabel = ref(null);
const windowUnit = ref(DURATION_UNITS.MINUTES);

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

const detectUnit = minutes => {
  const m = Number(minutes) || 0;
  if (m === 0) return DURATION_UNITS.MINUTES;
  if (m % (24 * 60) === 0) return DURATION_UNITS.DAYS;
  if (m % 60 === 0) return DURATION_UNITS.HOURS;
  return DURATION_UNITS.MINUTES;
};

const onClickAddTag = tag => {
  excludedLabels.value = [...excludedLabels.value, tag.name];
};

const onClickRemoveTag = tagId => {
  const tag = props.tagsList?.find(label => label.id === tagId);
  if (tag) {
    excludedLabels.value = excludedLabels.value.filter(
      name => name !== tag.name
    );
  }
};

onMounted(() => {
  windowUnit.value = detectUnit(excludeOlderThanHours.value);
});
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
          class="[&>button]:!text-n-blue-text"
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
        <!-- allow 10 mins to 999 days -->
        <DurationInput
          v-model:unit="windowUnit"
          v-model:model-value="excludeOlderThanHours"
          :min="10"
          :max="1438560"
        />
      </div>
    </div>
  </div>
</template>

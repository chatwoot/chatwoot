<script setup>
import { computed, watch, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import PipelineStagesAPI from 'dashboard/api/pipelineStages';

const props = defineProps({
  contactId: {
    type: [Number, String],
    required: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const store = useStore();

const contactStages = ref([]);
const labelStagesMap = ref({});
const isFetching = ref(false);

const labels = computed(() => store.getters['labels/getLabels']);

const stagesGroupedByLabel = computed(() => {
  return contactStages.value.map(cs => {
    const label = labels.value.find(l => l.id === cs.label_id);
    return {
      labelTitle: cs.label_title,
      labelColor: label?.color || '#1f93ff',
      stages: labelStagesMap.value[cs.label_id] || [],
      currentAssignment: cs,
    };
  });
});

const hasStages = computed(() => contactStages.value.length > 0);

const fetchContactStages = async () => {
  if (!props.contactId) return;
  isFetching.value = true;
  try {
    const response = await PipelineStagesAPI.getContactStages(props.contactId);
    contactStages.value = response.data.payload || [];

    // Fetch stages for each label to populate dropdown options
    const labelIds = [...new Set(contactStages.value.map(cs => cs.label_id))];
    const stagesMap = {};
    await Promise.all(
      labelIds.map(async labelId => {
        try {
          const stagesResponse = await PipelineStagesAPI.getStages(labelId);
          stagesMap[labelId] = stagesResponse.data.payload || [];
        } catch {
          stagesMap[labelId] = [];
        }
      })
    );
    labelStagesMap.value = stagesMap;
  } catch {
    contactStages.value = [];
  } finally {
    isFetching.value = false;
  }
};

const changeStage = async (assignment, newStageId) => {
  if (Number(newStageId) === assignment.pipeline_stage_id) return;
  try {
    const response = await PipelineStagesAPI.updateContactStage(
      props.contactId,
      assignment.id,
      Number(newStageId)
    );
    contactStages.value = response.data.payload || [];
    useAlert(t('PIPELINE.API.UPDATE_SUCCESS'));
  } catch {
    useAlert(t('PIPELINE.API.ERROR'));
  }
};

onMounted(fetchContactStages);
watch(() => props.contactId, fetchContactStages);
</script>

<template>
  <!-- Compact mode: inline tags matching label pill style -->
  <div
    v-if="compact && hasStages"
    class="flex flex-wrap items-center gap-2 px-4 pb-3"
  >
    <div
      v-for="group in stagesGroupedByLabel"
      :key="group.labelTitle"
      class="inline-flex items-center gap-1 rounded-md bg-n-alpha-2 px-2 py-0.5 text-xs"
    >
      <span
        class="size-2 rounded-full shrink-0"
        :style="{ backgroundColor: group.labelColor }"
      />
      <select
        :value="group.currentAssignment.pipeline_stage_id"
        class="bg-transparent text-xs text-n-slate-12 focus:outline-none cursor-pointer appearance-none pr-0"
        @change="e => changeStage(group.currentAssignment, e.target.value)"
      >
        <option v-for="stage in group.stages" :key="stage.id" :value="stage.id">
          {{ stage.title }}
        </option>
      </select>
      <span class="i-lucide-chevron-down size-3 text-n-slate-10 -ml-0.5" />
    </div>
  </div>

  <!-- Full mode: rows with label + select -->
  <div v-else-if="hasStages" class="flex flex-col gap-3 p-3">
    <div
      v-for="group in stagesGroupedByLabel"
      :key="group.labelTitle"
      class="flex items-center gap-3"
    >
      <span
        class="inline-flex items-center gap-1.5 text-xs font-medium text-n-slate-11 min-w-[80px]"
      >
        <span
          class="size-2 rounded-full shrink-0"
          :style="{ backgroundColor: group.labelColor }"
        />
        {{ group.labelTitle }}
      </span>
      <select
        :value="group.currentAssignment.pipeline_stage_id"
        class="flex-1 px-2 py-1.5 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
        @change="e => changeStage(group.currentAssignment, e.target.value)"
      >
        <option v-for="stage in group.stages" :key="stage.id" :value="stage.id">
          {{ stage.title }}
        </option>
      </select>
    </div>
  </div>
  <p v-else-if="!compact && !isFetching" class="p-3 text-sm text-n-slate-10">
    {{ $t('PIPELINE.NO_PIPELINES') }}
  </p>
</template>

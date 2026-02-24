<script setup>
import { computed, ref, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Draggable from 'vuedraggable';
import PipelineContactCard from './PipelineContactCard.vue';
import PipelineStagesAPI from 'dashboard/api/pipelineStages';

const props = defineProps({
  stages: {
    type: Array,
    required: true,
  },
  contacts: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['showContact']);

const { t } = useI18n();
const store = useStore();

// Map contactId -> pipeline stage assignments for the current label
const contactStageMap = ref({});

const stageIdSet = computed(() => new Set(props.stages.map(s => s.id)));

const fetchContactStages = async () => {
  const map = {};
  await Promise.all(
    props.contacts.map(async contact => {
      try {
        const response = await PipelineStagesAPI.getContactStages(contact.id);
        const assignments = response.data.payload || [];
        const relevant = assignments.find(a =>
          stageIdSet.value.has(a.pipeline_stage_id)
        );
        if (relevant) {
          map[contact.id] = relevant;
        }
      } catch {
        // skip
      }
    })
  );
  contactStageMap.value = map;
};

onMounted(fetchContactStages);
watch(() => [props.contacts, props.stages], fetchContactStages, {
  deep: true,
});

const columnContacts = computed(() => {
  const result = {};
  props.stages.forEach(stage => {
    result[stage.id] = [];
  });
  props.contacts.forEach(contact => {
    const assignment = contactStageMap.value[contact.id];
    if (assignment && result[assignment.pipeline_stage_id]) {
      result[assignment.pipeline_stage_id].push({
        ...contact,
        assignmentId: assignment.id,
      });
    }
  });
  return result;
});

const getStageContacts = stageId => {
  return columnContacts.value[stageId] || [];
};

const onDragChange = async (stageId, event) => {
  if (!event.added) return;

  const contact = event.added.element;
  try {
    await store.dispatch('pipelineStages/updateContactStage', {
      contactId: contact.id,
      assignmentId: contact.assignmentId,
      pipelineStageId: stageId,
    });
    // Update local map
    contactStageMap.value = {
      ...contactStageMap.value,
      [contact.id]: {
        ...contactStageMap.value[contact.id],
        pipeline_stage_id: stageId,
      },
    };
    useAlert(t('PIPELINE.KANBAN.MOVE_SUCCESS'));
  } catch {
    useAlert(t('PIPELINE.KANBAN.MOVE_ERROR'));
  }
};

const showContact = contactId => {
  emit('showContact', contactId);
};
</script>

<template>
  <div class="flex flex-col p-4">
    <div v-if="$slots['header-actions']" class="flex justify-end mb-3">
      <slot name="header-actions" />
    </div>
    <div class="flex gap-4 overflow-x-auto items-start flex-1">
      <div
        v-for="stage in stages"
        :key="stage.id"
        class="flex flex-col min-w-[280px] max-w-[320px] flex-1"
      >
        <div
          class="flex items-center justify-between px-3 py-2 mb-3 rounded-lg bg-n-solid-3"
        >
          <span class="text-sm font-medium text-n-slate-12">
            {{ stage.title }}
          </span>
          <span class="text-xs text-n-slate-10">
            {{ getStageContacts(stage.id).length }}
          </span>
        </div>
        <Draggable
          :list="getStageContacts(stage.id)"
          group="pipeline"
          item-key="id"
          class="flex flex-col flex-1 gap-2 p-1 min-h-[100px]"
          ghost-class="opacity-50"
          @change="event => onDragChange(stage.id, event)"
        >
          <template #item="{ element }">
            <PipelineContactCard :contact="element" @show="showContact" />
          </template>
        </Draggable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useFunctionGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Draggable from 'vuedraggable';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  labelId: {
    type: Number,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const labelIdRef = computed(() => props.labelId);
const stagesGetter = useFunctionGetter('pipelineStages/getStages', labelIdRef);
const stages = computed(() => stagesGetter.value || []);
const uiFlags = computed(() => store.getters['pipelineStages/getUIFlags']);

const newStageTitle = ref('');
const editingStageId = ref(null);
const editingTitle = ref('');

const fetchStages = () => {
  if (props.labelId) {
    store.dispatch('pipelineStages/fetchStages', props.labelId);
  }
};

onMounted(fetchStages);
watch(() => props.labelId, fetchStages);

const addStage = async () => {
  const title = newStageTitle.value.trim();
  if (!title) return;
  try {
    await store.dispatch('pipelineStages/createStage', {
      labelId: props.labelId,
      title,
      position: stages.value.length,
    });
    newStageTitle.value = '';
    useAlert(t('PIPELINE.API.CREATE_SUCCESS'));
  } catch {
    useAlert(t('PIPELINE.API.ERROR'));
  }
};

const startEditing = stage => {
  editingStageId.value = stage.id;
  editingTitle.value = stage.title;
};

const saveEdit = async stage => {
  const title = editingTitle.value.trim();
  if (!title || title === stage.title) {
    editingStageId.value = null;
    return;
  }
  try {
    await store.dispatch('pipelineStages/updateStage', {
      labelId: props.labelId,
      stageId: stage.id,
      title,
    });
    editingStageId.value = null;
    useAlert(t('PIPELINE.API.UPDATE_SUCCESS'));
  } catch {
    useAlert(t('PIPELINE.API.ERROR'));
  }
};

const cancelEdit = () => {
  editingStageId.value = null;
};

const deleteStage = async stage => {
  try {
    await store.dispatch('pipelineStages/deleteStage', {
      labelId: props.labelId,
      stageId: stage.id,
    });
    useAlert(t('PIPELINE.API.DELETE_SUCCESS'));
  } catch {
    useAlert(t('PIPELINE.API.ERROR'));
  }
};

const onDragEnd = async () => {
  const positions = stages.value.map((stage, index) => ({
    id: stage.id,
    position: index,
  }));
  try {
    await store.dispatch('pipelineStages/reorderStages', {
      labelId: props.labelId,
      positions,
    });
    useAlert(t('PIPELINE.API.REORDER_SUCCESS'));
  } catch {
    useAlert(t('PIPELINE.API.ERROR'));
  }
};
</script>

<template>
  <div class="flex flex-col gap-3 mt-4">
    <label class="text-sm font-medium text-n-slate-12">
      {{ t('PIPELINE.EDITOR.TITLE') }}
    </label>
    <p class="text-xs text-n-slate-10">
      {{ t('PIPELINE.EDITOR.DESCRIPTION') }}
    </p>

    <div v-if="stages.length" class="flex flex-col gap-1">
      <Draggable
        :list="[...stages]"
        item-key="id"
        handle=".drag-handle"
        animation="200"
        @end="onDragEnd"
      >
        <template #item="{ element }">
          <div
            class="flex items-center gap-2 px-3 py-2 rounded-lg group bg-n-solid-2 border border-n-weak"
          >
            <span
              class="i-lucide-grip-vertical size-4 text-n-slate-8 cursor-grab drag-handle"
            />
            <template v-if="editingStageId === element.id">
              <input
                v-model="editingTitle"
                class="flex-1 px-2 py-1 text-sm border rounded border-n-weak bg-n-solid-1 text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
                @keydown.enter="saveEdit(element)"
                @keydown.escape="cancelEdit"
              />
              <NextButton
                icon="i-lucide-check"
                variant="ghost"
                size="xs"
                color="slate"
                @click="saveEdit(element)"
              />
              <NextButton
                icon="i-lucide-x"
                variant="ghost"
                size="xs"
                color="slate"
                @click="cancelEdit"
              />
            </template>
            <template v-else>
              <span class="flex-1 text-sm text-n-slate-12">
                {{ element.title }}
              </span>
              <NextButton
                icon="i-lucide-pencil"
                variant="ghost"
                size="xs"
                color="slate"
                class="opacity-0 group-hover:opacity-100"
                @click="startEditing(element)"
              />
              <NextButton
                icon="i-lucide-trash-2"
                variant="ghost"
                size="xs"
                color="slate"
                class="opacity-0 group-hover:opacity-100"
                @click="deleteStage(element)"
              />
            </template>
          </div>
        </template>
      </Draggable>
    </div>
    <p v-else class="text-xs text-n-slate-10">
      {{ t('PIPELINE.EDITOR.EMPTY') }}
    </p>

    <div class="flex items-center gap-2">
      <input
        v-model="newStageTitle"
        :placeholder="t('PIPELINE.STAGE_PLACEHOLDER')"
        class="flex-1 px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-solid-2 text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
        @keydown.enter="addStage"
      />
      <NextButton
        :label="t('PIPELINE.ADD_STAGE')"
        size="sm"
        :disabled="!newStageTitle.trim() || uiFlags.isUpdating"
        :is-loading="uiFlags.isUpdating"
        @click="addStage"
      />
    </div>
  </div>
</template>

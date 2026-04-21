<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import axios from 'axios';
import draggable from 'vuedraggable';
import Card from 'primevue/card';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import Dialog from 'primevue/dialog';
import Select from 'primevue/select';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const stages = ref([]);
const leads = ref([]);
const loading = ref(true);
const editingStageId = ref(null);
const editingStageName = ref('');
const showNewStageDialog = ref(false);
const newStageName = ref('');
const newStageColor = ref('#2196F3');
const newStageType = ref('custom');

const stageTypeOptions = [
  { label: t('SYNAPSEOS.PIPELINE.STAGE_TYPES.INBOUND'), value: 'inbound' },
  { label: t('SYNAPSEOS.PIPELINE.STAGE_TYPES.WORKING'), value: 'working' },
  { label: t('SYNAPSEOS.PIPELINE.STAGE_TYPES.WON'), value: 'won' },
  { label: t('SYNAPSEOS.PIPELINE.STAGE_TYPES.LOST'), value: 'lost' },
  { label: t('SYNAPSEOS.PIPELINE.STAGE_TYPES.CUSTOM'), value: 'custom' },
];

const accountId = computed(() => route.params.accountId);
const apiBase = computed(() => `/api/v1/accounts/${accountId.value}/synapseos`);

const columns = computed(() =>
  stages.value.map(stage => ({
    stage,
    leads: leads.value.filter(l => l.pipeline_stage_id === stage.id),
  })),
);

const unassignedColumn = computed(() => ({
  stage: { id: null, name: t('SYNAPSEOS.PIPELINE.UNASSIGNED'), color: '#94a3b8', stage_type: 'custom' },
  leads: leads.value.filter(l => !l.pipeline_stage_id),
}));

const totalValueForStage = stageId => {
  const stageLeads = leads.value.filter(l => l.pipeline_stage_id === stageId);
  const total = stageLeads.reduce((sum, l) => sum + (l.deal?.amount || 0), 0);
  if (!total) return '';
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
    maximumFractionDigits: 0,
  }).format(total);
};

const fetchPipeline = async () => {
  loading.value = true;
  try {
    const { data } = await axios.get(`${apiBase.value}/pipeline`);
    stages.value = data.stages;
    leads.value = data.leads;
  } finally {
    loading.value = false;
  }
};

const onDragChange = async (event, targetStageId) => {
  const added = event.added;
  if (!added) return;
  const lead = added.element;
  if (lead.pipeline_stage_id === targetStageId) return;
  lead.pipeline_stage_id = targetStageId;
  try {
    await axios.patch(`${apiBase.value}/leads/${lead.id}`, {
      lead: { pipeline_stage_id: targetStageId },
    });
  } catch (e) {
    // rollback on failure
    fetchPipeline();
  }
};

const startEditStage = stage => {
  editingStageId.value = stage.id;
  editingStageName.value = stage.name;
};

const commitEditStage = async stage => {
  if (!editingStageName.value.trim() || editingStageName.value === stage.name) {
    editingStageId.value = null;
    return;
  }
  const trimmed = editingStageName.value.trim();
  try {
    const { data } = await axios.patch(`${apiBase.value}/pipeline_stages/${stage.id}`, {
      pipeline_stage: { name: trimmed },
    });
    Object.assign(stage, data);
  } finally {
    editingStageId.value = null;
  }
};

const openNewStage = () => {
  newStageName.value = '';
  newStageColor.value = '#2196F3';
  newStageType.value = 'custom';
  showNewStageDialog.value = true;
};

const submitNewStage = async () => {
  if (!newStageName.value.trim()) return;
  const { data } = await axios.post(`${apiBase.value}/pipeline_stages`, {
    pipeline_stage: {
      name: newStageName.value.trim(),
      color: newStageColor.value,
      stage_type: newStageType.value,
    },
  });
  stages.value.push(data);
  showNewStageDialog.value = false;
};

const deleteStage = async stage => {
  if (!confirm(t('SYNAPSEOS.PIPELINE.CONFIRM_DELETE', { name: stage.name }))) return;
  await axios.delete(`${apiBase.value}/pipeline_stages/${stage.id}`);
  stages.value = stages.value.filter(s => s.id !== stage.id);
  leads.value.forEach(l => {
    if (l.pipeline_stage_id === stage.id) l.pipeline_stage_id = null;
  });
};

const openConversation = lead => {
  if (!lead.conversation_id) return;
  router.push({
    name: 'inbox_conversation',
    params: { accountId: accountId.value, conversation_id: lead.conversation_id },
  });
};

const formatAmount = amount => {
  if (!amount) return '';
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
    maximumFractionDigits: 0,
  }).format(amount);
};

onMounted(fetchPipeline);
</script>

<template>
  <div class="flex flex-col h-full overflow-hidden p-6 gap-4">
    <header class="flex items-end justify-between flex-wrap gap-4">
      <div>
        <h1 class="text-2xl font-semibold text-n-slate-12">
          {{ t('SYNAPSEOS.PIPELINE.TITLE') }}
        </h1>
        <p class="text-sm text-n-slate-11">
          {{ t('SYNAPSEOS.PIPELINE.SUBTITLE') }}
        </p>
      </div>
      <div class="flex gap-2">
        <Button
          icon="pi pi-plus"
          :label="t('SYNAPSEOS.PIPELINE.ADD_STAGE')"
          severity="secondary"
          outlined
          @click="openNewStage"
        />
        <Button
          icon="pi pi-refresh"
          severity="secondary"
          text
          @click="fetchPipeline"
        />
      </div>
    </header>

    <div v-if="loading" class="text-sm text-n-slate-10">
      {{ t('SYNAPSEOS.PIPELINE.LOADING') }}
    </div>

    <div v-else class="flex gap-4 overflow-x-auto flex-1 pb-4">
      <div
        v-if="unassignedColumn.leads.length"
        class="flex flex-col w-80 shrink-0 bg-n-slate-2 rounded-lg border border-n-weak"
      >
        <div class="px-3 py-2 flex items-center gap-2 border-b border-n-weak">
          <span class="inline-block size-2 rounded-full" :style="{ backgroundColor: unassignedColumn.stage.color }" />
          <span class="text-sm font-medium text-n-slate-12">{{ unassignedColumn.stage.name }}</span>
          <span class="text-xs text-n-slate-10 ml-auto">{{ unassignedColumn.leads.length }}</span>
        </div>
        <draggable
          :model-value="unassignedColumn.leads"
          group="leads"
          item-key="id"
          class="flex flex-col gap-2 p-2 overflow-y-auto"
          @change="e => onDragChange(e, null)"
        >
          <template #item="{ element }">
            <div
              class="bg-n-background border border-n-weak rounded-md p-3 cursor-grab hover:border-n-strong transition-colors"
              @click="openConversation(element)"
            >
              <div class="font-medium text-sm text-n-slate-12 truncate">{{ element.contact.name }}</div>
              <div class="text-xs text-n-slate-10 truncate mt-0.5">
                {{ element.contact.phone_number || element.contact.email || '—' }}
              </div>
              <div v-if="element.deal?.amount" class="text-xs text-n-teal-9 mt-1">
                {{ formatAmount(element.deal.amount) }}
              </div>
            </div>
          </template>
        </draggable>
      </div>

      <div
        v-for="column in columns"
        :key="column.stage.id"
        class="flex flex-col w-80 shrink-0 bg-n-slate-2 rounded-lg border border-n-weak"
      >
        <div class="px-3 py-2 flex items-center gap-2 border-b border-n-weak group">
          <span
            class="inline-block size-2 rounded-full shrink-0"
            :style="{ backgroundColor: column.stage.color }"
          />
          <InputText
            v-if="editingStageId === column.stage.id"
            v-model="editingStageName"
            size="small"
            class="!text-sm flex-1"
            autofocus
            @blur="commitEditStage(column.stage)"
            @keydown.enter="commitEditStage(column.stage)"
            @keydown.escape="editingStageId = null"
          />
          <span
            v-else
            class="text-sm font-medium text-n-slate-12 flex-1 cursor-text"
            @click="startEditStage(column.stage)"
          >
            {{ column.stage.name }}
          </span>
          <span class="text-xs text-n-slate-10">{{ column.leads.length }}</span>
          <Button
            icon="pi pi-trash"
            text
            severity="danger"
            size="small"
            class="opacity-0 group-hover:opacity-100 transition-opacity"
            @click="deleteStage(column.stage)"
          />
        </div>

        <div v-if="totalValueForStage(column.stage.id)" class="px-3 py-1 text-xs text-n-teal-9 border-b border-n-weak">
          Σ {{ totalValueForStage(column.stage.id) }}
        </div>

        <draggable
          :model-value="column.leads"
          group="leads"
          item-key="id"
          class="flex flex-col gap-2 p-2 overflow-y-auto flex-1 min-h-24"
          @change="e => onDragChange(e, column.stage.id)"
        >
          <template #item="{ element }">
            <div
              class="bg-n-background border border-n-weak rounded-md p-3 cursor-grab hover:border-n-strong transition-colors"
              @click="openConversation(element)"
            >
              <div class="flex items-start justify-between gap-2">
                <div class="font-medium text-sm text-n-slate-12 truncate flex-1">{{ element.contact.name }}</div>
                <span
                  v-if="element.source"
                  class="text-[10px] px-1.5 py-0.5 rounded bg-n-alpha-2 text-n-slate-11 uppercase tracking-wide shrink-0"
                >
                  {{ element.source }}
                </span>
              </div>
              <div class="text-xs text-n-slate-10 truncate mt-0.5">
                {{ element.contact.phone_number || element.contact.email || '—' }}
              </div>
              <div v-if="element.deal?.amount" class="text-sm font-semibold text-n-teal-9 mt-1">
                {{ formatAmount(element.deal.amount) }}
              </div>
              <div v-if="element.conversation_id" class="text-[10px] text-n-slate-10 mt-1">
                conv #{{ element.conversation_id }}
              </div>
            </div>
          </template>
        </draggable>
      </div>

      <div class="w-80 shrink-0 flex items-start">
        <button
          class="w-full p-3 border border-dashed border-n-weak rounded-lg text-sm text-n-slate-10 hover:border-n-strong hover:text-n-slate-12 transition-colors"
          @click="openNewStage"
        >
          + {{ t('SYNAPSEOS.PIPELINE.ADD_STAGE') }}
        </button>
      </div>
    </div>

    <Dialog
      v-model:visible="showNewStageDialog"
      :header="t('SYNAPSEOS.PIPELINE.NEW_STAGE_HEADER')"
      modal
      :style="{ width: '420px' }"
    >
      <div class="flex flex-col gap-3">
        <label class="text-sm text-n-slate-12">
          {{ t('SYNAPSEOS.PIPELINE.STAGE_NAME') }}
          <InputText v-model="newStageName" class="w-full mt-1" />
        </label>
        <label class="text-sm text-n-slate-12">
          {{ t('SYNAPSEOS.PIPELINE.STAGE_COLOR') }}
          <input
            v-model="newStageColor"
            type="color"
            class="w-full h-9 mt-1 rounded cursor-pointer"
          >
        </label>
        <label class="text-sm text-n-slate-12">
          {{ t('SYNAPSEOS.PIPELINE.STAGE_TYPE') }}
          <Select
            v-model="newStageType"
            :options="stageTypeOptions"
            option-label="label"
            option-value="value"
            class="w-full mt-1"
          />
        </label>
        <span class="text-xs text-n-slate-10">
          {{ t('SYNAPSEOS.PIPELINE.STAGE_TYPE_HINT') }}
        </span>
      </div>
      <template #footer>
        <Button
          severity="secondary"
          text
          :label="t('SYNAPSEOS.PIPELINE.CANCEL')"
          @click="showNewStageDialog = false"
        />
        <Button
          severity="primary"
          :label="t('SYNAPSEOS.PIPELINE.CREATE')"
          :disabled="!newStageName.trim()"
          @click="submitNewStage"
        />
      </template>
    </Dialog>
  </div>
</template>

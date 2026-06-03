<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
/* global axios */
import draggable from 'vuedraggable';
import InputText from 'primevue/inputtext';
import Select from 'primevue/select';
import SynapseButton from 'next/synapseos/SynapseButton.vue';
import SynapseBadge from 'next/synapseos/SynapseBadge.vue';
import SynapseDialog from 'next/synapseos/SynapseDialog.vue';

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

const showTemplateDialog = ref(false);
const templates = ref([]);
const templatesError = ref(null);
const templatesEmpty = ref(false);
const loadingTemplates = ref(false);
const applyingTemplate = ref(false);

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
  }))
);

const unassignedColumn = computed(() => ({
  stage: {
    id: null,
    name: t('SYNAPSEOS.PIPELINE.UNASSIGNED'),
    color: '#94a3b8',
    stage_type: 'custom',
  },
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
    const { data } = await axios.patch(
      `${apiBase.value}/pipeline_stages/${stage.id}`,
      {
        pipeline_stage: { name: trimmed },
      }
    );
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
  if (
    !window.confirm(
      t('SYNAPSEOS.PIPELINE.CONFIRM_DELETE', { name: stage.name })
    )
  )
    return;
  await axios.delete(`${apiBase.value}/pipeline_stages/${stage.id}`);
  stages.value = stages.value.filter(s => s.id !== stage.id);
  leads.value.forEach(l => {
    if (l.pipeline_stage_id === stage.id) l.pipeline_stage_id = null;
  });
};

const openConversation = lead => {
  // rota do Chatwoot usa display_id; conversation_id é o id interno e abriria
  // a conversa errada (bug display×interno).
  const convDisplayId = lead.conversation_display_id || lead.conversation_id;
  if (!convDisplayId) return;
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: accountId.value,
      conversation_id: convDisplayId,
    },
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

const openTemplates = async () => {
  showTemplateDialog.value = true;
  loadingTemplates.value = true;
  templatesError.value = null;
  templatesEmpty.value = false;
  try {
    const { data } = await axios.get(
      `${apiBase.value}/pipeline_stages/templates`
    );
    templates.value = Array.isArray(data) ? data : [];
    templatesEmpty.value = templates.value.length === 0;
  } catch (e) {
    templates.value = [];
    templatesError.value =
      e?.response?.data?.error ||
      e?.message ||
      t('SYNAPSEOS.PIPELINE.TEMPLATE_FETCH_ERROR');
  } finally {
    loadingTemplates.value = false;
  }
};

const applyTemplate = async key => {
  if (!window.confirm(t('SYNAPSEOS.PIPELINE.TEMPLATE_CONFIRM'))) return;
  applyingTemplate.value = true;
  try {
    const { data } = await axios.post(
      `${apiBase.value}/pipeline_stages/apply_template`,
      {
        template_key: key,
      }
    );
    stages.value = data;
    showTemplateDialog.value = false;
    await fetchPipeline();
  } finally {
    applyingTemplate.value = false;
  }
};

onMounted(fetchPipeline);
</script>

<template>
  <div
    class="bg-s-bg p-4 sm:p-6 md:p-8 h-full w-full flex-1 min-w-0 flex flex-col gap-4 overflow-hidden"
  >
    <header
      class="flex items-start md:items-end justify-between flex-wrap gap-3 md:gap-4"
    >
      <div class="flex flex-col gap-1 min-w-0">
        <h1 class="text-xl md:text-2xl font-semibold text-s-primary">
          {{ t('SYNAPSEOS.PIPELINE.TITLE') }}
        </h1>
        <p class="text-sm text-s-muted hidden sm:block">
          {{ t('SYNAPSEOS.PIPELINE.SUBTITLE') }}
        </p>
      </div>
      <div class="flex gap-2 shrink-0">
        <SynapseButton
          variant="outline"
          icon="i-lucide-layout-template"
          @click="openTemplates"
        >
          <span class="hidden sm:inline">{{
            t('SYNAPSEOS.PIPELINE.TEMPLATES')
          }}</span>
        </SynapseButton>
        <SynapseButton
          variant="outline"
          icon="i-lucide-refresh-cw"
          @click="fetchPipeline"
        />
        <SynapseButton
          variant="primary"
          icon="i-lucide-plus"
          @click="openNewStage"
        >
          <span class="hidden sm:inline">{{
            t('SYNAPSEOS.PIPELINE.ADD_STAGE')
          }}</span>
        </SynapseButton>
      </div>
    </header>

    <div v-if="loading" class="text-sm text-s-muted">
      {{ t('SYNAPSEOS.PIPELINE.LOADING') }}
    </div>

    <div v-else class="flex gap-4 overflow-x-auto flex-1 pb-2">
      <div
        v-if="unassignedColumn.leads.length"
        class="bg-s-subtle rounded-2xl border border-s-border flex flex-col w-[17rem] sm:w-80 shrink-0 h-full"
      >
        <div
          class="px-4 py-3 border-b border-s-border-subtle flex items-center gap-2"
        >
          <span
            class="inline-block size-2 rounded-full shrink-0"
            :style="{ backgroundColor: unassignedColumn.stage.color }"
          />
          <span class="text-sm font-semibold text-s-primary flex-1 truncate">
            {{ unassignedColumn.stage.name }}
          </span>
          <SynapseBadge tone="neutral">
            {{ unassignedColumn.leads.length }}
          </SynapseBadge>
        </div>
        <draggable
          :model-value="unassignedColumn.leads"
          group="leads"
          item-key="id"
          class="flex flex-col gap-2 p-3 overflow-y-auto flex-1"
          @change="e => onDragChange(e, null)"
        >
          <template #item="{ element }">
            <div
              class="bg-s-surface border border-s-border rounded-lg p-3 cursor-grab hover:border-s-accent-500 hover:shadow-s-sm transition-all"
              @click="openConversation(element)"
            >
              <div class="text-sm font-medium text-s-primary truncate">
                {{ element.contact.name }}
              </div>
              <div class="text-xs text-s-muted truncate mt-0.5">
                {{
                  element.contact.phone_number || element.contact.email || '—'
                }}
              </div>
              <div
                v-if="element.deal?.amount"
                class="text-sm font-semibold text-s-success-text mt-1"
              >
                {{ formatAmount(element.deal.amount) }}
              </div>
            </div>
          </template>
        </draggable>
      </div>

      <div
        v-for="column in columns"
        :key="column.stage.id"
        class="bg-s-subtle rounded-2xl border border-s-border flex flex-col w-[17rem] sm:w-80 shrink-0 h-full"
      >
        <div
          class="px-4 py-3 border-b border-s-border-subtle flex items-center gap-2 group"
        >
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
            class="text-sm font-semibold text-s-primary flex-1 cursor-text truncate"
            @click="startEditStage(column.stage)"
          >
            {{ column.stage.name }}
          </span>
          <span
            v-if="column.stage.description"
            v-tooltip.top="column.stage.description"
            class="i-lucide-help-circle size-4 text-s-muted cursor-help shrink-0"
          />
          <SynapseBadge tone="neutral">{{ column.leads.length }}</SynapseBadge>
          <button
            class="opacity-0 group-hover:opacity-100 transition-opacity text-s-muted hover:text-s-error-text"
            @click="deleteStage(column.stage)"
          >
            <span class="i-lucide-trash-2 size-4" />
          </button>
        </div>

        <div
          v-if="totalValueForStage(column.stage.id)"
          class="px-4 py-1.5 text-xs font-medium text-s-success-text border-b border-s-border-subtle"
        >
          {{
            t('SYNAPSEOS.PIPELINE.STAGE_SUM', {
              value: totalValueForStage(column.stage.id),
            })
          }}
        </div>

        <draggable
          :model-value="column.leads"
          group="leads"
          item-key="id"
          class="flex flex-col gap-2 p-3 overflow-y-auto flex-1 min-h-24"
          @change="e => onDragChange(e, column.stage.id)"
        >
          <template #item="{ element }">
            <div
              class="bg-s-surface border border-s-border rounded-lg p-3 cursor-grab hover:border-s-accent-500 hover:shadow-s-sm transition-all"
              @click="openConversation(element)"
            >
              <div class="flex items-start justify-between gap-2">
                <span
                  class="text-sm font-medium text-s-primary truncate flex-1"
                >
                  {{ element.contact.name }}
                </span>
                <SynapseBadge v-if="element.source" tone="brand">
                  {{ element.source }}
                </SynapseBadge>
              </div>
              <div class="text-xs text-s-muted truncate mt-1">
                {{
                  element.contact.phone_number || element.contact.email || '—'
                }}
              </div>
              <div
                v-if="element.deal?.amount"
                class="text-sm font-semibold text-s-success-text mt-1"
              >
                {{ formatAmount(element.deal.amount) }}
              </div>
              <div
                v-if="element.conversation_display_id || element.conversation_id"
                class="text-[11px] text-s-muted mt-1"
              >
                {{
                  t('SYNAPSEOS.PIPELINE.CONV_ID', {
                    id: element.conversation_display_id || element.conversation_id,
                  })
                }}
              </div>
            </div>
          </template>
        </draggable>
      </div>

      <div class="w-80 shrink-0 flex items-start">
        <button
          class="w-full h-24 border-2 border-dashed border-s-border rounded-2xl flex items-center justify-center text-sm text-s-muted hover:border-s-brand hover:text-s-brand transition-colors"
          @click="openNewStage"
        >
          {{ t('SYNAPSEOS.PIPELINE.ADD_STAGE_PLUS') }}
        </button>
      </div>
    </div>

    <!-- New Stage Dialog -->
    <SynapseDialog
      v-model:visible="showNewStageDialog"
      :header="t('SYNAPSEOS.PIPELINE.NEW_STAGE_HEADER')"
      modal
      class="w-[420px]"
    >
      <div class="flex flex-col gap-3">
        <label class="text-sm text-s-primary">
          {{ t('SYNAPSEOS.PIPELINE.STAGE_NAME') }}
          <InputText v-model="newStageName" class="w-full mt-1" />
        </label>
        <label class="text-sm text-s-primary">
          {{ t('SYNAPSEOS.PIPELINE.STAGE_COLOR') }}
          <input
            v-model="newStageColor"
            type="color"
            class="w-full h-9 mt-1 rounded cursor-pointer"
          />
        </label>
        <label class="text-sm text-s-primary">
          {{ t('SYNAPSEOS.PIPELINE.STAGE_TYPE') }}
          <Select
            v-model="newStageType"
            :options="stageTypeOptions"
            option-label="label"
            option-value="value"
            class="w-full mt-1"
          />
        </label>
        <span class="text-xs text-s-muted">
          {{ t('SYNAPSEOS.PIPELINE.STAGE_TYPE_HINT') }}
        </span>
      </div>
      <template #footer>
        <div class="flex justify-end gap-2">
          <SynapseButton variant="ghost" @click="showNewStageDialog = false">
            {{ t('SYNAPSEOS.PIPELINE.CANCEL') }}
          </SynapseButton>
          <SynapseButton
            variant="primary"
            :disabled="!newStageName.trim()"
            @click="submitNewStage"
          >
            {{ t('SYNAPSEOS.PIPELINE.CREATE') }}
          </SynapseButton>
        </div>
      </template>
    </SynapseDialog>

    <!-- Template Picker Dialog -->
    <SynapseDialog
      v-model:visible="showTemplateDialog"
      :header="t('SYNAPSEOS.PIPELINE.TEMPLATE_HEADER')"
      modal
      class="w-[560px]"
    >
      <div
        v-if="loadingTemplates"
        class="text-sm text-s-muted py-4 text-center"
      >
        {{ t('SYNAPSEOS.PIPELINE.LOADING') }}
      </div>
      <div v-else class="flex flex-col gap-3">
        <p class="text-sm text-s-muted">
          {{ t('SYNAPSEOS.PIPELINE.TEMPLATE_DESCRIPTION') }}
        </p>
        <div
          v-if="templatesError"
          class="rounded-md border border-s-error/30 bg-s-error-soft text-s-error-text text-xs p-3"
        >
          {{ templatesError }}
        </div>
        <div
          v-else-if="templatesEmpty"
          class="text-sm text-s-muted text-center py-4"
        >
          {{ t('SYNAPSEOS.PIPELINE.TEMPLATE_EMPTY') }}
        </div>
        <div
          v-for="tmpl in templates"
          :key="tmpl.key"
          class="border border-s-border rounded-xl p-4 hover:border-s-brand transition-colors cursor-pointer"
          @click="applyTemplate(tmpl.key)"
        >
          <div class="flex items-center justify-between gap-2">
            <span class="text-sm font-semibold text-s-primary">{{
              tmpl.name
            }}</span>
            <SynapseBadge tone="neutral">
              {{
                t('SYNAPSEOS.PIPELINE.TEMPLATE_STAGES', {
                  count: tmpl.stage_count,
                })
              }}
            </SynapseBadge>
          </div>
          <p class="text-xs text-s-muted mt-1">{{ tmpl.description }}</p>
        </div>
      </div>
      <template #footer>
        <div class="flex justify-end">
          <SynapseButton variant="ghost" @click="showTemplateDialog = false">
            {{ t('SYNAPSEOS.PIPELINE.CANCEL') }}
          </SynapseButton>
        </div>
      </template>
    </SynapseDialog>
  </div>
</template>

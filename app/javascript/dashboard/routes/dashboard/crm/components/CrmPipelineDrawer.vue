<script setup>
import { computed, reactive, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import CrmStageAutomationsPanel from './CrmStageAutomationsPanel.vue';
import CrmAiSettingsPanel from './CrmAiSettingsPanel.vue';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { useCrmPermissions } from '../composables/useCrmPermissions';

const props = defineProps({
  show: { type: Boolean, default: false },
  mode: { type: String, default: 'create' },
  pipeline: { type: Object, default: null },
  stages: { type: Array, default: () => [] },
  inboxes: { type: Array, default: () => [] },
  pipelineInboxes: { type: Array, default: () => [] },
  isSaving: { type: Boolean, default: false },
  isArchiving: { type: Boolean, default: false },
  isDeletingStage: { type: Boolean, default: false },
  isLoadingPipelineInboxes: { type: Boolean, default: false },
  isSavingPipelineInbox: { type: Boolean, default: false },
  isRemovingPipelineInbox: { type: Boolean, default: false },
  agents: { type: Array, default: () => [] },
});

const emit = defineEmits([
  'close',
  'save',
  'archive',
  'deleteStage',
  'addPipelineInbox',
  'removePipelineInbox',
]);

const { t } = useI18n();
const store = useStore();
const { canManageAi } = useCrmPermissions();

const isCrmAiEnabled = computed(
  () =>
    store.getters['globalConfig/get']?.crmAiEnabled === true ||
    window.globalConfig?.CRM_AI_ENABLED === 'true'
);

const stageColors = [
  '#2563eb',
  '#0891b2',
  '#ca8a04',
  '#16a34a',
  '#dc2626',
  '#9333ea',
];
const defaultStages = () => [
  { name: t('CRM_KANBAN.PIPELINE_DRAWER.DEFAULT_STAGE_NEW'), color: '#2563eb' },
  {
    name: t('CRM_KANBAN.PIPELINE_DRAWER.DEFAULT_STAGE_WORKING'),
    color: '#0891b2',
  },
  {
    name: t('CRM_KANBAN.PIPELINE_DRAWER.DEFAULT_STAGE_PROPOSAL'),
    color: '#ca8a04',
  },
  {
    name: t('CRM_KANBAN.PIPELINE_DRAWER.DEFAULT_STAGE_CLOSING'),
    color: '#16a34a',
  },
  {
    name: t('CRM_KANBAN.PIPELINE_DRAWER.DEFAULT_STAGE_LOST'),
    color: '#dc2626',
  },
];

// Native Meta funnel classifications a stage can map to for CTWA conversion sync.
const funnelStageTypeOptions = computed(() => [
  { value: '', label: t('CRM_KANBAN.PIPELINE_DRAWER.META_STAGE_TYPE_NONE') },
  {
    value: 'lead',
    label: t('CRM_KANBAN.PIPELINE_DRAWER.META_STAGE_TYPE_LEAD'),
  },
  {
    value: 'qualified',
    label: t('CRM_KANBAN.PIPELINE_DRAWER.META_STAGE_TYPE_QUALIFIED'),
  },
  {
    value: 'opportunity',
    label: t('CRM_KANBAN.PIPELINE_DRAWER.META_STAGE_TYPE_OPPORTUNITY'),
  },
  {
    value: 'negotiation',
    label: t('CRM_KANBAN.PIPELINE_DRAWER.META_STAGE_TYPE_NEGOTIATION'),
  },
]);

const form = reactive({
  name: '',
  description: '',
  monthlyTarget: '',
  stages: [],
  metaSync: {
    enabled: false,
    datasetId: '',
    events: { won: true, lost: false, moved: false },
  },
});
const newPipelineInbox = reactive({
  inboxId: '',
  defaultStageId: '',
  autoCreateCard: true,
});
const expandedAutomationStages = ref({});
const aiPanel = ref(null);

const isEditing = computed(() => props.mode === 'edit');
const title = computed(() =>
  isEditing.value
    ? t('CRM_KANBAN.PIPELINE_DRAWER.EDIT_TITLE')
    : t('CRM_KANBAN.PIPELINE_DRAWER.CREATE_TITLE')
);
const subtitle = computed(() =>
  isEditing.value
    ? t('CRM_KANBAN.PIPELINE_DRAWER.EDIT_SUBTITLE')
    : t('CRM_KANBAN.PIPELINE_DRAWER.CREATE_SUBTITLE')
);
const canSubmit = computed(
  () =>
    form.name.trim() &&
    form.stages.length > 0 &&
    form.stages.every(stage => stage.name.trim())
);
const linkedInboxIds = computed(() =>
  props.pipelineInboxes.map(item => Number(item.inbox_id))
);
const availableInboxes = computed(() =>
  props.inboxes.filter(
    inbox => !linkedInboxIds.value.includes(Number(inbox.id))
  )
);
const linkedInboxes = computed(() =>
  props.inboxes.filter(inbox => linkedInboxIds.value.includes(Number(inbox.id)))
);
const stageOptions = computed(() => form.stages.filter(stage => stage.id));
const canAddPipelineInbox = computed(
  () => isEditing.value && props.pipeline?.id && newPipelineInbox.inboxId
);

const cloneStage = (stage, index) => ({
  id: stage.id,
  name: stage.name || '',
  description: stage.description || '',
  color: stage.color || stageColors[index % stageColors.length],
  funnel_stage_type: stage.metadata?.funnel_stage_type || '',
});

const resetNewPipelineInbox = () => {
  newPipelineInbox.inboxId = availableInboxes.value[0]?.id || '';
  newPipelineInbox.defaultStageId = stageOptions.value[0]?.id || '';
  newPipelineInbox.autoCreateCard = true;
};

const resetForm = () => {
  const pipeline = props.pipeline || {};
  form.name = pipeline.name || t('CRM_KANBAN.PIPELINE_DRAWER.DEFAULT_NAME');
  form.description =
    pipeline.description || t('CRM_KANBAN.PIPELINE_DRAWER.DEFAULT_DESCRIPTION');
  const targetCents = pipeline.metadata?.goals?.monthly_target_cents;
  form.monthlyTarget = targetCents ? Number(targetCents) / 100 : '';
  const metaSync = pipeline.metadata?.meta_sync || {};
  form.metaSync = {
    enabled: Boolean(metaSync.enabled),
    datasetId: metaSync.dataset_id || '',
    events: {
      won: metaSync.events?.won ?? true,
      lost: metaSync.events?.lost ?? false,
      moved: metaSync.events?.moved ?? false,
    },
  };
  const sourceStages = isEditing.value ? props.stages : defaultStages();
  form.stages = sourceStages.map(cloneStage);
  resetNewPipelineInbox();
};

const addStage = () => {
  form.stages.push({
    name: t('CRM_KANBAN.PIPELINE_DRAWER.NEW_STAGE_NAME', {
      count: form.stages.length + 1,
    }),
    description: '',
    color: stageColors[form.stages.length % stageColors.length],
    funnel_stage_type: '',
  });
};

const removeStage = index => {
  const stage = form.stages[index];
  if (stage.id) {
    emit('deleteStage', stage);
    return;
  }
  form.stages.splice(index, 1);
};

const moveStage = (fromIndex, direction) => {
  const toIndex = fromIndex + direction;
  if (toIndex < 0 || toIndex >= form.stages.length) return;

  const stages = [...form.stages];
  const [stage] = stages.splice(fromIndex, 1);
  stages.splice(toIndex, 0, stage);
  form.stages = stages;
};

const toggleStageAutomations = stage => {
  if (!stage.id) return;
  expandedAutomationStages.value = {
    ...expandedAutomationStages.value,
    [stage.id]: !expandedAutomationStages.value[stage.id],
  };
};

const isStageAutomationsExpanded = stage =>
  Boolean(stage.id && expandedAutomationStages.value[stage.id]);

const pipelineInboxName = pipelineInbox =>
  pipelineInbox.inbox?.name ||
  props.inboxes.find(
    inbox => Number(inbox.id) === Number(pipelineInbox.inbox_id)
  )?.name ||
  t('CRM_KANBAN.PIPELINE_DRAWER.UNKNOWN_INBOX');

const pipelineInboxStageName = pipelineInbox =>
  pipelineInbox.default_stage?.name ||
  stageOptions.value.find(
    stage => Number(stage.id) === Number(pipelineInbox.default_stage_id)
  )?.name ||
  t('CRM_KANBAN.PIPELINE_DRAWER.FIRST_STAGE');

const addPipelineInbox = () => {
  if (!canAddPipelineInbox.value) return;

  emit('addPipelineInbox', {
    pipelineId: props.pipeline.id,
    inbox_id: newPipelineInbox.inboxId,
    default_stage_id: newPipelineInbox.defaultStageId || null,
    auto_create_card: newPipelineInbox.autoCreateCard,
  });
};

const removePipelineInbox = pipelineInbox => {
  emit('removePipelineInbox', {
    pipelineId: props.pipeline.id,
    inboxId: pipelineInbox.inbox_id,
  });
};

const onSubmit = async () => {
  if (!canSubmit.value) return;
  // Master save: "Salvar funil" also persists the embedded AI panel (auto_move,
  // criteria, handoff) so the user never loses it for forgetting "Salvar IA".
  // Done BEFORE emit('save') because saving the pipeline closes the drawer and
  // unmounts the panel. Best-effort: the panel surfaces its own error and never
  // throws, so the pipeline save always proceeds.
  if (aiPanel.value) {
    await aiPanel.value.saveSettings({ silent: true });
  }
  emit('save', {
    pipeline: {
      id: props.pipeline?.id,
      name: form.name.trim(),
      description: form.description.trim(),
      is_default: props.pipeline?.is_default ?? !isEditing.value,
      position: props.pipeline?.position || 1,
      goal: {
        monthly_target_cents:
          Number(form.monthlyTarget) > 0
            ? Math.round(Number(form.monthlyTarget) * 100)
            : 0,
        currency: 'BRL',
      },
      // Always emitted so toggling Meta sync off persists enabled:false.
      meta_sync: {
        enabled: form.metaSync.enabled,
        events: { ...form.metaSync.events },
        dataset_id: form.metaSync.datasetId.trim() || null,
      },
    },
    stages: form.stages.map((stage, index) => ({
      ...stage,
      name: stage.name.trim(),
      description: stage.description?.trim() || '',
      position: index + 1,
      funnel_stage_type: stage.funnel_stage_type || null,
    })),
  });
};

// Reset only when the drawer opens or the target pipeline identity changes.
// We intentionally do NOT depend on props.stages content: realtime card events
// rebuild board.stages into a new array reference on every update, and a busy
// board would re-run resetForm mid-typing, wiping the stage name being edited.
watch(
  () => [props.show, props.pipeline?.id],
  () => {
    if (props.show) resetForm();
  },
  { immediate: true }
);

// Deleting a stage keeps the drawer open and removes it server-side, so we still
// need to drop it from the form. Reconcile deletions only (a persisted stage that
// vanished server-side) instead of a full resetForm, to preserve in-progress edits
// to the remaining stages. New stages and renames are NOT pulled in from realtime.
watch(
  () => props.stages,
  serverStages => {
    if (!props.show || !isEditing.value) return;
    const serverStageIds = new Set(serverStages.map(stage => stage.id));
    const next = form.stages.filter(
      stage => !stage.id || serverStageIds.has(stage.id)
    );
    if (next.length !== form.stages.length) form.stages = next;
  }
);

watch(
  () => [props.pipelineInboxes, props.inboxes],
  () => {
    if (props.show && isEditing.value) resetNewPipelineInbox();
  }
);

useKeyboardEvents({
  Escape: {
    action: () => {
      if (props.show) emit('close');
    },
    allowOnFocusedInput: true,
  },
});
</script>

<template>
  <transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="ltr:translate-x-full rtl:-translate-x-full opacity-0"
    leave-active-class="transition duration-150 ease-in"
    leave-to-class="ltr:translate-x-[30%] rtl:-translate-x-[30%] opacity-0"
  >
    <div
      v-if="show"
      class="fixed inset-y-0 ltr:right-0 rtl:left-0 z-50 flex h-full w-[40rem] max-w-full flex-col overflow-hidden border-n-weak bg-n-surface-2 shadow-lg ltr:border-l rtl:border-r"
    >
      <div
        class="flex items-start justify-between gap-4 border-b border-n-weak px-6 py-5"
      >
        <div class="min-w-0">
          <h2 class="mb-1 text-lg font-medium text-n-slate-12">
            {{ title }}
          </h2>
          <p class="mb-0 text-sm leading-5 text-n-slate-11">
            {{ subtitle }}
          </p>
        </div>
        <Button icon="i-lucide-x" slate ghost sm @click="$emit('close')" />
      </div>

      <div class="flex-1 overflow-y-auto px-6 py-5">
        <div class="grid gap-5">
          <Input
            v-model="form.name"
            :label="t('CRM_KANBAN.PIPELINE_DRAWER.NAME')"
            :placeholder="t('CRM_KANBAN.PIPELINE_DRAWER.NAME_PLACEHOLDER')"
            :message="
              !form.name.trim() ? t('CRM_KANBAN.PIPELINE_DRAWER.REQUIRED') : ''
            "
            :message-type="!form.name.trim() ? 'error' : 'info'"
          />

          <label class="grid gap-1">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('CRM_KANBAN.PIPELINE_DRAWER.DESCRIPTION') }}
            </span>
            <textarea
              v-model="form.description"
              rows="3"
              class="reset-base !mb-0 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 py-2.5 text-sm text-n-slate-12 outline outline-1 outline-n-weak transition-all placeholder:text-n-slate-10 focus:outline-n-brand"
              :placeholder="
                t('CRM_KANBAN.PIPELINE_DRAWER.DESCRIPTION_PLACEHOLDER')
              "
            />
          </label>

          <label class="grid gap-1">
            <span class="text-heading-3 text-n-slate-12">
              {{ t('CRM_KANBAN.PIPELINE_DRAWER.MONTHLY_TARGET') }}
            </span>
            <input
              v-model="form.monthlyTarget"
              type="number"
              min="0"
              step="0.01"
              class="reset-base !mb-0 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 py-2.5 text-sm text-n-slate-12 outline outline-1 outline-n-weak transition-all placeholder:text-n-slate-10 focus:outline-n-brand"
              :placeholder="
                t('CRM_KANBAN.PIPELINE_DRAWER.MONTHLY_TARGET_PLACEHOLDER')
              "
            />
            <span class="text-xs text-n-slate-11">
              {{ t('CRM_KANBAN.PIPELINE_DRAWER.MONTHLY_TARGET_HELP') }}
            </span>
          </label>

          <CrmAiSettingsPanel
            v-if="isEditing && pipeline?.id && isCrmAiEnabled && canManageAi"
            ref="aiPanel"
            :pipeline-id="pipeline.id"
            :stages="form.stages"
            :inboxes="linkedInboxes"
          />

          <section class="grid gap-3">
            <div class="flex items-center justify-between gap-3">
              <div>
                <h3 class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ t('CRM_KANBAN.PIPELINE_DRAWER.STAGES') }}
                </h3>
                <p class="mb-0 text-xs leading-5 text-n-slate-11">
                  {{ t('CRM_KANBAN.PIPELINE_DRAWER.STAGES_HELP') }}
                </p>
              </div>
              <Button
                :label="t('CRM_KANBAN.PIPELINE_DRAWER.ADD_STAGE')"
                icon="i-lucide-plus"
                slate
                faded
                sm
                @click="addStage"
              />
            </div>

            <div
              v-for="(stage, index) in form.stages"
              :key="stage.id || index"
              class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-3"
            >
              <div class="grid gap-3 md:grid-cols-[2.5rem_1fr_11rem_auto]">
                <label class="grid gap-1">
                  <span class="text-xs font-medium text-n-slate-11">
                    {{ t('CRM_KANBAN.PIPELINE_DRAWER.COLOR') }}
                  </span>
                  <input
                    v-model="stage.color"
                    type="color"
                    class="h-10 w-10 cursor-pointer rounded-md border border-n-weak bg-transparent p-1"
                  />
                </label>
                <Input
                  v-model="stage.name"
                  :label="t('CRM_KANBAN.PIPELINE_DRAWER.STAGE_NAME')"
                  :placeholder="
                    t('CRM_KANBAN.PIPELINE_DRAWER.STAGE_NAME_PLACEHOLDER')
                  "
                  :message="
                    !stage.name.trim()
                      ? t('CRM_KANBAN.PIPELINE_DRAWER.REQUIRED')
                      : ''
                  "
                  :message-type="!stage.name.trim() ? 'error' : 'info'"
                />
                <label class="grid gap-1">
                  <span class="text-xs font-medium text-n-slate-11">
                    {{ t('CRM_KANBAN.PIPELINE_DRAWER.META_STAGE_TYPE') }}
                  </span>
                  <select
                    v-model="stage.funnel_stage_type"
                    class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                  >
                    <option
                      v-for="option in funnelStageTypeOptions"
                      :key="option.value"
                      :value="option.value"
                    >
                      {{ option.label }}
                    </option>
                  </select>
                </label>
                <div class="flex items-end justify-end gap-1">
                  <Button
                    icon="i-lucide-arrow-up"
                    slate
                    ghost
                    sm
                    :title="t('CRM_KANBAN.PIPELINE_DRAWER.MOVE_STAGE_UP')"
                    :disabled="index === 0"
                    @click="moveStage(index, -1)"
                  />
                  <Button
                    icon="i-lucide-arrow-down"
                    slate
                    ghost
                    sm
                    :title="t('CRM_KANBAN.PIPELINE_DRAWER.MOVE_STAGE_DOWN')"
                    :disabled="index === form.stages.length - 1"
                    @click="moveStage(index, 1)"
                  />
                  <Button
                    v-if="isEditing && stage.id"
                    icon="i-lucide-workflow"
                    slate
                    ghost
                    sm
                    :title="t('CRM_KANBAN.STAGE_AUTOMATIONS.TITLE')"
                    :class="
                      isStageAutomationsExpanded(stage)
                        ? 'text-n-brand'
                        : 'text-n-slate-11'
                    "
                    @click="toggleStageAutomations(stage)"
                  />
                  <Button
                    icon="i-lucide-trash-2"
                    ruby
                    ghost
                    sm
                    :title="t('CRM_KANBAN.PIPELINE_DRAWER.DELETE_STAGE')"
                    :disabled="form.stages.length === 1 || isDeletingStage"
                    @click="removeStage(index)"
                  />
                </div>
              </div>
              <CrmStageAutomationsPanel
                v-if="
                  isEditing && stage.id && isStageAutomationsExpanded(stage)
                "
                :stage="stage"
                :pipeline-stages="form.stages"
                :agents="agents"
                :expanded="isStageAutomationsExpanded(stage)"
              />
            </div>
          </section>

          <section
            v-if="isEditing"
            class="grid gap-4 border-t border-n-weak pt-4"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <h3 class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ t('CRM_KANBAN.PIPELINE_DRAWER.META_SYNC_TITLE') }}
                </h3>
                <p class="mb-0 text-xs leading-5 text-n-slate-11">
                  {{ t('CRM_KANBAN.PIPELINE_DRAWER.META_SYNC_HELP') }}
                </p>
              </div>
              <label
                class="relative inline-flex shrink-0 cursor-pointer items-center"
              >
                <input
                  v-model="form.metaSync.enabled"
                  type="checkbox"
                  class="peer sr-only"
                />
                <span
                  class="h-5 w-9 rounded-full bg-n-alpha-2 transition-colors after:absolute after:left-0.5 after:top-0.5 after:h-4 after:w-4 after:rounded-full after:bg-white after:transition-transform peer-checked:bg-n-brand peer-checked:after:translate-x-4"
                />
              </label>
            </div>

            <div
              v-if="form.metaSync.enabled"
              class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-3"
            >
              <p class="mb-0 text-xs font-medium text-n-slate-11">
                {{ t('CRM_KANBAN.PIPELINE_DRAWER.META_SYNC_EVENTS') }}
              </p>
              <label class="flex items-center gap-2 text-sm text-n-slate-12">
                <input
                  v-model="form.metaSync.events.won"
                  type="checkbox"
                  class="h-4 w-4 rounded border-n-weak bg-n-alpha-black2 text-n-brand"
                />
                <span>
                  {{ t('CRM_KANBAN.PIPELINE_DRAWER.META_SYNC_EVENT_WON') }}
                </span>
              </label>
              <label class="flex items-center gap-2 text-sm text-n-slate-12">
                <input
                  v-model="form.metaSync.events.lost"
                  type="checkbox"
                  class="h-4 w-4 rounded border-n-weak bg-n-alpha-black2 text-n-brand"
                />
                <span>
                  {{ t('CRM_KANBAN.PIPELINE_DRAWER.META_SYNC_EVENT_LOST') }}
                </span>
              </label>
              <label class="flex items-center gap-2 text-sm text-n-slate-12">
                <input
                  v-model="form.metaSync.events.moved"
                  type="checkbox"
                  class="h-4 w-4 rounded border-n-weak bg-n-alpha-black2 text-n-brand"
                />
                <span>
                  {{ t('CRM_KANBAN.PIPELINE_DRAWER.META_SYNC_EVENT_MOVED') }}
                </span>
              </label>

              <label class="grid gap-1 border-t border-n-weak pt-3">
                <span class="text-xs font-medium text-n-slate-11">
                  {{ t('CRM_KANBAN.PIPELINE_DRAWER.META_SYNC_DATASET') }}
                </span>
                <input
                  v-model="form.metaSync.datasetId"
                  type="text"
                  class="reset-base !mb-0 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 py-2.5 text-sm text-n-slate-12 outline outline-1 outline-n-weak transition-all placeholder:text-n-slate-10 focus:outline-n-brand"
                  :placeholder="
                    t(
                      'CRM_KANBAN.PIPELINE_DRAWER.META_SYNC_DATASET_PLACEHOLDER'
                    )
                  "
                />
                <span class="text-xs text-n-slate-11">
                  {{ t('CRM_KANBAN.PIPELINE_DRAWER.META_SYNC_DATASET_HELP') }}
                </span>
              </label>
            </div>
          </section>

          <section
            v-if="isEditing"
            class="grid gap-4 border-t border-n-weak pt-4"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <h3 class="mb-1 text-sm font-medium text-n-slate-12">
                  {{ t('CRM_KANBAN.PIPELINE_DRAWER.INBOX_AUTOMATION') }}
                </h3>
                <p class="mb-0 text-xs leading-5 text-n-slate-11">
                  {{ t('CRM_KANBAN.PIPELINE_DRAWER.INBOX_AUTOMATION_HELP') }}
                </p>
              </div>
            </div>

            <div class="grid gap-2">
              <p class="mb-0 text-xs font-medium text-n-slate-11">
                {{ t('CRM_KANBAN.PIPELINE_DRAWER.LINKED_INBOXES') }}
              </p>
              <div
                v-if="isLoadingPipelineInboxes"
                class="rounded-lg border border-n-weak bg-n-alpha-black2 px-3 py-3 text-xs text-n-slate-11"
              >
                {{ t('CRM_KANBAN.PIPELINE_DRAWER.LOADING_INBOXES') }}
              </div>
              <div
                v-else-if="pipelineInboxes.length === 0"
                class="rounded-lg border border-dashed border-n-weak px-3 py-3 text-xs leading-5 text-n-slate-10"
              >
                {{ t('CRM_KANBAN.PIPELINE_DRAWER.NO_LINKED_INBOXES') }}
              </div>
              <template v-else>
                <div
                  v-for="pipelineInbox in pipelineInboxes"
                  :key="pipelineInbox.id || pipelineInbox.inbox_id"
                  class="flex items-center justify-between gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 px-3 py-3"
                >
                  <div class="min-w-0">
                    <p
                      class="mb-1 truncate text-sm font-medium text-n-slate-12"
                    >
                      {{ pipelineInboxName(pipelineInbox) }}
                    </p>
                    <p class="mb-0 truncate text-xs text-n-slate-11">
                      {{
                        t('CRM_KANBAN.PIPELINE_DRAWER.ENTRY_STAGE_VALUE', {
                          stage: pipelineInboxStageName(pipelineInbox),
                        })
                      }}
                    </p>
                  </div>
                  <div class="flex shrink-0 items-center gap-2">
                    <span
                      class="rounded-md px-2 py-1 text-xs"
                      :class="
                        pipelineInbox.auto_create_card
                          ? 'bg-n-teal-3 text-n-teal-11'
                          : 'bg-n-alpha-2 text-n-slate-11'
                      "
                    >
                      {{
                        pipelineInbox.auto_create_card
                          ? t('CRM_KANBAN.PIPELINE_DRAWER.AUTO_CREATE_ON')
                          : t('CRM_KANBAN.PIPELINE_DRAWER.AUTO_CREATE_OFF')
                      }}
                    </span>
                    <Button
                      icon="i-lucide-trash-2"
                      ruby
                      ghost
                      sm
                      :is-loading="isRemovingPipelineInbox"
                      :title="t('CRM_KANBAN.PIPELINE_DRAWER.REMOVE_INBOX')"
                      @click="removePipelineInbox(pipelineInbox)"
                    />
                  </div>
                </div>
              </template>
            </div>

            <div
              class="grid gap-3 rounded-lg border border-n-weak bg-n-alpha-black2 p-3"
            >
              <div class="grid gap-3 md:grid-cols-[1fr_1fr]">
                <label class="grid gap-1">
                  <span class="text-xs font-medium text-n-slate-11">
                    {{ t('CRM_KANBAN.PIPELINE_DRAWER.INBOX') }}
                  </span>
                  <select
                    v-model="newPipelineInbox.inboxId"
                    class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                    :disabled="availableInboxes.length === 0"
                  >
                    <option value="">
                      {{ t('CRM_KANBAN.PIPELINE_DRAWER.SELECT_INBOX') }}
                    </option>
                    <option
                      v-for="inbox in availableInboxes"
                      :key="inbox.id"
                      :value="inbox.id"
                    >
                      {{ inbox.name }}
                    </option>
                  </select>
                </label>

                <label class="grid gap-1">
                  <span class="text-xs font-medium text-n-slate-11">
                    {{ t('CRM_KANBAN.PIPELINE_DRAWER.ENTRY_STAGE') }}
                  </span>
                  <select
                    v-model="newPipelineInbox.defaultStageId"
                    class="reset-base !mb-0 h-10 w-full rounded-lg border-0 bg-n-alpha-black2 px-3 text-sm text-n-slate-12 outline outline-1 outline-n-weak focus:outline-n-brand"
                  >
                    <option value="">
                      {{ t('CRM_KANBAN.PIPELINE_DRAWER.FIRST_STAGE') }}
                    </option>
                    <option
                      v-for="stage in stageOptions"
                      :key="stage.id"
                      :value="stage.id"
                    >
                      {{ stage.name }}
                    </option>
                  </select>
                </label>
              </div>

              <div class="flex flex-wrap items-center justify-between gap-3">
                <label
                  class="flex min-w-0 items-center gap-2 text-sm text-n-slate-12"
                >
                  <input
                    v-model="newPipelineInbox.autoCreateCard"
                    type="checkbox"
                    class="h-4 w-4 rounded border-n-weak bg-n-alpha-black2 text-n-brand"
                  />
                  <span>
                    {{ t('CRM_KANBAN.PIPELINE_DRAWER.AUTO_CREATE_CARD') }}
                  </span>
                </label>
                <Button
                  :label="t('CRM_KANBAN.PIPELINE_DRAWER.ADD_INBOX')"
                  icon="i-lucide-plus"
                  slate
                  faded
                  sm
                  :is-loading="isSavingPipelineInbox"
                  :disabled="!canAddPipelineInbox"
                  @click="addPipelineInbox"
                />
              </div>
            </div>
          </section>
        </div>
      </div>

      <div
        class="flex items-center justify-between gap-3 border-t border-n-weak px-6 py-4"
      >
        <Button
          v-if="isEditing"
          :label="t('CRM_KANBAN.PIPELINE_DRAWER.ARCHIVE')"
          icon="i-lucide-archive"
          ruby
          ghost
          :is-loading="isArchiving"
          @click="$emit('archive')"
        />
        <span v-else />
        <div class="flex items-center gap-2">
          <Button
            :label="t('CRM_KANBAN.PIPELINE_DRAWER.CANCEL')"
            slate
            faded
            @click="$emit('close')"
          />
          <Button
            :label="
              isEditing
                ? t('CRM_KANBAN.PIPELINE_DRAWER.SAVE')
                : t('CRM_KANBAN.PIPELINE_DRAWER.CREATE')
            "
            icon="i-lucide-check"
            :is-loading="isSaving"
            :disabled="!canSubmit"
            @click="onSubmit"
          />
        </div>
      </div>
    </div>
  </transition>
</template>

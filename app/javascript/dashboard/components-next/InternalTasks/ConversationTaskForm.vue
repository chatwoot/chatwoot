<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import MessagePreview from 'dashboard/components/widgets/conversation/MessagePreview.vue';
import { templateIcon } from 'dashboard/helper/internalTaskUi';

const props = defineProps({
  conversationId: { type: [String, Number], required: true },
});

const emit = defineEmits(['created']);
const { t } = useI18n();
const store = useStore();
const templates = useMapGetter('internalTasks/getTaskTemplates');
const teams = useMapGetter('teams/getTeams');
const agents = useMapGetter('agents/getAgents');
const uiFlags = useMapGetter('internalTasks/getUIFlags');

const dialogRef = ref(null);
const step = ref('template');
const selectedTemplateId = ref(null);
const title = ref('');
const description = ref('');
const teamId = ref(null);
const assignedToId = ref(null);
const assignmentTabIndex = ref(0);
const metadata = ref({});
const sourceMessageId = ref(null);
const anchorMessage = ref(null);
const activeConversationId = ref(props.conversationId);

const assignmentTabs = computed(() => [
  { label: t('INTERNAL_TASKS.FORM.ASSIGNMENT_TEAM') },
  { label: t('INTERNAL_TASKS.FORM.ASSIGNMENT_AGENT') },
  { label: t('INTERNAL_TASKS.FORM.ASSIGNMENT_OPEN') },
]);

const assignmentMode = computed(() => {
  const modes = ['team', 'agent', 'open'];
  return modes[assignmentTabIndex.value] || 'open';
});

const selectedTemplate = computed(() =>
  templates.value.find(template => template.id === selectedTemplateId.value)
);

const metadataFields = computed(
  () => selectedTemplate.value?.metadataSchema || []
);

const teamOptions = computed(() => [
  { value: null, label: t('INTERNAL_TASKS.FORM.NO_TEAM') },
  ...teams.value.map(team => ({ value: team.id, label: team.name })),
]);

const selectedAgent = computed(() => {
  if (!assignedToId.value) return null;
  return agents.value.find(agent => agent.id === Number(assignedToId.value));
});

const onAssignmentTabChanged = tab => {
  const index = assignmentTabs.value.findIndex(
    item => item.label === tab.label
  );
  if (index >= 0) assignmentTabIndex.value = index;
  if (assignmentMode.value === 'team') assignedToId.value = null;
  if (assignmentMode.value === 'agent') teamId.value = null;
  if (assignmentMode.value === 'open') {
    teamId.value = null;
    assignedToId.value = null;
  }
};

const onAgentSelect = agent => {
  assignedToId.value = agent?.id ? Number(agent.id) : null;
};

const open = ({
  conversationId,
  sourceMessageId: messageId,
  anchorMessage: message,
} = {}) => {
  if (conversationId) activeConversationId.value = conversationId;
  step.value = 'template';
  selectedTemplateId.value = null;
  title.value = '';
  description.value = '';
  teamId.value = null;
  assignedToId.value = null;
  assignmentTabIndex.value = 0;
  metadata.value = {};
  sourceMessageId.value = messageId || null;
  anchorMessage.value = message || null;
  dialogRef.value?.open();
};

const selectTemplate = template => {
  selectedTemplateId.value = template?.id || null;
  title.value = template?.title || '';
  teamId.value = template?.defaultTeamId || null;
  assignedToId.value = null;
  assignmentTabIndex.value = template?.defaultTeamId ? 0 : 2;
  metadata.value = {};
  step.value = 'details';
};

const submit = async () => {
  const payload = {
    task_template_id: selectedTemplateId.value,
    title: title.value,
    description: description.value,
    metadata: metadata.value,
  };

  if (assignmentMode.value === 'team') payload.team_id = teamId.value;
  if (assignmentMode.value === 'agent')
    payload.assigned_to_id = assignedToId.value;
  if (sourceMessageId.value) payload.source_message_id = sourceMessageId.value;

  await store.dispatch('internalTasks/createConversationTask', {
    conversationId: activeConversationId.value,
    payload,
  });
  sourceMessageId.value = null;
  anchorMessage.value = null;
  dialogRef.value?.close();
  emit('created');
};

defineExpose({ open });

store.dispatch('teams/get');
store.dispatch('agents/get');
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="edit"
    width="2xl"
    :title="$t('INTERNAL_TASKS.FORM.DIALOG_TITLE')"
    :description="$t('INTERNAL_TASKS.FORM.DIALOG_DESCRIPTION')"
    :show-confirm-button="false"
    :show-cancel-button="false"
    @close="step = 'template'"
  >
    <div v-if="step === 'template'" class="flex flex-col gap-4">
      <p class="text-sm font-medium text-n-slate-12">
        {{ $t('INTERNAL_TASKS.FORM.SELECT_TEMPLATE') }}
      </p>
      <div class="grid grid-cols-2 gap-2">
        <button
          v-for="template in templates"
          :key="template.id"
          type="button"
          class="flex items-start gap-3 p-3 text-left rounded-xl border transition-all hover:border-n-brand hover:bg-n-alpha-1"
          :class="
            selectedTemplateId === template.id
              ? 'border-n-brand bg-n-alpha-2'
              : 'border-n-weak bg-n-solid-2'
          "
          @click="selectTemplate(template)"
        >
          <span
            class="size-9 shrink-0 rounded-lg bg-n-alpha-2 flex items-center justify-center text-n-brand"
            :class="templateIcon(template.key)"
          />
          <span class="min-w-0">
            <span class="block text-sm font-medium text-n-slate-12 truncate">
              {{ template.title }}
            </span>
            <span
              v-if="template.description"
              class="block text-xs text-n-slate-11 line-clamp-2 mt-0.5"
            >
              {{ template.description }}
            </span>
          </span>
        </button>
        <button
          type="button"
          class="flex items-start gap-3 p-3 text-left rounded-xl border border-dashed border-n-weak hover:border-n-brand hover:bg-n-alpha-1"
          @click="selectTemplate(null)"
        >
          <span
            class="size-9 shrink-0 rounded-lg bg-n-alpha-2 flex items-center justify-center text-n-slate-11 i-lucide-plus"
          />
          <span class="text-sm font-medium text-n-slate-12">
            {{ $t('INTERNAL_TASKS.FORM.OTHER') }}
          </span>
        </button>
      </div>
    </div>

    <div v-else class="flex flex-col gap-4">
      <button
        type="button"
        class="inline-flex items-center gap-1 text-xs text-n-brand w-fit"
        @click="step = 'template'"
      >
        <span class="i-lucide-arrow-left size-3.5" />
        {{ $t('INTERNAL_TASKS.FORM.BACK') }}
      </button>

      <Input v-model="title" :label="$t('INTERNAL_TASKS.FORM.TITLE')" />

      <div
        v-if="anchorMessage"
        class="rounded-lg border border-n-weak bg-n-alpha-2 px-3 py-2 flex flex-col gap-1"
      >
        <p class="text-xxs font-medium text-n-slate-11">
          {{ $t('INTERNAL_TASKS.FORM.ANCHORED_MESSAGE') }}
        </p>
        <MessagePreview
          :message="anchorMessage"
          :show-message-type="false"
          class="text-xs"
        />
      </div>

      <div class="flex flex-col gap-3">
        <label class="text-heading-3 text-n-slate-12">
          {{ $t('INTERNAL_TASKS.FORM.ASSIGNMENT_LABEL') }}
        </label>
        <TabBar
          :tabs="assignmentTabs"
          :initial-active-tab="assignmentTabIndex"
          @tab-changed="onAssignmentTabChanged"
        />

        <div v-if="assignmentMode === 'team'" class="flex flex-col gap-1">
          <label class="text-xs text-n-slate-11">
            {{ $t('INTERNAL_TASKS.FORM.TEAM') }}
          </label>
          <select
            v-model="teamId"
            class="block w-full h-10 px-3 text-sm rounded-lg bg-n-alpha-black2 outline outline-1 outline-n-weak text-n-slate-12"
          >
            <option
              v-for="option in teamOptions"
              :key="option.label"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
          <p class="text-xxs text-n-slate-11">
            {{ $t('INTERNAL_TASKS.FORM.ASSIGNMENT_TEAM_HINT') }}
          </p>
        </div>

        <div v-else-if="assignmentMode === 'agent'" class="flex flex-col gap-1">
          <label class="text-xs text-n-slate-11">
            {{ $t('INTERNAL_TASKS.FORM.AGENT') }}
          </label>
          <MultiselectDropdown
            :options="agents"
            :selected-item="selectedAgent"
            :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
            :multiselector-placeholder="$t('INTERNAL_TASKS.FORM.SELECT_AGENT')"
            :no-search-result="
              $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
            "
            :input-placeholder="
              $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
            "
            @select="onAgentSelect"
          />
          <p class="text-xxs text-n-slate-11">
            {{ $t('INTERNAL_TASKS.FORM.ASSIGNMENT_AGENT_HINT') }}
          </p>
        </div>

        <p
          v-else
          class="text-xs text-n-slate-11 rounded-lg bg-n-alpha-2 px-3 py-2"
        >
          {{ $t('INTERNAL_TASKS.FORM.ASSIGNMENT_OPEN_HINT') }}
        </p>
      </div>

      <TextArea
        v-model="description"
        :label="$t('INTERNAL_TASKS.FORM.DESCRIPTION')"
        :max-length="500"
        auto-height
      />

      <Input
        v-for="field in metadataFields"
        :key="field.key"
        v-model="metadata[field.key]"
        :label="field.label"
      />

      <div class="flex gap-2 justify-end pt-2">
        <Button
          variant="faded"
          color="slate"
          :label="$t('INTERNAL_TASKS.FORM.CANCEL')"
          @click="dialogRef?.close()"
        />
        <Button
          color="blue"
          :label="$t('INTERNAL_TASKS.FORM.CREATE')"
          :is-loading="uiFlags.isCreating"
          :disabled="!title || (assignmentMode === 'agent' && !assignedToId)"
          @click="submit"
        />
      </div>
    </div>
  </Dialog>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';

const props = defineProps({
  task: { type: Object, required: true },
  conversationId: { type: [String, Number], default: null },
  embedded: { type: Boolean, default: false },
  compact: { type: Boolean, default: false },
});

const emit = defineEmits(['updated', 'close']);
const { t } = useI18n();
const store = useStore();
const teams = useMapGetter('teams/getTeams');
const agents = useMapGetter('agents/getAgents');
const uiFlags = useMapGetter('internalTasks/getUIFlags');

const teamId = ref(props.task.teamId || null);
const assignedToId = ref(props.task.assignedToId || null);

const noneTeam = computed(() => ({
  id: 0,
  name: t('INTERNAL_TASKS.FORM.NO_TEAM'),
}));

const teamOptions = computed(() => [noneTeam.value, ...teams.value]);

const selectedTeam = computed(() => {
  if (!teamId.value) return noneTeam.value;
  return (
    teams.value.find(team => team.id === Number(teamId.value)) || noneTeam.value
  );
});

const selectedAgent = computed(() => {
  if (!assignedToId.value) return null;
  return agents.value.find(agent => agent.id === Number(assignedToId.value));
});

const onAgentSelect = agent => {
  assignedToId.value = agent?.id ? Number(agent.id) : null;
  if (assignedToId.value) teamId.value = null;
};

const onTeamSelect = team => {
  if (!team || team.id === 0) {
    teamId.value = null;
    return;
  }
  teamId.value = Number(team.id);
  assignedToId.value = null;
};

watch(
  () => props.task,
  newTask => {
    teamId.value = newTask.teamId || null;
    assignedToId.value = newTask.assignedToId || null;
  },
  { deep: true }
);

const save = async () => {
  await store.dispatch('internalTasks/updateTask', {
    taskId: props.task.id,
    conversationId: props.conversationId || props.task.conversation?.id,
    payload: {
      assigned_to_id: assignedToId.value,
      team_id: teamId.value,
    },
  });
  useAlert(t('INTERNAL_TASKS.REASSIGN.SUCCESS'));
  emit('updated');
  emit('close');
};

onMounted(() => {
  store.dispatch('teams/get');
  store.dispatch('agents/get');
});
</script>

<template>
  <div
    class="flex flex-col gap-3"
    :class="
      embedded
        ? compact
          ? 'p-3'
          : 'px-4 pb-3 border-t border-n-weak'
        : 'mx-4 mb-4 rounded-lg border border-n-slate-3 p-4'
    "
  >
    <h3 v-if="!embedded" class="text-sm font-semibold text-n-slate-12">
      {{ $t('INTERNAL_TASKS.REASSIGN.TITLE') }}
    </h3>

    <div class="flex flex-col gap-1">
      <label class="text-xs text-n-slate-11">{{
        $t('INTERNAL_TASKS.FORM.TEAM')
      }}</label>
      <MultiselectDropdown
        :options="teamOptions"
        :selected-item="selectedTeam"
        :has-thumbnail="false"
        compact
        :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.TEAM')"
        :multiselector-placeholder="$t('INTERNAL_TASKS.FORM.NO_TEAM')"
        :no-search-result="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.TEAM')
        "
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.TEAM')
        "
        @select="onTeamSelect"
      />
    </div>

    <div class="flex flex-col gap-1">
      <label class="text-xs text-n-slate-11">{{
        $t('INTERNAL_TASKS.FORM.AGENT')
      }}</label>
      <MultiselectDropdown
        :options="agents"
        :selected-item="selectedAgent"
        compact
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
    </div>

    <div class="flex items-center justify-end gap-2">
      <Button
        v-if="embedded"
        size="sm"
        variant="ghost"
        color="slate"
        :label="$t('INTERNAL_TASKS.FORM.CANCEL')"
        @click="emit('close')"
      />
      <Button
        size="sm"
        color="blue"
        :label="$t('INTERNAL_TASKS.REASSIGN.SAVE')"
        :is-loading="uiFlags.isUpdating"
        @click="save"
      />
    </div>
  </div>
</template>

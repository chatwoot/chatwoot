<script setup>
/* eslint-disable vue/no-mutating-props -- exitPolicy is shared mutable from parent */
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  exitPolicy: { type: Object, required: true },
  agents: { type: Array, default: () => [] },
  teams: { type: Array, default: () => [] },
});

const { t } = useI18n();

const exitEvents = ['on_complete', 'on_handoff', 'on_fail', 'on_human_break'];

const assigneeModes = computed(() => [
  { id: 'none', label: t('FLOWS.EXIT.MODE_NONE') },
  { id: 'keep', label: t('FLOWS.EXIT.MODE_KEEP') },
  { id: 'unassigned', label: t('FLOWS.EXIT.MODE_UNASSIGNED') },
  { id: 'pending', label: t('FLOWS.EXIT.MODE_PENDING') },
  { id: 'team', label: t('FLOWS.EXIT.MODE_TEAM') },
  { id: 'agent', label: t('FLOWS.EXIT.MODE_AGENT') },
  { id: 'contact_owner', label: t('FLOWS.EXIT.MODE_OWNER') },
]);

const statusOptions = computed(() => [
  { id: 'open', label: t('FLOWS.EXIT.STATUS_OPEN') },
  { id: 'pending', label: t('FLOWS.EXIT.STATUS_PENDING') },
  { id: 'resolved', label: t('FLOWS.EXIT.STATUS_RESOLVED') },
]);

const showTeamPicker = eventKey =>
  props.exitPolicy[eventKey]?.assignee_mode === 'team';

const showAgentPicker = eventKey =>
  props.exitPolicy[eventKey]?.assignee_mode === 'agent';

const showPrivateNote = eventKey =>
  ['on_handoff', 'on_fail', 'on_human_break'].includes(eventKey);
</script>

<template>
  <div class="flex flex-col gap-3 w-full">
    <p class="m-0 text-xs text-n-slate-11">
      {{ t('FLOWS.EXIT.HINT') }}
    </p>
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
      <div
        v-for="eventKey in exitEvents"
        :key="eventKey"
        class="rounded-md border border-n-weak bg-n-background dark:bg-n-solid-1 p-3"
      >
        <p class="m-0 mb-2 text-sm font-medium text-n-slate-12">
          {{ t(`FLOWS.EXIT.${eventKey.toUpperCase()}`) }}
        </p>
        <label class="mb-2 block">
          <span class="mb-1 block text-xs text-n-slate-11">
            {{ t('FLOWS.EXIT.STATUS') }}
          </span>
          <select v-model="exitPolicy[eventKey].status" class="mb-0">
            <option v-for="s in statusOptions" :key="s.id" :value="s.id">
              {{ s.label }}
            </option>
          </select>
        </label>
        <label class="mb-2 block">
          <span class="mb-1 block text-xs text-n-slate-11">
            {{ t('FLOWS.EXIT.ASSIGNEE') }}
          </span>
          <select v-model="exitPolicy[eventKey].assignee_mode" class="mb-0">
            <option v-for="m in assigneeModes" :key="m.id" :value="m.id">
              {{ m.label }}
            </option>
          </select>
        </label>
        <label v-if="showTeamPicker(eventKey)" class="mb-2 block">
          <span class="mb-1 block text-xs text-n-slate-11">
            {{ t('FLOWS.EXIT.TEAM') }}
          </span>
          <select v-model="exitPolicy[eventKey].team_id" class="mb-0">
            <option :value="null">
              {{ t('FLOWS.EXIT.PICK_TEAM') }}
            </option>
            <option v-for="team in teams" :key="team.id" :value="team.id">
              {{ team.name }}
            </option>
          </select>
        </label>
        <label v-if="showAgentPicker(eventKey)" class="mb-2 block">
          <span class="mb-1 block text-xs text-n-slate-11">
            {{ t('FLOWS.EXIT.AGENT') }}
          </span>
          <select v-model="exitPolicy[eventKey].agent_id" class="mb-0">
            <option :value="null">
              {{ t('FLOWS.EXIT.PICK_AGENT') }}
            </option>
            <option v-for="agent in agents" :key="agent.id" :value="agent.id">
              {{ agent.name }}
            </option>
          </select>
        </label>
        <label
          v-if="showPrivateNote(eventKey)"
          class="mb-0 flex items-center gap-2"
        >
          <input
            v-model="exitPolicy[eventKey].private_note"
            type="checkbox"
            class="mb-0"
          />
          <span class="text-xs text-n-slate-11">
            {{ t('FLOWS.EXIT.PRIVATE_NOTE') }}
          </span>
        </label>
      </div>
    </div>
  </div>
</template>

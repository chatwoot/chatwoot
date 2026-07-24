<script setup>
/* eslint-disable vue/no-mutating-props -- beta editor: selectedStep/exitPolicy are shared mutable objects from parent */
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  name: { type: String, default: '' },
  description: { type: String, default: '' },
  active: { type: Boolean, default: true },
  exitPolicy: { type: Object, required: true },
  selectedStep: { type: Object, default: null },
  selectedStepIndex: { type: Number, default: -1 },
  stepTargets: { type: Array, default: () => [] },
  agents: { type: Array, default: () => [] },
  teams: { type: Array, default: () => [] },
  saving: { type: Boolean, default: false },
});

const emit = defineEmits([
  'update:name',
  'update:description',
  'update:active',
  'submit',
]);

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

const stepHasSendMessage = computed(() =>
  (props.selectedStep?.actions || []).some(
    a => a.action_name === 'send_message'
  )
);

const sendMessageActions = computed(() => {
  const actions = (props.selectedStep?.actions || []).filter(
    a => a.action_name === 'send_message'
  );
  actions.forEach(action => {
    if (!action.delivery) {
      action.delivery = { delay_seconds: 3, mark_read_and_typing: true };
    }
  });
  return actions;
});

const branchTargetsForStep = computed(() => {
  if (!props.selectedStep) return props.stepTargets;
  return props.stepTargets.filter(o => o.id !== props.selectedStep.id);
});

const ensureButtons = () => {
  if (!props.selectedStep) return;
  if (!props.selectedStep.buttons) props.selectedStep.buttons = [];
  while (props.selectedStep.buttons.length < 3) {
    props.selectedStep.buttons.push({ title: '', value: '' });
  }
  if (!props.selectedStep.branches) props.selectedStep.branches = {};
};

const onButtonTitleInput = (btn, index) => {
  ensureButtons();
  if ((btn.title || '').trim() && !props.selectedStep.branches[index]) {
    props.selectedStep.branches[index] = 'end';
  }
};

const showTeamPicker = eventKey =>
  props.exitPolicy[eventKey]?.assignee_mode === 'team';

const showAgentPicker = eventKey =>
  props.exitPolicy[eventKey]?.assignee_mode === 'agent';

const showPrivateNote = eventKey =>
  ['on_handoff', 'on_fail', 'on_human_break'].includes(eventKey);
</script>

<template>
  <div
    class="p-4 bg-n-solid-2 border border-n-weak rounded-lg shadow-sm h-full flex flex-col overflow-y-auto"
  >
    <woot-input
      :model-value="name"
      :label="$t('FLOWS.ADD.FORM.NAME.LABEL')"
      :placeholder="$t('FLOWS.ADD.FORM.NAME.PLACEHOLDER')"
      @update:model-value="emit('update:name', $event)"
    />
    <woot-input
      :model-value="description"
      class="mt-3"
      :label="$t('FLOWS.ADD.FORM.DESCRIPTION.LABEL')"
      :placeholder="$t('FLOWS.ADD.FORM.DESCRIPTION.PLACEHOLDER')"
      @update:model-value="emit('update:description', $event)"
    />

    <div class="mt-4">
      <div class="flex items-center justify-between gap-3">
        <div>
          <p class="m-0 text-sm font-medium text-n-slate-12">
            {{ $t('FLOWS.ADD.FORM.ACTIVE.LABEL') }}
          </p>
          <p class="m-0 mt-1 text-n-slate-11 text-label-small">
            {{ $t('FLOWS.ADD.FORM.ACTIVE.DESCRIPTION') }}
          </p>
        </div>
        <Switch
          :model-value="active"
          @update:model-value="emit('update:active', $event)"
        />
      </div>
    </div>

    <!-- Selected step properties -->
    <div class="mt-5 pt-4 border-t border-n-weak">
      <p class="m-0 text-sm font-medium text-n-slate-12">
        {{ $t('FLOWS.EDIT.STEP_PROPERTIES') }}
      </p>
      <template v-if="selectedStep">
        <p class="mt-1 mb-3 text-xs text-n-slate-11">
          {{
            $t('FLOWS.EDIT.STEP_N', {
              n: selectedStepIndex >= 0 ? selectedStepIndex + 1 : '?',
            })
          }}
        </p>

        <template v-if="stepHasSendMessage">
          <div
            v-for="(action, i) in sendMessageActions"
            :key="`delay_${i}`"
            class="mb-3"
          >
            <label class="mb-0 block">
              <span class="mb-1 block text-xs text-n-slate-11">
                {{ $t('FLOWS.EDIT.DELAY') }}
              </span>
              <input
                v-model.number="action.delivery.delay_seconds"
                type="number"
                min="0"
                max="30"
                class="mb-0 w-full"
              />
            </label>
            <label class="mt-2 mb-0 flex items-center gap-2">
              <input
                v-model="action.delivery.mark_read_and_typing"
                type="checkbox"
                class="mb-0"
              />
              <span class="text-xs text-n-slate-11">
                {{ $t('FLOWS.EDIT.TYPING_INDICATOR') }}
              </span>
            </label>
          </div>

          <p class="mt-2 mb-1 text-sm font-medium text-n-slate-12">
            {{ $t('FLOWS.EDIT.BUTTONS') }}
          </p>
          <p class="mb-2 text-xs text-n-slate-11">
            {{ $t('FLOWS.EDIT.BUTTONS_HINT') }}
          </p>
          <div class="flex flex-col gap-3">
            <div
              v-for="(btn, bIndex) in selectedStep.buttons"
              :key="bIndex"
              class="flex flex-col gap-2 rounded-md border border-n-weak p-2"
            >
              <div class="grid grid-cols-1 gap-2">
                <input
                  v-model="btn.title"
                  type="text"
                  class="mb-0"
                  :placeholder="$t('FLOWS.EDIT.BUTTON_TITLE')"
                  @input="onButtonTitleInput(btn, bIndex)"
                />
                <input
                  v-model="btn.value"
                  type="text"
                  class="mb-0"
                  :placeholder="$t('FLOWS.EDIT.BUTTON_VALUE')"
                />
              </div>
              <label v-if="btn.title" class="mb-0">
                <span class="mb-1 block text-xs text-n-slate-11">
                  {{ $t('FLOWS.EDIT.BRANCH_TO') }}
                </span>
                <select v-model="selectedStep.branches[bIndex]" class="mb-0">
                  <option
                    v-for="opt in branchTargetsForStep"
                    :key="opt.id"
                    :value="opt.id"
                  >
                    {{ opt.label }}
                  </option>
                </select>
              </label>
            </div>
          </div>
        </template>
        <p v-else class="mt-2 mb-0 text-xs text-n-slate-11">
          {{ $t('FLOWS.EDIT.NO_WAIT_WITHOUT_MESSAGE') }}
        </p>
      </template>
      <p v-else class="mt-2 mb-0 text-xs text-n-slate-11">
        {{ $t('FLOWS.EDIT.NO_STEP_SELECTED') }}
      </p>
    </div>

    <!-- Exit policy -->
    <div class="mt-5 pt-4 border-t border-n-weak">
      <p class="block m-0 text-sm font-medium leading-[1.8] text-n-slate-12">
        {{ $t('FLOWS.EXIT.TITLE') }}
      </p>
      <p class="mt-1 mb-3 text-xs text-n-slate-11">
        {{ $t('FLOWS.EXIT.HINT') }}
      </p>
      <div class="flex flex-col gap-3">
        <div
          v-for="eventKey in exitEvents"
          :key="eventKey"
          class="rounded-md border border-n-weak bg-n-background dark:bg-n-solid-1 p-3"
        >
          <p class="m-0 mb-2 text-sm font-medium text-n-slate-12">
            {{ $t(`FLOWS.EXIT.${eventKey.toUpperCase()}`) }}
          </p>
          <label class="mb-2 block">
            <span class="mb-1 block text-xs text-n-slate-11">
              {{ $t('FLOWS.EXIT.STATUS') }}
            </span>
            <select v-model="exitPolicy[eventKey].status" class="mb-0">
              <option v-for="s in statusOptions" :key="s.id" :value="s.id">
                {{ s.label }}
              </option>
            </select>
          </label>
          <label class="mb-2 block">
            <span class="mb-1 block text-xs text-n-slate-11">
              {{ $t('FLOWS.EXIT.ASSIGNEE') }}
            </span>
            <select v-model="exitPolicy[eventKey].assignee_mode" class="mb-0">
              <option v-for="m in assigneeModes" :key="m.id" :value="m.id">
                {{ m.label }}
              </option>
            </select>
          </label>
          <label v-if="showTeamPicker(eventKey)" class="mb-2 block">
            <span class="mb-1 block text-xs text-n-slate-11">
              {{ $t('FLOWS.EXIT.TEAM') }}
            </span>
            <select v-model="exitPolicy[eventKey].team_id" class="mb-0">
              <option :value="null">
                {{ $t('FLOWS.EXIT.PICK_TEAM') }}
              </option>
              <option v-for="team in teams" :key="team.id" :value="team.id">
                {{ team.name }}
              </option>
            </select>
          </label>
          <label v-if="showAgentPicker(eventKey)" class="mb-2 block">
            <span class="mb-1 block text-xs text-n-slate-11">
              {{ $t('FLOWS.EXIT.AGENT') }}
            </span>
            <select v-model="exitPolicy[eventKey].agent_id" class="mb-0">
              <option :value="null">
                {{ $t('FLOWS.EXIT.PICK_AGENT') }}
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
              {{ $t('FLOWS.EXIT.PRIVATE_NOTE') }}
            </span>
          </label>
        </div>
      </div>
    </div>

    <div
      class="mt-3 flex items-start p-2 bg-n-alpha-1 gap-2 dark:bg-n-solid-3 rounded-md"
    >
      <Icon
        icon="i-lucide-info"
        class="flex-shrink-0 mt-0.5 size-4 text-n-slate-11"
      />
      <p class="mb-0 text-n-slate-11 text-body-para">
        {{ $t('FLOWS.ORDER_INFO') }}
      </p>
    </div>

    <div class="mt-4 w-full sticky bottom-0 pt-2 bg-n-solid-2">
      <NextButton
        blue
        solid
        :label="$t('FLOWS.HEADER_BTN_TXT_SAVE')"
        class="w-full"
        :is-loading="saving"
        @click="emit('submit')"
      />
    </div>
  </div>
</template>

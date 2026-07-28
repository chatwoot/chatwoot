<script setup>
/* eslint-disable vue/no-mutating-props -- shared mutable step from parent */
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import AutomationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import { showActionInput } from 'dashboard/helper/automationHelper';

const props = defineProps({
  selectedStep: { type: Object, default: null },
  selectedStepIndex: { type: Number, default: -1 },
  stepTargets: { type: Array, default: () => [] },
  flowActionTypes: { type: Array, default: () => [] },
  getActionDropdownValues: { type: Function, default: () => () => [] },
});

const emit = defineEmits(['add-action', 'remove-action', 'reset-action']);

const MAX_BUTTONS = 3;

const { t } = useI18n();

const actionsOpen = ref(true);
const buttonsOpen = ref(true);

const stepHasSendMessage = computed(() =>
  (props.selectedStep?.actions || []).some(
    a => a.action_name === 'send_message'
  )
);

const usedActionNames = computed(
  () => new Set((props.selectedStep?.actions || []).map(a => a.action_name))
);

const canAddAction = computed(() => {
  if (!props.selectedStep) return false;
  return props.flowActionTypes.some(
    type => !usedActionNames.value.has(type.key)
  );
});

const actionTypesForIndex = aIndex => {
  const usedElsewhere = new Set(
    (props.selectedStep?.actions || [])
      .filter((_, i) => i !== aIndex)
      .map(a => a.action_name)
  );
  return props.flowActionTypes.filter(type => !usedElsewhere.has(type.key));
};

const waitReplyEnabled = computed({
  get() {
    return (props.selectedStep?.buttons || []).length > 0;
  },
  set(on) {
    if (!props.selectedStep) return;
    if (on) {
      if (!props.selectedStep.buttons?.length) {
        props.selectedStep.buttons = [{ title: '', value: '' }];
      }
      if (!props.selectedStep.branches) props.selectedStep.branches = {};
      buttonsOpen.value = true;
    } else {
      props.selectedStep.buttons = [];
      props.selectedStep.branches = {};
    }
  },
});

const branchTargetsForStep = computed(() => {
  if (!props.selectedStep) return props.stepTargets;
  return props.stepTargets.filter(o => o.id !== props.selectedStep.id);
});

const nextTargetsForStep = computed(() => branchTargetsForStep.value);

const canAddButton = computed(
  () => (props.selectedStep?.buttons || []).length < MAX_BUTTONS
);

const onButtonTitleInput = (btn, index) => {
  if (!props.selectedStep) return;
  if (!props.selectedStep.branches) props.selectedStep.branches = {};
  if ((btn.title || '').trim() && !props.selectedStep.branches[index]) {
    props.selectedStep.branches[index] = 'end';
  }
};

const addButton = () => {
  if (!props.selectedStep || !canAddButton.value) return;
  if (!props.selectedStep.buttons) props.selectedStep.buttons = [];
  if (!props.selectedStep.branches) props.selectedStep.branches = {};
  const index = props.selectedStep.buttons.length;
  props.selectedStep.buttons.push({ title: '', value: '' });
  props.selectedStep.branches[index] = 'end';
};

const removeButton = index => {
  if (!props.selectedStep?.buttons) return;
  const oldBranches = { ...(props.selectedStep.branches || {}) };
  props.selectedStep.buttons.splice(index, 1);
  const cleaned = {};
  props.selectedStep.buttons.forEach((_, i) => {
    const sourceIndex = i < index ? i : i + 1;
    cleaned[i] = oldBranches[sourceIndex] || 'end';
  });
  props.selectedStep.branches = cleaned;
};
</script>

<template>
  <div
    class="p-3 bg-n-solid-2 border border-n-weak rounded-lg shadow-sm h-full min-h-0 flex flex-col overflow-y-auto overflow-x-hidden"
  >
    <p class="m-0 text-sm font-medium text-n-slate-12">
      {{ t('FLOWS.EDIT.STEP_PROPERTIES') }}
    </p>

    <template v-if="selectedStep">
      <p class="mt-0.5 mb-2 text-xs text-n-slate-11">
        {{
          t('FLOWS.EDIT.STEP_N', {
            n: selectedStepIndex >= 0 ? selectedStepIndex + 1 : '?',
          })
        }}
      </p>

      <label class="mb-2 block">
        <span class="mb-0.5 block text-xs text-n-slate-11">
          {{ t('FLOWS.EDIT.NODE_NAME') }}
        </span>
        <input
          v-model="selectedStep.title"
          type="text"
          class="mb-0 w-full"
          :placeholder="t('FLOWS.EDIT.NODE_NAME_PLACEHOLDER')"
        />
      </label>

      <details
        class="mb-2 rounded-md border border-n-weak group"
        :open="actionsOpen"
        @toggle="actionsOpen = $event.target.open"
      >
        <summary
          class="cursor-pointer list-none px-2.5 py-1.5 text-xs font-medium text-n-slate-12 flex items-center justify-between gap-2"
        >
          <span>{{ t('FLOWS.EDIT.SECTION_ACTIONS') }}</span>
          <span
            class="i-lucide-chevron-down size-3.5 text-n-slate-11 transition-transform group-open:rotate-180"
          />
        </summary>
        <div
          class="px-2.5 pb-2.5 flex flex-col gap-2 [&_li]:!py-0 [&_.ProseMirror-menubar-wrapper]:max-w-full [&_.ProseMirror-menubar-wrapper]:overflow-x-auto"
        >
          <div
            v-for="(action, aIndex) in selectedStep.actions"
            :key="`${selectedStep.id}_${aIndex}_${action.action_name}`"
            class="flex flex-col gap-1 rounded-md border border-n-weak bg-n-solid-1 px-2 py-1.5 min-w-0"
          >
            <div class="flex items-center justify-between gap-1 min-h-5">
              <p
                class="m-0 text-[11px] font-medium leading-none text-n-slate-11"
              >
                {{ t('FLOWS.EDIT.ACTION_N', { n: aIndex + 1 }) }}
              </p>
              <NextButton
                v-if="selectedStep.actions.length > 1"
                v-tooltip="t('FLOWS.EDIT.DELETE_ACTION_TOOLTIP')"
                icon="i-lucide-trash-2"
                xs
                ghost
                ruby
                @click="emit('remove-action', selectedStep, aIndex)"
              />
            </div>
            <div class="min-w-0 overflow-visible">
              <AutomationActionInput
                v-model="selectedStep.actions[aIndex]"
                :action-types="actionTypesForIndex(aIndex)"
                :dropdown-values="getActionDropdownValues(action.action_name)"
                :show-action-input="
                  showActionInput(flowActionTypes, action.action_name)
                "
                dropdown-max-height="max-h-80"
                is-macro
                @reset-action="emit('reset-action', selectedStep, aIndex)"
              />
            </div>
          </div>
          <NextButton
            xs
            faded
            teal
            icon="i-lucide-plus"
            :label="t('FLOWS.EDIT.ADD_ACTION')"
            :disabled="!canAddAction"
            @click="emit('add-action', selectedStep)"
          />
        </div>
      </details>

      <template v-if="!waitReplyEnabled">
        <label class="mb-2 block">
          <span class="mb-0.5 block text-xs text-n-slate-11">
            {{ t('FLOWS.EDIT.AFTER_ACTIONS') }}
          </span>
          <select v-model="selectedStep.next" class="mb-0">
            <option
              v-for="opt in nextTargetsForStep"
              :key="opt.id"
              :value="opt.id"
            >
              {{ opt.label }}
            </option>
          </select>
        </label>
      </template>
      <p v-else class="mb-2 text-[11px] leading-snug text-n-slate-11">
        {{ t('FLOWS.EDIT.AFTER_ACTIONS_WAIT_HINT') }}
      </p>

      <template v-if="stepHasSendMessage">
        <div
          class="mb-2 flex items-center justify-between gap-2 rounded-md border border-n-weak px-2.5 py-2"
        >
          <div class="min-w-0">
            <p class="m-0 text-xs font-medium text-n-slate-12">
              {{ t('FLOWS.EDIT.WAIT_REPLY_TOGGLE') }}
            </p>
            <p class="m-0 mt-0.5 text-[11px] leading-snug text-n-slate-11">
              {{ t('FLOWS.EDIT.WAIT_REPLY_HINT') }}
            </p>
          </div>
          <Switch v-model="waitReplyEnabled" />
        </div>

        <details
          v-if="waitReplyEnabled"
          class="rounded-md border border-n-weak group"
          :open="buttonsOpen"
          @toggle="buttonsOpen = $event.target.open"
        >
          <summary
            class="cursor-pointer list-none px-2.5 py-1.5 text-xs font-medium text-n-slate-12 flex items-center justify-between gap-2"
          >
            <span>{{ t('FLOWS.EDIT.SECTION_BUTTONS') }}</span>
            <span
              class="i-lucide-chevron-down size-3.5 text-n-slate-11 transition-transform group-open:rotate-180"
            />
          </summary>
          <div class="px-2.5 pb-2.5 flex flex-col gap-2">
            <div
              v-for="(btn, bIndex) in selectedStep.buttons"
              :key="bIndex"
              class="flex flex-col gap-1.5 rounded-md border border-n-amber-6 bg-n-amber-2/30 dark:bg-n-solid-amber px-2 py-1.5"
            >
              <div class="flex items-center justify-between gap-1 min-h-5">
                <p
                  class="m-0 text-[11px] font-medium leading-none text-n-amber-11"
                >
                  {{ t('FLOWS.EDIT.BUTTON_N', { n: bIndex + 1 }) }}
                </p>
                <NextButton
                  v-tooltip="t('FLOWS.EDIT.REMOVE_BUTTON')"
                  icon="i-lucide-trash-2"
                  xs
                  ghost
                  ruby
                  @click="removeButton(bIndex)"
                />
              </div>
              <div class="grid grid-cols-1 gap-1.5">
                <input
                  v-model="btn.title"
                  type="text"
                  class="mb-0"
                  :placeholder="t('FLOWS.EDIT.BUTTON_TITLE')"
                  @input="onButtonTitleInput(btn, bIndex)"
                />
                <input
                  v-model="btn.value"
                  type="text"
                  class="mb-0"
                  :placeholder="t('FLOWS.EDIT.BUTTON_VALUE')"
                />
              </div>
              <label v-if="btn.title" class="mb-0">
                <span class="mb-0.5 block text-[11px] text-n-slate-11">
                  {{ t('FLOWS.EDIT.BRANCH_TO') }}
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
            <NextButton
              xs
              faded
              teal
              icon="i-lucide-plus"
              :label="t('FLOWS.EDIT.ADD_BUTTON')"
              :disabled="!canAddButton"
              @click="addButton"
            />
          </div>
        </details>
      </template>
      <p v-else class="mt-1.5 mb-0 text-[11px] text-n-slate-11">
        {{ t('FLOWS.EDIT.NO_WAIT_WITHOUT_MESSAGE') }}
      </p>
    </template>
    <p v-else class="mt-1.5 mb-0 text-[11px] text-n-slate-11">
      {{ t('FLOWS.EDIT.NO_STEP_SELECTED') }}
    </p>
  </div>
</template>

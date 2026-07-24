<script setup>
import { useI18n } from 'vue-i18n';
import AutomationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { showActionInput } from 'dashboard/helper/automationHelper';
import { FLOW_ACTION_TYPES } from './constants';

const props = defineProps({
  steps: { type: Array, required: true },
  selectedStepId: { type: String, default: null },
  flowActionTypes: { type: Array, required: true },
  getActionDropdownValues: { type: Function, required: true },
});

const emit = defineEmits([
  'select-step',
  'add-step',
  'remove-step',
  'add-action',
  'remove-action',
  'reset-action',
]);

const { t } = useI18n();

const stepHasButtons = step =>
  (step.buttons || []).some(b => (b.title || '').trim());

const filledButtons = step =>
  (step.buttons || []).filter(b => (b.title || '').trim());

const stepLabel = step => {
  const send = (step.actions || []).find(a => a.action_name === 'send_message');
  if (send) {
    const content = Array.isArray(send.action_params)
      ? send.action_params[0]
      : send.action_params;
    if (typeof content === 'string' && content.trim()) {
      return content.slice(0, 40);
    }
  }
  const first = step.actions?.[0]?.action_name;
  const type = FLOW_ACTION_TYPES.find(a => a.key === first);
  return type ? t(`AUTOMATION.ACTIONS.${type.label}`) : step.id;
};

const targetLabel = (step, btnIndex) => {
  const target = step.branches?.[btnIndex];
  if (!target || target === 'end') return t('FLOWS.EDIT.BRANCH_END');
  if (target === 'handoff') return t('FLOWS.EDIT.BRANCH_HANDOFF');
  const dest = props.steps.find(s => s.id === target);
  if (!dest) return t('FLOWS.EDIT.BRANCH_END');
  const idx = props.steps.indexOf(dest);
  return t('FLOWS.EDIT.STEP_N', { n: idx + 1 });
};

const nextStepHint = index => {
  const next = props.steps[index + 1];
  if (!next) return t('FLOWS.EDIT.BRANCH_END');
  return t('FLOWS.EDIT.LINEAR_NEXT', {
    n: index + 2,
    label: stepLabel(next),
  });
};

const isSelected = step => props.selectedStepId === step.id;

const cardClass = step => [
  'flex-grow min-w-0 rounded-md shadow-sm outline outline-1 p-3 cursor-pointer transition-colors',
  isSelected(step)
    ? 'outline-n-brand bg-n-blue-2/40 dark:bg-n-solid-blue'
    : 'outline-n-weak bg-n-background dark:bg-n-solid-1 hover:outline-n-slate-6',
];
</script>

<template>
  <div class="flex flex-col gap-0 max-w-[50rem]">
    <div class="relative pb-8">
      <span
        class="bg-n-solid-blue text-n-blue-11 py-1 px-1.5 leading-none text-sm rounded-md"
      >
        {{ $t('FLOWS.EDIT.START_FLOW') }}
      </span>
      <div
        class="absolute top-full ltr:ml-6 rtl:mr-6 h-8 w-0 border-l border-dashed border-n-blue-7 dark:border-n-blue-11"
      />
    </div>

    <div v-for="(step, index) in steps" :key="step.id" class="relative pb-8">
      <div class="flex items-start w-full min-w-0">
        <div
          :class="cardClass(step)"
          role="button"
          tabindex="0"
          @click="emit('select-step', step.id)"
          @keydown.enter.prevent="emit('select-step', step.id)"
        >
          <div class="flex items-center justify-between mb-3 gap-2">
            <p class="text-sm font-medium text-n-slate-12">
              {{ $t('FLOWS.EDIT.STEP_N', { n: index + 1 }) }}
            </p>
            <span
              v-if="stepHasButtons(step)"
              class="text-xs text-n-amber-11 bg-n-amber-2 dark:bg-n-solid-amber px-1.5 py-0.5 rounded"
            >
              {{ $t('FLOWS.EDIT.HAS_BRANCHES') }}
            </span>
          </div>

          <div class="flex flex-col gap-3" @click.stop>
            <div
              v-for="(action, aIndex) in step.actions"
              :key="`${step.id}_${aIndex}_${action.action_name}`"
              class="flex items-start gap-2"
            >
              <div class="flex-grow min-w-0">
                <AutomationActionInput
                  v-model="step.actions[aIndex]"
                  :action-types="flowActionTypes"
                  :dropdown-values="getActionDropdownValues(action.action_name)"
                  :show-action-input="
                    showActionInput(flowActionTypes, action.action_name)
                  "
                  is-macro
                  @reset-action="emit('reset-action', step, aIndex)"
                />
              </div>
              <NextButton
                v-if="step.actions.length > 1"
                v-tooltip="$t('FLOWS.EDIT.DELETE_ACTION_TOOLTIP')"
                icon="i-lucide-trash-2"
                sm
                faded
                ruby
                class="flex-shrink-0 mt-1"
                @click="emit('remove-action', step, aIndex)"
              />
            </div>
          </div>

          <NextButton
            class="mt-3"
            sm
            faded
            teal
            icon="i-lucide-plus"
            :label="$t('FLOWS.EDIT.ADD_ACTION')"
            @click.stop="emit('add-action', step)"
          />

          <!-- Branch fork preview (edit in right panel) -->
          <div
            v-if="stepHasButtons(step)"
            class="mt-4 pt-3 border-t border-dashed border-n-weak"
            @click.stop="emit('select-step', step.id)"
          >
            <p class="mb-2 text-xs font-medium text-n-slate-11">
              {{ $t('FLOWS.EDIT.BRANCHES_PREVIEW') }}
            </p>
            <div class="flex flex-wrap gap-2">
              <div
                v-for="(btn, bIndex) in filledButtons(step)"
                :key="`${step.id}_fork_${bIndex}`"
                class="flex items-center gap-1.5 rounded-md border border-n-weak bg-n-alpha-1 dark:bg-n-solid-3 px-2 py-1.5 max-w-full"
              >
                <span
                  class="text-xs font-medium text-n-slate-12 truncate max-w-[8rem]"
                >
                  {{ btn.title }}
                </span>
                <span
                  class="i-lucide-arrow-right size-3 text-n-slate-10 flex-shrink-0"
                />
                <span class="text-xs text-n-slate-11 truncate max-w-[8rem]">
                  {{ targetLabel(step, step.buttons.indexOf(btn)) }}
                </span>
              </div>
            </div>
          </div>
          <p v-else class="mt-3 mb-0 text-xs text-n-slate-11">
            {{ nextStepHint(index) }}
          </p>
        </div>

        <NextButton
          v-if="steps.length > 1"
          v-tooltip="$t('FLOWS.EDIT.DELETE_BTN_TOOLTIP')"
          icon="i-lucide-trash-2"
          sm
          faded
          ruby
          class="flex-shrink-0 ltr:ml-2 rtl:mr-2"
          @click="emit('remove-step', index)"
        />
      </div>

      <!-- Connector: fork when branching, else straight -->
      <div
        v-if="stepHasButtons(step)"
        class="absolute bottom-0 ltr:left-6 rtl:right-6 flex flex-col items-start pointer-events-none"
      >
        <div
          class="h-3 w-0 border-l border-dashed border-n-amber-7 dark:border-n-amber-9"
        />
        <div class="flex items-center gap-1 -ml-px">
          <div
            class="h-0 w-4 border-t border-dashed border-n-amber-7 dark:border-n-amber-9"
          />
          <span class="text-[10px] leading-none text-n-amber-11">
            {{ $t('FLOWS.EDIT.FORK') }}
          </span>
        </div>
      </div>
      <div
        v-else
        class="absolute bottom-0 ltr:ml-6 rtl:mr-6 h-8 w-0 border-l border-dashed border-n-blue-7 dark:border-n-blue-11"
      />
    </div>

    <div class="relative pb-8">
      <NextButton
        class="shadow-sm"
        solid
        teal
        icon="i-lucide-plus-circle"
        :label="$t('FLOWS.EDIT.ADD_BTN_TOOLTIP')"
        @click="emit('add-step')"
      />
      <div
        class="absolute top-full ltr:ml-6 rtl:mr-6 h-8 w-0 border-l border-dashed border-n-blue-7 dark:border-n-blue-11"
      />
    </div>

    <div>
      <span
        class="bg-n-solid-blue text-n-blue-11 py-1 px-1.5 leading-none text-sm rounded-md"
      >
        {{ $t('FLOWS.EDIT.END_FLOW') }}
      </span>
    </div>
  </div>
</template>

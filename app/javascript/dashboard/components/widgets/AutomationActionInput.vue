<script setup>
import { computed, ref } from 'vue';
import AutomationActionTeamMessageInput from './AutomationActionTeamMessageInput.vue';
import AutomationActionFileInput from './AutomationFileInput.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  modelValue: {
    type: Object,
    default: () => null,
  },
  actionTypes: {
    type: Array,
    default: () => [],
  },
  dropdownValues: {
    type: Array,
    default: () => [],
  },
  errorMessage: {
    type: String,
    default: '',
  },
  showActionInput: {
    type: Boolean,
    default: true,
  },
  initialFileName: {
    type: String,
    default: '',
  },
  isMacro: {
    type: Boolean,
    default: false,
  },
  dropdownMaxHeight: {
    type: String,
    default: 'max-h-80',
  },
  // [{ key, label }] recommended actions for the action picker.
  recommendations: {
    type: Array,
    default: () => [],
  },
});
const emit = defineEmits([
  'update:modelValue',
  'input',
  'removeAction',
  'resetAction',
  'recommend',
]);
const CONTACT_EMAIL_TOKEN = '{{contact.email}}';
const VERTICAL_INPUT_TYPES = ['team_message', 'textarea', 'email'];

const actionPickerRef = ref(null);

const updateAction = changes => {
  const payload = { ...(props.modelValue || {}), ...changes };
  emit('update:modelValue', payload);
  emit('input', payload);
};

const actionName = computed({
  get: () => props.modelValue?.action_name ?? null,
  set: value => updateAction({ action_name: value }),
});

const actionParams = computed({
  get: () => props.modelValue?.action_params ?? null,
  set: value => updateAction({ action_params: value }),
});

const inputType = computed(
  () =>
    props.actionTypes.find(action => action.key === actionName.value)?.inputType
);

const actionNameAsSelectModel = computed(() => {
  if (!actionName.value) return null;
  const found = props.actionTypes.find(
    action => action.key === actionName.value
  );
  return found ? { id: found.key, name: found.label } : null;
});

const actionTypesAsOptions = computed(() =>
  props.actionTypes.map(action => ({
    id: action.key,
    name: action.label,
    icon: action.icon,
  }))
);

const isVerticalLayout = computed(() =>
  VERTICAL_INPUT_TYPES.includes(inputType.value)
);

const castMessageVmodel = computed({
  get: () =>
    Array.isArray(actionParams.value)
      ? actionParams.value[0]
      : actionParams.value,
  set: value => {
    actionParams.value = value;
  },
});

const removeAction = () => emit('removeAction');
const resetAction = () => emit('resetAction');

const onActionNameChange = value => {
  actionName.value = value?.id || value;
  resetAction();
};

const insertContactEmailToken = () => {
  const existingEmails = (castMessageVmodel.value || '')
    .split(',')
    .map(email => email.trim())
    .filter(Boolean);

  const hasContactEmail = existingEmails.some(
    email => email.replace(/\s+/g, '') === CONTACT_EMAIL_TOKEN
  );
  if (hasContactEmail) return;

  actionParams.value = [[...existingEmails, CONTACT_EMAIL_TOKEN].join(',')];
};

// Opens the action picker, such as on a row added for the next recommendation.
const openActionPicker = () => actionPickerRef.value?.open();

defineExpose({ openActionPicker });
</script>

<template>
  <li class="list-none py-2 first:pt-0 last:pb-0">
    <div
      class="flex flex-col gap-2"
      :class="{ 'animate-wiggle': errorMessage }"
    >
      <div class="flex items-center gap-2">
        <SingleSelect
          ref="actionPickerRef"
          :model-value="actionNameAsSelectModel"
          :options="actionTypesAsOptions"
          :dropdown-max-height="dropdownMaxHeight"
          :recommendations="recommendations"
          :recommendations-options-label="$t('FILTER.ALL_ACTIONS')"
          disable-deselect
          class="flex-shrink-0"
          @update:model-value="onActionNameChange"
          @recommend="key => emit('recommend', key)"
        />
        <template v-if="showActionInput && !isVerticalLayout">
          <SingleSelect
            v-if="inputType === 'search_select'"
            v-model="actionParams"
            :options="dropdownValues"
            :dropdown-max-height="dropdownMaxHeight"
          />
          <MultiSelect
            v-else-if="inputType === 'multi_select'"
            v-model="actionParams"
            :options="dropdownValues"
            :dropdown-max-height="dropdownMaxHeight"
          />
          <NextInput
            v-else-if="inputType === 'url'"
            v-model="actionParams"
            type="url"
            size="sm"
            :placeholder="$t('AUTOMATION.ACTION.URL_INPUT_PLACEHOLDER')"
          />
          <AutomationActionFileInput
            v-else-if="inputType === 'attachment'"
            v-model="actionParams"
            :initial-file-name="initialFileName"
          />
        </template>
        <NextButton
          v-if="!isMacro"
          sm
          solid
          slate
          icon="i-lucide-trash"
          class="flex-shrink-0"
          @click="removeAction"
        />
      </div>
      <div v-if="inputType === 'email'" class="flex items-center w-full gap-2">
        <NextInput
          v-model="actionParams"
          type="text"
          size="sm"
          class="flex-1"
          :placeholder="$t('AUTOMATION.ACTION.EMAIL_INPUT_PLACEHOLDER')"
        />
        <NextButton
          sm
          faded
          slate
          class="flex-shrink-0 whitespace-nowrap"
          :label="$t('AUTOMATION.ACTION.INSERT_CONTACT_EMAIL')"
          @click="insertContactEmailToken"
        />
      </div>
      <AutomationActionTeamMessageInput
        v-else-if="inputType === 'team_message'"
        v-model="actionParams"
        :teams="dropdownValues"
        :dropdown-max-height="dropdownMaxHeight"
      />
      <WootMessageEditor
        v-else-if="inputType === 'textarea'"
        v-model="castMessageVmodel"
        rows="4"
        enable-variables
        :placeholder="$t('AUTOMATION.ACTION.TEAM_MESSAGE_INPUT_PLACEHOLDER')"
        class="[&_.ProseMirror-menubar]:hidden px-3 py-1 bg-n-alpha-1 rounded-lg outline outline-1 outline-n-weak dark:outline-n-strong"
      />
    </div>
    <span v-if="errorMessage" class="text-sm text-n-ruby-11">
      {{ errorMessage }}
    </span>
  </li>
</template>

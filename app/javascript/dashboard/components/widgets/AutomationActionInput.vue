<script>
import AutomationActionTeamMessageInput from './AutomationActionTeamMessageInput.vue';
import AutomationActionFileInput from './AutomationFileInput.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';

const CONTACT_EMAIL_TOKEN = '{{contact.email}}';

export default {
  components: {
    AutomationActionTeamMessageInput,
    AutomationActionFileInput,
    WootMessageEditor,
    NextButton,
    SingleSelect,
    MultiSelect,
    NextInput,
  },
  props: {
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
  },
  emits: ['update:modelValue', 'input', 'removeAction', 'resetAction'],
  computed: {
    action_name: {
      get() {
        if (!this.modelValue) return null;
        return this.modelValue.action_name;
      },
      set(value) {
        const payload = this.modelValue || {};
        this.$emit('update:modelValue', { ...payload, action_name: value });
        this.$emit('input', { ...payload, action_name: value });
      },
    },
    action_params: {
      get() {
        if (!this.modelValue) return null;
        return this.modelValue.action_params;
      },
      set(value) {
        const payload = this.modelValue || {};
        this.$emit('update:modelValue', { ...payload, action_params: value });
        this.$emit('input', { ...payload, action_params: value });
      },
    },
    inputType() {
      return this.actionTypes.find(action => action.key === this.action_name)
        .inputType;
    },
    actionNameAsSelectModel: {
      get() {
        if (!this.action_name) return null;
        const found = this.actionTypes.find(a => a.key === this.action_name);
        return found ? { id: found.key, name: found.label } : null;
      },
      set(value) {
        this.action_name = value?.id || value;
      },
    },
    actionTypesAsOptions() {
      return this.actionTypes.map(a => ({
        id: a.key,
        name: a.label,
        icon: a.icon,
      }));
    },
    isVerticalLayout() {
      return ['team_message', 'textarea', 'email'].includes(this.inputType);
    },
    castMessageVmodel: {
      get() {
        if (Array.isArray(this.action_params)) {
          return this.action_params[0];
        }
        return this.action_params;
      },
      set(value) {
        this.action_params = value;
      },
    },
  },
  methods: {
    removeAction() {
      this.$emit('removeAction');
    },
    resetAction() {
      this.$emit('resetAction');
    },
    onActionNameChange(value) {
      this.actionNameAsSelectModel = value;
      this.resetAction();
    },
    insertContactEmailToken() {
      const existingEmails = (this.castMessageVmodel || '')
        .split(',')
        .map(email => email.trim())
        .filter(Boolean);

      const hasContactEmail = existingEmails.some(
        email => email.replace(/\s+/g, '') === CONTACT_EMAIL_TOKEN
      );
      if (hasContactEmail) return;

      this.action_params = [[...existingEmails, CONTACT_EMAIL_TOKEN].join(',')];
    },
  },
};
</script>

<template>
  <li class="list-none py-2 first:pt-0 last:pb-0">
    <div
      class="flex flex-col gap-2"
      :class="{ 'animate-wiggle': errorMessage }"
    >
      <div class="flex items-center gap-2">
        <SingleSelect
          :model-value="actionNameAsSelectModel"
          :options="actionTypesAsOptions"
          :dropdown-max-height="dropdownMaxHeight"
          disable-deselect
          class="flex-shrink-0"
          @update:model-value="onActionNameChange"
        />
        <template v-if="showActionInput && !isVerticalLayout">
          <SingleSelect
            v-if="inputType === 'search_select'"
            v-model="action_params"
            :options="dropdownValues"
            :dropdown-max-height="dropdownMaxHeight"
          />
          <MultiSelect
            v-else-if="inputType === 'multi_select'"
            v-model="action_params"
            :options="dropdownValues"
            :dropdown-max-height="dropdownMaxHeight"
          />
          <NextInput
            v-else-if="inputType === 'url'"
            v-model="action_params"
            type="url"
            size="sm"
            :placeholder="$t('AUTOMATION.ACTION.URL_INPUT_PLACEHOLDER')"
          />
          <AutomationActionFileInput
            v-else-if="inputType === 'attachment'"
            v-model="action_params"
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
          v-model="action_params"
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
        v-model="action_params"
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

<script>
import AutomationActionTeamMessageInput from './AutomationActionTeamMessageInput.vue';
import AutomationActionCustomAttributeInput from './AutomationActionCustomAttributeInput.vue';
import AutomationActionWhatsAppTemplateInput from './AutomationActionWhatsAppTemplateInput.vue';
import AutomationActionFileInput from './AutomationFileInput.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';
import NextInput from 'dashboard/components-next/input/Input.vue';
import InsertVariableButton from 'dashboard/components-next/variable/InsertVariableButton.vue';

const DEFAULT_DELIVERY = { delay_seconds: 0, mark_read_and_typing: false };

const CONTACT_EMAIL_TOKEN = '{{contact.email}}';

export default {
  components: {
    AutomationActionTeamMessageInput,
    AutomationActionCustomAttributeInput,
    AutomationActionWhatsAppTemplateInput,
    AutomationActionFileInput,
    WootMessageEditor,
    NextButton,
    SingleSelect,
    MultiSelect,
    NextInput,
    InsertVariableButton,
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
    delivery: {
      get() {
        return {
          ...DEFAULT_DELIVERY,
          ...(this.modelValue?.delivery || {}),
        };
      },
      set(value) {
        const payload = this.modelValue || {};
        this.$emit('update:modelValue', { ...payload, delivery: value });
        this.$emit('input', { ...payload, delivery: value });
      },
    },
    delaySeconds: {
      get() {
        return Number(this.delivery.delay_seconds) || 0;
      },
    },
    markReadAndTyping: {
      get() {
        return Boolean(this.delivery.mark_read_and_typing);
      },
    },
    showDeliveryOptions() {
      return ['textarea', 'attachment'].includes(this.inputType);
    },
    inputType() {
      return this.actionTypes.find(action => action.key === this.action_name)
        ?.inputType;
    },
    isCustomAttributeAction() {
      return [
        'update_contact_custom_attribute',
        'update_conversation_custom_attribute',
      ].includes(this.action_name);
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
      return (
        this.isCustomAttributeAction ||
        [
          'team_message',
          'textarea',
          'custom_attribute',
          'whatsapp_template',
          'email',
        ].includes(this.inputType)
      );
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
      const actionName = value?.id || value;
      const supportsDelivery = ['send_message', 'send_attachment'].includes(
        actionName
      );

      // Single atomic update so the custom-attribute panel mounts with the
      // new action_name (avoid resetAction wiping state in a second tick).
      const payload = {
        action_name: actionName,
        action_params: this.defaultActionParams(actionName),
        delivery: supportsDelivery ? { ...DEFAULT_DELIVERY } : undefined,
      };
      this.$emit('update:modelValue', payload);
      this.$emit('input', payload);
    },
    defaultActionParams(actionName) {
      if (
        [
          'update_contact_custom_attribute',
          'update_conversation_custom_attribute',
        ].includes(actionName)
      ) {
        return { attribute_key: '', value: '' };
      }
      if (actionName === 'send_whatsapp_template') return {};
      return [];
    },
    insertMessageVariable(token) {
      const current = this.castMessageVmodel || '';
      this.castMessageVmodel = current ? `${current} ${token}` : token;
    },
    updateDelivery(partial) {
      const next = { ...this.delivery, ...partial };
      const delay = Math.min(25, Math.max(0, Number(next.delay_seconds) || 0));
      next.delay_seconds = delay;
      if (delay < 1) {
        next.mark_read_and_typing = false;
      }
      this.delivery = next;
    },
    onDelayInput(event) {
      this.updateDelivery({ delay_seconds: event.target.value });
    },
    onMarkReadChange(event) {
      this.updateDelivery({ mark_read_and_typing: event.target.checked });
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
      <AutomationActionWhatsAppTemplateInput
        v-if="
          inputType === 'whatsapp_template' ||
          action_name === 'send_whatsapp_template'
        "
        v-model="action_params"
        :dropdown-max-height="dropdownMaxHeight"
      />
      <AutomationActionCustomAttributeInput
        v-if="isCustomAttributeAction || inputType === 'custom_attribute'"
        v-model="action_params"
        :attributes="dropdownValues || []"
        :attribute-model="
          action_name === 'update_conversation_custom_attribute'
            ? 'conversation_attribute'
            : 'contact_attribute'
        "
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
      <div
        v-if="inputType === 'textarea'"
        class="flex items-center justify-between gap-2 mt-1"
      >
        <span class="text-xs text-n-slate-11">
          {{ $t('AUTOMATION.ACTION.VARIABLES_HINT') }}
        </span>
        <InsertVariableButton @insert="insertMessageVariable" />
      </div>
      <div
        v-if="showDeliveryOptions"
        class="flex flex-col gap-1.5 rounded-lg border border-dashed border-n-weak px-3 py-2"
      >
        <div class="flex flex-wrap items-center gap-4">
          <label class="flex items-center gap-2 text-xs text-n-slate-12">
            <span>{{ $t('AUTOMATION.ACTION.DELAY_SECONDS_LABEL') }}</span>
            <input
              type="number"
              min="0"
              max="25"
              class="h-7 w-16 rounded-md border border-n-strong bg-n-background px-2 text-xs"
              :value="delaySeconds"
              @input="onDelayInput"
            />
          </label>
          <label
            class="flex items-center gap-2 text-xs text-n-slate-12"
            :class="{ 'opacity-50': delaySeconds < 1 }"
          >
            <input
              type="checkbox"
              class="rounded border-n-strong"
              :disabled="delaySeconds < 1"
              :checked="markReadAndTyping"
              @change="onMarkReadChange"
            />
            <span>{{ $t('AUTOMATION.ACTION.MARK_READ_TYPING_LABEL') }}</span>
          </label>
        </div>
        <p class="mb-0 text-xs text-n-slate-11">
          {{ $t('AUTOMATION.ACTION.DELIVERY_HINT') }}
        </p>
      </div>
    </div>
    <span v-if="errorMessage" class="text-sm text-n-ruby-11">
      {{ errorMessage }}
    </span>
  </li>
</template>

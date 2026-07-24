<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { convertToAttributeSlug } from 'dashboard/helper/commons.js';
import { normalizeRegexPattern } from 'shared/helpers/Validators';
import { ATTRIBUTE_MODELS, ATTRIBUTE_TYPES, FORMULA_OPS } from './constants';

import NextButton from 'dashboard/components-next/button/Button.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

export default {
  components: {
    NextButton,
    TagInput,
  },
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
    // Passes 0 or 1 based on the selected AttributeModel tab selected in the UI
    // Needs a better data type, todo: refactor this component later
    selectedAttributeModelTab: {
      type: Number,
      default: 0,
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      displayName: '',
      description: '',
      // Using the prop as default. There is no side effect here as the component
      // is destroyed completely when the modal is closed. The prop doesn't change
      // dynamically when the modal is active.
      attributeModel: this.selectedAttributeModelTab || 0,
      attributeType: 0,
      attributeKey: '',
      regexPattern: null,
      regexCue: null,
      regexEnabled: false,
      values: [],
      show: true,
      tagInputTouched: false,
      featured: false,
      formulaEnabled: false,
      formulaOp: 'sum',
      formulaSourceKey: '',
    };
  },

  computed: {
    ...mapGetters({
      uiFlags: 'getUIFlags',
      getAttributesByModel: 'attributes/getAttributesByModel',
    }),
    models() {
      return ATTRIBUTE_MODELS.map(item => ({
        ...item,
        option: this.$t(`ATTRIBUTES_MGMT.ATTRIBUTE_MODELS.${item.key}`),
      }));
    },
    types() {
      return ATTRIBUTE_TYPES.map(item => ({
        ...item,
        option: this.$t(`ATTRIBUTES_MGMT.ATTRIBUTE_TYPES.${item.key}`),
      }));
    },
    formulaOps() {
      return FORMULA_OPS.map(item => ({
        ...item,
        option: this.$t(`ATTRIBUTES_MGMT.FORMULA.OP.${item.key}`),
      }));
    },
    isContactModel() {
      return this.attributeModel === 1;
    },
    conversationNumericAttributes() {
      const defs = this.getAttributesByModel('conversation_attribute') || [];
      return defs.filter(def =>
        ['number', 'currency'].includes(def.attribute_display_type)
      );
    },
    isTagInputEmpty() {
      return this.isAttributeTypeList && this.values.length === 0;
    },
    isTagInputInvalid() {
      return this.tagInputTouched && this.isTagInputEmpty;
    },
    attributeListValues() {
      return this.values;
    },
    isButtonDisabled() {
      return (
        this.v$.displayName.$invalid ||
        this.v$.description.$invalid ||
        this.uiFlags.isCreating ||
        this.isTagInputEmpty
      );
    },
    keyErrorMessage() {
      if (!this.v$.attributeKey.isKey) {
        return this.$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.IN_VALID');
      }
      return this.$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.ERROR');
    },
    isAttributeTypeList() {
      return this.attributeType === 6 || this.attributeType === 9;
    },
    isAttributeTypeText() {
      return this.attributeType === 0;
    },
    isRegexEnabled() {
      return this.regexEnabled;
    },
  },

  validations: {
    displayName: { required, minLength: minLength(1) },
    description: { required },
    attributeModel: { required },
    attributeType: { required },
    attributeKey: {
      required,
      isKey(value) {
        return !(value.indexOf(' ') >= 0);
      },
    },
  },

  watch: {
    attributeType() {
      this.tagInputTouched = false;
      this.values = [];
    },
  },

  methods: {
    onDisplayNameChange() {
      this.attributeKey = convertToAttributeSlug(this.displayName);
    },
    toggleRegexEnabled() {
      this.regexEnabled = !this.regexEnabled;
    },
    async addAttributes() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      if (!this.regexEnabled) {
        this.regexPattern = null;
        this.regexCue = null;
      }
      try {
        await this.$store.dispatch('attributes/create', {
          attribute_display_name: this.displayName,
          attribute_description: this.description,
          attribute_model: this.attributeModel,
          attribute_display_type: this.attributeType,
          attribute_key: this.attributeKey,
          attribute_values: this.attributeListValues,
          regex_pattern: normalizeRegexPattern(this.regexPattern),
          regex_cue: this.regexCue,
          featured: this.featured,
          formula:
            this.isContactModel && this.formulaEnabled && this.formulaSourceKey
              ? {
                  op: this.formulaOp,
                  source_attribute_key: this.formulaSourceKey,
                  source_model: 'conversation',
                }
              : null,
        });
        this.alertMessage = this.$t('ATTRIBUTES_MGMT.ADD.API.SUCCESS_MESSAGE');
        this.onClose();
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage || this.$t('ATTRIBUTES_MGMT.ADD.API.ERROR_MESSAGE');
      } finally {
        useAlert(this.alertMessage);
      }
    },
  },
};
</script>

<template>
  <woot-modal v-model:show="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="$t('ATTRIBUTES_MGMT.ADD.TITLE')" />

      <form class="flex w-full" @submit.prevent="addAttributes">
        <div class="w-full">
          <label :class="{ error: v$.attributeModel.$error }">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.MODEL.LABEL') }}
            <select v-model="attributeModel">
              <option v-for="model in models" :key="model.id" :value="model.id">
                {{ model.option }}
              </option>
            </select>
            <span v-if="v$.attributeModel.$error" class="message">
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.MODEL.ERROR') }}
            </span>
          </label>
          <woot-input
            v-model="displayName"
            :label="$t('ATTRIBUTES_MGMT.ADD.FORM.NAME.LABEL')"
            type="text"
            :class="{ error: v$.displayName.$error }"
            :error="
              v$.displayName.$error
                ? $t('ATTRIBUTES_MGMT.ADD.FORM.NAME.ERROR')
                : ''
            "
            :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
            @update:model-value="onDisplayNameChange"
            @blur="v$.displayName.$touch"
          />
          <woot-input
            v-model="attributeKey"
            :label="$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.LABEL')"
            type="text"
            :class="{ error: v$.attributeKey.$error }"
            :error="v$.attributeKey.$error ? keyErrorMessage : ''"
            :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.PLACEHOLDER')"
            @blur="v$.attributeKey.$touch"
          />
          <label :class="{ error: v$.description.$error }">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.DESC.LABEL') }}
            <textarea
              v-model="description"
              rows="3"
              type="text"
              :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.DESC.PLACEHOLDER')"
              @blur="v$.description.$touch"
            />
            <span v-if="v$.description.$error" class="message">
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.DESC.ERROR') }}
            </span>
          </label>
          <label :class="{ error: v$.attributeType.$error }">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LABEL') }}
            <select v-model="attributeType">
              <option v-for="type in types" :key="type.id" :value="type.id">
                {{ type.option }}
              </option>
            </select>
            <span v-if="v$.attributeType.$error" class="message">
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.ERROR') }}
            </span>
          </label>
          <div v-if="isAttributeTypeList" class="mb-4">
            <label class="mb-1 block">
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.LABEL') }}
            </label>
            <div
              class="rounded-xl border px-3 py-2"
              :class="isTagInputInvalid ? 'border-n-ruby-9' : 'border-n-weak'"
            >
              <TagInput
                v-model="values"
                :placeholder="
                  $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.PLACEHOLDER')
                "
                allow-create
                @blur="tagInputTouched = true"
              />
            </div>
            <label
              v-show="isTagInputInvalid"
              class="text-n-ruby-9 dark:text-n-ruby-9 text-sm font-normal mt-1"
            >
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.ERROR') }}
            </label>
          </div>
          <div v-if="isAttributeTypeText">
            <input
              v-model="regexEnabled"
              type="checkbox"
              @input="toggleRegexEnabled"
            />
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.ENABLE_REGEX.LABEL') }}
          </div>
          <woot-input
            v-if="isAttributeTypeText && isRegexEnabled"
            v-model="regexPattern"
            :label="$t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_PATTERN.LABEL')"
            type="text"
            :placeholder="
              $t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_PATTERN.PLACEHOLDER')
            "
          />
          <woot-input
            v-if="isAttributeTypeText && isRegexEnabled"
            v-model="regexCue"
            :label="$t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_CUE.LABEL')"
            type="text"
            :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.REGEX_CUE.PLACEHOLDER')"
          />
          <div class="mb-4">
            <label class="flex items-center gap-2">
              <input v-model="featured" type="checkbox" />
              {{ $t('ATTRIBUTES_MGMT.FEATURED.LABEL') }}
            </label>
            <p class="text-sm text-n-slate-11 mb-0 mt-1">
              {{ $t('ATTRIBUTES_MGMT.FEATURED.HELP') }}
            </p>
          </div>
          <div v-if="isContactModel" class="mb-4">
            <label class="flex items-center gap-2">
              <input v-model="formulaEnabled" type="checkbox" />
              {{ $t('ATTRIBUTES_MGMT.FORMULA.ENABLE') }}
            </label>
            <p class="text-sm text-n-slate-11 mb-2 mt-1">
              {{ $t('ATTRIBUTES_MGMT.FORMULA.HELP') }}
            </p>
            <template v-if="formulaEnabled">
              <label>
                {{ $t('ATTRIBUTES_MGMT.FORMULA.OP.LABEL') }}
                <select v-model="formulaOp">
                  <option v-for="op in formulaOps" :key="op.id" :value="op.id">
                    {{ op.option }}
                  </option>
                </select>
              </label>
              <label>
                {{ $t('ATTRIBUTES_MGMT.FORMULA.SOURCE.LABEL') }}
                <select v-model="formulaSourceKey">
                  <option value="">
                    {{ $t('ATTRIBUTES_MGMT.FORMULA.SOURCE.PLACEHOLDER') }}
                  </option>
                  <option
                    v-for="attr in conversationNumericAttributes"
                    :key="attr.attribute_key"
                    :value="attr.attribute_key"
                  >
                    {{ attr.attribute_display_name }}
                  </option>
                </select>
              </label>
            </template>
          </div>
          <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
            <NextButton
              faded
              slate
              type="reset"
              :label="$t('ATTRIBUTES_MGMT.ADD.CANCEL_BUTTON_TEXT')"
              @click.prevent="onClose"
            />
            <NextButton
              type="submit"
              :label="$t('ATTRIBUTES_MGMT.ADD.SUBMIT')"
              :disabled="isButtonDisabled"
            />
          </div>
        </div>
      </form>
    </div>
  </woot-modal>
</template>

<style lang="scss" scoped>
.key-value {
  padding: 0 0.5rem 0.5rem 0;
  font-family: monospace;
}
</style>

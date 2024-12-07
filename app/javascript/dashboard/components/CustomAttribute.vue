<script>
import { format, parseISO } from 'date-fns';
import { required, url } from '@vuelidate/validators';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import HelperTextPopup from 'dashboard/components/ui/HelperTextPopup.vue';
import { isValidURL } from '../helper/URLHelper';
import { getRegexp } from 'shared/helpers/Validators';
import { useVuelidate } from '@vuelidate/core';
import { emitter } from 'shared/helpers/mitt';

const DATE_FORMAT = 'yyyy-MM-dd';

export default {
  components: {
    MultiselectDropdown,
    HelperTextPopup,
  },
  props: {
    label: { type: String, required: true },
    description: { type: String, default: '' },
    values: { type: Array, default: () => [] },
    value: { type: [String, Number, Boolean], default: '' },
    showActions: { type: Boolean, default: false },
    attributeType: { type: String, default: 'text' },
    attributeRegex: {
      type: String,
      default: null,
    },
    regexCue: { type: String, default: null },
    attributeKey: { type: String, required: true },
    contactId: { type: Number, default: null },
  },
  emits: ['update', 'delete', 'copy'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      isEditing: false,
      editedValue: null,
    };
  },
  computed: {
    displayValue() {
      if (this.isAttributeTypeDate) {
        return this.value
          ? new Date(this.value || new Date()).toLocaleDateString()
          : '';
      }
      if (this.isAttributeTypeCheckbox) {
        return this.value === 'false' ? false : this.value;
      }
      return this.value;
    },
    formattedValue() {
      return this.isAttributeTypeDate
        ? format(this.value ? new Date(this.value) : new Date(), DATE_FORMAT)
        : this.value;
    },
    listOptions() {
      return this.values.map((value, index) => ({
        id: index + 1,
        name: value,
      }));
    },
    selectedItem() {
      const id = this.values.indexOf(this.editedValue) + 1;
      return { id, name: this.editedValue };
    },
    isAttributeTypeCheckbox() {
      return this.attributeType === 'checkbox';
    },
    isAttributeTypeList() {
      return this.attributeType === 'list';
    },
    isAttributeTypeLink() {
      return this.attributeType === 'link';
    },
    isAttributeTypeDate() {
      return this.attributeType === 'date';
    },
    urlValue() {
      return isValidURL(this.value) ? this.value : '---';
    },
    hrefURL() {
      return isValidURL(this.value) ? this.value : '';
    },
    notAttributeTypeCheckboxAndList() {
      return !this.isAttributeTypeCheckbox && !this.isAttributeTypeList;
    },
    inputType() {
      return this.isAttributeTypeLink ? 'url' : this.attributeType;
    },
    shouldShowErrorMessage() {
      return this.v$.editedValue.$error;
    },
    errorMessage() {
      if (this.v$.editedValue.url) {
        return this.$t('CUSTOM_ATTRIBUTES.VALIDATIONS.INVALID_URL');
      }
      if (!this.v$.editedValue.regexValidation) {
        return this.regexCue
          ? this.regexCue
          : this.$t('CUSTOM_ATTRIBUTES.VALIDATIONS.INVALID_INPUT');
      }
      return this.$t('CUSTOM_ATTRIBUTES.VALIDATIONS.REQUIRED');
    },
  },
  watch: {
    value() {
      this.isEditing = false;
      this.editedValue = this.formattedValue;
    },
    contactId() {
      // Fix to solve validation not resetting when contactId changes in contact page
      this.v$.$reset();
    },
  },

  validations() {
    if (this.isAttributeTypeLink) {
      return {
        editedValue: { required, url },
      };
    }
    return {
      editedValue: {
        required,
        regexValidation: value => {
          return !(
            this.attributeRegex && !getRegexp(this.attributeRegex).test(value)
          );
        },
      },
    };
  },
  mounted() {
    this.editedValue = this.formattedValue;
    emitter.on(BUS_EVENTS.FOCUS_CUSTOM_ATTRIBUTE, this.onFocusAttribute);
  },
  unmounted() {
    emitter.off(BUS_EVENTS.FOCUS_CUSTOM_ATTRIBUTE, this.onFocusAttribute);
  },
  methods: {
    onFocusAttribute(focusAttributeKey) {
      if (this.attributeKey === focusAttributeKey) {
        this.onEdit();
      }
    },
    focusInput() {
      if (this.$refs.inputfield) {
        this.$refs.inputfield.focus();
      }
    },
    onClickAway() {
      this.v$.$reset();
      this.isEditing = false;
    },
    onEdit() {
      this.isEditing = true;
      this.$nextTick(() => {
        this.focusInput();
      });
    },
    onUpdateListValue(value) {
      if (value) {
        this.editedValue = value.name;
        this.onUpdate();
      }
    },
    onUpdate() {
      const updatedValue =
        this.attributeType === 'date'
          ? parseISO(this.editedValue)
          : this.editedValue;
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      this.isEditing = false;
      this.$emit('update', this.attributeKey, updatedValue);
    },
    onDelete() {
      this.isEditing = false;
      this.v$.$reset();
      this.$emit('delete', this.attributeKey);
    },
    onCopy() {
      this.$emit('copy', this.value);
    },
  },
};
</script>

<template>
  <div class="px-4 py-3">
    <div class="flex items-center mb-1">
      <h4 class="flex items-center w-full m-0 text-sm error">
        <div v-if="isAttributeTypeCheckbox" class="flex items-center">
          <input
            v-model="editedValue"
            class="!my-0 mr-2 ml-0"
            type="checkbox"
            @change="onUpdate"
          />
        </div>
        <div class="flex items-center justify-between w-full">
          <span
            class="w-full inline-flex gap-1.5 items-start font-medium whitespace-nowrap text-sm mb-0"
            :class="
              v$.editedValue.$error
                ? 'text-red-400 dark:text-red-500'
                : 'text-slate-800 dark:text-slate-100'
            "
          >
            {{ label }}
            <HelperTextPopup
              v-if="description"
              :message="description"
              class="mt-0.5"
            />
          </span>
          <woot-button
            v-if="showActions && value"
            v-tooltip.left="$t('CUSTOM_ATTRIBUTES.ACTIONS.DELETE')"
            variant="link"
            size="medium"
            color-scheme="secondary"
            icon="delete"
            class-names="flex justify-end w-4"
            @click="onDelete"
          />
        </div>
      </h4>
    </div>
    <div v-if="notAttributeTypeCheckboxAndList">
      <div v-if="isEditing" v-on-clickaway="onClickAway">
        <div class="flex items-center w-full mb-2">
          <input
            ref="inputfield"
            v-model="editedValue"
            :type="inputType"
            class="!h-8 ltr:!rounded-r-none rtl:!rounded-l-none !mb-0 !text-sm"
            autofocus="true"
            :class="{ error: v$.editedValue.$error }"
            @blur="v$.editedValue.$touch"
            @keyup.enter="onUpdate"
          />
          <div>
            <woot-button
              size="small"
              icon="checkmark"
              class="rounded-l-none rtl:rounded-r-none"
              @click="onUpdate"
            />
          </div>
        </div>
        <span
          v-if="shouldShowErrorMessage"
          class="block w-full -mt-px text-sm font-normal text-red-400 dark:text-red-500"
        >
          {{ errorMessage }}
        </span>
      </div>
      <div
        v-show="!isEditing"
        class="flex group"
        :class="{ 'is-editable': showActions }"
      >
        <a
          v-if="isAttributeTypeLink"
          :href="hrefURL"
          target="_blank"
          rel="noopener noreferrer"
          class="group-hover:bg-slate-50 group-hover:dark:bg-slate-700 inline-block rounded-sm mb-0 break-all py-0.5 px-1"
        >
          {{ urlValue }}
        </a>
        <p
          v-else
          class="group-hover:bg-slate-50 group-hover:dark:bg-slate-700 inline-block rounded-sm mb-0 break-all py-0.5 px-1"
        >
          {{ displayValue || '---' }}
        </p>
        <div class="flex max-w-[2rem] gap-1 ml-1 rtl:mr-1 rtl:ml-0">
          <woot-button
            v-if="showActions && value"
            v-tooltip="$t('CUSTOM_ATTRIBUTES.ACTIONS.COPY')"
            variant="link"
            size="small"
            color-scheme="secondary"
            icon="clipboard"
            class-names="hidden group-hover:flex !w-6 flex-shrink-0"
            @click="onCopy"
          />
          <woot-button
            v-if="showActions"
            v-tooltip.right="$t('CUSTOM_ATTRIBUTES.ACTIONS.EDIT')"
            variant="link"
            size="small"
            color-scheme="secondary"
            icon="edit"
            class-names="hidden group-hover:flex !w-6 flex-shrink-0"
            @click="onEdit"
          />
        </div>
      </div>
    </div>
    <div v-if="isAttributeTypeList">
      <MultiselectDropdown
        :options="listOptions"
        :selected-item="selectedItem"
        :has-thumbnail="false"
        :multiselector-placeholder="
          $t('CUSTOM_ATTRIBUTES.FORM.ATTRIBUTE_TYPE.LIST.PLACEHOLDER')
        "
        :no-search-result="
          $t('CUSTOM_ATTRIBUTES.FORM.ATTRIBUTE_TYPE.LIST.NO_RESULT')
        "
        :input-placeholder="
          $t(
            'CUSTOM_ATTRIBUTES.FORM.ATTRIBUTE_TYPE.LIST.SEARCH_INPUT_PLACEHOLDER'
          )
        "
        @select="onUpdateListValue"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
::v-deep {
  .selector-wrap {
    @apply m-0 top-1;

    .selector-name {
      @apply ml-0;
    }
  }

  .name {
    @apply ml-0;
  }
}
</style>

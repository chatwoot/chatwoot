<template>
  <div class="py-3 px-4">
    <div class="flex items-center mb-1">
      <h4 class="text-sm flex items-center m-0 w-full error">
        <div v-if="isAttributeTypeCheckbox" class="checkbox-wrap">
          <input
            v-model="editedValue"
            class="checkbox"
            type="checkbox"
            @change="onUpdate"
          />
        </div>
        <div class="flex items-center justify-between w-full">
          <span
            class="attribute-name w-full text-slate-800 dark:text-slate-100 font-medium text-sm mb-0"
            :class="{ error: $v.editedValue.$error }"
          >
            {{ label }}
          </span>
          <woot-button
            v-if="showActions"
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
      <div v-show="isEditing">
        <div class="mb-2 w-full flex items-center">
          <input
            ref="inputfield"
            v-model="editedValue"
            :type="inputType"
            class="!h-8 ltr:rounded-r-none rtl:rounded-l-none !mb-0 !text-sm"
            autofocus="true"
            :class="{ error: $v.editedValue.$error }"
            @blur="$v.editedValue.$touch"
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
          class="text-red-400 dark:text-red-500 text-sm block font-normal -mt-px w-full"
        >
          {{ errorMessage }}
        </span>
      </div>
      <div
        v-show="!isEditing"
        class="value--view"
        :class="{ 'is-editable': showActions }"
      >
        <a
          v-if="isAttributeTypeLink"
          :href="hrefURL"
          target="_blank"
          rel="noopener noreferrer"
          class="value inline-block rounded-sm mb-0 break-all py-0.5 px-1"
        >
          {{ urlValue }}
        </a>
        <p
          v-else
          class="value inline-block rounded-sm mb-0 break-all py-0.5 px-1"
        >
          {{ displayValue || '---' }}
        </p>
        <div class="flex max-w-[2rem] gap-1 ml-1 rtl:mr-1 rtl:ml-0">
          <woot-button
            v-if="showActions"
            v-tooltip="$t('CUSTOM_ATTRIBUTES.ACTIONS.COPY')"
            variant="link"
            size="small"
            color-scheme="secondary"
            icon="clipboard"
            class-names="edit-button"
            @click="onCopy"
          />
          <woot-button
            v-if="showActions"
            v-tooltip.right="$t('CUSTOM_ATTRIBUTES.ACTIONS.EDIT')"
            variant="link"
            size="small"
            color-scheme="secondary"
            icon="edit"
            class-names="edit-button"
            @click="onEdit"
          />
        </div>
      </div>
    </div>
    <div v-if="isAttributeTypeList">
      <multiselect-dropdown
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
        @click="onUpdateListValue"
      />
    </div>
  </div>
</template>

<script>
import { format, parseISO } from 'date-fns';
import { required, url } from 'vuelidate/lib/validators';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import { isValidURL } from '../helper/URLHelper';
import customAttributeMixin from '../mixins/customAttributeMixin';
const DATE_FORMAT = 'yyyy-MM-dd';

export default {
  components: {
    MultiselectDropdown,
  },
  mixins: [customAttributeMixin],
  props: {
    label: { type: String, required: true },
    values: { type: Array, default: () => [] },
    value: { type: [String, Number, Boolean], default: '' },
    showActions: { type: Boolean, default: false },
    attributeType: { type: String, default: 'text' },
    attributeRegex: {
      type: String,
      default: null,
    },
    regexCue: { type: String, default: null },
    regexEnabled: { type: Boolean, default: false },
    attributeKey: { type: String, required: true },
    contactId: { type: Number, default: null },
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
        return new Date(this.value || new Date()).toLocaleDateString();
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
      return this.$v.editedValue.$error;
    },
    errorMessage() {
      if (this.$v.editedValue.url) {
        return this.$t('CUSTOM_ATTRIBUTES.VALIDATIONS.INVALID_URL');
      }
      if (!this.$v.editedValue.regexValidation) {
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
            this.attributeRegex &&
            !this.getRegexp(this.attributeRegex).test(value)
          );
        },
      },
    };
  },
  mounted() {
    this.editedValue = this.formattedValue;
    bus.$on(BUS_EVENTS.FOCUS_CUSTOM_ATTRIBUTE, this.onFocusAttribute);
  },
  destroyed() {
    bus.$off(BUS_EVENTS.FOCUS_CUSTOM_ATTRIBUTE, this.onFocusAttribute);
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
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.isEditing = false;
      this.$emit('update', this.attributeKey, updatedValue);
    },
    onDelete() {
      this.isEditing = false;
      this.$emit('delete', this.attributeKey);
    },
    onCopy() {
      this.$emit('copy', this.value);
    },
  },
};
</script>

<style lang="scss" scoped>
.checkbox-wrap {
  @apply flex items-center;
}
.checkbox {
  @apply my-0 mr-2 ml-0;
}
.attribute-name {
  &.error {
    @apply text-red-400 dark:text-red-500;
  }
}

.edit-button {
  @apply hidden;
}

.value--view {
  @apply flex;

  &.is-editable:hover {
    .value {
      @apply bg-slate-50 dark:bg-slate-700 mb-0;
    }
    .edit-button {
      @apply block;
    }
  }
}

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

<template>
  <div class="custom-attribute">
    <div class="title-wrap">
      <h4 class="text-block-title title error">
        <div v-if="isAttributeTypeCheckbox" class="checkbox-wrap">
          <input
            v-model="editedValue"
            class="checkbox"
            type="checkbox"
            @change="onUpdate"
          />
        </div>
        <div class="name-button__wrap">
          <span
            class="attribute-name"
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
            class-names="delete-button"
            @click="onDelete"
          />
        </div>
      </h4>
    </div>
    <div v-if="notAttributeTypeCheckboxAndList">
      <div v-show="isEditing">
        <div class="input-group small">
          <input
            ref="inputfield"
            v-model="editedValue"
            :type="inputType"
            class="input-group-field"
            autofocus="true"
            :class="{ error: $v.editedValue.$error }"
            @blur="$v.editedValue.$touch"
            @keyup.enter="onUpdate"
          />
          <div class="input-group-button">
            <woot-button size="small" icon="checkmark" @click="onUpdate" />
          </div>
        </div>
        <span v-if="shouldShowErrorMessage" class="error-message">
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
          :href="value"
          target="_blank"
          rel="noopener noreferrer"
          class="value"
        >
          {{ urlValue }}
        </a>
        <p v-else class="value">
          {{ displayValue || '---' }}
        </p>
        <div class="action-buttons__wrap">
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
import format from 'date-fns/format';
import { required, url } from 'vuelidate/lib/validators';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import { isValidURL } from '../helper/URLHelper';
const DATE_FORMAT = 'yyyy-MM-dd';

export default {
  components: {
    MultiselectDropdown,
  },
  props: {
    label: { type: String, required: true },
    values: { type: Array, default: () => [] },
    value: { type: [String, Number, Boolean], default: '' },
    showActions: { type: Boolean, default: false },
    attributeType: { type: String, default: 'text' },
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
    formattedValue() {
      if (this.isAttributeTypeDate) {
        return format(new Date(this.value || new Date()), DATE_FORMAT);
      }
      if (this.isAttributeTypeCheckbox) {
        return this.value === 'false' ? false : this.value;
      }
      return this.value;
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
      return this.$t('CUSTOM_ATTRIBUTES.VALIDATIONS.REQUIRED');
    },
    displayValue() {
      if (this.attributeType === 'date') {
        return format(new Date(this.editedValue), 'dd-MM-yyyy');
      }
      return this.editedValue;
    },
  },
  watch: {
    value() {
      this.isEditing = false;
      this.editedValue = this.value;
    },
  },

  validations() {
    if (this.isAttributeTypeLink) {
      return {
        editedValue: { required, url },
      };
    }
    return {
      editedValue: { required },
    };
  },
  mounted() {
    this.editedValue = this.formattedValue;
    bus.$on(BUS_EVENTS.FOCUS_CUSTOM_ATTRIBUTE, focusAttributeKey => {
      if (this.attributeKey === focusAttributeKey) {
        this.onEdit();
      }
    });
  },
  methods: {
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
          ? format(new Date(this.editedValue), DATE_FORMAT)
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
.custom-attribute {
  padding: var(--space-slab) var(--space-normal);
}

.title-wrap {
  display: flex;
  align-items: center;
  margin-bottom: var(--space-mini);
}
.title {
  display: flex;
  align-items: center;
  margin: 0;
  width: 100%;
}
.checkbox-wrap {
  display: flex;
  align-items: center;
}
.checkbox {
  margin: 0 var(--space-small) 0 0;
}
.name-button__wrap {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}
.attribute-name {
  width: 100%;
  &.error {
    color: var(--r-400);
  }
}
.title--icon {
  width: var(--space-two);
}
.edit-button {
  display: none;
}
.delete-button {
  display: flex;
  justify-content: flex-end;
  width: var(--space-normal);
}
.value--view {
  display: flex;

  &.is-editable:hover {
    .value {
      background: var(--color-background);
      margin-bottom: 0;
    }
    .edit-button {
      display: block;
    }
  }

  .action-buttons__wrap {
    display: flex;
    max-width: var(--space-larger);
  }
}
.value {
  display: inline-block;
  min-width: var(--space-mega);
  border-radius: var(--border-radius-small);
  margin-bottom: 0;
  word-break: break-all;
  padding: var(--space-micro) var(--space-smaller);
}
.error-message {
  color: var(--r-400);
  display: block;
  font-size: 1.4rem;
  font-size: var(--font-size-small);
  font-weight: 400;
  margin-bottom: 1rem;
  margin-top: -1.6rem;
  width: 100%;
}

::v-deep {
  .selector-wrap {
    margin: 0;
    top: var(--space-smaller);
    .selector-name {
      margin-left: 0;
    }
  }
  .name {
    margin-left: 0;
  }
}
</style>

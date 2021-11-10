<template>
  <div class="custom-attribute">
    <div class="title-wrap">
      <h4 class="text-block-title title error">
        <span class="attribute-name" :class="{ error: $v.editedValue.$error }">
          {{ label }}
        </span>
      </h4>
    </div>
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
          <woot-button size="small" icon="ion-checkmark" @click="onUpdate" />
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
        {{ value || '---' }}
      </a>
      <p v-else class="value">
        {{ formattedValue || '---' }}
      </p>
      <woot-button
        v-if="showActions"
        v-tooltip="$t('CUSTOM_ATTRIBUTES.ACTIONS.COPY')"
        variant="link"
        size="small"
        color-scheme="secondary"
        icon="ion-clipboard"
        class-names="edit-button"
        @click="onCopy"
      />
      <woot-button
        v-if="showActions"
        v-tooltip="$t('CUSTOM_ATTRIBUTES.ACTIONS.EDIT')"
        variant="link"
        size="small"
        color-scheme="secondary"
        icon="ion-compose"
        class-names="edit-button"
        @click="onEdit"
      />
      <woot-button
        v-if="showActions"
        v-tooltip="$t('CUSTOM_ATTRIBUTES.ACTIONS.DELETE')"
        variant="link"
        size="small"
        color-scheme="secondary"
        icon="ion-trash-a"
        class-names="edit-button"
        @click="onDelete"
      />
    </div>
  </div>
</template>

<script>
import format from 'date-fns/format';
import { required, url } from 'vuelidate/lib/validators';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const DATE_FORMAT = 'yyyy-MM-dd';

export default {
  props: {
    label: { type: String, required: true },
    value: { type: [String, Number], default: '' },
    showActions: { type: Boolean, default: false },
    attributeType: { type: String, default: 'text' },
    attributeKey: { type: String, required: true },
    contactId: { type: Number, default: null },
  },
  data() {
    return {
      isEditing: false,
      editedValue:
        this.attributeType === 'date'
          ? format(new Date(this.value), DATE_FORMAT)
          : this.value,
    };
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

  computed: {
    isAttributeTypeLink() {
      return this.attributeType === 'link';
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
    formattedValue() {
      if (this.attributeType === 'date') {
        return format(new Date(this.editedValue), 'dd-MM-yyyy');
      }
      return this.editedValue;
    },
  },
  mounted() {
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
}
.attribute-name {
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
.value--view {
  display: flex;

  &.is-editable:hover {
    .value {
      background: var(--color-background);
    }
    .edit-button {
      display: block;
    }
  }
}
.value {
  display: inline-block;
  min-width: var(--space-mega);
  border-radius: var(--border-radius-small);
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
</style>

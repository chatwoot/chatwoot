<template>
  <div class="column content-box">
    <woot-modal-header :header-title="pageTitle" />
    <form class="row" @submit.prevent="editAttributes">
      <div class="medium-12 columns">
        <woot-input
          v-model.trim="displayName"
          :label="$t('ATTRIBUTES_MGMT.ADD.FORM.NAME.LABEL')"
          type="text"
          :class="{ error: $v.displayName.$error }"
          :error="
            $v.displayName.$error
              ? $t('ATTRIBUTES_MGMT.ADD.FORM.NAME.ERROR')
              : ''
          "
          :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
          @blur="$v.displayName.$touch"
        />
        <woot-input
          v-model.trim="attributeKey"
          :label="$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.LABEL')"
          type="text"
          :class="{ error: $v.attributeKey.$error }"
          :error="$v.attributeKey.$error ? keyErrorMessage : ''"
          :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.PLACEHOLDER')"
          readonly
          @blur="$v.attributeKey.$touch"
        />
        <label :class="{ error: $v.description.$error }">
          {{ $t('ATTRIBUTES_MGMT.ADD.FORM.DESC.LABEL') }}
          <textarea
            v-model.trim="description"
            rows="5"
            type="text"
            :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.DESC.PLACEHOLDER')"
            @blur="$v.description.$touch"
          />
          <span v-if="$v.description.$error" class="message">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.DESC.ERROR') }}
          </span>
        </label>
        <label :class="{ error: $v.attributeType.$error }">
          {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LABEL') }}
          <select v-model="attributeType" disabled>
            <option v-for="type in types" :key="type.id" :value="type.id">
              {{ type.option }}
            </option>
          </select>
          <span v-if="$v.attributeType.$error" class="message">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.ERROR') }}
          </span>
        </label>
        <div v-if="isAttributeTypeList" class="multiselect--wrap">
          <label>
            {{ $t('ATTRIBUTES_MGMT.EDIT.TYPE.LIST.LABEL') }}
          </label>
          <multiselect
            ref="tagInput"
            v-model="values"
            :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.PLACEHOLDER')"
            label="name"
            track-by="name"
            :class="{ invalid: isMultiselectInvalid }"
            :options="options"
            :multiple="true"
            :taggable="true"
            @tag="addTagValue"
          />
          <label v-show="isMultiselectInvalid" class="error-message">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.ERROR') }}
          </label>
        </div>
      </div>
      <div class="modal-footer">
        <woot-button :is-loading="isUpdating" :disabled="isButtonDisabled">
          {{ $t('ATTRIBUTES_MGMT.EDIT.UPDATE_BUTTON_TEXT') }}
        </woot-button>
        <woot-button variant="clear" @click.prevent="onClose">
          {{ $t('ATTRIBUTES_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { required, minLength } from 'vuelidate/lib/validators';
import { ATTRIBUTE_TYPES } from './constants';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {},
  mixins: [alertMixin],
  props: {
    selectedAttribute: {
      type: Object,
      default: () => {},
    },
    isUpdating: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      displayName: '',
      description: '',
      attributeType: 0,
      types: ATTRIBUTE_TYPES,
      show: true,
      attributeKey: '',
      values: [],
      options: [],
      isTouched: true,
    };
  },
  validations: {
    displayName: {
      required,
    },
    attributeType: {
      required,
    },
    description: {
      required,
      minLength: minLength(1),
    },
    attributeKey: {
      required,
      isKey(value) {
        return !(value.indexOf(' ') >= 0);
      },
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'attributes/getUIFlags',
    }),
    setAttributeListValue() {
      return this.selectedAttribute.attribute_values.map(values => ({
        name: values,
      }));
    },
    updatedAttributeListValues() {
      return this.values.map(item => item.name);
    },
    isButtonDisabled() {
      return this.$v.description.$invalid || this.isMultiselectInvalid;
    },
    isMultiselectInvalid() {
      return (
        this.isAttributeTypeList && this.isTouched && this.values.length === 0
      );
    },
    pageTitle() {
      return `${this.$t('ATTRIBUTES_MGMT.EDIT.TITLE')} - ${
        this.selectedAttribute.attribute_display_name
      }`;
    },
    selectedAttributeType() {
      return this.types.find(
        item =>
          item.option.toLowerCase() ===
          this.selectedAttribute.attribute_display_type
      ).id;
    },
    keyErrorMessage() {
      if (!this.$v.attributeKey.isKey) {
        return this.$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.IN_VALID');
      }
      return this.$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.ERROR');
    },
    isAttributeTypeList() {
      return this.attributeType === 6;
    },
  },
  mounted() {
    this.setFormValues();
  },
  methods: {
    onClose() {
      this.$emit('on-close');
    },
    addTagValue(tagValue) {
      const tag = {
        name: tagValue,
      };
      this.values.push(tag);
      this.$refs.tagInput.$el.focus();
    },
    setFormValues() {
      this.displayName = this.selectedAttribute.attribute_display_name;
      this.description = this.selectedAttribute.attribute_description;
      this.attributeType = this.selectedAttributeType;
      this.attributeKey = this.selectedAttribute.attribute_key;
      this.values = this.setAttributeListValue;
    },
    async editAttributes() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('attributes/update', {
          id: this.selectedAttribute.id,
          attribute_description: this.description,
          attribute_display_name: this.displayName,
          attribute_values: this.updatedAttributeListValues,
        });

        this.alertMessage = this.$t('ATTRIBUTES_MGMT.EDIT.API.SUCCESS_MESSAGE');
        this.onClose();
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage || this.$t('ATTRIBUTES_MGMT.EDIT.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.key-value {
  padding: 0 var(--space-small) var(--space-small) 0;
  font-family: monospace;
}
.multiselect--wrap {
  margin-bottom: var(--space-normal);
  .error-message {
    color: var(--r-400);
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-normal);
  }
  .invalid {
    ::v-deep {
      .multiselect__tags {
        border: 1px solid var(--r-400);
      }
    }
  }
}
::v-deep {
  .multiselect {
    margin-bottom: 0;
  }
  .multiselect__content-wrapper {
    display: none;
  }
  .multiselect--active .multiselect__tags {
    border-radius: var(--border-radius-normal);
  }
}
</style>

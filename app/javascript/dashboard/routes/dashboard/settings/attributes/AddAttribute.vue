<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header :header-title="$t('ATTRIBUTES_MGMT.ADD.TITLE')" />

      <form class="row" @submit.prevent="addAttributes">
        <div class="medium-12 columns">
          <label :class="{ error: $v.attributeModel.$error }">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.MODEL.LABEL') }}
            <select v-model="attributeModel">
              <option v-for="model in models" :key="model.id" :value="model.id">
                {{ model.option }}
              </option>
            </select>
            <span v-if="$v.attributeModel.$error" class="message">
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.MODEL.ERROR') }}
            </span>
          </label>
          <woot-input
            v-model="displayName"
            :label="$t('ATTRIBUTES_MGMT.ADD.FORM.NAME.LABEL')"
            type="text"
            :class="{ error: $v.displayName.$error }"
            :error="
              $v.displayName.$error
                ? $t('ATTRIBUTES_MGMT.ADD.FORM.NAME.ERROR')
                : ''
            "
            :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
            @input="onDisplayNameChange"
            @blur="$v.displayName.$touch"
          />
          <woot-input
            v-model="attributeKey"
            :label="$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.LABEL')"
            type="text"
            :class="{ error: $v.attributeKey.$error }"
            :error="$v.attributeKey.$error ? keyErrorMessage : ''"
            :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.KEY.PLACEHOLDER')"
            @blur="$v.attributeKey.$touch"
          />
          <label :class="{ error: $v.description.$error }">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.DESC.LABEL') }}
            <textarea
              v-model="description"
              rows="3"
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
            <select v-model="attributeType">
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
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.LABEL') }}
            </label>
            <multiselect
              ref="tagInput"
              v-model="values"
              :placeholder="
                $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.PLACEHOLDER')
              "
              label="name"
              track-by="name"
              :class="{ invalid: isMultiselectInvalid }"
              :options="options"
              :multiple="true"
              :taggable="true"
              @close="onTouch"
              @tag="addTagValue"
            />
            <label v-show="isMultiselectInvalid" class="error-message">
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LIST.ERROR') }}
            </label>
          </div>
          <div class="modal-footer">
            <woot-submit-button
              :disabled="isButtonDisabled"
              :button-text="$t('ATTRIBUTES_MGMT.ADD.SUBMIT')"
            />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('ATTRIBUTES_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </woot-modal>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';
import { mapGetters } from 'vuex';
import { convertToSlug } from 'dashboard/helper/commons.js';
import { ATTRIBUTE_MODELS, ATTRIBUTE_TYPES } from './constants';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
  },

  data() {
    return {
      displayName: '',
      description: '',
      attributeModel: 0,
      attributeType: 0,
      attributeKey: '',
      models: ATTRIBUTE_MODELS,
      types: ATTRIBUTE_TYPES,
      values: [],
      options: [],
      show: true,
      isTouched: false,
    };
  },

  computed: {
    ...mapGetters({
      uiFlags: 'getUIFlags',
    }),
    isMultiselectInvalid() {
      return this.isTouched && this.values.length === 0;
    },
    isTagInputInvalid() {
      return this.isAttributeTypeList && this.values.length === 0;
    },
    attributeListValues() {
      return this.values.map(item => item.name);
    },
    isButtonDisabled() {
      return (
        this.$v.displayName.$invalid ||
        this.$v.description.$invalid ||
        this.uiFlags.isCreating ||
        this.isTagInputInvalid
      );
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

  validations: {
    displayName: {
      required,
      minLength: minLength(1),
    },
    description: {
      required,
    },
    attributeModel: {
      required,
    },
    attributeType: {
      required,
    },
    attributeKey: {
      required,
      isKey(value) {
        return !(value.indexOf(' ') >= 0);
      },
    },
  },

  methods: {
    addTagValue(tagValue) {
      const tag = {
        name: tagValue,
      };
      this.values.push(tag);
      this.$refs.tagInput.$el.focus();
    },
    onTouch() {
      this.isTouched = true;
    },
    onDisplayNameChange() {
      this.attributeKey = convertToSlug(this.displayName);
    },
    async addAttributes() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('attributes/create', {
          attribute_display_name: this.displayName,
          attribute_description: this.description,
          attribute_model: this.attributeModel,
          attribute_display_type: this.attributeType,
          attribute_key: this.attributeKey,
          attribute_values: this.attributeListValues,
        });
        this.alertMessage = this.$t('ATTRIBUTES_MGMT.ADD.API.SUCCESS_MESSAGE');
        this.onClose();
      } catch (error) {
        const errorMessage = error?.message;
        this.alertMessage =
          errorMessage || this.$t('ATTRIBUTES_MGMT.ADD.API.ERROR_MESSAGE');
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

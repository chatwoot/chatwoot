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
            @blur="$v.displayName.$touch"
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
          <div v-if="displayName" class="medium-12 columns">
            <label>
              {{ $t('ATTRIBUTES_MGMT.ADD.FORM.KEY.LABEL') }}
              <i class="ion-help" />
            </label>
            <p class="key-value text-truncate">
              {{ attributeKey }}
            </p>
          </div>
          <div class="modal-footer">
            <woot-submit-button
              :disabled="
                $v.displayName.$invalid ||
                  $v.description.$invalid ||
                  uiFlags.isCreating
              "
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
      models: ATTRIBUTE_MODELS,
      types: ATTRIBUTE_TYPES,
      show: true,
    };
  },

  computed: {
    ...mapGetters({
      uiFlags: 'getUIFlags',
    }),
    attributeKey() {
      return convertToSlug(this.displayName);
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
  },

  methods: {
    async addAttributes() {
      try {
        await this.$store.dispatch('attributes/create', {
          attribute_display_name: this.displayName,
          attribute_description: this.description,
          attribute_model: this.attributeModel,
          attribute_display_type: this.attributeType,
          attribute_key: this.attributeKey,
        });
        this.alertMessage = this.$t('ATTRIBUTES_MGMT.ADD.API.SUCCESS_MESSAGE');
        this.onClose();
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
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
</style>

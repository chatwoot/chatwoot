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
      </div>
      <div class="modal-footer">
        <woot-button
          :is-loading="isUpdating"
          :disabled="$v.displayName.$invalid || $v.description.$invalid"
        >
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
import { convertToSlug } from 'dashboard/helper/commons.js';
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
  },
  computed: {
    ...mapGetters({
      uiFlags: 'attributes/getUIFlags',
    }),
    pageTitle() {
      return `${this.$t('ATTRIBUTES_MGMT.EDIT.TITLE')} - ${
        this.selectedAttribute.attribute_display_name
      }`;
    },
    attributeKey() {
      return convertToSlug(this.displayName);
    },
  },
  mounted() {
    this.setFormValues();
  },
  methods: {
    onClose() {
      this.$emit('on-close');
    },
    setFormValues() {
      this.displayName = this.selectedAttribute.attribute_display_name;
      this.description = this.selectedAttribute.attribute_description;
    },
    async editAttributes() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('attributes/update', {
          id: this.selectedAttribute.id,
          attribute_display_name: this.displayName,
          attribute_description: this.description,
          attribute_display_type: this.attributeType,
          attribute_key: this.attributeKey,
        });
        this.showAlert(this.$t('ATTRIBUTES_MGMT.EDIT.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error?.response?.message ||
          this.$t('ATTRIBUTES_MGMT.EDIT.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
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

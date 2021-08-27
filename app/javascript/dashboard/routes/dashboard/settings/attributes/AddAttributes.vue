<template>
  <woot-modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header :header-title="$t('ATTRIBUTES_MGMT.ADD.TITLE')" />

      <form class="row" @submit.prevent="addAttributes()">
        <div class="medium-12 columns">
          <label :class="{ error: $v.displayName.$error }">
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.NAME.LABEL') }}
            <input
              v-model.trim="displayName"
              type="text"
              :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
              @input="$v.displayName.$touch"
            />
          </label>
        </div>
        <div class="medium-12 columns">
          <label>
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.DESC.LABEL') }}
            <woot-input
              v-model="description"
              type="text"
              rows="5"
              :placeholder="$t('ATTRIBUTES_MGMT.ADD.FORM.DESC.PLACEHOLDER')"
              @blur="$v.description.$touch"
            />
          </label>
        </div>
        <div class="medium-12 columns">
          <label>
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.MODEL.LABEL') }}
            <select>
              <option
                v-for="model in models"
                :key="model.id"
                :value="model.option"
              >
                {{ model.option }}
              </option>
            </select>
          </label>
        </div>
        <div class="medium-12 columns">
          <label>
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.TYPE.LABEL') }}
            <select>
              <option v-for="type in types" :key="type.id" :value="type.option">
                {{ type.option }}
              </option>
            </select>
          </label>
        </div>
        <div class="medium-12 columns">
          <label>
            {{ $t('ATTRIBUTES_MGMT.ADD.FORM.KEY.LABEL') }}
            <i class="ion-help" />
          </label>
          <span class="key-value">
            {{ convertToSlug }}
          </span>
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
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

export default {
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
      models: [
        {
          id: 0,
          option: 'Text',
        },
        {
          id: 1,
          option: 'Number',
        },
        {
          id: 2,
          option: 'Currency',
        },
        {
          id: 3,
          option: 'Percent',
        },
        {
          id: 4,
          option: 'Link',
        },
      ],
      types: [
        {
          id: 0,
          option: 'Conversation',
        },
        {
          id: 1,
          option: 'Contact',
        },
      ],
      show: true,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'getUIFlags',
    }),
    convertToSlug() {
      return this.displayName.replace(/[^\w ]+/g, '').replace(/ +/g, '-');
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
  },

  methods: {
    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
    async addAttributes() {
      try {
        await this.$store.dispatch('attributes/createAttribute', {
          attribute_display_name: this.displayName,
          attribute_description: this.description,
          attribute_model: this.models.id,
          attribute_display_type: this.types.id,
          attribute_key: this.convertToSlug,
        });
        this.showAlert(this.$t('ATTRIBUTES_MGMT.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        this.showAlert(this.$t('ATTRIBUTES_MGMT.ADD.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
<style lang="scss" scoped>
.key-value {
  height: 2rem;
}
</style>

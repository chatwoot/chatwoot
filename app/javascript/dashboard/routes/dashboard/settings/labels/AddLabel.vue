<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('LABEL_MGMT.ADD.TITLE')"
        :header-content="$t('LABEL_MGMT.ADD.DESC')"
      />
      <form class="row" @submit.prevent="addLabel">
        <woot-input
          v-model.trim="title"
          :class="{ error: $v.title.$error }"
          class="medium-12 columns"
          :label="$t('LABEL_MGMT.FORM.NAME.LABEL')"
          :placeholder="$t('LABEL_MGMT.FORM.NAME.PLACEHOLDER')"
          @input="$v.title.$touch"
        />

        <woot-input
          v-model.trim="description"
          :class="{ error: $v.description.$error }"
          class="medium-12 columns"
          :label="$t('LABEL_MGMT.FORM.DESCRIPTION.LABEL')"
          :placeholder="$t('LABEL_MGMT.FORM.DESCRIPTION.PLACEHOLDER')"
          @input="$v.description.$touch"
        />

        <div class="medium-12">
          <label>
            {{ $t('LABEL_MGMT.FORM.COLOR.LABEL') }}
            <woot-color-picker v-model="color" />
          </label>
        </div>
        <div class="medium-12">
          <input v-model="showOnSidebar" type="checkbox" :value="true" />
          <label for="conversation_creation">
            {{ $t('LABEL_MGMT.FORM.SHOW_ON_SIDEBAR.LABEL') }}
          </label>
        </div>
        <div class="modal-footer">
          <woot-submit-button
            :disabled="$v.title.$invalid || uiFlags.isCreating"
            :button-text="$t('LABEL_MGMT.FORM.CREATE')"
            :loading="uiFlags.isCreating"
          />
          <button class="button clear" @click.prevent="onClose">
            {{ $t('LABEL_MGMT.FORM.CANCEL') }}
          </button>
        </div>
      </form>
    </div>
  </modal>
</template>

<script>
import WootSubmitButton from '../../../../components/buttons/FormSubmitButton';
import Modal from '../../../../components/Modal';
import alertMixin from 'shared/mixins/alertMixin';
import { mapGetters } from 'vuex';
import validations from './validations';

export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  mixins: [alertMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
    show: {
      type: Boolean,
      default: true,
    },
  },
  data() {
    return {
      color: '#000',
      description: '',
      title: '',
      showOnSidebar: true,
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'labels/getUIFlags',
    }),
  },
  mounted() {
    this.color = this.getRandomColor();
  },
  methods: {
    getRandomColor() {
      const letters = '0123456789ABCDEF';
      let color = '#';
      for (let i = 0; i < 6; i += 1) {
        color += letters[Math.floor(Math.random() * 16)];
      }
      return color;
    },
    addLabel() {
      this.$store
        .dispatch('labels/create', {
          color: this.color,
          description: this.description,
          title: this.title,
          show_on_sidebar: this.showOnSidebar,
        })
        .then(() => {
          this.showAlert(this.$t('LABEL_MGMT.ADD.API.SUCCESS_MESSAGE'));
          this.onClose();
        })
        .catch(() => {
          this.showAlert(this.$t('LABEL_MGMT.ADD.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>

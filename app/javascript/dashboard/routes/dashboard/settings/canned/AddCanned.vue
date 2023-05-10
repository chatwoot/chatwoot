<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('CANNED_MGMT.ADD.TITLE')"
        :header-content="$t('CANNED_MGMT.ADD.DESC')"
      />
      <form class="row" @submit.prevent="addAgent()">
        <div class="medium-12 columns">
          <label :class="{ error: $v.shortCode.$error }">
            {{ $t('CANNED_MGMT.ADD.FORM.SHORT_CODE.LABEL') }}
            <input
              v-model.trim="shortCode"
              type="text"
              :placeholder="$t('CANNED_MGMT.ADD.FORM.SHORT_CODE.PLACEHOLDER')"
              @input="$v.shortCode.$touch"
            />
          </label>
        </div>

        <div class="medium-12 columns">
          <label :class="{ error: $v.content.$error }">
            {{ $t('CANNED_MGMT.ADD.FORM.CONTENT.LABEL') }}
          </label>
          <div class="editor-wrap">
            <woot-message-editor
              v-model="content"
              class="message-editor"
              :class="{ editor_warning: $v.content.$error }"
              :enable-variables="true"
              :enable-canned-responses="false"
              :placeholder="$t('CANNED_MGMT.ADD.FORM.CONTENT.PLACEHOLDER')"
              @blur="$v.content.$touch"
            />
          </div>
        </div>
        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-submit-button
              :disabled="
                $v.content.$invalid ||
                  $v.shortCode.$invalid ||
                  addCanned.showLoading
              "
              :button-text="$t('CANNED_MGMT.ADD.FORM.SUBMIT')"
              :loading="addCanned.showLoading"
            />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('CANNED_MGMT.ADD.CANCEL_BUTTON_TEXT') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </modal>
</template>

<script>
import { required, minLength } from 'vuelidate/lib/validators';

import WootSubmitButton from '../../../../components/buttons/FormSubmitButton';
import Modal from '../../../../components/Modal';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    WootSubmitButton,
    Modal,
    WootMessageEditor,
  },
  mixins: [alertMixin],
  props: {
    responseContent: {
      type: String,
      default: '',
    },
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      shortCode: '',
      content: this.responseContent || '',
      addCanned: {
        showLoading: false,
        message: '',
      },
      show: true,
    };
  },
  validations: {
    shortCode: {
      required,
      minLength: minLength(2),
    },
    content: {
      required,
    },
  },
  methods: {
    resetForm() {
      this.shortCode = '';
      this.content = '';
      this.$v.shortCode.$reset();
      this.$v.content.$reset();
    },
    addAgent() {
      // Show loading on button
      this.addCanned.showLoading = true;
      // Make API Calls
      this.$store
        .dispatch('createCannedResponse', {
          short_code: this.shortCode,
          content: this.content,
        })
        .then(() => {
          // Reset Form, Show success message
          this.addCanned.showLoading = false;
          this.showAlert(this.$t('CANNED_MGMT.ADD.API.SUCCESS_MESSAGE'));
          this.resetForm();
          this.onClose();
        })
        .catch(() => {
          this.addCanned.showLoading = false;
          this.showAlert(this.$t('CANNED_MGMT.ADD.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>

<style scoped lang="scss">
::v-deep {
  .ProseMirror-menubar {
    display: none;
  }

  .ProseMirror-woot-style {
    min-height: 20rem;

    p {
      font-size: var(--font-size-default);
    }
  }

  .message-editor {
    border: 1px solid var(--s-200);
  }
}
</style>

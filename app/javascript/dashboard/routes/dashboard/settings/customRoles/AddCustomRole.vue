<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';

import WootSubmitButton from '../../../../components/buttons/FormSubmitButton.vue';
import Modal from '../../../../components/Modal.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

export default {
  components: {
    WootSubmitButton,
    Modal,
    WootMessageEditor,
  },
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
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      name: '',
      description: this.responseContent || '',
      permissions: [],
      addCustomRole: {
        showLoading: false,
        message: '',
      },
      show: true,
    };
  },
  validations: {
    name: {
      required,
      minLength: minLength(2),
    },
    description: {
      required,
    },
    permissions: {
      required,
      minLength: minLength(1),
    },
  },
  methods: {
    resetForm() {
      this.name = '';
      this.description = '';
      this.permissions = [];
      this.v$.name.$reset();
      this.v$.description.$reset();
      this.v$.permissions.$reset();
    },
    updatePermissions(permission, event) {
      if (event.target.checked) {
        this.permissions.push(permission);
      } else {
        this.permissions = this.permissions.filter(p => p !== permission);
      }
    },
    addCustomRoleResponse() {
      // Show loading on button
      this.addCustomRole.showLoading = true;
      // Make API Calls
      this.$store
        .dispatch('createCustomRole', {
          name: this.name,
          description: this.description,
          permissions: this.permissions,
        })
        .then(() => {
          // Reset Form, Show success message
          this.addCustomRole.showLoading = false;
          useAlert(this.$t('CUSTOM_ROLE.ADD.API.SUCCESS_MESSAGE'));
          this.resetForm();
          this.onClose();
        })
        .catch(error => {
          this.addCustomRole.showLoading = false;
          const errorMessage =
            error?.message || this.$t('CUSTOM_ROLE.ADD.API.ERROR_MESSAGE');
          useAlert(errorMessage);
        });
    },
  },
};
</script>

<template>
  <Modal :show.sync="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="$t('CUSTOM_ROLE.ADD.TITLE')"
        :header-content="$t('CUSTOM_ROLE.ADD.DESC')"
      />
      <form class="flex flex-col w-full" @submit.prevent="addCustomRoleResponse()">
        <div class="w-full">
          <label :class="{ error: v$.name.$error }">
            {{ $t('CUSTOM_ROLE.ADD.FORM.NAME.LABEL') }}
            <input
              v-model.trim="name"
              type="text"
              :placeholder="$t('CUSTOM_ROLE.ADD.FORM.NAME.PLACEHOLDER')"
              @input="v$.name.$touch"
            />
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: v$.description.$error }">
            {{ $t('CUSTOM_ROLE.ADD.FORM.DESCRIPTION.LABEL') }}
          </label>
          <div class="editor-wrap">
            <WootMessageEditor
              v-model="description"
              class="message-editor [&>div]:px-1"
              :class="{ editor_warning: v$.description.$error }"
              enable-variables
              :enable-canned-responses="false"
              :placeholder="$t('CUSTOM_ROLE.ADD.FORM.DESCRIPTION.PLACEHOLDER')"
              @blur="v$.description.$touch"
            />
          </div>
        </div>

        <div class="w-full">
        <label :class="{ error: v$.permissions.$error }">
          {{ $t('CUSTOM_ROLE.ADD.FORM.PERMISSIONS.LABEL') }}
        </label>
        <div class="flex flex-col gap-2">
          <label>
            <input type="checkbox" @change="updatePermissions('conversation_manage', $event)" />
            conversation_manage
          </label>
          <label>
            <input type="checkbox" @change="updatePermissions('conversation_unassigned_manage', $event)" />
            conversation_unassigned_manage
          </label>
          <label>
            <input type="checkbox" @change="updatePermissions('conversation_participating_manage', $event)" />
            conversation_participating_manage
          </label>
          <label>
            <input type="checkbox" @change="updatePermissions('contact_manage', $event)" />
            contact_manage
          </label>
          <label>
            <input type="checkbox" @change="updatePermissions('report_manage', $event)" />
            report_manage
          </label>
          <label>
            <input type="checkbox" @change="updatePermissions('knowledge_base_manage', $event)" />
            knowledge_base_manage
          </label>
        </div>
      </div>

        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <WootSubmitButton
            :disabled="
              v$.name.$invalid ||
              v$.description.$invalid ||
              v$.permissions.$invalid ||
              addCustomRole.showLoading
            "
            :button-text="$t('CUSTOM_ROLE.ADD.FORM.SUBMIT')"
            :loading="addCustomRole.showLoading"
          />
          <button class="button clear" @click.prevent="onClose">
            {{ $t('CUSTOM_ROLE.ADD.CANCEL_BUTTON_TEXT') }}
          </button>
        </div>
      </form>
    </div>
  </Modal>
</template>

<style scoped lang="scss">
::v-deep {
  .ProseMirror-menubar {
    @apply hidden;
  }

  .ProseMirror-woot-style {
    @apply min-h-[12.5rem];

    p {
      @apply text-base;
    }
  }
}
</style>

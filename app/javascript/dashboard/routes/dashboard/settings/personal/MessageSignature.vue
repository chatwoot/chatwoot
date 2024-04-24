<template>
  <div class="flex flex-col gap-6">
    <woot-message-editor
      id="message-signature-input"
      v-model="messageSignature"
      class="message-editor h-[10rem] !px-3"
      :is-format-mode="true"
      :placeholder="$t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.PLACEHOLDER')"
      :enabled-menu-options="customEditorMenuList"
      :enable-suggestions="false"
      :show-image-resize-toolbar="true"
    />
    <v3-button
      type="submit"
      color-scheme="primary"
      variant="solid"
      size="large"
      @click.prevent="updateSignature"
    >
      {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.BTN_TEXT') }}
    </v3-button>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import alertMixin from 'shared/mixins/alertMixin';
import { MESSAGE_SIGNATURE_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';
import V3Button from 'v3/components/Form/Button.vue';

export default {
  components: {
    WootMessageEditor,
    V3Button,
  },
  mixins: [alertMixin],
  data() {
    return {
      messageSignature: '',
      enableMessageSignature: false,
      isUpdating: false,
      errorMessage: '',
      customEditorMenuList: MESSAGE_SIGNATURE_EDITOR_MENU_OPTIONS,
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentUserId: 'getCurrentUserID',
    }),
  },
  mounted() {
    this.initValues();
  },
  methods: {
    initValues() {
      const { message_signature: messageSignature } = this.currentUser;
      this.messageSignature = messageSignature || '';
    },
    async updateSignature() {
      try {
        await this.$store.dispatch('updateProfile', {
          message_signature: this.messageSignature || '',
        });
        this.errorMessage = this.$t(
          'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.API_SUCCESS'
        );
      } catch (error) {
        this.errorMessage = this.$t(
          'PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.API_ERROR'
        );
        if (error?.response?.data?.message) {
          this.errorMessage = error.response.data.message;
        }
      } finally {
        this.isUpdating = false;
        this.initValues();
        this.showAlert(this.errorMessage);
      }
    },
  },
};
</script>

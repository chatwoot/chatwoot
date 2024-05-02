<template>
  <div
    class="profile--settings--row text-black-900 dark:text-slate-300 flex items-center"
  >
    <div class="w-1/4 py-4 pr-6 ml-0">
      <h4 class="text-lg text-black-900 dark:text-slate-200">
        {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.TITLE') }}
      </h4>
      <p>{{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.NOTE') }}</p>
    </div>
    <div class="p-4 w-[45%]">
      <div>
        <label for="message-signature-input">{{
          $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.LABEL')
        }}</label>
        <woot-message-editor
          id="message-signature-input"
          v-model="messageSignature"
          class="message-editor h-[10rem]"
          :is-format-mode="true"
          :placeholder="
            $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE.PLACEHOLDER')
          "
          :enabled-menu-options="customEditorMenuList"
          :enable-suggestions="false"
          :show-image-resize-toolbar="true"
        />
      </div>
      <woot-button
        :is-loading="isUpdating"
        type="button"
        @click.prevent="updateSignature"
      >
        {{ $t('PROFILE_SETTINGS.FORM.MESSAGE_SIGNATURE_SECTION.BTN_TEXT') }}
      </woot-button>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';

import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import alertMixin from 'shared/mixins/alertMixin';
import { MESSAGE_SIGNATURE_EDITOR_MENU_OPTIONS } from 'dashboard/constants/editor';

export default {
  components: {
    WootMessageEditor,
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

<style lang="scss" scoped>
.message-editor {
  @apply px-3 mb-4;

  ::v-deep {
    .ProseMirror-menubar {
      @apply left-2;
    }
  }
}
</style>

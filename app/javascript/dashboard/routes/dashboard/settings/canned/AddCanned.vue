<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { mapGetters } from 'vuex';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Modal from '../../../../components/Modal.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

export default {
  name: 'AddCanned',
  components: {
    NextButton,
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
      shortCode: '',
      content: this.responseContent || '',
      visibility: 'public_response',
      selectedUsers: [],
      selectedTeams: [],
      selectedInboxes: [],
      addCanned: { showLoading: false },
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
  computed: {
    ...mapGetters({
      teams: 'teams/getTeams',
      inboxes: 'inboxes/getInboxes',
      agents: 'agents/getAgents',
      currentUser: 'getCurrentUser',
    }),
    isAdministrator() {
      return this.currentUser?.role === 'administrator';
    },
    isPrivate() {
      return this.visibility === 'private_response';
    },
    isVisibilityActive() {
      return key =>
        this.visibility === key
          ? 'bg-n-blue-2 dark:bg-n-blue-1 border-n-blue-3 dark:border-n-blue-4'
          : 'bg-white dark:bg-n-solid-2 border-n-weak dark:border-n-strong';
    },
    isFormInvalid() {
      if (this.v$.content.$invalid || this.v$.shortCode.$invalid) return true;
      if (this.isPrivate && this.isAdministrator) {
        const hasScope =
          this.selectedUsers.length > 0 ||
          this.selectedTeams.length > 0 ||
          this.selectedInboxes.length > 0;
        if (!hasScope) return true;
      }
      return false;
    },
  },
  mounted() {
    this.$store.dispatch('agents/get');
    this.$store.dispatch('teams/get');
    this.$store.dispatch('inboxes/get');
  },
  methods: {
    resetForm() {
      this.shortCode = '';
      this.content = '';
      this.visibility = 'public_response';
      this.selectedUsers = [];
      this.selectedTeams = [];
      this.selectedInboxes = [];
      this.v$.shortCode.$reset();
      this.v$.content.$reset();
    },
    onUpdateVisibility(value) {
      this.visibility = value;
      this.selectedUsers = [];
      this.selectedTeams = [];
      this.selectedInboxes = [];
    },
    buildPayload() {
      const payload = {
        short_code: this.shortCode,
        content: this.content,
        visibility: this.visibility,
      };
      if (this.isPrivate) {
        payload.inbox_ids = this.selectedInboxes.map(i => i.id);
        if (this.isAdministrator) {
          payload.user_ids = this.selectedUsers.map(u => u.id);
          payload.team_ids = this.selectedTeams.map(t => t.id);
        }
      }
      return payload;
    },
    async addCannedResponse() {
      this.addCanned.showLoading = true;
      try {
        await this.$store.dispatch('createCannedResponse', this.buildPayload());
        useAlert(this.$t('CANNED_MGMT.ADD.API.SUCCESS_MESSAGE'));
        this.resetForm();
        this.onClose();
      } catch (error) {
        useAlert(
          error?.message || this.$t('CANNED_MGMT.ADD.API.ERROR_MESSAGE')
        );
      } finally {
        this.addCanned.showLoading = false;
      }
    },
  },
};
</script>

<template>
  <Modal v-model:show="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header
        :header-title="$t('CANNED_MGMT.ADD.TITLE')"
        :header-content="$t('CANNED_MGMT.ADD.DESC')"
      />
      <form class="flex flex-col w-full" @submit.prevent="addCannedResponse">
        <div class="w-full">
          <label :class="{ error: v$.shortCode.$error }">
            {{ $t('CANNED_MGMT.ADD.FORM.SHORT_CODE.LABEL') }}
            <input
              v-model="shortCode"
              type="text"
              :placeholder="$t('CANNED_MGMT.ADD.FORM.SHORT_CODE.PLACEHOLDER')"
              @blur="v$.shortCode.$touch"
            />
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: v$.content.$error }">
            {{ $t('CANNED_MGMT.ADD.FORM.CONTENT.LABEL') }}
          </label>
          <div class="editor-wrap">
            <WootMessageEditor
              v-model="content"
              class="message-editor [&>div]:px-1"
              :class="{ editor_warning: v$.content.$error }"
              channel-type="Context::Default"
              enable-variables
              :enable-canned-responses="false"
              :placeholder="$t('CANNED_MGMT.ADD.FORM.CONTENT.PLACEHOLDER')"
              @blur="v$.content.$touch"
            />
          </div>
        </div>

        <div class="w-full mt-3">
          <p
            class="block m-0 text-sm font-medium leading-[1.8] text-n-slate-12"
          >
            {{ $t('CANNED_MGMT.ADD.FORM.VISIBILITY.LABEL') }}
          </p>
          <div class="grid grid-cols-2 gap-3 mt-1">
            <button
              type="button"
              class="p-2 relative rounded-md border border-solid text-left cursor-default"
              :class="isVisibilityActive('public_response')"
              @click="onUpdateVisibility('public_response')"
            >
              <fluent-icon
                v-if="visibility === 'public_response'"
                icon="checkmark-circle"
                type="solid"
                class="absolute text-n-brand top-2 right-2"
              />
              <p
                class="block m-0 text-sm font-medium leading-[1.8] text-n-slate-12"
              >
                {{ $t('CANNED_MGMT.ADD.FORM.VISIBILITY.PUBLIC.LABEL') }}
              </p>
              <p class="text-xs text-n-slate-11">
                {{ $t('CANNED_MGMT.ADD.FORM.VISIBILITY.PUBLIC.DESCRIPTION') }}
              </p>
            </button>
            <button
              type="button"
              class="p-2 relative rounded-md border border-solid text-left cursor-default"
              :class="isVisibilityActive('private_response')"
              @click="onUpdateVisibility('private_response')"
            >
              <fluent-icon
                v-if="visibility === 'private_response'"
                icon="checkmark-circle"
                type="solid"
                class="absolute text-n-brand top-2 right-2"
              />
              <p
                class="block m-0 text-sm font-medium leading-[1.8] text-n-slate-12"
              >
                {{ $t('CANNED_MGMT.ADD.FORM.VISIBILITY.PRIVATE.LABEL') }}
              </p>
              <p class="text-xs text-n-slate-11">
                {{ $t('CANNED_MGMT.ADD.FORM.VISIBILITY.PRIVATE.DESCRIPTION') }}
              </p>
            </button>
          </div>
        </div>

        <div v-if="isPrivate" class="w-full mt-3">
          <p
            class="block m-0 text-sm font-medium leading-[1.8] text-n-slate-12"
          >
            {{ $t('CANNED_MGMT.ADD.FORM.SCOPE.LABEL') }}
          </p>

          <template v-if="isAdministrator">
            <div class="mt-2">
              <label class="text-xs text-n-slate-11 mb-1 block">
                {{ $t('CANNED_MGMT.ADD.FORM.SCOPE.USER') }}
              </label>
              <multiselect
                v-model="selectedUsers"
                :options="agents"
                track-by="id"
                label="name"
                multiple
                :close-on-select="false"
                :placeholder="$t('CANNED_MGMT.ADD.FORM.SCOPE.PLACEHOLDER')"
                :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
                :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
              />
            </div>

            <div class="mt-2">
              <label class="text-xs text-n-slate-11 mb-1 block">
                {{ $t('CANNED_MGMT.ADD.FORM.SCOPE.TEAM') }}
              </label>
              <multiselect
                v-model="selectedTeams"
                :options="teams"
                track-by="id"
                label="name"
                multiple
                :close-on-select="false"
                :placeholder="$t('CANNED_MGMT.ADD.FORM.SCOPE.PLACEHOLDER')"
                :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
                :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
              />
            </div>
          </template>

          <div class="mt-2">
            <label class="text-xs text-n-slate-11 mb-1 block">
              {{ $t('CANNED_MGMT.ADD.FORM.SCOPE.INBOX') }}
            </label>
            <multiselect
              v-model="selectedInboxes"
              :options="inboxes"
              track-by="id"
              label="name"
              multiple
              :close-on-select="false"
              :placeholder="$t('CANNED_MGMT.ADD.FORM.SCOPE.PLACEHOLDER')"
              :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
              :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
            />
          </div>
        </div>

        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2 mt-3">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('CANNED_MGMT.ADD.CANCEL_BUTTON_TEXT')"
            @click.prevent="onClose"
          />
          <NextButton
            type="submit"
            :label="$t('CANNED_MGMT.ADD.FORM.SUBMIT')"
            :disabled="isFormInvalid || addCanned.showLoading"
            :is-loading="addCanned.showLoading"
          />
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

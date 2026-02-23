<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { mapGetters } from 'vuex';

import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Modal from '../../../../components/Modal.vue';

export default {
  components: {
    NextButton,
    Modal,
    WootMessageEditor,
  },
  props: {
    id: { type: Number, default: null },
    edcontent: { type: String, default: '' },
    edshortCode: { type: String, default: '' },
    edvisibility: { type: String, default: 'public_response' },
    edscopes: { type: Array, default: () => [] },
    onClose: { type: Function, default: () => {} },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      editCanned: { showLoading: false },
      shortCode: this.edshortCode,
      content: this.edcontent,
      visibility: this.edvisibility,
      selectedUsers: [],
      selectedTeams: [],
      selectedInboxes: [],
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
    pageTitle() {
      return `${this.$t('CANNED_MGMT.EDIT.TITLE')} - ${this.edshortCode}`;
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
    this.$nextTick(() => {
      this.initSelectedScope();
    });
  },
  methods: {
    initSelectedScope() {
      this.selectedUsers = this.agents.filter(a =>
        this.edscopes.some(
          s => Array.isArray(s.user_ids) && s.user_ids.includes(a.id)
        )
      );
      this.selectedTeams = this.teams.filter(t =>
        this.edscopes.some(
          s => Array.isArray(s.team_ids) && s.team_ids.includes(t.id)
        )
      );
      this.selectedInboxes = this.inboxes.filter(i =>
        this.edscopes.some(
          s => Array.isArray(s.inbox_ids) && s.inbox_ids.includes(i.id)
        )
      );
    },
    onUpdateVisibility(value) {
      this.visibility = value;
      this.selectedUsers = [];
      this.selectedTeams = [];
      this.selectedInboxes = [];
    },
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
    buildPayload() {
      const payload = {
        id: this.id,
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
    async editCannedResponse() {
      this.editCanned.showLoading = true;
      try {
        await this.$store.dispatch('updateCannedResponse', this.buildPayload());
        useAlert(this.$t('CANNED_MGMT.EDIT.API.SUCCESS_MESSAGE'));
        this.resetForm();
        setTimeout(() => this.onClose(), 10);
      } catch (error) {
        useAlert(
          error?.message || this.$t('CANNED_MGMT.EDIT.API.ERROR_MESSAGE')
        );
      } finally {
        this.editCanned.showLoading = false;
      }
    },
  },
};
</script>

<template>
  <Modal v-model:show="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="pageTitle" />
      <form class="flex flex-col w-full" @submit.prevent="editCannedResponse">
        <div class="w-full">
          <label :class="{ error: v$.shortCode.$error }">
            {{ $t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.LABEL') }}
            <input
              v-model="shortCode"
              type="text"
              :placeholder="$t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.PLACEHOLDER')"
              @input="v$.shortCode.$touch"
            />
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: v$.content.$error }">
            {{ $t('CANNED_MGMT.EDIT.FORM.CONTENT.LABEL') }}
          </label>
          <div class="editor-wrap">
            <WootMessageEditor
              v-model="content"
              class="message-editor [&>div]:px-1"
              :class="{ editor_warning: v$.content.$error }"
              channel-type="Context::Default"
              enable-variables
              :enable-canned-responses="false"
              :placeholder="$t('CANNED_MGMT.EDIT.FORM.CONTENT.PLACEHOLDER')"
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
            :label="$t('CANNED_MGMT.EDIT.CANCEL_BUTTON_TEXT')"
            @click.prevent="onClose"
          />
          <NextButton
            type="submit"
            :label="$t('CANNED_MGMT.EDIT.FORM.SUBMIT')"
            :disabled="isFormInvalid || editCanned.showLoading"
            :is-loading="editCanned.showLoading"
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

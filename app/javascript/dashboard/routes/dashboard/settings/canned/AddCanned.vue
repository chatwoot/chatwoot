<script>
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Modal from '../../../../components/Modal.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import InsertVariableButton from './InsertVariableButton.vue';

export default {
  name: 'AddCanned',
  components: {
    NextButton,
    Icon,
    Modal,
    WootMessageEditor,
    InsertVariableButton,
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
    const { isAdmin } = useAdmin();
    return { v$: useVuelidate(), isAdmin };
  },
  data() {
    return {
      shortCode: '',
      category: '',
      content: this.responseContent || '',
      visibility: 'personal',
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
  computed: {
    isPublicVisibilityDisabled() {
      return !this.isAdmin;
    },
    publicVisibilityDescription() {
      if (this.isPublicVisibilityDisabled) {
        return this.$t(
          'CANNED_MGMT.ADD.FORM.VISIBILITY.GLOBAL.CREATE_DISABLED_DESCRIPTION'
        );
      }
      return this.$t('CANNED_MGMT.ADD.FORM.VISIBILITY.GLOBAL.DESCRIPTION');
    },
  },
  created() {
    this.visibility = this.isAdmin ? 'global' : 'personal';
  },
  methods: {
    isActive(key) {
      return this.visibility === key
        ? 'bg-n-blue-2 dark:bg-n-blue-1 border-n-blue-3 dark:border-n-blue-4'
        : 'bg-white dark:bg-n-solid-2 border-n-weak dark:border-n-strong';
    },
    onUpdateVisibility(value) {
      if (value === 'global' && this.isPublicVisibilityDisabled) return;
      this.visibility = value;
    },
    insertVariable(key) {
      const token = `{{${key}}}`;
      this.content = this.content ? `${this.content}${token}` : token;
    },
    resetForm() {
      this.shortCode = '';
      this.category = '';
      this.content = '';
      this.visibility = this.isAdmin ? 'global' : 'personal';
      this.v$.shortCode.$reset();
      this.v$.content.$reset();
    },
    addCannedResponse() {
      this.addCanned.showLoading = true;
      this.$store
        .dispatch('createCannedResponse', {
          short_code: this.shortCode,
          content: this.content,
          category: this.category || null,
          visibility: this.visibility,
        })
        .then(() => {
          this.addCanned.showLoading = false;
          useAlert(
            this.isAdmin
              ? this.$t('CANNED_MGMT.ADD.API.SUCCESS_MESSAGE')
              : this.$t('CANNED_MGMT.ADD.API.SUCCESS_MESSAGE_PENDING')
          );
          this.resetForm();
          this.onClose();
        })
        .catch(error => {
          this.addCanned.showLoading = false;
          const errorMessage =
            error?.message || this.$t('CANNED_MGMT.ADD.API.ERROR_MESSAGE');
          useAlert(errorMessage);
        });
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
      <form class="flex flex-col w-full" @submit.prevent="addCannedResponse()">
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
          <label>
            {{ $t('CANNED_MGMT.ADD.FORM.CATEGORY.LABEL') }}
            <input
              v-model="category"
              type="text"
              :placeholder="$t('CANNED_MGMT.ADD.FORM.CATEGORY.PLACEHOLDER')"
            />
          </label>
          <p class="mb-0 text-xs text-n-slate-11">
            {{ $t('CANNED_MGMT.ADD.FORM.CATEGORY.HELP') }}
          </p>
        </div>

        <div v-if="isAdmin" class="w-full mt-2">
          <p class="block m-0 text-sm font-medium leading-[1.8] text-n-slate-12">
            {{ $t('CANNED_MGMT.ADD.FORM.VISIBILITY.LABEL') }}
          </p>
          <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
            <button
              type="button"
              class="flex flex-col items-start justify-between gap-2 p-2 text-start relative rounded-md border border-solid"
              :class="isActive('global')"
              @click="onUpdateVisibility('global')"
            >
              <div class="flex items-center justify-between w-full gap-2 min-w-0">
                <p class="block m-0 text-heading-3 text-n-slate-12 line-clamp-1">
                  {{ $t('CANNED_MGMT.ADD.FORM.VISIBILITY.GLOBAL.LABEL') }}
                </p>
                <Icon
                  v-if="visibility === 'global'"
                  icon="i-lucide-circle-check-big"
                  class="text-n-brand size-4"
                />
              </div>
              <p class="text-n-slate-11 text-label-small">
                {{ $t('CANNED_MGMT.ADD.FORM.VISIBILITY.GLOBAL.DESCRIPTION') }}
              </p>
            </button>
            <button
              type="button"
              class="flex flex-col items-start justify-between gap-2 p-2 text-start relative rounded-md border border-solid"
              :class="isActive('personal')"
              @click="onUpdateVisibility('personal')"
            >
              <div class="flex items-center justify-between w-full gap-2 min-w-0">
                <p class="block m-0 text-heading-3 text-n-slate-12 line-clamp-1">
                  {{ $t('CANNED_MGMT.ADD.FORM.VISIBILITY.PERSONAL.LABEL') }}
                </p>
                <Icon
                  v-if="visibility === 'personal'"
                  icon="i-lucide-circle-check-big"
                  class="text-n-brand size-4"
                />
              </div>
              <p class="text-n-slate-11 text-label-small">
                {{ $t('CANNED_MGMT.ADD.FORM.VISIBILITY.PERSONAL.DESCRIPTION') }}
              </p>
            </button>
          </div>
        </div>
        <p
          v-else
          class="w-full mt-2 mb-0 text-xs text-n-slate-11 rounded-md border border-solid border-n-weak bg-n-alpha-black2 px-2.5 py-2"
        >
          {{ $t('CANNED_MGMT.ADD.AGENT_PENDING_HINT') }}
        </p>

        <div class="w-full mt-2">
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
          <div class="flex flex-col gap-2 mt-2">
            <InsertVariableButton @insert="insertVariable" />
            <p class="mb-0 text-xs text-n-slate-11">
              {{ $t('CANNED_MGMT.ADD.FORM.CONTENT.VARIABLES_HELP') }}
            </p>
          </div>
        </div>
        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
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
            :disabled="
              v$.content.$invalid ||
              v$.shortCode.$invalid ||
              addCanned.showLoading
            "
            :is-loading="addCanned.showLoading"
          />
        </div>
      </form>
    </div>
  </Modal>
</template>

<style scoped lang="scss">
:deep(.ProseMirror-menubar) {
  @apply hidden;
}

:deep(.ProseMirror-woot-style) {
  @apply min-h-[12.5rem];

  p {
    @apply text-base;
  }
}
</style>

<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import validations, { getLabelTitleErrorMessage } from './validations';
import { useVuelidate } from '@vuelidate/core';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    selectedResponse: {
      type: Object,
      default: () => {},
    },
  },
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      title: '',
      description: '',
      showOnSidebar: true,
      color: '',
    };
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'labels/getUIFlags',
    }),
    pageTitle() {
      return `${this.$t('LABEL_MGMT.EDIT.TITLE')} - ${
        this.selectedResponse.title
      }`;
    },
    labelTitleErrorMessage() {
      const errorMessage = getLabelTitleErrorMessage(this.v$);
      return this.$t(errorMessage);
    },
  },
  mounted() {
    this.setFormValues();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    setFormValues() {
      this.title = this.selectedResponse.title;
      this.description = this.selectedResponse.description;
      this.showOnSidebar = this.selectedResponse.show_on_sidebar;
      this.color = this.selectedResponse.color;
    },
    editLabel() {
      this.$store
        .dispatch('labels/update', {
          id: this.selectedResponse.id,
          color: this.color,
          description: this.description,
          title: this.title.toLowerCase(),
          show_on_sidebar: this.showOnSidebar,
        })
        .then(() => {
          useAlert(this.$t('LABEL_MGMT.EDIT.API.SUCCESS_MESSAGE'));
          setTimeout(() => this.onClose(), 10);
        })
        .catch(() => {
          useAlert(this.$t('LABEL_MGMT.EDIT.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>

<template>
  <div class="flex h-auto flex-col overflow-auto">
    <woot-modal-header :header-title="pageTitle" />
    <form
      class="mx-0 flex w-full flex-col gap-5 px-1 pb-1 pt-2"
      @submit.prevent="editLabel"
    >
      <woot-input
        v-model="title"
        :class="{ error: v$.title.$error }"
        class="label-name--input w-full"
        :label="$t('LABEL_MGMT.FORM.NAME.LABEL')"
        :placeholder="$t('LABEL_MGMT.FORM.NAME.PLACEHOLDER')"
        :error="labelTitleErrorMessage"
        @input="v$.title.$touch"
        @blur="v$.title.$touch"
      />
      <woot-input
        v-model="description"
        :class="{ error: v$.description.$error }"
        class="w-full"
        :label="$t('LABEL_MGMT.FORM.DESCRIPTION.LABEL')"
        :placeholder="$t('LABEL_MGMT.FORM.DESCRIPTION.PLACEHOLDER')"
        @input="v$.description.$touch"
        @blur="v$.description.$touch"
      />

      <div class="w-full">
        <span
          class="mb-2 block text-xs font-semibold uppercase tracking-wider text-on-surface-variant"
        >
          {{ $t('LABEL_MGMT.FORM.COLOR.LABEL') }}
        </span>
        <woot-color-picker v-model="color" />
      </div>
      <div
        class="flex w-full items-start gap-3 rounded-lg border border-outline-variant/20 bg-surface-container-lowest/60 p-3"
      >
        <input
          id="label-edit-show-sidebar"
          v-model="showOnSidebar"
          type="checkbox"
          class="mt-0.5 size-4 shrink-0 rounded border-outline-variant/40 text-secondary focus:ring-secondary"
          :value="true"
        />
        <label
          for="label-edit-show-sidebar"
          class="cursor-pointer text-sm leading-snug text-on-surface"
        >
          {{ $t('LABEL_MGMT.FORM.SHOW_ON_SIDEBAR.LABEL') }}
        </label>
      </div>
      <div
        class="mt-1 flex w-full items-center justify-end gap-2 border-t border-outline-variant/15 pt-4"
      >
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('LABEL_MGMT.FORM.CANCEL')"
          @click.prevent="onClose"
        />
        <NextButton
          solid
          teal
          type="submit"
          :label="$t('LABEL_MGMT.FORM.EDIT')"
          :disabled="v$.title.$invalid || uiFlags.isUpdating"
          :is-loading="uiFlags.isUpdating"
        />
      </div>
    </form>
  </div>
</template>

<style lang="scss" scoped>
// Label API supports only lowercase letters
.label-name--input {
  ::v-deep {
    input {
      @apply lowercase;
    }
  }
}
</style>

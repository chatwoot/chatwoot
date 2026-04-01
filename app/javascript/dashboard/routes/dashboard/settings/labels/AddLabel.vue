<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import validations, { getLabelTitleErrorMessage } from './validations';
import { getRandomColor } from 'dashboard/helper/labelColor';
import { useVuelidate } from '@vuelidate/core';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    prefillTitle: {
      type: String,
      default: '',
    },
  },
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
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
    labelTitleErrorMessage() {
      const errorMessage = getLabelTitleErrorMessage(this.v$);
      return this.$t(errorMessage);
    },
  },
  mounted() {
    this.color = getRandomColor();
    this.title = this.prefillTitle.toLowerCase();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async addLabel() {
      try {
        await this.$store.dispatch('labels/create', {
          color: this.color,
          description: this.description,
          title: this.title.toLowerCase(),
          show_on_sidebar: this.showOnSidebar,
        });
        useAlert(this.$t('LABEL_MGMT.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error.message || this.$t('LABEL_MGMT.ADD.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <div class="flex h-auto flex-col overflow-auto">
    <woot-modal-header
      :header-title="$t('LABEL_MGMT.ADD.TITLE')"
      :header-content="$t('LABEL_MGMT.ADD.DESC')"
    />
    <form
      class="mx-0 flex w-full flex-col gap-5 px-1 pb-1 pt-2"
      @submit.prevent="addLabel"
    >
      <woot-input
        v-model="title"
        :class="{ error: v$.title.$error }"
        class="label-name--input w-full"
        :label="$t('LABEL_MGMT.FORM.NAME.LABEL')"
        :placeholder="$t('LABEL_MGMT.FORM.NAME.PLACEHOLDER')"
        :error="labelTitleErrorMessage"
        data-testid="label-title"
        @input="v$.title.$touch"
        @blur="v$.title.$touch"
      />

      <woot-input
        v-model="description"
        :class="{ error: v$.description.$error }"
        class="w-full"
        :label="$t('LABEL_MGMT.FORM.DESCRIPTION.LABEL')"
        :placeholder="$t('LABEL_MGMT.FORM.DESCRIPTION.PLACEHOLDER')"
        data-testid="label-description"
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
          id="label-add-show-sidebar"
          v-model="showOnSidebar"
          type="checkbox"
          class="mt-0.5 size-4 shrink-0 rounded border-outline-variant/40 text-secondary focus:ring-secondary"
          :value="true"
        />
        <label
          for="label-add-show-sidebar"
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
          data-testid="label-submit"
          :label="$t('LABEL_MGMT.FORM.CREATE')"
          :disabled="v$.title.$invalid || uiFlags.isCreating"
          :is-loading="uiFlags.isCreating"
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

<template>
  <div class="h-auto overflow-auto flex flex-col">
    <woot-modal-header
      :header-title="$t('SLA.ADD.TITLE')"
      :header-content="$t('SLA.ADD.DESC')"
    />
    <form class="mx-0 flex flex-wrap" @submit.prevent="addSLA">
      <woot-input
        v-model.trim="title"
        :class="{ error: $v.title.$error }"
        class="w-full sla-name--input"
        :sla="$t('SLA.FORM.NAME.SLA')"
        :placeholder="$t('SLA.FORM.NAME.PLACEHOLDER')"
        :error="getSLATitleErrorMessage"
        data-testid="sla-title"
        @input="$v.title.$touch"
      />

      <woot-input
        v-model.trim="description"
        :class="{ error: $v.description.$error }"
        class="w-full"
        :sla="$t('SLA.FORM.DESCRIPTION.SLA')"
        :placeholder="$t('SLA.FORM.DESCRIPTION.PLACEHOLDER')"
        data-testid="sla-description"
        @input="$v.description.$touch"
      />

      <div class="w-full">
        <sla>
          {{ $t('SLA.FORM.COLOR.SLA') }}
          <woot-color-picker v-model="color" />
        </sla>
      </div>
      <div class="w-full">
        <input v-model="showOnSidebar" type="checkbox" :value="true" />
        <sla for="conversation_creation">
          {{ $t('SLA.FORM.SHOW_ON_SIDEBAR.SLA') }}
        </sla>
      </div>
      <div class="flex justify-end items-center py-2 px-0 gap-2 w-full">
        <woot-button
          :is-disabled="$v.title.$invalid || uiFlags.isCreating"
          :is-loading="uiFlags.isCreating"
          data-testid="sla-submit"
        >
          {{ $t('SLA.FORM.CREATE') }}
        </woot-button>
        <woot-button class="button clear" @click.prevent="onClose">
          {{ $t('SLA.FORM.CANCEL') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import validationMixin from './validationMixin';
import { mapGetters } from 'vuex';
import validations from './validations';
import { getRandomColor } from 'dashboard/helper/labelColor';

export default {
  mixins: [alertMixin, validationMixin],
  props: {
    prefillTitle: {
      type: String,
      default: '',
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
      uiFlags: 'slas/getUIFlags',
    }),
  },
  mounted() {
    this.color = getRandomColor();
    this.title = this.prefillTitle.toLowerCase();
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async addSLA() {
      try {
        await this.$store.dispatch('slas/create', {
          color: this.color,
          description: this.description,
          title: this.title.toLowerCase(),
          show_on_sidebar: this.showOnSidebar,
        });
        this.showAlert(this.$t('SLA.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error.message || this.$t('SLA.ADD.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
  },
};
</script>
<style lang="scss" scoped>
// SLA API supports only lowercase letters
.sla-name--input {
  ::v-deep {
    input {
      @apply lowercase;
    }
  }
}
</style>

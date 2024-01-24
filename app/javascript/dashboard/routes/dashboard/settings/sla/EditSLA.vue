<template>
  <div class="h-auto overflow-auto flex flex-col">
    <woot-modal-header :header-title="pageTitle" />
    <form class="mx-0 flex flex-wrap" @submit.prevent="editSLA">
      <woot-input
        v-model.trim="title"
        :class="{ error: $v.title.$error }"
        class="w-full sla-name--input"
        :sla="$t('SLA.FORM.NAME.SLA')"
        :placeholder="$t('SLA.FORM.NAME.PLACEHOLDER')"
        :error="getSLATitleErrorMessage"
        @input="$v.title.$touch"
      />
      <woot-input
        v-model.trim="description"
        :class="{ error: $v.description.$error }"
        class="w-full"
        :sla="$t('SLA.FORM.DESCRIPTION.SLA')"
        :placeholder="$t('SLA.FORM.DESCRIPTION.PLACEHOLDER')"
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
          :is-disabled="$v.title.$invalid || uiFlags.isUpdating"
          :is-loading="uiFlags.isUpdating"
        >
          {{ $t('SLA.FORM.EDIT') }}
        </woot-button>
        <woot-button class="button clear" @click.prevent="onClose">
          {{ $t('SLA.FORM.CANCEL') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import validationMixin from './validationMixin';
import validations from './validations';

export default {
  mixins: [alertMixin, validationMixin],
  props: {
    selectedResponse: {
      type: Object,
      default: () => {},
    },
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
      uiFlags: 'slas/getUIFlags',
    }),
    pageTitle() {
      return `${this.$t('SLA.EDIT.TITLE')} - ${this.selectedResponse.title}`;
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
    editSLA() {
      this.$store
        .dispatch('slas/update', {
          id: this.selectedResponse.id,
          color: this.color,
          description: this.description,
          title: this.title.toLowerCase(),
          show_on_sidebar: this.showOnSidebar,
        })
        .then(() => {
          this.showAlert(this.$t('SLA.EDIT.API.SUCCESS_MESSAGE'));
          setTimeout(() => this.onClose(), 10);
        })
        .catch(() => {
          this.showAlert(this.$t('SLA.EDIT.API.ERROR_MESSAGE'));
        });
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

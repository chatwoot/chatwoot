<template>
  <div class="column content-box">
    <woot-modal-header :header-title="pageTitle" />
    <form class="row" @submit.prevent="editLabel">
      <woot-input
        v-model.trim="title"
        :class="{ error: $v.title.$error }"
        class="medium-12 columns"
        :label="$t('LABEL_MGMT.FORM.NAME.LABEL')"
        :placeholder="$t('LABEL_MGMT.FORM.NAME.PLACEHOLDER')"
        :error="getLabelTitleErrorMessage"
        @input="$v.title.$touch"
      />
      <woot-input
        v-model.trim="description"
        :class="{ error: $v.description.$error }"
        class="medium-12 columns"
        :label="$t('LABEL_MGMT.FORM.DESCRIPTION.LABEL')"
        :placeholder="$t('LABEL_MGMT.FORM.DESCRIPTION.PLACEHOLDER')"
        @input="$v.description.$touch"
      />

      <div class="medium-12">
        <label>
          {{ $t('LABEL_MGMT.FORM.COLOR.LABEL') }}
          <woot-color-picker v-model="color" />
        </label>
      </div>
      <div class="medium-12">
        <input v-model="showOnSidebar" type="checkbox" :value="true" />
        <label for="conversation_creation">
          {{ $t('LABEL_MGMT.FORM.SHOW_ON_SIDEBAR.LABEL') }}
        </label>
      </div>
      <div class="modal-footer">
        <div class="medium-12 columns">
          <woot-button
            :is-disabled="$v.title.$invalid || uiFlags.isUpdating"
            :is-loading="uiFlags.isUpdating"
          >
            {{ $t('LABEL_MGMT.FORM.EDIT') }}
          </woot-button>
          <woot-button class="button clear" @click.prevent="onClose">
            {{ $t('LABEL_MGMT.FORM.CANCEL') }}
          </woot-button>
        </div>
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
      uiFlags: 'labels/getUIFlags',
    }),
    pageTitle() {
      return `${this.$t('LABEL_MGMT.EDIT.TITLE')} - ${
        this.selectedResponse.title
      }`;
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
          title: this.title,
          show_on_sidebar: this.showOnSidebar,
        })
        .then(() => {
          this.showAlert(this.$t('LABEL_MGMT.EDIT.API.SUCCESS_MESSAGE'));
          setTimeout(() => this.onClose(), 10);
        })
        .catch(() => {
          this.showAlert(this.$t('LABEL_MGMT.EDIT.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>

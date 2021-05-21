<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header
        :header-title="integration.name"
        :header-content="integration.description"
      />
      <FormulateForm
        #default="{ hasErrors }"
        v-model="values"
        @submit="submitForm"
      >
        <FormulateInput
          v-for="item in formItems"
          :key="item.name"
          v-bind="item"
        />

        <FormulateInput
          v-if="showInboxSelect"
          :options="inboxes"
          type="select"
          name="inbox"
          placeholder="Select Inbox"
          label="Select Inbox"
          validation="required"
          validation-name="Inbox"
        />
        <div class="modal-footer">
          <woot-button :disabled="hasErrors" :loading="addHook.showLoading">
            Create
          </woot-button>
          <woot-button class="button clear" @click.prevent="onClose">
            Cancel
          </woot-button>
        </div>
      </FormulateForm>
    </div>
  </modal>
</template>
<script>
/* global bus */
import { mapGetters } from 'vuex';
import Modal from '../../../../components/Modal';

export default {
  components: {
    Modal,
  },
  props: {
    onClose: {
      type: Function,
      required: true,
    },
    integration: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      endPoint: '',
      addHook: {
        showAlert: false,
        showLoading: false,
        message: '',
      },
      show: true,
      values: {},
      formItems: this.integration.settings_form_schema,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
    }),
    inboxes() {
      const inboxes = this.$store.getters['inboxes/getInboxes'];
      const selectedInboxes = inboxes
        .filter(item => item.channel_type === 'Channel::WebWidget')
        .map(item => {
          return { ...item, label: item.name, value: item.id };
        });
      return selectedInboxes;
    },
    showInboxSelect() {
      return this.integration.hook_type === 'inbox';
    },
  },
  methods: {
    showAlert() {
      bus.$emit('newToastMessage', this.addHook.message);
    },
    async submitForm() {
      this.addHook.showLoading = true;
      const hookSettings = {};
      Object.keys(this.values).forEach(key => {
        if (key !== 'inbox') {
          hookSettings[key] = this.values[key];
        }
      });
      // eslint-disable-next-line no-prototype-builtins
      if (hookSettings.hasOwnProperty('inbox')) {
        delete hookSettings.inbox;
      }

      const hookData = {
        app_id: this.integration.id,
        inbox_id: this.values.inbox,
        settings: hookSettings,
      };
      // eslint-disable-next-line
      if (this.values.hasOwnProperty('inbox_id')) {
        hookData.inbox_id = this.values.inbox_id;
      }
      try {
        await this.$store.dispatch('integrations/createHook', hookData);
        this.addHook.showLoading = false;
        this.addHook.message = 'Hook added successfully';
        this.showAlert();
        this.onClose();
      } catch (error) {
        this.addHook.showLoading = false;
        this.addHook.message =
          error.response.data.message || 'Something went wrong';
        this.showAlert();
      }
    },
  },
};
</script>
<style lang="scss" scoped></style>

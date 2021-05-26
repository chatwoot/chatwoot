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
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import Modal from '../../../../components/Modal';

export default {
  components: {
    Modal,
  },
  mixins: [alertMixin],
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
    formItems() {
      return this.integration.settings_form_schema;
    },
    showInboxSelect() {
      return this.integration.hook_type === 'inbox';
    },
  },
  methods: {
    async submitForm() {
      this.addHook.showLoading = true;
      const hookSettings = {};
      Object.keys(this.values).forEach(key => {
        if (key !== 'inbox') {
          hookSettings[key] = this.values[key];
        }
      });
      this.formItems.forEach(item => {
        if (item.validation.includes('JSON')) {
          hookSettings[item.name] = JSON.parse(hookSettings[item.name]);
        }
      });
      const hookData = {
        app_id: this.integration.id,
        settings: hookSettings,
      };

      if (this.showInboxSelect && this.values.inbox) {
        hookData.inbox_id = this.values.inbox;
      }
      console.log('Hook data', hookData);
      try {
        await this.$store.dispatch('integrations/createHook', hookData);
        this.addHook.message = 'Hook added successfully';
        this.onClose();
      } catch (error) {
        this.addHook.message =
          error.response.data.message || 'Something went wrong';
      } finally {
        this.addHook.showLoading = false;
        this.showAlert(this.addHook.message);
      }
    },
  },
};
</script>
<style lang="scss" scoped></style>

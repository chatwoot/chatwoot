<template>
  <div class="mx-8">
    <settings-section
      :title="'Agent Status Email Notifications'"
      :sub-title="'Configure email notifications when agents go online or offline'"
    >
      <form @submit.prevent="updateSettings">
        <label for="toggle-notifications" class="toggle-input-wrap">
          <input
            v-model="isNotificationsEnabled"
            type="checkbox"
            class="ltr:mr-2 rtl:ml-2"
            name="toggle-notifications"
          />
          Send email notifications when agents change their status
        </label>
        <p class="text-slate-700 dark:text-slate-300 mb-4">
          When enabled, selected administrators will receive email notifications
          when any agent goes online or offline.
        </p>

        <div v-if="isNotificationsEnabled" class="mb-6">
          <div class="recipients-input-wrap">
            <label> Select Administrators to Notify </label>
            <multiselect
              v-model="selectedAdmins"
              :options="administratorOptions"
              :multiple="true"
              :close-on-select="false"
              :clear-on-select="false"
              :preserve-search="true"
              placeholder="Select one or more administrators"
              track-by="value"
              label="label"
              deselect-label=""
              select-label=""
              selected-label=""
            >
              <template slot="selection" slot-scope="{ values, isOpen }">
                <span
                  v-if="values.length && !isOpen"
                  class="multiselect__single"
                >
                  {{ values.length }} administrator(s) selected
                </span>
              </template>
            </multiselect>
            <p
              v-if="isNotificationsEnabled && selectedAdmins.length === 0"
              class="text-red-600 dark:text-red-400 text-sm mt-1"
            >
              Please select at least one administrator to receive notifications
            </p>
          </div>
        </div>

        <woot-submit-button
          :button-text="'Save Notification Settings'"
          :loading="isUpdating"
          :disabled="hasError"
        />
      </form>
    </settings-section>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import SettingsSection from 'dashboard/components/SettingsSection.vue';

export default {
  components: {
    SettingsSection,
  },
  mixins: [alertMixin],
  props: {
    accountId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      isNotificationsEnabled: false,
      selectedAdmins: [],
      isUpdating: false,
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      agentList: 'agents/getAgents',
    }),
    administratorOptions() {
      // Filter only administrators from agent list
      const admins = this.agentList.filter(
        agent => agent.role === 'administrator'
      );

      // Map to multiselect format
      return admins.map(admin => ({
        label: `${admin.name} (${admin.email})`,
        value: admin.email,
      }));
    },
    hasError() {
      // Error if notifications enabled but no admins selected
      if (this.isNotificationsEnabled && this.selectedAdmins.length === 0) {
        return true;
      }
      return false;
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      const { custom_attributes } = this.getAccount(this.accountId);
      const settings = custom_attributes?.agent_status_notifications;

      if (settings) {
        this.isNotificationsEnabled = settings.enabled || false;

        if (settings.recipient_emails && settings.recipient_emails.length) {
          // Map email addresses back to multiselect options
          this.selectedAdmins = settings.recipient_emails
            .map(email => {
              const admin = this.agentList.find(agent => agent.email === email);
              if (admin) {
                return {
                  label: `${admin.name} (${admin.email})`,
                  value: admin.email,
                };
              }
              return null;
            })
            .filter(Boolean);
        }
      }
    },
    async updateSettings() {
      try {
        this.isUpdating = true;

        const agentStatusNotifications = {
          enabled: this.isNotificationsEnabled,
          recipient_emails: this.selectedAdmins.map(admin => admin.value),
        };

        await this.$store.dispatch('accounts/update', {
          agent_status_notifications: agentStatusNotifications,
        });

        this.showAlert('Notification settings updated successfully');
      } catch (error) {
        this.showAlert(
          error.message ||
            "We couldn't update notification settings. Please try again later."
        );
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.recipients-input-wrap {
  @apply max-w-[37.5rem];

  &::v-deep .multiselect {
    @apply mt-2;
  }
}

.toggle-input-wrap {
  @apply flex items-center mb-2;
}
</style>

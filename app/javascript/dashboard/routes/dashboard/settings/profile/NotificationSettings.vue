<template>
  <div>
    <div class="profile--settings--row row">
      <div class="columns small-3 ">
        <h4 class="block-title">
          {{ $t('PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.TITLE') }}
        </h4>
        <p>
          {{ $t('PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.NOTE') }}
        </p>
      </div>
      <div class="columns small-9">
        <div>
          <input
            v-model="selectedEmailFlags"
            class="notification--checkbox"
            type="checkbox"
            value="email_conversation_creation"
            @input="handleEmailInput"
          />
          <label for="conversation_creation">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.CONVERSATION_CREATION'
              )
            }}
          </label>
        </div>

        <div>
          <input
            v-model="selectedEmailFlags"
            class="notification--checkbox"
            type="checkbox"
            value="email_conversation_assignment"
            @input="handleEmailInput"
          />
          <label for="conversation_assignment">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.CONVERSATION_ASSIGNMENT'
              )
            }}
          </label>
        </div>

        <div>
          <input
            v-model="selectedEmailFlags"
            class="notification--checkbox"
            type="checkbox"
            value="email_assigned_conversation_new_message"
            @input="handleEmailInput"
          />
          <label for="assigned_conversation_new_message">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.ASSIGNED_CONVERSATION_NEW_MESSAGE'
              )
            }}
          </label>
        </div>
      </div>
    </div>
    <div v-if="vapidPublicKey" class="profile--settings--row row push-row">
      <div class="columns small-3 ">
        <h4 class="block-title">
          {{ $t('PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.TITLE') }}
        </h4>
        <p>{{ $t('PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.NOTE') }}</p>
      </div>
      <div class="columns small-9">
        <p v-if="hasEnabledPushPermissions">
          {{
            $t(
              'PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.HAS_ENABLED_PUSH'
            )
          }}
        </p>
        <div v-else>
          <woot-submit-button
            :button-text="
              $t(
                'PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.REQUEST_PUSH'
              )
            "
            class="button nice small"
            type="button"
            @click="onRequestPermissions"
          />
        </div>
        <div>
          <input
            v-model="selectedPushFlags"
            class="notification--checkbox"
            type="checkbox"
            value="push_conversation_creation"
            @input="handlePushInput"
          />
          <label for="conversation_creation">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.CONVERSATION_CREATION'
              )
            }}
          </label>
        </div>

        <div>
          <input
            v-model="selectedPushFlags"
            class="notification--checkbox"
            type="checkbox"
            value="push_conversation_assignment"
            @input="handlePushInput"
          />
          <label for="conversation_assignment">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.CONVERSATION_ASSIGNMENT'
              )
            }}
          </label>
        </div>

        <div>
          <input
            v-model="selectedPushFlags"
            class="notification--checkbox"
            type="checkbox"
            value="push_assigned_conversation_new_message"
            @input="handlePushInput"
          />
          <label for="assigned_conversation_new_message">
            {{
              $t(
                'PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.ASSIGNED_CONVERSATION_NEW_MESSAGE'
              )
            }}
          </label>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import {
  hasPushPermissions,
  requestPushPermissions,
  verifyServiceWorkerExistence,
} from '../../../../helper/pushHelper';

export default {
  mixins: [alertMixin, configMixin],
  data() {
    return {
      selectedEmailFlags: [],
      selectedPushFlags: [],
      hasEnabledPushPermissions: false,
    };
  },
  computed: {
    ...mapGetters({
      emailFlags: 'userNotificationSettings/getSelectedEmailFlags',
      pushFlags: 'userNotificationSettings/getSelectedPushFlags',
    }),
  },
  watch: {
    emailFlags(value) {
      this.selectedEmailFlags = value;
    },
    pushFlags(value) {
      this.selectedPushFlags = value;
    },
  },
  mounted() {
    if (hasPushPermissions()) {
      this.getPushSubscription();
    }

    this.$store.dispatch('userNotificationSettings/get');
  },
  methods: {
    onRegistrationSuccess() {
      this.hasEnabledPushPermissions = true;
    },
    onRequestPermissions() {
      requestPushPermissions({
        onSuccess: this.onRegistrationSuccess,
      });
    },
    getPushSubscription() {
      verifyServiceWorkerExistence(registration =>
        registration.pushManager
          .getSubscription()
          .then(subscription => {
            if (!subscription) {
              this.hasEnabledPushPermissions = false;
            } else {
              this.hasEnabledPushPermissions = true;
            }
          })
          .catch(error => console.log(error))
      );
    },
    async updateNotificationSettings() {
      try {
        this.$store.dispatch('userNotificationSettings/update', {
          selectedEmailFlags: this.selectedEmailFlags,
          selectedPushFlags: this.selectedPushFlags,
        });
        this.showAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_SUCCESS'));
      } catch (error) {
        this.showAlert(this.$t('PROFILE_SETTINGS.FORM.API.UPDATE_ERROR'));
      }
    },
    handleEmailInput(e) {
      this.selectedEmailFlags = this.toggleInput(
        this.selectedEmailFlags,
        e.target.value
      );

      this.updateNotificationSettings();
    },
    handlePushInput(e) {
      this.selectedPushFlags = this.toggleInput(
        this.selectedPushFlags,
        e.target.value
      );

      this.updateNotificationSettings();
    },
    toggleInput(selected, current) {
      if (selected.includes(current)) {
        const newSelectedFlags = selected.filter(flag => flag !== current);
        return newSelectedFlags;
      }
      return [...selected, current];
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables.scss';

.notification--checkbox {
  font-size: $font-size-large;
}

// Hide on Safari
.push-row:not(:root:root) {
  display: none;
}
</style>

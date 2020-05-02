<template>
  <div class="profile--settings--row row">
    <div class="columns small-3 ">
      <h4 class="block-title">
        {{ $t('PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.TITLE') }}
      </h4>
      <p>{{ $t('PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.NOTE') }}</p>
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
    </div>

    <div class="columns small-3 ">
      <h4 class="block-title">
        {{ $t('PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.TITLE') }}
      </h4>
      <p>{{ $t('PROFILE_SETTINGS.FORM.PUSH_NOTIFICATIONS_SECTION.NOTE') }}</p>
    </div>
    <div class="columns small-9">
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
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  mixins: [alertMixin],
  data() {
    return {
      selectedEmailFlags: [],
      selectedPushFlags: [],
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
    this.$store.dispatch('userNotificationSettings/get');
  },
  methods: {
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
</style>

<template>
  <div class="profile--settings--row row">
    <div class="columns small-3 ">
      <p class="section--title">
        {{ $t('PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.TITLE') }}
      </p>
      <p>{{ $t('PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.NOTE') }}</p>
    </div>
    <div class="columns small-9">
      <div>
        <input
          v-model="selectedNotifications"
          class="email-notification--checkbox"
          type="checkbox"
          value="conversation_creation"
          @input="handleInput"
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
          v-model="selectedNotifications"
          class="email-notification--checkbox"
          type="checkbox"
          value="conversation_assignment"
          @input="handleInput"
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
  </div>
</template>

<script>
/* global bus */
import { mapGetters } from 'vuex';

export default {
  data() {
    return {
      selectedNotifications: [],
    };
  },
  computed: {
    ...mapGetters({
      selectedEmailFlags: 'userNotificationSettings/getSelectedEmailFlags',
    }),
  },
  watch: {
    selectedEmailFlags(value) {
      this.selectedNotifications = value;
    },
  },
  mounted() {
    this.$store.dispatch('userNotificationSettings/get');
  },
  methods: {
    async handleInput(e) {
      const selectedValue = e.target.value;
      if (this.selectedEmailFlags.includes(e.target.value)) {
        const selectedEmailFlags = this.selectedEmailFlags.filter(
          flag => flag !== selectedValue
        );
        this.selectedNotifications = selectedEmailFlags;
      } else {
        this.selectedNotifications = [
          ...this.selectedEmailFlags,
          selectedValue,
        ];
      }
      try {
        this.$store.dispatch(
          'userNotificationSettings/update',
          this.selectedNotifications
        );
        bus.$emit(
          'newToastMessage',
          this.$t(
            'PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.UPDATE_SUCCESS'
          )
        );
      } catch (error) {
        bus.$emit(
          'newToastMessage',
          this.$t(
            'PROFILE_SETTINGS.FORM.EMAIL_NOTIFICATIONS_SECTION.UPDATE_ERROR'
          )
        );
      }
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables.scss';

.email-notification--checkbox {
  font-size: $font-size-large;
}
</style>

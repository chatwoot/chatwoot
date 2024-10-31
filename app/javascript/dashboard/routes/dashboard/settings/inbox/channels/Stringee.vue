<template>
  <div
    class="border border-slate-25 dark:border-slate-800/60 bg-white dark:bg-slate-900 h-full p-6 w-full max-w-full md:w-3/4 md:max-w-[75%] flex-shrink-0 flex-grow-0"
  >
    <page-header
      :header-title="$t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.TITLE')"
      :header-content="$t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.DESC')"
    />
    <form class="mx-0 flex flex-wrap" @submit.prevent="createChannel()">
      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <label :class="{ error: $v.channelName.$error }">
          {{ $t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.CHANNEL_NAME.LABEL') }}
          <input
            v-model.trim="channelName"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.CHANNEL_NAME.PLACEHOLDER')
            "
            @blur="$v.channelName.$touch"
          />
          <span v-if="$v.channelName.$error" class="message">{{
            $t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.CHANNEL_NAME.ERROR')
          }}</span>
        </label>
      </div>

      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <label :class="{ error: $v.phoneNumber.$error }">
          {{ $t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.PHONE_NUMBER.LABEL') }}
          <input
            v-model.trim="phoneNumber"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.PHONE_NUMBER.PLACEHOLDER')
            "
            @blur="$v.phoneNumber.$touch"
          />
        </label>
      </div>

      <div class="w-[65%] flex-shrink-0 flex-grow-0 max-w-[65%]">
        <span class="text-sm notification-label">
          {{ $t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.ROUTE_TYPE.TITLE') }}
        </span>
        <div class="flex items-center gap-2 mb-1">
          <input
            id="by_group"
            v-model="routeType"
            class="notification--checkbox"
            type="radio"
            value="by_group"
          />
          <label for="by_group">
            {{ $t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.ROUTE_TYPE.GROUP') }}
          </label>
        </div>
        <div class="flex items-center gap-2 mb-1">
          <input
            id="from_list"
            v-model="routeType"
            class="notification--checkbox"
            type="radio"
            value="from_list"
          />
          <label for="from_list">
            {{ $t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.ROUTE_TYPE.LIST') }}
          </label>
        </div>
      </div>

      <div class="w-full">
        <woot-submit-button
          :loading="uiFlags.isCreating"
          :button-text="$t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.SUBMIT_BUTTON')"
        />
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import { required } from 'vuelidate/lib/validators';
import router from '../../../../index';
import PageHeader from '../../SettingsSubPageHeader.vue';

export default {
  components: {
    PageHeader,
  },
  mixins: [alertMixin],
  data() {
    return {
      channelName: '',
      phoneNumber: '',
      routeType: 'by_group',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
    phoneNumber: { required },
  },
  methods: {
    async createChannel() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        const inbox = await this.$store.dispatch(
          'inboxes/createStringeeChannel',
          {
            inbox_name: this.channelName,
            phone_number: this.phoneNumber,
            route_type: this.routeType,
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            channel_type: inbox.channel_type,
            inbox_id: inbox.id,
          },
        });
      } catch (error) {
        this.showAlert(
          this.$t('INBOX_MGMT.ADD.STRINGEE_CHANNEL.SAVE.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>

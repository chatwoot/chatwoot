<template>
  <div class="column content-box">
    <woot-modal-header :header-title="pageTitle" />
    <form class="row" @submit.prevent="editCampaign">
      <div class="medium-12 columns">
        <woot-input
          v-model="title"
          :label="$t('CAMPAIGN.ADD.FORM.TITLE.LABEL')"
          type="text"
          :class="{ error: $v.title.$error }"
          :error="$v.title.$error ? $t('CAMPAIGN.ADD.FORM.TITLE.ERROR') : ''"
          :placeholder="$t('CAMPAIGN.ADD.FORM.TITLE.PLACEHOLDER')"
          @blur="$v.title.$touch"
        />
        <label class="editor-wrap">
          {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.LABEL') }}
          <woot-message-editor
            v-model.trim="message"
            class="message-editor"
            :is-format-mode="true"
            :class="{ editor_warning: $v.message.$error }"
            :placeholder="$t('CAMPAIGN.ADD.FORM.MESSAGE.PLACEHOLDER')"
            @input="$v.message.$touch"
          />
          <span v-if="$v.message.$error" class="editor-warning__message">
            {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.ERROR') }}
          </span>
        </label>

        <label :class="{ error: $v.selectedInbox.$error }">
          {{ $t('CAMPAIGN.ADD.FORM.INBOX.LABEL') }}
          <select v-model="selectedInbox" @change="onChangeInbox($event)">
            <option v-for="item in inboxes" :key="item.name" :value="item.id">
              {{ item.name }}
            </option>
          </select>
          <span v-if="$v.selectedInbox.$error" class="message">
            {{ $t('CAMPAIGN.ADD.FORM.INBOX.ERROR') }}
          </span>
        </label>

        <label :class="{ error: $v.selectedSender.$error }">
          {{ $t('CAMPAIGN.ADD.FORM.SENT_BY.LABEL') }}
          <select v-model="selectedSender">
            <option
              v-for="sender in sendersAndBotList"
              :key="sender.name"
              :value="sender.id"
            >
              {{ sender.name }}
            </option>
          </select>
          <span v-if="$v.selectedSender.$error" class="message">
            {{ $t('CAMPAIGN.ADD.FORM.SENT_BY.ERROR') }}
          </span>
        </label>
        <woot-input
          v-model="endPoint"
          :label="$t('CAMPAIGN.ADD.FORM.END_POINT.LABEL')"
          type="text"
          :class="{ error: $v.endPoint.$error }"
          :error="
            $v.endPoint.$error ? $t('CAMPAIGN.ADD.FORM.END_POINT.ERROR') : ''
          "
          :placeholder="$t('CAMPAIGN.ADD.FORM.END_POINT.PLACEHOLDER')"
          @blur="$v.endPoint.$touch"
        />
        <woot-input
          v-model="timeOnPage"
          :label="$t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.LABEL')"
          type="text"
          :class="{ error: $v.timeOnPage.$error }"
          :error="
            $v.timeOnPage.$error
              ? $t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.ERROR')
              : ''
          "
          :placeholder="$t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.PLACEHOLDER')"
          @blur="$v.timeOnPage.$touch"
        />
        <label>
          <input
            v-model="enabled"
            type="checkbox"
            value="enabled"
            name="enabled"
          />
          {{ $t('CAMPAIGN.ADD.FORM.ENABLED') }}
        </label>
        <label v-if="isOngoingType">
          <input
            v-model="triggerOnlyDuringBusinessHours"
            type="checkbox"
            value="triggerOnlyDuringBusinessHours"
            name="triggerOnlyDuringBusinessHours"
          />
          {{ $t('CAMPAIGN.ADD.FORM.TRIGGER_ONLY_BUSINESS_HOURS') }}
        </label>
      </div>
      <div class="modal-footer">
        <woot-button :is-loading="uiFlags.isCreating">
          {{ $t('CAMPAIGN.EDIT.UPDATE_BUTTON_TEXT') }}
        </woot-button>
        <woot-button variant="clear" @click.prevent="onClose">
          {{ $t('CAMPAIGN.ADD.CANCEL_BUTTON_TEXT') }}
        </woot-button>
      </div>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { required, url, minLength } from 'vuelidate/lib/validators';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor';
import alertMixin from 'shared/mixins/alertMixin';
import campaignMixin from 'shared/mixins/campaignMixin';
export default {
  components: {
    WootMessageEditor,
  },
  mixins: [alertMixin, campaignMixin],
  props: {
    selectedCampaign: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      title: '',
      message: '',
      selectedSender: '',
      selectedInbox: null,
      endPoint: '',
      timeOnPage: 10,
      triggerOnlyDuringBusinessHours: false,
      show: true,
      enabled: true,
      senderList: [],
    };
  },
  validations: {
    title: {
      required,
    },
    message: {
      required,
    },
    selectedSender: {
      required,
    },
    endPoint: {
      required,
      minLength: minLength(7),
      url,
    },
    timeOnPage: {
      required,
    },
    selectedInbox: {
      required,
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'campaigns/getUIFlags',
      inboxes: 'inboxes/getTwilioInboxes',
    }),
    inboxes() {
      if (this.isOngoingType) {
        return this.$store.getters['inboxes/getWebsiteInboxes'];
      }
      return this.$store.getters['inboxes/getTwilioSMSInboxes'];
    },
    pageTitle() {
      return `${this.$t('CAMPAIGN.EDIT.TITLE')} - ${
        this.selectedCampaign.title
      }`;
    },
    sendersAndBotList() {
      return [
        {
          id: 0,
          name: 'Bot',
        },
        ...this.senderList,
      ];
    },
  },
  mounted() {
    this.setFormValues();
  },
  methods: {
    onClose() {
      this.$emit('on-close');
    },

    async loadInboxMembers() {
      try {
        const response = await this.$store.dispatch('inboxMembers/get', {
          inboxId: this.selectedInbox,
        });
        const {
          data: { payload: inboxMembers },
        } = response;
        this.senderList = inboxMembers;
      } catch (error) {
        const errorMessage =
          error?.response?.message || this.$t('CAMPAIGN.ADD.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
    onChangeInbox() {
      this.loadInboxMembers();
    },
    setFormValues() {
      const {
        title,
        message,
        enabled,
        trigger_only_during_business_hours: triggerOnlyDuringBusinessHours,
        inbox: { id: inboxId },
        trigger_rules: { url: endPoint, time_on_page: timeOnPage },
        sender,
      } = this.selectedCampaign;
      this.title = title;
      this.message = message;
      this.endPoint = endPoint;
      this.timeOnPage = timeOnPage;
      this.selectedInbox = inboxId;
      this.triggerOnlyDuringBusinessHours = triggerOnlyDuringBusinessHours;
      this.selectedSender = (sender && sender.id) || 0;
      this.enabled = enabled;
      this.loadInboxMembers();
    },
    async editCampaign() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      try {
        await this.$store.dispatch('campaigns/update', {
          id: this.selectedCampaign.id,
          title: this.title,
          message: this.message,
          inbox_id: this.$route.params.inboxId,
          trigger_only_during_business_hours:
            // eslint-disable-next-line prettier/prettier
            this.triggerOnlyDuringBusinessHours,
          sender_id: this.selectedSender || null,
          enabled: this.enabled,
          trigger_rules: {
            url: this.endPoint,
            time_on_page: this.timeOnPage,
          },
        });
        this.showAlert(this.$t('CAMPAIGN.EDIT.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        this.showAlert(this.$t('CAMPAIGN.EDIT.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>
<style lang="scss" scoped>
::v-deep .ProseMirror-woot-style {
  height: 8rem;
}
</style>

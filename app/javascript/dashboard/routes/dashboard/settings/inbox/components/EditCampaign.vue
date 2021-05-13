<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header :header-title="pageTitle" />
      <form class="row" @submit.prevent="editCampaign">
        <div class="medium-12 columns">
          <label :class="{ error: $v.title.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.TITLE.LABEL') }}
            <input
              v-model.trim="title"
              type="text"
              :placeholder="$t('CAMPAIGN.ADD.FORM.TITLE.PLACEHOLDER')"
              @input="$v.title.$touch"
            />
            <span v-if="$v.title.$error" class="message">
              {{ $t('CAMPAIGN.ADD.FORM.TITLE.ERROR') }}
            </span>
          </label>
        </div>

        <div class="medium-12 columns">
          <label :class="{ error: $v.message.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.LABEL') }}
            <textarea
              v-model.trim="message"
              rows="5"
              type="text"
              :placeholder="$t('CAMPAIGN.ADD.FORM.MESSAGE.PLACEHOLDER')"
              @input="$v.message.$touch"
            />
            <span v-if="$v.message.$error" class="message">
              {{ $t('CAMPAIGN.ADD.FORM.MESSAGE.ERROR') }}
            </span>
          </label>
        </div>

        <div class="medium-12 columns">
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
        </div>

        <div class="medium-12 columns">
          <label :class="{ error: $v.endPoint.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.END_POINT.LABEL') }}
            <input
              v-model.trim="endPoint"
              type="text"
              :placeholder="$t('CAMPAIGN.ADD.FORM.END_POINT.PLACEHOLDER')"
              @input="$v.endPoint.$touch"
            />
            <span v-if="$v.endPoint.$error" class="message">
              {{ $t('CAMPAIGN.ADD.FORM.END_POINT.ERROR') }}
            </span>
          </label>
        </div>
        <div class="medium-12 columns">
          <label :class="{ error: $v.timeOnPage.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.LABEL') }}
            <input
              v-model.trim="timeOnPage"
              type="number"
              :placeholder="$t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.PLACEHOLDER')"
              @input="$v.timeOnPage.$touch"
            />
            <span v-if="$v.timeOnPage.$error" class="message">
              {{ $t('CAMPAIGN.ADD.FORM.TIME_ON_PAGE.ERROR') }}
            </span>
          </label>
        </div>

        <div class="medium-12 columns">
          <label>
            <input
              v-model="enabled"
              type="checkbox"
              value="enabled"
              name="enabled"
            />
            {{ $t('CAMPAIGN.ADD.FORM.ENABLED') }}
          </label>
        </div>

        <div class="modal-footer">
          <woot-button :disabled="buttonDisabled" :loading="uiFlags.isCreating">
            {{ $t('CAMPAIGN.EDIT.UPDATE_BUTTON_TEXT') }}
          </woot-button>
          <woot-button
            class="button clear"
            :disabled="buttonDisabled"
            :loading="uiFlags.isCreating"
            @click.prevent="onClose"
          >
            {{ $t('CAMPAIGN.ADD.CANCEL_BUTTON_TEXT') }}
          </woot-button>
        </div>
      </form>
    </div>
  </modal>
</template>

<script>
import { mapGetters } from 'vuex';
import { required, url, minLength } from 'vuelidate/lib/validators';
import Modal from 'dashboard/components/Modal';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    Modal,
  },
  mixins: [alertMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
    selectedCampaign: {
      type: Object,
      default: () => {},
    },
    senderList: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      title: '',
      message: '',
      selectedSender: '',
      endPoint: '',
      timeOnPage: 10,
      show: true,
      enabled: true,
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
  },

  computed: {
    ...mapGetters({
      uiFlags: 'campaigns/getUIFlags',
    }),
    buttonDisabled() {
      return (
        this.$v.message.$invalid ||
        this.$v.title.$invalid ||
        this.$v.selectedSender.$invalid ||
        this.$v.endPoint.$invalid ||
        this.$v.timeOnPage.$invalid ||
        this.uiFlags.isCreating
      );
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
    setFormValues() {
      const {
        title,
        message,
        enabled,
        trigger_rules: { url: endPoint, time_on_page: timeOnPage },
        sender,
      } = this.selectedCampaign;
      this.title = title;
      this.message = message;
      this.endPoint = endPoint;
      this.timeOnPage = timeOnPage;
      this.selectedSender = (sender && sender.id) || 0;
      this.enabled = enabled;
    },

    async editCampaign() {
      try {
        await this.$store.dispatch('campaigns/update', {
          id: this.selectedCampaign.id,
          title: this.title,
          message: this.message,
          inbox_id: this.$route.params.inboxId,
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
.content-box .page-top-bar::v-deep {
  padding: var(--space-large) var(--space-large) var(--space-zero);
}
</style>

<template>
  <modal :show.sync="show" :on-close="onClose">
    <div class="column content-box">
      <woot-modal-header
        :header-title="$t('CAMPAIGN.ADD.TITLE')"
        :header-content="$t('CAMPAIGN.ADD.DESC')"
      />
      <form class="row" @submit.prevent="addCampaign">
        <div class="medium-12 columns">
          <label :class="{ error: $v.title.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.TITLE.LABEL') }}
            <input
              v-model.trim="title"
              type="text"
              :placeholder="$t('CAMPAIGN.ADD.FORM.TITLE.PLACEHOLDER')"
              @input="$v.title.$touch"
            />
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
          </label>
        </div>

        <div class="medium-12 columns">
          <label :class="{ error: $v.selectedAgent.$error }">
            {{ $t('CAMPAIGN.ADD.FORM.SENT_BY.LABEL') }}
            <select v-model="selectedAgent">
              <option
                v-for="agent in agentsList"
                :key="agent.name"
                :value="agent.name"
              >
                {{ agent.name }}
              </option>
            </select>
            <span v-if="$v.selectedAgent.$error" class="message">
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

        <div class="modal-footer">
          <div class="medium-12 columns">
            <woot-submit-button
              :disabled="
                $v.message.$invalid ||
                $v.title.$invalid ||
                $v.selectedAgent.$invalid ||
                $v.endPoint.$invalid ||
                $v.timeOnPage.$invalid ||
                uiFlags.isCreating
              "
              :loading="uiFlags.isCreating"
              :button-text="$t('CAMPAIGN.ADD.CREATE_BUTTON_TEXT')"
            />
            <button class="button clear" @click.prevent="onClose">
              {{ $t('CAMPAIGN.ADD.CANCEL_BUTTON_TEXT') }}
            </button>
          </div>
        </div>
      </form>
    </div>
  </modal>
</template>

<script>
import { mapGetters } from 'vuex';
import { required, url, minLength } from 'vuelidate/lib/validators';

import WootSubmitButton from '../../../../../components/buttons/FormSubmitButton';
import Modal from '../../../../../components/Modal';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    WootSubmitButton,
    Modal,
  },
  mixins: [alertMixin],
  props: {
    onClose: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      title: '',
      message: '',
      selectedAgent: '',
      endPoint: '',
      timeOnPage: 10,
      show: true,
    };
  },
  validations: {
    title: {
      required,
    },
    message: {
      required,
    },
    selectedAgent: {
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
      agentList: 'agents/getAgents',
      uiFlags: 'campaigns/getUIFlags',
    }),

    agentsList() {
      return this.agentList;
    },
  },
  methods: {
    addCampaign() {
      this.$store
        .dispatch('campaigns/create', {
          title: this.title,
          message: this.message,
          inbox_id: this.$route.params.inboxId,
          sender_id: this.selectedAgent,
          trigger_rules: {
            url: this.endPoint,
            time_on_page: this.timeOnPage,
          },
        })
        .then(() => {
          this.showAlert(this.$t('CAMPAIGN.ADD.API.SUCCESS_MESSAGE'));
          this.onClose();
        })
        .catch(() => {
          this.showAlert(this.$t('CAMPAIGN.ADD.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>

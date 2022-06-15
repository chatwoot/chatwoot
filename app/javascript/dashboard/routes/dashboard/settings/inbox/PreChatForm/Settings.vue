<template>
  <div class="settings--content">
    <div class="pre-chat--title">
      {{ $t('INBOX_MGMT.PRE_CHAT_FORM.DESCRIPTION') }}
    </div>
    <form @submit.prevent="updateInbox">
      <label class="medium-3 columns">
        {{ $t('INBOX_MGMT.PRE_CHAT_FORM.ENABLE.LABEL') }}
        <select v-model="preChatFormEnabled">
          <option :value="true">
            {{ $t('INBOX_MGMT.PRE_CHAT_FORM.ENABLE.OPTIONS.ENABLED') }}
          </option>
          <option :value="false">
            {{ $t('INBOX_MGMT.PRE_CHAT_FORM.ENABLE.OPTIONS.DISABLED') }}
          </option>
        </select>
      </label>
      <div v-if="preChatFormEnabled">
        <label class="medium-3 columns">
          {{ $t('INBOX_MGMT.PRE_CHAT_FORM.PRE_CHAT_MESSAGE.LABEL') }}
          <textarea
            v-model.trim="preChatMessage"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.PRE_CHAT_FORM.PRE_CHAT_MESSAGE.PLACEHOLDER')
            "
          />
        </label>
        <div class="medium-8 columns">
          <label>{{ $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS') }}</label>
          <table class="table table-striped w-full">
            <thead class="thead-dark">
              <tr>
                <th scope="col" />
                <th scope="col" />
                <th scope="col">
                  {{ $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS_HEADER.KEY') }}
                </th>
                <th scope="col">
                  {{ $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS_HEADER.TYPE') }}
                </th>
                <th scope="col">
                  {{
                    $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS_HEADER.REQUIRED')
                  }}
                </th>
                <th scope="col">
                  {{ $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS_HEADER.LABEL') }}
                </th>
                <th scope="col">
                  {{
                    $t(
                      'INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS_HEADER.PLACE_HOLDER'
                    )
                  }}
                </th>
              </tr>
            </thead>
            <pre-chat-fields
              :pre-chat-fields="preChatFields"
              @update="handlePreChatFieldOptions"
              @drag-end="changePreChatFieldFieldsOrder"
            />
          </table>
        </div>
      </div>

      <woot-submit-button
        :button-text="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        :loading="uiFlags.isUpdatingInbox"
      />
    </form>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import PreChatFields from './PreChatFields.vue';
import { getPreChatFields, standardFieldKeys } from 'dashboard/helper/preChat';

export default {
  components: {
    PreChatFields,
  },
  mixins: [alertMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      preChatFormEnabled: false,
      preChatMessage: '',
      preChatFields: [],
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
      customAttributes: 'attributes/getAttributes',
    }),
    preChatFieldOptions() {
      const { pre_chat_form_options: preChatFormOptions } = this.inbox;
      return getPreChatFields({
        preChatFormOptions,
        customAttributes: this.customAttributes,
      });
    },
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      const { pre_chat_form_enabled: preChatFormEnabled } = this.inbox;
      this.preChatFormEnabled = preChatFormEnabled;
      const {
        pre_chat_message: preChatMessage,
        pre_chat_fields: preChatFields,
      } = this.preChatFieldOptions || {};
      this.preChatMessage = preChatMessage;
      this.preChatFields = preChatFields;
    },
    isFieldEditable(item) {
      return !!standardFieldKeys[item.name] || !item.enabled;
    },
    handlePreChatFieldOptions(event, type, item) {
      this.preChatFields.forEach((field, index) => {
        if (field.name === item.name) {
          this.preChatFields[index][type] = !item[type];
        }
      });
    },

    changePreChatFieldFieldsOrder(updatedPreChatFieldOptions) {
      this.preChatFields = updatedPreChatFieldOptions;
    },

    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            pre_chat_form_enabled: this.preChatFormEnabled,
            pre_chat_form_options: {
              pre_chat_message: this.preChatMessage,
              pre_chat_fields: this.preChatFields,
            },
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        this.showAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      }
    },
  },
};
</script>
<style scoped lang="scss">
.settings--content {
  font-size: var(--font-size-default);
}
.pre-chat--title {
  margin: var(--space-medium) 0 var(--space-slab);
}
</style>

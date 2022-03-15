<template>
  <div class="settings--content">
    <div class="prechat--title">
      {{ $t('INBOX_MGMT.PRE_CHAT_FORM.DESCRIPTION') }}
    </div>
    <form class="medium-6" @submit.prevent="updateInbox">
      <label class="medium-9 columns">
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
        <label class="medium-9">
          {{ $t('INBOX_MGMT.PRE_CHAT_FORM.PRE_CHAT_MESSAGE.LABEL') }}
          <textarea
            v-model.trim="preChatMessage"
            type="text"
            :placeholder="
              $t('INBOX_MGMT.PRE_CHAT_FORM.PRE_CHAT_MESSAGE.PLACEHOLDER')
            "
          />
        </label>
        <label> {{ $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS') }} </label>
        <table class="table table-striped">
          <thead class="thead-dark">
            <tr>
              <th scope="col"></th>
              <th scope="col"></th>
              <th scope="col">
                {{ $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS_HEADER.FIELDS') }}
              </th>
              <th scope="col">
                {{ $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS_HEADER.REQUIRED') }}
              </th>
            </tr>
          </thead>
          <draggable v-model="preChatFields" tag="tbody">
            <tr v-for="(item, index) in preChatFields" :key="index">
              <th scope="col"><fluent-icon icon="drag" /></th>
              <td scope="row">
                <toggle-button
                  :active="item['enabled']"
                  @click="handlePreChatFieldOptions($event, 'enabled', item)"
                />
              </td>
              <td :class="{ 'disabled-text': !item['enabled'] }">
                {{ item.label }}
              </td>
              <td>
                <input
                  v-model="item['required']"
                  type="checkbox"
                  :value="`${item.name}-required`"
                  :disabled="!item['enabled']"
                  @click="handlePreChatFieldOptions($event, 'required', item)"
                />
              </td>
            </tr>
          </draggable>
        </table>
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
import draggable from 'vuedraggable';
import ToggleButton from 'dashboard/components/buttons/ToggleButton';
export default {
  components: {
    draggable,
    ToggleButton,
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
      preChatFieldOptions: [],
      preChatFields: [],
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
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
      const {
        pre_chat_form_enabled: preChatFormEnabled,
        pre_chat_form_options: preChatFormOptions,
      } = this.inbox;
      this.preChatFormEnabled = preChatFormEnabled;
      const {
        pre_chat_message: preChatMessage,
        pre_chat_fields: preChatFields,
      } = preChatFormOptions || {};
      this.preChatMessage = preChatMessage;
      this.preChatFields = preChatFields;
    },
    handlePreChatFieldOptions(event, type, item) {
      this.preChatFields.forEach((field, index) => {
        if (field.name === item.name) {
          this.preChatFields[index][type] = !item[type];
        }
      });
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
<style scoped>
.settings--content {
  font-size: var(--font-size-default);
}

.prechat--title {
  margin: var(--space-medium) 0 var(--space-slab);
}

.disabled-text {
  font-size: var(--font-size-small);
  color: var(--s-500);
}

table thead th {
  text-transform: none;
}
checkbox {
  margin: 0;
}
</style>

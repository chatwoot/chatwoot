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
      <label> Set your fields </label>
      <table class="table table-striped">
        <thead class="thead-dark">
          <tr>
            <th scope="col"></th>
            <th scope="col">Field</th>
            <th scope="col">Required</th>
          </tr>
        </thead>
        <draggable v-model="preChatFields" tag="tbody">
          <tr v-for="(item, index) in preChatFields" :key="index">
            <td scope="row">
              <button
                type="button"
                class="toggle-button"
                :class="{ active: item['enabled'] }"
                role="switch"
                @click="handlePreChatFieldOptions($event, 'enabled', item)"
              >
                <span
                  aria-hidden="true"
                  :class="{ active: item['enabled'] }"
                ></span>
              </button>
            </td>
            <td :class="{ 'disabled-text': !item['enabled'] }">
              {{ item.label }}
            </td>
            <td>
              <input
                v-if="item['enabled']"
                v-model="item['required']"
                type="checkbox"
                :value="`${item.name}-required`"
                @click="handlePreChatFieldOptions($event, 'required', item)"
              />
            </td>
          </tr>
        </draggable>
      </table>

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

export default {
  components: {
    draggable,
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
      // eslint-disable-next-line
      this.preChatFields.map((field, index) => {
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
.toggle-button {
  background-color: var(--s-200);
  position: relative;
  display: inline-flex;
  height: 19px;
  width: 34px;
  border: 2px solid transparent;
  border-radius: var(--border-radius-large);
  cursor: pointer;
  transition-property: background-color;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 200ms;
  flex-shrink: 0;
}

.toggle-button.active {
  background-color: var(--w-500);
}

.toggle-button span {
  --space-one-point-five: 1.5rem;
  height: var(--space-one-point-five);
  width: var(--space-one-point-five);
  display: inline-block;
  background-color: var(--white);
  box-shadow: rgb(255, 255, 255) 0px 0px 0px 0px,
    rgba(59, 130, 246, 0.5) 0px 0px 0px 0px, rgba(0, 0, 0, 0.1) 0px 1px 3px 0px,
    rgba(0, 0, 0, 0.06) 0px 1px 2px 0px;
  transform: translate(0, 0);
  border-radius: 100%;
  transition-property: transform;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 200ms;
}
.toggle-button span.active {
  transform: translate(var(--space-one-point-five), var(--space-zero));
}
.disabled-text {
  font-size: var(--font-size-small);
  color: var(--s-500);
}
</style>

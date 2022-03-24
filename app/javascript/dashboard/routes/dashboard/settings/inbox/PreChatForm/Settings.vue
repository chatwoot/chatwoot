<template>
  <div class="settings--content">
    <div class="pre-chat--title">
      {{ $t('INBOX_MGMT.PRE_CHAT_FORM.DESCRIPTION') }}
    </div>
    <form @submit.prevent="updateInbox">
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
                {{ $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS_HEADER.KEY') }}
              </th>
              <th scope="col">
                {{ $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS_HEADER.TYPE') }}
              </th>
              <th scope="col">
                {{ $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS_HEADER.REQUIRED') }}
              </th>
              <th scope="col">Translations</th>
            </tr>
          </thead>
          <draggable v-model="preChatFields" tag="tbody">
            <tr v-for="(item, index) in preChatFields" :key="index">
              <td class="pre-chat-field"><fluent-icon icon="drag" /></td>
              <td class="pre-chat-field">
                <toggle-button
                  :active="item['enabled']"
                  @click="handlePreChatFieldOptions($event, 'enabled', item)"
                />
              </td>
              <td
                class="pre-chat-field"
                :class="{ 'disabled-text': !item['enabled'] }"
              >
                {{ item.name }}
              </td>
              <td
                class="pre-chat-field"
                :class="{ 'disabled-text': !item['enabled'] }"
              >
                {{ item.type }}
              </td>
              <td class="pre-chat-field">
                <input
                  v-model="item['required']"
                  type="checkbox"
                  :value="`${item.name}-required`"
                  :disabled="!item['enabled']"
                  @click="handlePreChatFieldOptions($event, 'required', item)"
                />
              </td>
              <td v-if="item.translations && item.translations.length">
                <div class="translation">
                  <table>
                    <thead class="thead-dark">
                      <tr>
                        <th scope="col">locale</th>
                        <th scope="col">label</th>
                        <th scope="col">placeholder</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr
                        v-for="(translation, key) in item.translations.slice(
                          0,
                          10
                        )"
                        :key="key"
                      >
                        <!-- <td scope="row">
                    <input
                      v-model="translation['active']"
                      type="checkbox"
                      :value="`${translation.locale}-required`"
                      :disabled="!item['enabled']"
                      @click="
                        handleTranslationsOption(
                          $event,
                          'active',
                          item,
                          translation
                        )
                      "
                    />
                  </td>-->
                        <td :class="{ 'disabled-text': !item['enabled'] }">
                          {{ translation.locale }}
                        </td>
                        <td>
                          <input
                            v-model.trim="translation.label"
                            type="text"
                            :class="{ 'disabled-text': !item['enabled'] }"
                          />
                        </td>
                        <td>
                          <input
                            v-model.trim="translation.placeholder"
                            type="text"
                            :class="{ 'disabled-text': !item['enabled'] }"
                          />
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
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
import { getPreChatFields } from 'dashboard/helper/inbox';

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
    handlePreChatFieldOptions(event, type, item) {
      this.preChatFields.forEach((field, index) => {
        if (field.name === item.name) {
          this.preChatFields[index][type] = !item[type];
        }
      });
    },

    handleTranslationsOption(event, type, item, translation) {
      this.preChatFields.forEach((field, index) => {
        if (field.name === item.name) {
          item.translations.forEach((t, i) => {
            if (t.locale === translation.locale) {
              this.preChatFields[index].locale = translation.locale;
              this.preChatFields[index].translations[i].active = true;
            } else {
              this.preChatFields[index].translations[i].active = false;
            }
          });
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
<style scoped lang="scss">
.settings--content {
  font-size: var(--font-size-default);
}
.pre-chat--title {
  margin: var(--space-medium) 0 var(--space-slab);
}
.disabled-text {
  color: var(--s-500);
}
table thead th {
  text-transform: none;
}
checkbox {
  margin: 0;
}
.translation {
  border: 1px solid var(--b-200);
  overflow: auto;
  height: 200px;
  table {
    border-collapse: collapse;
    width: 100%;
    th {
      position: sticky;
      top: 0;
      background: var(--b-200);
    }
    th,
    td {
      padding: var(--space-half) var(--space-one);
    }
    thead {
      border: none;
    }
  }
}
.pre-chat-field {
  vertical-align: top;
}
</style>

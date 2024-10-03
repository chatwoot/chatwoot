<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import PreChatFields from './PreChatFields.vue';
import { getPreChatFields, standardFieldKeys } from 'dashboard/helper/preChat';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
export default {
  components: {
    PreChatFields,
    WootMessageEditor,
  },
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
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <div class="mx-8 my-2 text-base">
    <div class="mx-0 mt-6 mb-3">
      {{ $t('INBOX_MGMT.PRE_CHAT_FORM.DESCRIPTION') }}
    </div>
    <form class="flex flex-col" @submit.prevent="updateInbox">
      <label class="w-1/4">
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
        <div class="w-[70%]">
          <label>
            {{ $t('INBOX_MGMT.PRE_CHAT_FORM.PRE_CHAT_MESSAGE.LABEL') }}
          </label>
          <WootMessageEditor
            v-model="preChatMessage"
            class="message-editor"
            :placeholder="
              $t('INBOX_MGMT.PRE_CHAT_FORM.PRE_CHAT_MESSAGE.PLACEHOLDER')
            "
          />
        </div>
        <div class="w-[70%] mt-4">
          <label>{{ $t('INBOX_MGMT.PRE_CHAT_FORM.SET_FIELDS') }}</label>
          <table class="table w-full table-striped woot-table">
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
            <PreChatFields
              :pre-chat-fields="preChatFields"
              @update="handlePreChatFieldOptions"
              @drag-end="changePreChatFieldFieldsOrder"
            />
          </table>
        </div>
      </div>
      <div class="w-auto my-4">
        <woot-submit-button
          :button-text="
            $t('INBOX_MGMT.SETTINGS_POPUP.UPDATE_PRE_CHAT_FORM_SETTINGS')
          "
          :loading="uiFlags.isUpdating"
        />
      </div>
    </form>
  </div>
</template>

<style scoped lang="scss">
.message-editor {
  @apply px-3;

  ::v-deep {
    .ProseMirror-menubar {
      @apply rounded-tl-[4px];
    }
  }
}
</style>

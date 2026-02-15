<script>
import Avatar from 'next/avatar/Avatar.vue';
import ConversationWorkflowCard from './ConversationWorkflowCard.vue';

export default {
  components: {
    Avatar,
    ConversationWorkflowCard,
  },
  props: {
    senderNameType: {
      type: String,
      default: 'friendly',
    },
    businessName: {
      type: String,
      default: '',
    },
  },
  emits: ['update'],
  data() {
    return {
      senderNameKeyOptions: [
        {
          key: 'friendly',
          heading: this.$t(
            'INBOX_MGMT.EDIT.SENDER_NAME_SECTION.FRIENDLY.TITLE'
          ),
          content: this.$t(
            'INBOX_MGMT.EDIT.SENDER_NAME_SECTION.FRIENDLY.SUBTITLE'
          ),
          preview: {
            senderName: 'Smith',
            businessName: 'Chatwoot',
            email: '<support@yourbusiness.com>',
          },
        },
        {
          key: 'professional',
          heading: this.$t(
            'INBOX_MGMT.EDIT.SENDER_NAME_SECTION.PROFESSIONAL.TITLE'
          ),
          content: this.$t(
            'INBOX_MGMT.EDIT.SENDER_NAME_SECTION.PROFESSIONAL.SUBTITLE'
          ),
          preview: {
            senderName: '',
            businessName: 'Chatwoot   ',
            email: '<support@yourbusiness.com>',
          },
        },
      ],
    };
  },
  methods: {
    isKeyOptionFriendly(key) {
      return key === 'friendly';
    },
    userName(keyOption) {
      return this.isKeyOptionFriendly(keyOption.key)
        ? keyOption.preview.senderName
        : keyOption.preview.businessName;
    },
    toggleSenderNameType(key) {
      this.$emit('update', key);
    },
  },
};
</script>

<template>
  <div class="grid grid-cols-1 items-stretch gap-4 w-full sm:grid-cols-2">
    <ConversationWorkflowCard
      v-for="keyOption in senderNameKeyOptions"
      :key="keyOption.key"
      :active="keyOption.key === senderNameType"
      :title="keyOption.heading"
      :description="keyOption.content"
      radio-name="sender-name-style"
      description-min-height-class="sm:min-h-[4.5rem]"
      @click="toggleSenderNameType(keyOption.key)"
    >
      <template #footer>
          <div class="flex flex-row items-center gap-2">
            <Avatar :name="userName(keyOption)" :size="32" rounded-full />
            <div class="flex flex-col items-start gap-1">
              <div class="items-center flex flex-row gap-0.5 max-w-[18rem]">
                <span
                  v-if="isKeyOptionFriendly(keyOption.key)"
                  class="text-xs font-semibold leading-tight"
                >
                  {{ keyOption.preview.senderName }}
                </span>
                <span v-if="isKeyOptionFriendly(keyOption.key)" class="text-xs">
                  {{ $t('INBOX_MGMT.EDIT.SENDER_NAME_SECTION.FRIENDLY.FROM') }}
                </span>
                <span
                  class="text-xs font-semibold leading-tight overflow-hidden whitespace-nowrap text-ellipsis"
                >
                  {{ businessName || keyOption.preview.businessName }}
                </span>
              </div>
              <span class="text-xs">{{ keyOption.preview.email }}</span>
            </div>
          </div>
      </template>
    </ConversationWorkflowCard>
  </div>
</template>

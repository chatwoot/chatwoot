<template>
  <div class="sender-name--preview-container">
    <button
      v-for="keyOption in senderNameKeyOptions"
      :key="keyOption.key"
      class="preview-button"
      @click="toggleCustomSenderName(keyOption.value)"
    >
      <preview-card
        :heading="keyOption.heading"
        :content="keyOption.content"
        :active="keyOption.value === customSenderNameEnabled"
      >
        <div class="sender-name--preview-content">
          <span class="text">For eg:</span>
          <div class="sender-name--preview">
            <thumbnail :username="userName(keyOption)" />
            <div class="preview-card--content">
              <div>
                <span v-if="isKeyOptionFriendly(keyOption.key)" class="name">
                  {{ keyOption.preview.senderName }}
                </span>
                <span v-if="isKeyOptionFriendly(keyOption.key)" class="text">
                  {{ $t('INBOX_MGMT.EDIT.ENABLE_AGENT_NAME.FRIENDLY.FROM') }}
                </span>
                <span class="name">{{ keyOption.preview.businessName }}</span>
              </div>
              <span class="text">{{ keyOption.preview.email }}</span>
            </div>
          </div>
        </div>
      </preview-card>
    </button>
  </div>
</template>

<script>
import PreviewCard from 'dashboard/components/ui/PreviewCard.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail';

export default {
  components: {
    PreviewCard,
    Thumbnail,
  },
  props: {
    customSenderNameEnabled: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      senderNameKeyOptions: [
        {
          key: 'friendly',
          value: false,
          heading: this.$t('INBOX_MGMT.EDIT.ENABLE_AGENT_NAME.FRIENDLY.TITLE'),
          content: this.$t(
            'INBOX_MGMT.EDIT.ENABLE_AGENT_NAME.FRIENDLY.SUBTITLE'
          ),
          preview: {
            senderName: 'Smith',
            businessName: 'Chatwoot',
            email: '<support@yourbusiness.com>',
          },
        },
        {
          key: 'professional',
          value: true,
          heading: this.$t(
            'INBOX_MGMT.EDIT.ENABLE_AGENT_NAME.PROFESSIONAL.TITLE'
          ),
          content: this.$t(
            'INBOX_MGMT.EDIT.ENABLE_AGENT_NAME.PROFESSIONAL.SUBTITLE'
          ),
          preview: {
            senderName: '',
            businessName: 'Chatwoot',
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
    toggleCustomSenderName(value) {
      this.$emit('update', value);
    },
  },
};
</script>

<style lang="scss" scoped>
.sender-name--preview-container {
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: var(--space-normal);

  .sender-name--preview-content {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    padding: var(--space-slab);
    gap: var(--space-small);
  }
}

.preview-button {
  color: var(--s-700);

  .text {
    font-size: var(--font-size-mini);
  }

  .sender-name--preview {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: var(--space-small);

    .preview-card--content {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
      gap: var(--space-smaller);

      .name {
        font-size: var(--font-size-mini);
        font-weight: var(--font-weight-bold);
      }
    }
  }
}
</style>

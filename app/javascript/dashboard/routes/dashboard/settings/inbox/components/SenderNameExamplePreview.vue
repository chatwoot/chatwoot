<template>
  <div class="sender-name--preview-container">
    <button
      v-for="keyOption in senderNameKeyOptions"
      :key="keyOption.key"
      class="preview-button"
      @click="toggleSenderNameType(keyOption.key)"
    >
      <preview-card
        :heading="keyOption.heading"
        :content="keyOption.content"
        :active="keyOption.key === senderNameType"
      >
        <div class="sender-name--preview-content">
          <span class="text">
            {{ $t('INBOX_MGMT.EDIT.SENDER_NAME_SECTION.FOR_EG') }}
          </span>
          <div class="sender-name--preview">
            <thumbnail :username="userName(keyOption)" size="32px" />
            <div class="preview-card--content">
              <div class="sender-name--preview">
                <span v-if="isKeyOptionFriendly(keyOption.key)" class="name">
                  {{ keyOption.preview.senderName }}
                </span>
                <span v-if="isKeyOptionFriendly(keyOption.key)" class="text">
                  {{ $t('INBOX_MGMT.EDIT.SENDER_NAME_SECTION.FRIENDLY.FROM') }}
                </span>
                <span class="name text-truncate">
                  {{ businessName || keyOption.preview.businessName }}
                </span>
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
import PreviewCard from 'dashboard/components/ui/PreviewCard';
import Thumbnail from 'dashboard/components/widgets/Thumbnail';

export default {
  components: {
    PreviewCard,
    Thumbnail,
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
    toggleSenderNameType(key) {
      this.$emit('update', key);
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

      .sender-name--preview {
        align-items: center;
        display: flex;
        flex-direction: row;
        gap: var(--space-micro);
        max-width: 18rem;

        .name {
          font-size: var(--font-size-mini);
          font-weight: var(--font-weight-bold);
          line-height: 1.2;
        }
      }
    }
  }
}
</style>

<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'next/avatar/Avatar.vue';
import RadioCard from 'dashboard/components-next/AssignmentPolicy/components/RadioCard.vue';

const props = defineProps({
  senderNameType: {
    type: String,
    default: 'friendly',
  },
  businessName: {
    type: String,
    default: '',
  },
  isWebsiteChannel: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update']);

const { t } = useI18n();

const senderNameKeyOptions = computed(() => [
  {
    key: 'friendly',
    heading: t('INBOX_MGMT.EDIT.SENDER_NAME_SECTION.FRIENDLY.TITLE'),
    content: t('INBOX_MGMT.EDIT.SENDER_NAME_SECTION.FRIENDLY.SUBTITLE'),
    preview: {
      senderName: 'Smith',
      businessName: 'Chatwoot',
      email: '<support@yourbusiness.com>',
    },
  },
  {
    key: 'professional',
    heading: t('INBOX_MGMT.EDIT.SENDER_NAME_SECTION.PROFESSIONAL.TITLE'),
    content: t('INBOX_MGMT.EDIT.SENDER_NAME_SECTION.PROFESSIONAL.SUBTITLE'),
    preview: {
      senderName: '',
      businessName: 'Chatwoot',
      email: '<support@yourbusiness.com>',
    },
  },
]);

const isKeyOptionFriendly = key => key === 'friendly';

const userName = keyOption =>
  isKeyOptionFriendly(keyOption.key)
    ? keyOption.preview.senderName
    : keyOption.preview.businessName;

const toggleSenderNameType = key => {
  emit('update', key);
};
</script>

<template>
  <div
    class="flex flex-col items-start gap-4 mt-3 min-w-0"
    :class="
      isWebsiteChannel ? 'sm:flex-row md:flex-col xl:flex-row' : 'sm:flex-row'
    "
  >
    <RadioCard
      v-for="keyOption in senderNameKeyOptions"
      :id="keyOption.key"
      :key="keyOption.key"
      :label="keyOption.heading"
      :description="keyOption.content"
      :is-active="keyOption.key === props.senderNameType"
      class="flex-1 !gap-2"
      @select="toggleSenderNameType"
    >
      <div class="flex items-center gap-3">
        <Avatar :name="userName(keyOption)" :size="30" />
        <div class="flex flex-col">
          <div class="flex items-center gap-1">
            <span
              v-if="isKeyOptionFriendly(keyOption.key)"
              class="text-body-main text-n-slate-12"
            >
              {{ keyOption.preview.senderName }}
            </span>
            <span
              v-if="isKeyOptionFriendly(keyOption.key)"
              class="text-body-main text-n-slate-11"
            >
              {{ t('INBOX_MGMT.EDIT.SENDER_NAME_SECTION.FRIENDLY.FROM') }}
            </span>
            <span class="text-body-main text-n-slate-12">
              {{ props.businessName || keyOption.preview.businessName }}
            </span>
          </div>
          <span class="text-label-small text-n-slate-11">
            {{ keyOption.preview.email }}
          </span>
        </div>
      </div>
    </RadioCard>
  </div>
</template>

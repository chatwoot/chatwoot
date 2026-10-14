<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import Icon from 'next/icon/Icon.vue';
import { useMessageContext } from '../provider.js';

const { contentAttributes } = useMessageContext();
const { t } = useI18n();
const currentChat = useMapGetter('getSelectedChat');

const recipients = computed(() => [
  ...(contentAttributes.value.toEmails ?? []),
  ...(contentAttributes.value.ccEmails ?? []),
]);
const contact = computed(() => currentChat.value?.meta?.sender ?? {});
const hiddenFromContact = computed(
  () =>
    ![...recipients.value, ...(contentAttributes.value.bccEmails ?? [])]
      .map(email => email.toLowerCase())
      .includes(contact.value.email?.toLowerCase())
);
</script>

<template>
  <div class="flex items-center gap-1.5 text-xs font-medium">
    <Icon icon="i-lucide-forward" class="size-4 text-n-amber-10" />
    <span class="text-n-amber-10">
      {{ t('FORWARD_EMAIL.FORWARDED_TO', { emails: recipients.join(', ') }) }}
    </span>
    <template v-if="hiddenFromContact">
      <span class="w-px h-3 bg-n-slate-7" />
      <span class="text-n-slate-11">
        {{ t('FORWARD_EMAIL.CONTACT_CANNOT_SEE', { name: contact.name }) }}
      </span>
    </template>
  </div>
</template>

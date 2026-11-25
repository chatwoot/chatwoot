<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import ContactAPI from 'dashboard/api/contacts';
import InboxesAPI from 'dashboard/api/inboxes';
import { canCheckWhatsappNumber } from 'dashboard/helper/whatsappNumberMissing';

const props = defineProps({
  targetInbox: { type: Object, default: null },
  selectedContact: { type: Object, default: null },
});

const { t } = useI18n();

const isMissing = ref(false);

// The contact picked from a name search reaches the form without its phone (TagInput keeps
// it only for a phone search), and the one opened from its own page is snake_cased.
const resolvePhone = async contact => {
  const known = contact?.phoneNumber || contact?.phone_number;
  if (known || !contact?.id) return known || '';

  const { data } = await ContactAPI.show(contact.id);
  return data?.payload?.phone_number || '';
};

// Only an explicit "no" warns. A failed or slow lookup is "unknown", and it never blocks
// the send either way: the agent may know something the lookup does not.
let lookupId = 0;
watch(
  // The phone is part of what is being asked: a correction made with the form open has to
  // drop the old answer and ask about the new number.
  () => [
    props.targetInbox?.id,
    props.selectedContact?.id,
    props.selectedContact?.phoneNumber || props.selectedContact?.phone_number,
  ],
  async () => {
    lookupId += 1;
    const currentLookup = lookupId;
    isMissing.value = false;
    if (!props.selectedContact || !canCheckWhatsappNumber(props.targetInbox)) {
      return;
    }

    try {
      const phoneNumber = await resolvePhone(props.selectedContact);
      if (!phoneNumber || currentLookup !== lookupId) return;

      const { data } = await InboxesAPI.onWhatsapp(
        props.targetInbox.id,
        phoneNumber
      );
      if (currentLookup === lookupId) isMissing.value = data?.exists === false;
    } catch {
      // Unknown is not "no".
    }
  },
  { immediate: true }
);
</script>

<template>
  <div
    v-if="isMissing"
    role="alert"
    class="flex items-center gap-2 w-full px-4 py-3 dark:bg-n-amber-11/15 bg-n-amber-3"
  >
    <span class="i-lucide-triangle-alert size-4 shrink-0 text-n-amber-11" />
    <span class="text-sm text-n-amber-11">
      {{ t('COMPOSE_NEW_CONVERSATION.FORM.WHATSAPP_NUMBER_MISSING') }}
    </span>
  </div>
</template>

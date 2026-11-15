<script setup>
import { computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import ConversationAPI from 'dashboard/api/inbox/conversation';
import Banner from 'dashboard/components/ui/Banner.vue';
import {
  isWhatsappMissingRecheckDue,
  whatsappMissingCheckedAt,
} from 'dashboard/helper/whatsappNumberMissing';
import {
  currentDateLocale,
  dateTimeFormat,
} from 'shared/helpers/localizedDate';

const props = defineProps({
  conversation: { type: Object, required: true },
});

const { t } = useI18n();

const checkedAt = computed(() => whatsappMissingCheckedAt(props.conversation));

// Dated, because it is the answer of one lookup and the number may have registered since.
const message = computed(() =>
  t('CONVERSATION.WHATSAPP_NUMBER_MISSING_BANNER', {
    date: dateTimeFormat(currentDateLocale()).format(
      new Date(checkedAt.value * 1000)
    ),
  })
);

// Opening the conversation is when a stale answer matters, so that is when it is asked
// again. The answer comes back as a conversation update; a failure leaves the banner as
// it was, which is the right reading of "unknown". Two sources rather than one getter
// returning an array: every update replaces the conversation object, and a fresh array
// would ask again on each one while the provider keeps failing.
watch(
  [() => props.conversation.id, checkedAt],
  () => {
    if (!isWhatsappMissingRecheckDue(checkedAt.value)) return;
    ConversationAPI.recheckWhatsappNumber(props.conversation.id).catch(
      () => {}
    );
  },
  { immediate: true }
);
</script>

<template>
  <Banner
    v-if="checkedAt"
    color-scheme="warning"
    class="mt-2 mx-2 rounded-lg overflow-hidden"
    :banner-message="message"
  />
</template>

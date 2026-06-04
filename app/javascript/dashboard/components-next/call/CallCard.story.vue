<script setup>
import CallCard from './CallCard.vue';
import { VOICE_CALL_DIRECTION } from 'dashboard/components-next/message/constants';
import { VOICE_CALL_PROVIDERS } from 'dashboard/helper/inbox';

const whatsappCall = {
  callSid: 'wamid.HBgM',
  conversationId: 1234,
  provider: VOICE_CALL_PROVIDERS.WHATSAPP,
};

const twilioCall = {
  callSid: 'CA1234567890',
  conversationId: 1234,
};

const richCallInfo = {
  contactName: 'John Does',
  phoneNumber: '+1 412 245 0242',
  inboxName: 'Customer support',
  location: 'San Francisco, United States',
  countryFlag: '\u{1F1FA}\u{1F1F8}',
  hasLocation: true,
  avatar:
    'https://app.chatwoot.com/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBBd3FodGc9PSIsImV4cCI6bnVsbCwicHVyIjoiYmxvYl9pZCJ9fQ==--d218a325af0ef45061eefd352f8efb9ac84275e8/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCem9MWm05eWJXRjBTU0lKYW5CbFp3WTZCa1ZVT2hOeVpYTnBlbVZmZEc5ZlptbHNiRnNIYVFINk1BPT0iLCJleHAiOm51bGwsInB1ciI6InZhcmlhdGlvbiJ9fQ==--533c3ad7218e24c4b0e8f8959dc1953ce1d279b9/1707423736896.jpeg',
};

// Falls back to inbox name when neither city nor country is on the contact.
const noLocationCallInfo = {
  contactName: 'Anonymous Lead',
  phoneNumber: '+44 20 7916 0428',
  inboxName: 'Sales',
  location: 'Sales',
  countryFlag: '',
  hasLocation: false,
  avatar: '',
};

// Truncation regression check — both contact name and location should ellipsize.
const longCallInfo = {
  contactName: 'Aleksandra Konstantinopolskaya',
  phoneNumber: '+49 30 911890',
  inboxName: 'Customer support',
  location:
    'Friedrichshain-Kreuzberg, Federal Republic of Germany (Deutschland)',
  countryFlag: '\u{1F1E9}\u{1F1EA}',
  hasLocation: true,
  avatar: '',
};

const unknownCallerInfo = {
  contactName: 'Unknown caller',
  phoneNumber: '',
  inboxName: 'Customer support',
  location: 'Customer support',
  countryFlag: '',
  hasLocation: false,
  avatar: '',
};

const log =
  (label, ...args) =>
  () => {
    // eslint-disable-next-line no-console
    console.log(`[CallCard.story] ${label}`, ...args);
  };
</script>

<template>
  <Story
    title="Components/Call/CallCard"
    :layout="{ type: 'grid', width: '400px' }"
  >
    <Variant title="Incoming · WhatsApp">
      <CallCard
        :call="whatsappCall"
        :call-info="richCallInfo"
        :state="VOICE_CALL_DIRECTION.INCOMING"
        @accept="log('accept')"
        @reject="log('reject')"
        @go-to-conversation="log('goToConversation')"
      />
    </Variant>

    <Variant title="Incoming · Twilio (no flag)">
      <CallCard
        :call="twilioCall"
        :call-info="noLocationCallInfo"
        :state="VOICE_CALL_DIRECTION.INCOMING"
        @accept="log('accept')"
        @reject="log('reject')"
        @go-to-conversation="log('goToConversation')"
      />
    </Variant>

    <Variant title="Outgoing · WhatsApp ringing">
      <CallCard
        :call="whatsappCall"
        :call-info="richCallInfo"
        :state="VOICE_CALL_DIRECTION.OUTGOING"
        @reject="log('reject')"
        @go-to-conversation="log('goToConversation')"
      />
    </Variant>

    <Variant title="Ongoing · WhatsApp (mute visible, unmuted)">
      <CallCard
        :call="whatsappCall"
        :call-info="richCallInfo"
        :state="VOICE_CALL_DIRECTION.ONGOING"
        duration="01:23"
        :is-muted="false"
        show-mute
        @end="log('end')"
        @toggle-mute="log('toggleMute')"
        @go-to-conversation="log('goToConversation')"
      />
    </Variant>

    <Variant title="Ongoing · WhatsApp muted">
      <CallCard
        :call="whatsappCall"
        :call-info="richCallInfo"
        :state="VOICE_CALL_DIRECTION.ONGOING"
        duration="03:47"
        is-muted
        show-mute
        @end="log('end')"
        @toggle-mute="log('toggleMute')"
        @go-to-conversation="log('goToConversation')"
      />
    </Variant>

    <Variant title="Ongoing · Twilio (no mute control)">
      <CallCard
        :call="twilioCall"
        :call-info="richCallInfo"
        :state="VOICE_CALL_DIRECTION.ONGOING"
        duration="00:42"
        @end="log('end')"
        @go-to-conversation="log('goToConversation')"
      />
    </Variant>

    <Variant title="Incoming · Unknown caller">
      <CallCard
        :call="whatsappCall"
        :call-info="unknownCallerInfo"
        :state="VOICE_CALL_DIRECTION.INCOMING"
        @accept="log('accept')"
        @reject="log('reject')"
        @go-to-conversation="log('goToConversation')"
      />
    </Variant>

    <Variant title="Truncation · long name and location">
      <CallCard
        :call="whatsappCall"
        :call-info="longCallInfo"
        :state="VOICE_CALL_DIRECTION.INCOMING"
        @accept="log('accept')"
        @reject="log('reject')"
        @go-to-conversation="log('goToConversation')"
      />
    </Variant>

    <Variant title="Ongoing · no conversation link in footer">
      <CallCard
        :call="{ ...whatsappCall, conversationId: null }"
        :call-info="richCallInfo"
        :state="VOICE_CALL_DIRECTION.ONGOING"
        duration="02:10"
        show-mute
        @end="log('end')"
        @toggle-mute="log('toggleMute')"
      />
    </Variant>
  </Story>
</template>

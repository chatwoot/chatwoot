<script setup>
import TemplatePreview from './TemplatePreview.vue';
import {
  whatsAppTemplates,
  getWhatsAppVariables,
} from './templates/whatsapp-templates.js';
import { twilioTemplates } from './templates/twilio-templates.js';

const findWhatsApp = name => whatsAppTemplates.find(t => t.name === name);
const findTwilio = name => twilioTemplates.find(t => t.friendly_name === name);

const greet = findWhatsApp('greet');
const eventInvitation = findWhatsApp('event_invitation_static');
const orderConfirmation = findWhatsApp('order_confirmation');
const discountCoupon = findWhatsApp('discount_coupon');
const trainingVideo = findWhatsApp('training_video');

const twilioGreet = findTwilio('greet');
const shoeLaunch = findTwilio('shoe_launch');
const welcomeMessage = findTwilio('welcome_message_new');
const courseFeeReminder = findTwilio('course_fee_reminder');
</script>

<template>
  <Story
    title="Components/TemplatePreview"
    :layout="{ type: 'grid', width: 400 }"
  >
    <Variant title="WhatsApp - Simple Text">
      <TemplatePreview
        :template="greet"
        :variables="getWhatsAppVariables(greet)"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WhatsApp - Simple Text (No Variables)">
      <TemplatePreview :template="greet" :variables="{}" platform="whatsapp" />
    </Variant>

    <Variant title="WhatsApp - Call to Action Buttons">
      <TemplatePreview
        :template="eventInvitation"
        :variables="getWhatsAppVariables(eventInvitation)"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WhatsApp - Image Media">
      <TemplatePreview
        :template="orderConfirmation"
        :variables="getWhatsAppVariables(orderConfirmation)"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WhatsApp - Video Media">
      <TemplatePreview
        :template="trainingVideo"
        :variables="getWhatsAppVariables(trainingVideo)"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WhatsApp - Copy Code">
      <TemplatePreview
        :template="discountCoupon"
        :variables="getWhatsAppVariables(discountCoupon)"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="Twilio - Text">
      <TemplatePreview
        :template="twilioGreet"
        :variables="twilioGreet.variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio - Media">
      <TemplatePreview
        :template="shoeLaunch"
        :variables="shoeLaunch.variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio - Quick Reply">
      <TemplatePreview
        :template="welcomeMessage"
        :variables="welcomeMessage.variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio - Call to Action">
      <TemplatePreview
        :template="courseFeeReminder"
        :variables="courseFeeReminder.variables"
        platform="twilio"
      />
    </Variant>
  </Story>
</template>

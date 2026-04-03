<script setup>
import TemplatePreview from './TemplatePreview.vue';
import {
  whatsAppTemplates,
  getWhatsAppVariables,
} from './templates/whatsapp-templates.js';
import { twilioTemplates } from './templates/twillio-templates.js';
</script>

<template>
  <Story
    title="Components/TemplatePreviewExamples"
    :layout="{ type: 'grid', width: 400 }"
  >
    <Variant title="WA: Event Invitation (Buttons)">
      <TemplatePreview
        :template="whatsAppTemplates[0]"
        :variables="getWhatsAppVariables(whatsAppTemplates[0])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Purchase Receipt (Document)">
      <TemplatePreview
        :template="whatsAppTemplates[1]"
        :variables="getWhatsAppVariables(whatsAppTemplates[1])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Discount Coupon (Copy Code)">
      <TemplatePreview
        :template="whatsAppTemplates[2]"
        :variables="getWhatsAppVariables(whatsAppTemplates[2])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Support Callback (Phone)">
      <TemplatePreview
        :template="whatsAppTemplates[3]"
        :variables="getWhatsAppVariables(whatsAppTemplates[3])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Training Video (Video)">
      <TemplatePreview
        :template="whatsAppTemplates[4]"
        :variables="getWhatsAppVariables(whatsAppTemplates[4])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Order Confirmation (Image)">
      <TemplatePreview
        :template="whatsAppTemplates[5]"
        :variables="getWhatsAppVariables(whatsAppTemplates[5])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Product Launch (Image + Footer)">
      <TemplatePreview
        :template="whatsAppTemplates[6]"
        :variables="getWhatsAppVariables(whatsAppTemplates[6])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Technician Visit (Header + Buttons)">
      <TemplatePreview
        :template="whatsAppTemplates[7]"
        :variables="getWhatsAppVariables(whatsAppTemplates[7])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Greet (Simple Text)">
      <TemplatePreview
        :template="whatsAppTemplates[8]"
        :variables="getWhatsAppVariables(whatsAppTemplates[8])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Hello World (Header + Footer)">
      <TemplatePreview
        :template="whatsAppTemplates[9]"
        :variables="getWhatsAppVariables(whatsAppTemplates[9])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Feedback Request (Button)">
      <TemplatePreview
        :template="whatsAppTemplates[10]"
        :variables="getWhatsAppVariables(whatsAppTemplates[10])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Address Update (Header)">
      <TemplatePreview
        :template="whatsAppTemplates[11]"
        :variables="getWhatsAppVariables(whatsAppTemplates[11])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Delivery Confirmation">
      <TemplatePreview
        :template="whatsAppTemplates[12]"
        :variables="getWhatsAppVariables(whatsAppTemplates[12])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="Twilio: Shoe Launch (Media)">
      <TemplatePreview
        :template="twilioTemplates[0]"
        :variables="twilioTemplates[0].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Product Launch Custom Price (Media)">
      <TemplatePreview
        :template="twilioTemplates[1]"
        :variables="twilioTemplates[1].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Product Launch (Media)">
      <TemplatePreview
        :template="twilioTemplates[2]"
        :variables="twilioTemplates[2].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Greet (Text)">
      <TemplatePreview
        :template="twilioTemplates[3]"
        :variables="twilioTemplates[3].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Order Status (Text)">
      <TemplatePreview
        :template="twilioTemplates[4]"
        :variables="twilioTemplates[4].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Hello World (Text)">
      <TemplatePreview
        :template="twilioTemplates[5]"
        :variables="twilioTemplates[5].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Welcome Message New (Quick Reply)">
      <TemplatePreview
        :template="twilioTemplates[6]"
        :variables="twilioTemplates[6].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: SaaS WhatsApp Question (Quick Reply)">
      <TemplatePreview
        :template="twilioTemplates[7]"
        :variables="twilioTemplates[7].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Welcome Message (Quick Reply)">
      <TemplatePreview
        :template="twilioTemplates[8]"
        :variables="twilioTemplates[8].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Course Fee Reminder (Call to Action)">
      <TemplatePreview
        :template="twilioTemplates[9]"
        :variables="twilioTemplates[9].variables"
        platform="twilio"
      />
    </Variant>
  </Story>
</template>

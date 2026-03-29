<script setup>
import TemplatePreview from './TemplatePreview.vue';

// Sample template data from the JSON files
const whatsAppTemplates = {
  greet: {
    id: '997298832221901',
    name: 'greet',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        text: 'Hey {{customer_name}} how may I help you?',
        type: 'BODY',
        example: {
          body_text_named_params: [
            {
              example: 'John',
              param_name: 'customer_name',
            },
          ],
        },
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'NAMED',
  },

  eventInvitation: {
    id: '1381151706284063',
    name: 'event_invitation_static',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        text: "You're invited to {{event_name}} at {{location}}, Join us for an amazing experience!",
        type: 'BODY',
        example: {
          body_text_named_params: [
            {
              example: 'F1',
              param_name: 'event_name',
            },
            {
              example: 'Dubai',
              param_name: 'location',
            },
          ],
        },
      },
      {
        type: 'BUTTONS',
        buttons: [
          {
            url: 'https://events.example.com/register',
            text: 'Visit website',
            type: 'URL',
          },
          {
            url: 'https://maps.app.goo.gl/YoWAzRj1GDuxs6qz8',
            text: 'Get Directions',
            type: 'URL',
          },
        ],
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'NAMED',
  },

  orderConfirmation: {
    id: '1106685194739985',
    name: 'order_confirmation',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        type: 'HEADER',
        format: 'IMAGE',
        example: {
          header_handle: ['https://vite-five-phi.vercel.app/vaporfly.png'],
        },
      },
      {
        text: 'Hi your order {{1}} is confirmed. Please wait for further updates',
        type: 'BODY',
        example: {
          body_text: [['blue canvas shoes']],
        },
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'POSITIONAL',
  },

  discountCoupon: {
    id: '1469258364071127',
    name: 'discount_coupon',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        text: 'Special offer for you! Get {{discount_percentage}}% off your next purchase. Use the code below at checkout',
        type: 'BODY',
        example: {
          body_text_named_params: [
            {
              example: '30',
              param_name: 'discount_percentage',
            },
          ],
        },
      },
      {
        type: 'BUTTONS',
        buttons: [
          {
            text: 'Copy offer code',
            type: 'COPY_CODE',
            example: ['SAVE30OFF'],
          },
        ],
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'NAMED',
  },

  trainingVideo: {
    id: '1023596726651144',
    name: 'training_video',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        type: 'HEADER',
        format: 'VIDEO',
        example: {
          header_handle: [
            'https://scontent.whatsapp.net/v/t61.29466-34/521582686_1023596729984477_1872358575355618432_n.mp4',
          ],
        },
      },
      {
        text: "Hi {{name}}, here's your training video. Please watch by {{date}}.",
        type: 'BODY',
        example: {
          body_text_named_params: [
            {
              example: 'john',
              param_name: 'name',
            },
            {
              example: 'July 31',
              param_name: 'date',
            },
          ],
        },
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'NAMED',
  },
};

const twilioTemplates = {
  greet: {
    body: 'Hey {{1}}, how may I help you?',
    types: {
      'twilio/text': {
        body: 'Hey {{1}}, how may I help you?',
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {
      1: 'John',
    },
    content_sid: 'HXee240fd3a8b5045dba057feda5173e55',
    friendly_name: 'greet',
    template_type: 'text',
  },

  shoeLaunch: {
    body: 'Introducing our latest release — the {{1}}! Available now for just {{2}}. Be among the first to own this style. Limited stock available!',
    types: {
      'twilio/media': {
        body: 'Introducing our latest release — the {{1}}! Available now for just {{2}}. Be among the first to own this style. Limited stock available!',
        media: ['https://vite-five-phi.vercel.app/jordan-shoes.jpg'],
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {
      1: 'Jordan',
      2: '100$',
    },
    content_sid: 'HX4b1ff075f097ccdf7f274b6af4d7be02',
    friendly_name: 'shoe_launch',
    template_type: 'media',
  },

  welcomeMessage: {
    body: 'Thanks for reaching out to us. Before we proceed, we would like to get some information from you to assist you better. To whom would you like to connect?',
    types: {
      'twilio/quick-reply': {
        body: 'Thanks for reaching out to us. Before we proceed, we would like to get some information from you to assist you better. To whom would you like to connect?',
        actions: [
          {
            id: 'Sales_payload',
            title: 'Sales',
          },
          {
            id: 'Support_payload',
            title: 'Support',
          },
        ],
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en_US',
    variables: {},
    content_sid: 'HX778677f5867f96175ab4b7efb9a5bee6',
    friendly_name: 'welcome_message_new',
    template_type: 'quick_reply',
  },

  courseFeeReminder: {
    types: {
      'twilio/call-to-action': {
        actions: [
          {
            id: null,
            title: 'Pay now',
            type: 'URL',
            url: 'https://payments.example.com/pay',
          },
        ],
        body: 'Hello, this is a gentle reminder regarding your course fee.\n\nThe payment is due on {{date}}.\nKindly complete the payment at your convenience',
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {
      date: '01-Jan-2026',
    },
    content_sid: 'HX63e56fc142aad670f320bf400d5bfeb7',
    friendly_name: 'course_fee_reminder',
    template_type: 'call_to_action',
  },
};
</script>

<template>
  <Story
    title="Components/TemplatePreview"
    :layout="{ type: 'grid', width: 400 }"
  >
    <Variant title="WhatsApp - Simple Text">
      <TemplatePreview
        :template="whatsAppTemplates.greet"
        :variables="{ customer_name: 'John' }"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WhatsApp - Simple Text (No Variables)">
      <TemplatePreview
        :template="whatsAppTemplates.greet"
        :variables="{}"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WhatsApp - Call to Action Buttons">
      <TemplatePreview
        :template="whatsAppTemplates.eventInvitation"
        :variables="{ event_name: 'F1 Grand Prix', location: 'Dubai' }"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WhatsApp - Image Media">
      <TemplatePreview
        :template="whatsAppTemplates.orderConfirmation"
        :variables="{ '1': 'Blue Canvas Shoes' }"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WhatsApp - Video Media">
      <TemplatePreview
        :template="whatsAppTemplates.trainingVideo"
        :variables="{ name: 'John', date: 'July 31st' }"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WhatsApp - Copy Code">
      <TemplatePreview
        :template="whatsAppTemplates.discountCoupon"
        :variables="{ discount_percentage: '30' }"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="Twilio - Text">
      <TemplatePreview
        :template="twilioTemplates.greet"
        :variables="{ '1': 'John' }"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio - Media">
      <TemplatePreview
        :template="twilioTemplates.shoeLaunch"
        :variables="{ '1': 'Air Jordan', '2': '$150' }"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio - Quick Reply">
      <TemplatePreview
        :template="twilioTemplates.welcomeMessage"
        :variables="{}"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio - Call to Action">
      <TemplatePreview
        :template="twilioTemplates.courseFeeReminder"
        :variables="{ date: '02-Jan-2026' }"
        platform="twilio"
      />
    </Variant>
  </Story>
</template>

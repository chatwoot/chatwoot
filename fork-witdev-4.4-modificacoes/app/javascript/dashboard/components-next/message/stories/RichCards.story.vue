<script setup>
import { ref, reactive, computed } from 'vue';
import Message from '../Message.vue';

const currentUserId = ref(1);

const state = reactive({
  useCurrentUserId: false,
});

const getMessage = overrides => {
  const contentAttributes = {
    inReplyTo: null,
    ...(overrides.contentAttributes ?? {}),
  };

  const sender = {
    additionalAttributes: {},
    customAttributes: {},
    email: 'hey@example.com',
    id: 597,
    identifier: null,
    name: 'John Doe',
    phoneNumber: null,
    thumbnail: '',
    type: 'contact',
    ...(overrides.sender ?? {}),
  };

  return {
    id: 5272,
    content: 'Rich message fallback text',
    inboxId: 475,
    conversationId: 43,
    messageType: 0,
    contentType: 'cards',
    status: 'sent',
    createdAt: 1732195656,
    private: false,
    sourceId: null,
    ...overrides,
    sender,
    contentAttributes,
  };
};

const baseSenderData = computed(() => {
  return {
    messageType: state.useCurrentUserId ? 1 : 0,
    senderId: state.useCurrentUserId ? currentUserId.value : 597,
    sender: {
      id: state.useCurrentUserId ? currentUserId.value : 597,
      type: state.useCurrentUserId ? 'User' : 'Contact',
    },
  };
});

// Generic Template with multiple cards
const genericTemplate = computed(() =>
  getMessage({
    ...baseSenderData.value,
    contentAttributes: {
      items: [
        {
          media_url:
            'https://images.pexels.com/photos/90946/pexels-photo-90946.jpeg?auto=compress&cs=tinysrgb&w=400',
          title: 'Premium Wireless Headphones',
          description:
            'Experience crystal-clear audio with our latest wireless headphones featuring noise cancellation.',
          actions: [
            {
              type: 'link',
              text: 'View Details',
              uri: 'https://example.com/headphones',
            },
            {
              type: 'postback',
              text: 'Add to Cart',
              payload: 'ADD_TO_CART_HEADPHONES',
            },
          ],
        },
        {
          media_url:
            'https://images.pexels.com/photos/788946/pexels-photo-788946.jpeg?auto=compress&cs=tinysrgb&w=400',
          title: 'Smart Watch Series X',
          description:
            'Track your fitness goals and stay connected with our advanced smartwatch.',
          actions: [
            {
              type: 'link',
              text: 'Learn More',
              uri: 'https://example.com/smartwatch',
            },
            {
              type: 'postback',
              text: 'Buy Now',
              payload: 'BUY_SMARTWATCH',
            },
          ],
        },
        {
          media_url:
            'https://images.pexels.com/photos/1649771/pexels-photo-1649771.jpeg?auto=compress&cs=tinysrgb&w=400',
          title: 'Bluetooth Speaker',
          description:
            'Portable speaker with 360-degree sound and waterproof design.',
          actions: [
            {
              type: 'postback',
              text: 'Get Quote',
              payload: 'QUOTE_SPEAKER',
            },
          ],
        },
      ],
    },
  })
);

// Button Template with single card
const buttonTemplate = computed(() =>
  getMessage({
    ...baseSenderData.value,
    contentAttributes: {
      items: [
        {
          title: 'Customer Support',
          description:
            'How can we help you today? Choose from the options below.',
          actions: [
            {
              type: 'postback',
              text: 'Technical Support',
              payload: 'TECH_SUPPORT',
            },
            {
              type: 'postback',
              text: 'Billing Question',
              payload: 'BILLING_SUPPORT',
            },
            {
              type: 'link',
              text: 'Visit Help Center',
              uri: 'https://example.com/help',
            },
          ],
        },
      ],
    },
  })
);

// Card without image
const cardWithoutImage = computed(() =>
  getMessage({
    ...baseSenderData.value,
    contentAttributes: {
      items: [
        {
          title: 'Special Offer',
          description:
            'Get 20% off your next purchase with code SAVE20. Valid until the end of this month.',
          actions: [
            {
              type: 'postback',
              text: 'Claim Offer',
              payload: 'CLAIM_OFFER_SAVE20',
            },
            {
              type: 'link',
              text: 'Shop Now',
              uri: 'https://example.com/shop',
            },
          ],
        },
      ],
    },
  })
);

// Card with long text (testing truncation)
const cardWithLongText = computed(() =>
  getMessage({
    ...baseSenderData.value,
    contentAttributes: {
      items: [
        {
          media_url:
            'https://images.pexels.com/photos/1779487/pexels-photo-1779487.jpeg?auto=compress&cs=tinysrgb&w=400',
          title:
            'This is a very long title that should be truncated when it exceeds the maximum character limit set by the component',
          description:
            'This is an extremely long description that should demonstrate how the component handles text truncation. It contains multiple sentences to test the line clamping functionality. The description should be limited to a certain number of lines to maintain a clean and consistent layout across all cards in the carousel.',
          actions: [
            {
              type: 'postback',
              text: 'Read More',
              payload: 'READ_MORE_LONG_TEXT',
            },
          ],
        },
      ],
    },
  })
);

// Feature flag disabled scenario (should show text fallback)
const featureFlagDisabled = computed(() => {
  // Temporarily disable the feature flag for this story
  if (window.globalConfig) {
    window.globalConfig.SOCIALWISE_RICH_DASHBOARD = false;
  }

  return getMessage({
    ...baseSenderData.value,
    content: 'This should show as text because feature flag is disabled',
    contentAttributes: {
      items: [
        {
          title: 'This should not render as rich card',
          description: 'Feature flag is disabled',
          actions: [],
        },
      ],
    },
  });
});
</script>

<template>
  <Story
    title="Components/Message Bubbles/Rich Cards"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Generic Template (Multiple Cards)">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="genericTemplate" />
      </div>
    </Variant>

    <Variant title="Button Template (Single Card)">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="buttonTemplate" />
      </div>
    </Variant>

    <Variant title="Card Without Image">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="cardWithoutImage" />
      </div>
    </Variant>

    <Variant title="Long Text (Truncation Test)">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="cardWithLongText" />
      </div>
    </Variant>

    <Variant title="Feature Flag Disabled (Text Fallback)">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="featureFlagDisabled" />
      </div>
    </Variant>
  </Story>
</template>

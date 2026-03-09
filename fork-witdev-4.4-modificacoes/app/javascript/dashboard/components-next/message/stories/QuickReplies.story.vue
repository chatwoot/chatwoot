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
    content: 'Quick reply fallback text',
    inboxId: 475,
    conversationId: 43,
    messageType: 0,
    contentType: 'input_select',
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

// Basic QuickReplies with simple options
const basicQuickReplies = computed(() =>
  getMessage({
    ...baseSenderData.value,
    contentAttributes: {
      items: [
        {
          title: 'Yes',
          value: 'yes',
          payload: 'USER_SAID_YES',
        },
        {
          title: 'No',
          value: 'no',
          payload: 'USER_SAID_NO',
        },
        {
          title: 'Maybe',
          value: 'maybe',
          payload: 'USER_SAID_MAYBE',
        },
      ],
    },
  })
);

// QuickReplies with longer text
const longTextQuickReplies = computed(() =>
  getMessage({
    ...baseSenderData.value,
    contentAttributes: {
      items: [
        {
          title: 'I would like to speak with a customer service representative',
          value: 'customer_service',
          payload: 'CUSTOMER_SERVICE_REQUEST',
        },
        {
          title: 'I need technical support for my account',
          value: 'technical_support',
          payload: 'TECHNICAL_SUPPORT_REQUEST',
        },
        {
          title: 'I want to cancel my subscription',
          value: 'cancel_subscription',
          payload: 'CANCEL_SUBSCRIPTION_REQUEST',
        },
      ],
    },
  })
);

// QuickReplies without values (title only)
const titleOnlyQuickReplies = computed(() =>
  getMessage({
    ...baseSenderData.value,
    contentAttributes: {
      items: [
        {
          title: 'Get Started',
        },
        {
          title: 'Learn More',
        },
        {
          title: 'Contact Support',
        },
      ],
    },
  })
);

// QuickReplies with same title and value
const sameValueQuickReplies = computed(() =>
  getMessage({
    ...baseSenderData.value,
    contentAttributes: {
      items: [
        {
          title: 'Option A',
          value: 'Option A',
          payload: 'OPTION_A',
        },
        {
          title: 'Option B',
          value: 'Option B',
          payload: 'OPTION_B',
        },
      ],
    },
  })
);

// Many options (testing scrolling/layout)
const manyOptionsQuickReplies = computed(() =>
  getMessage({
    ...baseSenderData.value,
    contentAttributes: {
      items: [
        { title: 'Option 1', value: 'opt1', payload: 'OPT_1' },
        { title: 'Option 2', value: 'opt2', payload: 'OPT_2' },
        { title: 'Option 3', value: 'opt3', payload: 'OPT_3' },
        { title: 'Option 4', value: 'opt4', payload: 'OPT_4' },
        { title: 'Option 5', value: 'opt5', payload: 'OPT_5' },
        { title: 'Option 6', value: 'opt6', payload: 'OPT_6' },
        { title: 'Option 7', value: 'opt7', payload: 'OPT_7' },
        { title: 'Option 8', value: 'opt8', payload: 'OPT_8' },
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
          title: 'This should not render as quick replies',
          value: 'disabled',
        },
      ],
    },
  });
});

// Submitted form (should use FormBubble, not QuickReplies)
const submittedForm = computed(() =>
  getMessage({
    ...baseSenderData.value,
    content: 'User selected an option',
    contentAttributes: {
      items: [
        {
          title: 'Option 1',
          value: 'opt1',
        },
        {
          title: 'Option 2',
          value: 'opt2',
        },
      ],
      submittedValues: [
        {
          title: 'Option 1',
          value: 'opt1',
        },
      ],
    },
  })
);
</script>

<template>
  <Story
    title="Components/Message Bubbles/Quick Replies"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Basic Quick Replies">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="basicQuickReplies" />
      </div>
    </Variant>

    <Variant title="Long Text Options">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="longTextQuickReplies" />
      </div>
    </Variant>

    <Variant title="Title Only (No Values)">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="titleOnlyQuickReplies" />
      </div>
    </Variant>

    <Variant title="Same Title and Value">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="sameValueQuickReplies" />
      </div>
    </Variant>

    <Variant title="Many Options">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="manyOptionsQuickReplies" />
      </div>
    </Variant>

    <Variant title="Feature Flag Disabled (Text Fallback)">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="featureFlagDisabled" />
      </div>
    </Variant>

    <Variant title="Submitted Form (Uses FormBubble)">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="submittedForm" />
      </div>
    </Variant>
  </Story>
</template>

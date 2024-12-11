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
    content: 'Hey, how are ya, I had a few questions about Chatwoot?',
    inboxId: 475,
    conversationId: 43,
    messageType: 0,
    contentType: 'text',
    status: 'sent',
    createdAt: 1732195656,
    private: false,
    sourceId: null,
    ...overrides,
    sender,
    contentAttributes,
  };
};

const getAttachment = (type, url, overrides) => {
  return {
    id: 22,
    messageId: 5319,
    fileType: type,
    accountId: 2,
    extension: null,
    dataUrl: url,
    thumbUrl: '',
    fileSize: 345644,
    width: null,
    height: null,
    ...overrides,
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

const instagramStory = computed(() =>
  getMessage({
    content: 'cwtestinglocal mentioned you in the story: ',
    contentAttributes: {
      imageType: 'story_mention',
    },
    attachments: [
      getAttachment(
        'image',
        'https://images.pexels.com/photos/2587370/pexels-photo-2587370.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=2'
      ),
    ],
    ...baseSenderData.value,
  })
);

const unsupported = computed(() =>
  getMessage({
    content: null,
    contentAttributes: {
      isUnsupported: true,
    },
    ...baseSenderData.value,
  })
);

const igReel = computed(() =>
  getMessage({
    content: null,
    attachments: [
      getAttachment(
        'ig_reel',
        'https://videos.pexels.com/video-files/2023708/2023708-hd_720_1280_30fps.mp4'
      ),
    ],
    ...baseSenderData.value,
  })
);
</script>

<template>
  <Story
    title="Components/Message Bubbles/Instagram"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Instagram Reel">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="igReel" />
      </div>
    </Variant>

    <Variant title="Instagram Story">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="instagramStory" />
      </div>
    </Variant>

    <Variant title="Unsupported">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="unsupported" />
      </div>
    </Variant>
  </Story>
</template>

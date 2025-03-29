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

const audioMessage = computed(() =>
  getMessage({
    content: null,
    attachments: [
      getAttachment(
        'audio',
        'https://cdn.freesound.org/previews/769/769025_16085454-lq.mp3'
      ),
    ],
    ...baseSenderData.value,
  })
);

const brokenImageMessage = computed(() =>
  getMessage({
    content: null,
    attachments: [getAttachment('image', 'https://chatwoot.dev/broken.png')],
    ...baseSenderData.value,
  })
);

const imageMessage = computed(() =>
  getMessage({
    content: null,
    attachments: [
      getAttachment(
        'image',
        'https://images.pexels.com/photos/28506417/pexels-photo-28506417/free-photo-of-motorbike-on-scenic-road-in-surat-thani-thailand.jpeg'
      ),
    ],
    ...baseSenderData.value,
  })
);

const videoMessage = computed(() =>
  getMessage({
    content: null,
    attachments: [
      getAttachment(
        'video',
        'https://videos.pexels.com/video-files/1739010/1739010-hd_1920_1080_30fps.mp4'
      ),
    ],
    ...baseSenderData.value,
  })
);

const attachmentsOnly = computed(() =>
  getMessage({
    content: null,
    attachments: [
      getAttachment('image', 'https://chatwoot.dev/broken.png'),
      getAttachment(
        'video',
        'https://videos.pexels.com/video-files/1739010/1739010-hd_1920_1080_30fps.mp4'
      ),
      getAttachment(
        'image',
        'https://images.pexels.com/photos/28506417/pexels-photo-28506417/free-photo-of-motorbike-on-scenic-road-in-surat-thani-thailand.jpeg'
      ),
      getAttachment('file', 'https://chatwoot.dev/invoice.pdf'),
      getAttachment('file', 'https://chatwoot.dev/logs.txt'),
      getAttachment('file', 'https://chatwoot.dev/contacts.xls'),
      getAttachment('file', 'https://chatwoot.dev/customers.csv'),
      getAttachment('file', 'https://chatwoot.dev/warehousing-policy.docx'),
      getAttachment('file', 'https://chatwoot.dev/pitch-deck.ppt'),
      getAttachment('file', 'https://chatwoot.dev/all-files.tar'),
      getAttachment(
        'audio',
        'https://cdn.freesound.org/previews/769/769025_16085454-lq.mp3'
      ),
    ],
    ...baseSenderData.value,
  })
);

const singleFile = computed(() =>
  getMessage({
    content: null,
    attachments: [getAttachment('file', 'https://chatwoot.dev/all-files.tar')],
    ...baseSenderData.value,
  })
);

const contact = computed(() =>
  getMessage({
    content: null,
    attachments: [
      getAttachment('contact', null, {
        fallbackTitle: '+919999999999',
      }),
    ],
    ...baseSenderData.value,
  })
);

const location = computed(() =>
  getMessage({
    content: null,
    attachments: [
      getAttachment('location', null, {
        coordinatesLat: 37.7937545,
        coordinatesLong: -122.3997472,
        fallbackTitle: 'Chatwoot Inc',
      }),
    ],
    ...baseSenderData.value,
  })
);

const dyte = computed(() => {
  return getMessage({
    messageType: 1,
    contentType: 'integrations',
    contentAttributes: {
      type: 'dyte',
      data: {
        meetingId: 'f16bebe6-08b9-4593-899a-849f59c47397',
        roomName: 'zcufnc-adbjcg',
      },
    },
    senderId: 1,
    sender: {
      id: 1,
      name: 'Shivam Mishra',
      availableName: 'Shivam Mishra',
      type: 'user',
    },
  });
});
</script>

<template>
  <Story
    title="Components/Message Bubbles/Media"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <!-- Media Types -->
    <Variant title="Audio">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="audioMessage" />
      </div>
    </Variant>
    <Variant title="Image">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="imageMessage" />
      </div>
    </Variant>
    <Variant title="Broken Image">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="brokenImageMessage" />
      </div>
    </Variant>
    <Variant title="Video">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="videoMessage" />
      </div>
    </Variant>

    <!-- Files and Attachments -->
    <Variant title="Multiple Attachments">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="attachmentsOnly" />
      </div>
    </Variant>
    <Variant title="File">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="singleFile" />
      </div>
    </Variant>
    <Variant title="Contact">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="contact" />
      </div>
    </Variant>
    <Variant title="Location">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="location" />
      </div>
    </Variant>
    <Variant title="Dyte Video">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="dyte" />
      </div>
    </Variant>
  </Story>
</template>

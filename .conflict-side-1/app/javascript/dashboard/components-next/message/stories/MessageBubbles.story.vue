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

const simpleText = computed(() =>
  getMessage({
    ...baseSenderData.value,
  })
);
const privateText = computed(() =>
  getMessage({ private: true, ...baseSenderData.value })
);

const activityMessage = computed(() =>
  getMessage({
    content: 'John self-assigned this conversation',
    messageType: 2,
  })
);

const email = computed(() =>
  getMessage({
    content: null,
    contentType: 'incoming_email',
    contentAttributes: {
      email: {
        bcc: null,
        cc: null,
        contentType:
          'multipart/alternative; boundary=0000000000009d889e0628477235',
        date: '2024-12-02T16:29:39+05:30',
        from: ['hey@shivam.dev'],
        htmlContent: {
          full: '<div dir="ltr"><h3><span style="font-size:small;font-weight:normal">Hi Team,</span></h3>\r\n<p>I hope this email finds you well! I wanted to share some updates regarding our integration with <strong>Chatwoot</strong> and outline some key features we’ve explored.</p>\r\n<hr>\r\n<h3>Key Updates</h3>\r\n<ol>\r\n<li>\r\n<p><strong>Integration Status</strong>:<br>\r\nThe initial integration with Chatwoot has been successful. We&#39;ve tested:</p>\r\n<ul>\r\n<li>API connectivity</li>\r\n<li>Multi-channel messaging</li>\r\n<li>Real-time chat updates</li>\r\n</ul>\r\n</li>\r\n<li>\r\n<p><strong>Upcoming Tasks</strong>:</p>\r\n<ul>\r\n<li>Streamlining notification workflows</li>\r\n<li>Enhancing webhook reliability</li>\r\n<li>Testing team collaboration features</li>\r\n</ul>\r\n</li>\r\n</ol>\r\n<blockquote>\r\n<p><strong>Note:</strong><br>\r\nDon’t forget to check out the automation capabilities in Chatwoot for handling repetitive queries. It can save a ton of time!</p>\r\n</blockquote>\r\n<hr>\r\n<h3>Features We Love</h3>\r\n<p>Here’s what stood out so far:</p>\r\n<ul>\r\n<li><strong>Unified Inbox</strong>: All customer conversations in one place.</li>\r\n<li><strong>Customizable Workflows</strong>: Tailored to our team’s unique needs.</li>\r\n<li><strong>Integrations</strong>: Works seamlessly with CRM and Slack.</li>\r\n</ul>\r\n<hr>\r\n<h3>Action Items</h3>\r\n<h4>For Next Week:</h4>\r\n<ol>\r\n<li>Implement the webhook for <strong>ticket prioritization</strong>.</li>\r\n<li>Test <strong>CSAT surveys</strong> post-chat sessions.</li>\r\n<li>Review <strong>analytics dashboard</strong> insights.</li>\r\n</ol>\r\n<hr>\r\n<h3>Data Snapshot</h3>\r\n<p>Here’s a quick overview of our conversation stats this week:</p>\r\n<table>\r\n<thead>\r\n<tr>\r\n<th>Metric</th>\r\n<th>Value</th>\r\n<th>Change (%)</th>\r\n</tr>\r\n</thead>\r\n<tbody>\r\n<tr>\r\n<td>Total Conversations</td>\r\n<td>350</td>\r\n<td>+25%</td>\r\n</tr>\r\n<tr>\r\n<td>Average Response Time</td>\r\n<td>3 minutes</td>\r\n<td>-15%</td>\r\n</tr>\r\n<tr>\r\n<td>CSAT Score</td>\r\n<td>92%</td>\r\n<td>+10%</td>\r\n</tr>\r\n</tbody>\r\n</table>\r\n<hr>\r\n<h3>Feedback</h3>\r\n<p><i>Do let me know if you have additional feedback or ideas to improve our workflows. Here’s an image of how our Chatwoot dashboard looks with recent changes:</i></p>\r\n<p><img src="https://via.placeholder.com/600x300" alt="Chatwoot Dashboard Screenshot" title="Chatwoot Dashboard"></p>\r\n<hr>\r\n<p>Looking forward to hearing your thoughts!</p>\r\n<p>Best regards,<br>~ Shivam Mishra<br></p></div>\r\n',
          reply:
            "Hi Team,\n\nI hope this email finds you well! I wanted to share some updates regarding our integration with Chatwoot and outline some key features we’ve explored.\n\n---------------------------------------------------------------\n\nKey Updates\n\n-\n\nIntegration Status:\nThe initial integration with Chatwoot has been successful. We've tested:\n\n- API connectivity\n- Multi-channel messaging\n- Real-time chat updates\n\n-\n\nUpcoming Tasks:\n\n- Streamlining notification workflows\n- Enhancing webhook reliability\n- Testing team collaboration features\n\n>\n---------------------------------------------------------------\n\nFeatures We Love\n\nHere’s what stood out so far:\n\n-  Unified Inbox: All customer conversations in one place.\n-  Customizable Workflows: Tailored to our team’s unique needs.\n-  Integrations: Works seamlessly with CRM and Slack.\n\n---------------------------------------------------------------\n\nAction Items\n\nFor Next Week:\n\n- Implement the webhook for ticket prioritization.\n- Test CSAT surveys post-chat sessions.\n- Review analytics dashboard insights.\n\n---------------------------------------------------------------\n\nData Snapshot\n\nHere’s a quick overview of our conversation stats this week:\n\nMetric\tValue\tChange (%)\nTotal Conversations\t350\t+25%\nAverage Response Time\t3 minutes\t-15%\nCSAT Score\t92%\t+10%\n---------------------------------------------------------------\n\nFeedback\n\nDo let me know if you have additional feedback or ideas to improve our workflows. Here’s an image of how our Chatwoot dashboard looks with recent changes:\n\n[Chatwoot Dashboard]\n\n---------------------------------------------------------------\n\nLooking forward to hearing your thoughts!\n\nBest regards,\n~ Shivam Mishra",
          quoted:
            'Hi Team,\n\nI hope this email finds you well! I wanted to share some updates regarding our integration with Chatwoot and outline some key features we’ve explored.',
        },
        inReplyTo: null,
        messageId:
          'CAM_Qp+8bpiT5xFL7HmVL4a9RD0TmdYw7Lu6ZV02yu=eyon41DA@mail.gmail.com',
        multipart: true,
        numberOfAttachments: 0,
        subject: 'Update on Chatwoot Integration and Features',
        textContent: {
          full: "Hi Team,\r\n\r\nI hope this email finds you well! I wanted to share some updates regarding\r\nour integration with *Chatwoot* and outline some key features we’ve\r\nexplored.\r\n------------------------------\r\nKey Updates\r\n\r\n   1.\r\n\r\n   *Integration Status*:\r\n   The initial integration with Chatwoot has been successful. We've tested:\r\n   - API connectivity\r\n      - Multi-channel messaging\r\n      - Real-time chat updates\r\n   2.\r\n\r\n   *Upcoming Tasks*:\r\n   - Streamlining notification workflows\r\n      - Enhancing webhook reliability\r\n      - Testing team collaboration features\r\n\r\n*Note:*\r\nDon’t forget to check out the automation capabilities in Chatwoot for\r\nhandling repetitive queries. It can save a ton of time!\r\n\r\n------------------------------\r\nFeatures We Love\r\n\r\nHere’s what stood out so far:\r\n\r\n   - *Unified Inbox*: All customer conversations in one place.\r\n   - *Customizable Workflows*: Tailored to our team’s unique needs.\r\n   - *Integrations*: Works seamlessly with CRM and Slack.\r\n\r\n------------------------------\r\nAction Items For Next Week:\r\n\r\n   1. Implement the webhook for *ticket prioritization*.\r\n   2. Test *CSAT surveys* post-chat sessions.\r\n   3. Review *analytics dashboard* insights.\r\n\r\n------------------------------\r\nData Snapshot\r\n\r\nHere’s a quick overview of our conversation stats this week:\r\nMetric Value Change (%)\r\nTotal Conversations 350 +25%\r\nAverage Response Time 3 minutes -15%\r\nCSAT Score 92% +10%\r\n------------------------------\r\nFeedback\r\n\r\n*Do let me know if you have additional feedback or ideas to improve our\r\nworkflows. Here’s an image of how our Chatwoot dashboard looks with recent\r\nchanges:*\r\n\r\n[image: Chatwoot Dashboard Screenshot]\r\n------------------------------\r\n\r\nLooking forward to hearing your thoughts!\r\n\r\nBest regards,\r\n~ Shivam Mishra\r\n",
          reply:
            "Hi Team,\n\nI hope this email finds you well! I wanted to share some updates regarding\nour integration with *Chatwoot* and outline some key features we’ve\nexplored.\n------------------------------\nKey Updates\n\n   1.\n\n   *Integration Status*:\n   The initial integration with Chatwoot has been successful. We've tested:\n   - API connectivity\n      - Multi-channel messaging\n      - Real-time chat updates\n   2.\n\n   *Upcoming Tasks*:\n   - Streamlining notification workflows\n      - Enhancing webhook reliability\n      - Testing team collaboration features\n\n*Note:*\nDon’t forget to check out the automation capabilities in Chatwoot for\nhandling repetitive queries. It can save a ton of time!\n\n------------------------------\nFeatures We Love\n\nHere’s what stood out so far:\n\n   - *Unified Inbox*: All customer conversations in one place.\n   - *Customizable Workflows*: Tailored to our team’s unique needs.\n   - *Integrations*: Works seamlessly with CRM and Slack.\n\n------------------------------\nAction Items For Next Week:\n\n   1. Implement the webhook for *ticket prioritization*.\n   2. Test *CSAT surveys* post-chat sessions.\n   3. Review *analytics dashboard* insights.\n\n------------------------------\nData Snapshot\n\nHere’s a quick overview of our conversation stats this week:\nMetric Value Change (%)\nTotal Conversations 350 +25%\nAverage Response Time 3 minutes -15%\nCSAT Score 92% +10%\n------------------------------\nFeedback\n\n*Do let me know if you have additional feedback or ideas to improve our\nworkflows. Here’s an image of how our Chatwoot dashboard looks with recent\nchanges:*\n\n[image: Chatwoot Dashboard Screenshot]\n------------------------------\n\nLooking forward to hearing your thoughts!\n\nBest regards,\n~ Shivam Mishra",
          quoted:
            'Hi Team,\n\nI hope this email finds you well! I wanted to share some updates regarding\nour integration with *Chatwoot* and outline some key features we’ve\nexplored.',
        },
        to: ['shivam@chatwoot.com'],
      },
      ccEmail: null,
      bccEmail: null,
    },
    attachments: [
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
</script>

<template>
  <Story
    title="Components/Message Bubbles/Bubbles"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Text">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="simpleText" />
      </div>
    </Variant>
    <Variant title="Activity">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="activityMessage" />
      </div>
    </Variant>
    <Variant title="Private Message">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="privateText" />
      </div>
    </Variant>

    <!-- Platform Specific -->
    <Variant title="Email">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" is-email-inbox v-bind="email" />
      </div>
    </Variant>
  </Story>
</template>

<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import {
  getEffectiveChannelType,
  getReplyVariables,
  resolveVariablesInMessage,
} from 'dashboard/helper/editorHelper';
import {
  CHANGE_TYPES,
  adaptCannedResponse,
} from 'dashboard/helper/cannedResponseHelper';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import MessageFormatter from 'shared/helpers/MessageFormatter';

import Button from 'dashboard/components-next/button/Button.vue';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import FileChip from 'dashboard/components-next/message/chips/File.vue';
import ChannelName from 'dashboard/routes/dashboard/settings/inbox/components/ChannelName.vue';

const props = defineProps({
  content: { type: String, required: true },
  files: { type: Array, required: true },
});

const SAMPLE_CONTACT = {
  name: 'Maya Patel',
  email: 'maya@example.com',
  phone_number: '+14155550100',
};

const BLOCKING_CHANGES = [
  CHANGE_TYPES.IMAGE_BLOCKED,
  CHANGE_TYPES.FILE_BLOCKED,
];

const STATUS_DOT_CLASSES = {
  unchanged: 'bg-n-teal-9',
  adjusted: 'bg-n-amber-9',
  blocked: 'bg-n-ruby-9',
};

const { t } = useI18n();

const inboxes = useMapGetter('inboxes/getInboxes');
const currentUser = useMapGetter('getCurrentUser');

const selectedChannel = ref(null);
const showAllChanges = ref(false);

const channelOf = inbox =>
  getEffectiveChannelType(inbox.channel_type, inbox.medium);

const isImage = file => file.content_type.startsWith('image/');

const statusOf = changes => {
  if (changes.some(change => BLOCKING_CHANGES.includes(change.type))) {
    return 'blocked';
  }
  return changes.length ? 'adjusted' : 'unchanged';
};

const previews = computed(() => {
  const uploadedFiles = props.files.filter(file => file.signed_id);
  // X inboxes can no longer be added, so one left from before gets no preview
  const channelInboxes = inboxes.value.filter(
    (inbox, index) =>
      inbox.channel_type !== INBOX_TYPES.TWITTER &&
      inboxes.value.findIndex(item => channelOf(item) === channelOf(inbox)) ===
        index
  );

  return channelInboxes.map(inbox => {
    const variables = getReplyVariables({
      conversation: { meta: { sender: SAMPLE_CONTACT } },
      contact: SAMPLE_CONTACT,
      inbox,
      user: currentUser.value,
    });
    const preview = adaptCannedResponse(
      {
        content: resolveVariablesInMessage(props.content, variables),
        files: uploadedFiles,
      },
      { channelType: inbox.channel_type, medium: inbox.medium }
    );
    return { ...preview, inbox, status: statusOf(preview.changes) };
  });
});

const preview = computed(
  () =>
    previews.value.find(
      item => channelOf(item.inbox) === selectedChannel.value
    ) ?? previews.value[0]
);

const formattedContent = computed(
  () => new MessageFormatter(preview.value.content).formattedMessage
);

const images = computed(() => preview.value.attachments.filter(isImage));

const documents = computed(() =>
  preview.value.attachments.filter(file => !isImage(file))
);

const isEmpty = computed(
  () => !preview.value.content.trim() && !preview.value.attachments.length
);

const statusLabel = computed(() => {
  const labels = {
    unchanged: t('CANNED_MGMT.PREVIEW.STATUS.UNCHANGED'),
    adjusted: t('CANNED_MGMT.PREVIEW.STATUS.ADJUSTED'),
    blocked: t('CANNED_MGMT.PREVIEW.STATUS.BLOCKED'),
  };
  return labels[preview.value.status];
});

const describeChange = ({ type, name }) => {
  const messages = {
    [CHANGE_TYPES.BOLD]: t('CANNED_MGMT.PREVIEW.CHANGES.BOLD'),
    [CHANGE_TYPES.ITALIC]: t('CANNED_MGMT.PREVIEW.CHANGES.ITALIC'),
    [CHANGE_TYPES.CODE]: t('CANNED_MGMT.PREVIEW.CHANGES.CODE'),
    [CHANGE_TYPES.STRIKETHROUGH]: t(
      'CANNED_MGMT.PREVIEW.CHANGES.STRIKETHROUGH'
    ),
    [CHANGE_TYPES.QUOTE]: t('CANNED_MGMT.PREVIEW.CHANGES.QUOTE'),
    [CHANGE_TYPES.LINK]: t('CANNED_MGMT.PREVIEW.CHANGES.LINK'),
    [CHANGE_TYPES.LIST]: t('CANNED_MGMT.PREVIEW.CHANGES.LIST'),
    [CHANGE_TYPES.IMAGE_MOVED]: t('CANNED_MGMT.PREVIEW.CHANGES.IMAGE_MOVED'),
    [CHANGE_TYPES.IMAGE_BLOCKED]: t(
      'CANNED_MGMT.PREVIEW.CHANGES.IMAGE_BLOCKED'
    ),
    [CHANGE_TYPES.FILE_SEPARATE]: t(
      'CANNED_MGMT.PREVIEW.CHANGES.FILE_SEPARATE'
    ),
    [CHANGE_TYPES.FILE_BLOCKED]: t('CANNED_MGMT.PREVIEW.CHANGES.FILE_BLOCKED', {
      fileName: name,
    }),
  };
  return messages[type];
};

const changes = computed(() => {
  const notes = preview.value.changes.map(change => ({
    message: describeChange(change),
    isBlocked: BLOCKING_CHANGES.includes(change.type),
  }));
  return [
    ...notes.filter(note => note.isBlocked),
    ...notes.filter(note => !note.isBlocked),
  ];
});

const visibleChanges = computed(() =>
  showAllChanges.value ? changes.value : changes.value.slice(0, 1)
);
</script>

<template>
  <div class="flex-shrink-0 lg:relative lg:w-96">
    <div class="flex flex-col gap-1 h-[30rem] lg:absolute lg:inset-0 lg:h-auto">
      <span class="mb-0.5 text-heading-3 text-n-slate-12">
        {{ t('CANNED_MGMT.PREVIEW.TITLE') }}
      </span>
      <div
        class="flex flex-col flex-1 min-h-0 overflow-hidden border rounded-xl border-n-strong"
      >
        <div class="flex flex-wrap gap-1 p-1.5 border-b border-n-strong">
          <Button
            v-for="item in previews"
            :key="item.inbox.id"
            type="button"
            slate
            sm
            class="relative"
            :variant="item === preview ? 'faded' : 'ghost'"
            :aria-pressed="item === preview"
            @click="selectedChannel = channelOf(item.inbox)"
          >
            <template #icon>
              <ChannelIcon :inbox="item.inbox" class="flex-shrink-0 size-4" />
              <ChannelName
                class="sr-only"
                :channel-type="item.inbox.channel_type"
                :medium="item.inbox.medium"
              />
              <span
                class="absolute rounded-full top-1 end-1 size-1.5"
                :class="STATUS_DOT_CLASSES[item.status]"
              />
            </template>
          </Button>
        </div>

        <div
          :key="preview.inbox.id"
          class="flex flex-col flex-1 min-h-0 gap-3 p-3 overflow-y-auto"
        >
          <div class="flex items-center justify-between gap-3">
            <ChannelName
              class="truncate text-heading-3 text-n-slate-12"
              :channel-type="preview.inbox.channel_type"
              :medium="preview.inbox.medium"
            />
            <span
              v-if="!isEmpty"
              class="flex items-center flex-shrink-0 gap-1.5 text-label-small text-n-slate-11"
            >
              <span
                class="rounded-full size-1.5"
                :class="STATUS_DOT_CLASSES[preview.status]"
              />
              {{ statusLabel }}
            </span>
          </div>

          <p v-if="isEmpty" class="mb-0 text-body-main text-n-slate-10">
            {{ t('CANNED_MGMT.PREVIEW.EMPTY') }}
          </p>
          <div
            v-else
            class="flex flex-col flex-shrink-0 gap-3 px-4 py-3 text-sm rounded-xl ltr:rounded-br-sm rtl:rounded-bl-sm bg-n-solid-blue text-n-slate-12"
          >
            <span
              v-if="preview.content.trim()"
              v-dompurify-html="formattedContent"
              class="prose prose-bubble"
            />
            <div v-if="images.length" class="flex flex-wrap justify-end gap-2">
              <img
                v-for="(image, index) in images"
                :key="index"
                :src="image.file_url"
                alt=""
                class="object-cover size-[4.5rem] rounded-xl bg-n-alpha-2"
              />
            </div>
            <div
              v-if="documents.length"
              class="flex flex-wrap justify-end gap-2"
            >
              <FileChip
                v-for="file in documents"
                :key="file.signed_id"
                :attachment="{ dataUrl: file.file_url }"
              />
            </div>
          </div>
        </div>

        <div
          v-if="changes.length"
          class="flex flex-col items-start gap-2 p-3 border-t border-n-strong"
        >
          <ul
            class="flex flex-col w-full gap-1.5 m-0 overflow-y-auto list-none max-h-40"
          >
            <li
              v-for="change in visibleChanges"
              :key="change.message"
              class="flex items-start gap-1.5 text-label-small text-n-slate-11"
            >
              <Icon
                :icon="
                  change.isBlocked
                    ? 'i-lucide-circle-x'
                    : 'i-lucide-triangle-alert'
                "
                class="flex-shrink-0 mt-px size-3.5"
                :class="change.isBlocked ? 'text-n-ruby-11' : 'text-n-amber-11'"
              />
              {{ change.message }}
            </li>
          </ul>
          <Button
            v-if="changes.length > 1"
            type="button"
            faded
            slate
            xs
            trailing-icon
            class="ms-5"
            :aria-expanded="showAllChanges"
            :icon="
              showAllChanges ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'
            "
            :label="
              showAllChanges
                ? t('CANNED_MGMT.PREVIEW.SHOW_LESS')
                : t('CANNED_MGMT.PREVIEW.SHOW_MORE', {
                    count: changes.length - 1,
                  })
            "
            @click="showAllChanges = !showAllChanges"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  notes: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const route = useRoute();
const router = useRouter();
const { t } = useI18n();
const { formatMessage } = useMessageFormatter();
const currentUser = useMapGetter('getCurrentUser');

const hasNotes = computed(() => props.notes.length > 0);

const contactName = contact =>
  contact?.name || t('COMPANIES.DETAIL.CONTACTS.UNNAMED_CONTACT');

const getWrittenBy = note => {
  const isCurrentUser = note?.user?.id === currentUser.value.id;
  return isCurrentUser
    ? t('CONTACTS_LAYOUT.SIDEBAR.NOTES.YOU')
    : note?.user?.name || 'Bot';
};

const openContact = contactId => {
  router.push({
    name: 'contacts_edit',
    params: {
      accountId: route.params.accountId,
      contactId,
    },
  });
};
</script>

<template>
  <div v-if="hasNotes" class="flex flex-col px-6">
    <div class="flex flex-col divide-y divide-n-strong">
      <div
        v-for="note in notes"
        :key="note.id"
        class="flex flex-col gap-2 py-4 group/note"
      >
        <div class="flex items-center gap-1.5 min-w-0">
          <Avatar
            :name="contactName(note.contact)"
            :src="note.contact?.thumbnail"
            :size="16"
            rounded-full
            hide-offline-status
          />
          <div
            class="flex items-center justify-between min-w-0 gap-1 w-full text-sm text-n-slate-11"
          >
            <button
              type="button"
              class="min-w-0 font-medium truncate text-start text-n-slate-12 hover:text-n-blue-11 p-0"
              @click="openContact(note.contact.id)"
            >
              {{ contactName(note.contact) }}
            </button>
            <div class="min-w-0 truncate">
              <span
                class="inline-flex items-center gap-1 text-sm text-n-slate-10"
              >
                <span class="font-medium text-n-slate-11">
                  {{ getWrittenBy(note) }}
                </span>
                {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.WROTE') }}
                <span class="font-medium text-n-slate-11">
                  {{ dynamicTime(note.createdAt) }}
                </span>
              </span>
            </div>
          </div>
        </div>
        <p
          v-dompurify-html="formatMessage(note.content || '')"
          class="mb-0 prose-sm prose-p:text-sm prose-p:leading-relaxed prose-p:mb-1 prose-p:mt-0 prose-ul:mb-1 prose-ul:mt-0 text-n-slate-12"
        />
      </div>
    </div>
  </div>

  <div
    v-else-if="isLoading"
    class="flex items-center justify-center py-10 text-n-slate-11"
  >
    <Spinner />
  </div>

  <p
    v-else
    class="py-8 mx-6 px-4 text-sm text-center rounded-xl border border-dashed border-n-strong text-n-slate-11"
  >
    {{ t('COMPANIES.DETAIL.NOTES.EMPTY') }}
  </p>
</template>

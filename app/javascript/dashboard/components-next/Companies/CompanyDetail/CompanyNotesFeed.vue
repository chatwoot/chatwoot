<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { fromUnixTime, isToday, isYesterday } from 'date-fns';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { dateFormat } from 'shared/helpers/timeHelper';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  notes: { type: Array, default: () => [] },
  isLoading: { type: Boolean, default: false },
  emptyMessage: { type: String, required: true },
  hasMore: { type: Boolean, default: false },
  highlight: { type: String, default: '' },
  deletable: { type: Boolean, default: false },
});

const emit = defineEmits(['loadMore', 'delete']);

const NOTE_CLAMP_LENGTH = 240;

const { t } = useI18n();
const router = useRouter();
const { accountId } = useAccount();
const { formatMessage } = useMessageFormatter();
const currentUser = useMapGetter('getCurrentUser');

const expandedNotes = ref(new Set());

const toggleNote = noteId => {
  const next = new Set(expandedNotes.value);
  if (next.has(noteId)) next.delete(noteId);
  else next.add(noteId);
  expandedNotes.value = next;
};

const escapeRegExp = value => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// Wrap search matches in <mark>, touching only text between tags so markup stays intact.
const noteHtml = note => {
  const html = formatMessage(note.content || '');
  const term = props.highlight.trim();
  if (!term) return html;

  const pattern = new RegExp(`(${escapeRegExp(term)})`, 'gi');
  return html
    .split(/(<[^>]+>)/)
    .map(part =>
      part.startsWith('<') ? part : part.replace(pattern, '<mark>$1</mark>')
    )
    .join('');
};

const noteAuthor = note =>
  note.user?.id === currentUser.value.id
    ? t('CONTACTS_LAYOUT.SIDEBAR.NOTES.YOU')
    : note.user?.name || t('COMPANIES.DETAIL.ACTIVITY.UNKNOWN_AUTHOR');

const noteContactName = note =>
  note.contact?.name || t('COMPANIES.DETAIL.CONTACTS.UNNAMED_CONTACT');

const openContact = contactId => {
  router.push({
    name: 'contacts_edit',
    params: { accountId: accountId.value, contactId },
  });
};

const dayLabel = time => {
  const date = fromUnixTime(time);
  if (isToday(date)) return t('COMPANIES.DETAIL.ACTIVITY.TODAY');
  if (isYesterday(date)) return t('COMPANIES.DETAIL.ACTIVITY.YESTERDAY');
  return dateFormat(time, 'EEEE, MMM d');
};

const groups = computed(() =>
  props.notes.reduce((result, note) => {
    const label = dayLabel(note.createdAt);
    const group = result.at(-1);
    if (group?.label === label) group.notes.push(note);
    else result.push({ label, notes: [note] });
    return result;
  }, [])
);
</script>

<template>
  <section class="flex flex-col gap-5">
    <div v-if="isLoading && !notes.length" class="flex justify-center py-12">
      <Spinner />
    </div>

    <p
      v-else-if="!notes.length"
      class="px-6 py-10 text-sm text-center border border-dashed rounded-xl border-n-weak text-n-slate-11"
    >
      {{ emptyMessage }}
    </p>

    <div v-else class="flex flex-col gap-6">
      <div v-for="group in groups" :key="group.label" class="flex flex-col">
        <h3 class="text-label-small text-n-slate-10">{{ group.label }}</h3>
        <ol class="m-0 list-none divide-y ps-0 divide-n-weak">
          <li v-for="note in group.notes" :key="note.id">
            <div class="flex items-start gap-4 py-4">
              <Avatar
                :name="noteAuthor(note)"
                :src="note.user?.thumbnail"
                :size="40"
                hide-offline-status
                class="shrink-0"
              />
              <span class="flex flex-col flex-1 min-w-0 gap-1">
                <span class="flex items-center justify-between gap-2">
                  <span class="truncate text-heading-3 text-n-slate-12">
                    {{ noteAuthor(note) }}
                  </span>
                  <Button
                    v-if="deletable"
                    v-tooltip.top="t('CONTACTS_LAYOUT.DETAIL.NOTES.DELETE')"
                    icon="i-lucide-trash-2"
                    variant="ghost"
                    color="slate"
                    size="xs"
                    class="shrink-0"
                    @click="emit('delete', note.id)"
                  />
                </span>
                <span
                  v-dompurify-html="noteHtml(note)"
                  class="text-n-slate-11 text-body-main [&_p]:m-0 [&_p+p]:mt-2 [&_mark]:bg-n-amber-4 [&_mark]:text-n-slate-12 [&_mark]:rounded-sm [&_mark]:px-0.5"
                  :class="{
                    'line-clamp-3': !highlight && !expandedNotes.has(note.id),
                  }"
                />
                <button
                  v-if="
                    !highlight &&
                    (note.content || '').length > NOTE_CLAMP_LENGTH
                  "
                  type="button"
                  class="self-start p-0 text-label-small text-n-slate-11 hover:text-n-slate-12"
                  @click="toggleNote(note.id)"
                >
                  {{
                    expandedNotes.has(note.id)
                      ? t('COMPANIES.DETAIL.HEADER.LESS')
                      : t('COMPANIES.DETAIL.HEADER.MORE')
                  }}
                </button>
                <span class="flex items-center gap-1.5 text-xs text-n-slate-10">
                  <span class="leading-4 tabular-nums">
                    {{ dateFormat(note.createdAt, 'h:mm a') }}
                  </span>
                  <template v-if="note.contact">
                    <span class="rounded-full size-1 bg-n-slate-8" />
                    <button
                      type="button"
                      class="p-0 text-xs leading-4 truncate text-n-slate-10 hover:text-n-slate-12 hover:underline"
                      @click="openContact(note.contact.id)"
                    >
                      {{ noteContactName(note) }}
                    </button>
                  </template>
                </span>
              </span>
            </div>
          </li>
        </ol>
      </div>
    </div>

    <Button
      v-if="hasMore && notes.length"
      :label="t('COMPANIES.DETAIL.ACTIVITY.LOAD_MORE')"
      variant="faded"
      color="slate"
      size="sm"
      class="self-center"
      :is-loading="isLoading"
      @click="emit('loadMore')"
    />
  </section>
</template>

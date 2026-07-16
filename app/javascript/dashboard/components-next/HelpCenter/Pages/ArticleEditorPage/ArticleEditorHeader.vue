<script setup>
import { computed, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store.js';
import { useAlert, useTrack } from 'dashboard/composables';
import { PORTALS_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { OnClickOutside } from '@vueuse/components';
import { getArticleStatus } from 'dashboard/helper/portalHelper.js';
import {
  ARTICLE_EDITOR_STATUS_OPTIONS,
  ARTICLE_STATUSES,
  ARTICLE_MENU_ITEMS,
} from 'dashboard/helper/portalHelper';
import wootConstants from 'dashboard/constants/globals';

import ButtonGroup from 'dashboard/components-next/buttonGroup/ButtonGroup.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ArticlePendingChangesPopover from 'dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticlePendingChangesPopover.vue';

const props = defineProps({
  isUpdating: {
    type: Boolean,
    default: false,
  },
  isSaved: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    default: '',
  },
  articleId: {
    type: Number,
    default: 0,
  },
  pendingChanges: {
    type: Boolean,
    default: false,
  },
  isSaving: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['goBack', 'previewArticle', 'showDiff']);

const { t } = useI18n();
const store = useStore();
const route = useRoute();

const isArticlePublishing = ref(false);

const { ARTICLE_STATUS_TYPES } = wootConstants;

const showArticleActionMenu = ref(false);

const pendingChangesPopoverRef = useTemplateRef('pendingChangesPopoverRef');

// Per-article update flag the store already maintains.
const articleUiFlags = useMapGetter('articles/uiFlags');
const isUpdatingArticle = computed(
  () => articleUiFlags.value(props.articleId).isUpdating
);

// Publishing while a save is still in flight would promote a stale draft, so we show an alert
const blockedWhileSaving = () => {
  if (!props.isSaving && !isUpdatingArticle.value) return false;
  useAlert(t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.SAVE_IN_PROGRESS'));
  return true;
};

const isPublished = computed(() => props.status === ARTICLE_STATUSES.PUBLISHED);

const hasPendingChanges = computed(
  () => isPublished.value && props.pendingChanges
);

const articleMenuItems = computed(() => {
  const statusOptions = ARTICLE_EDITOR_STATUS_OPTIONS[props.status] ?? [];
  const items = statusOptions.map(option => {
    const { label, value, icon } = ARTICLE_MENU_ITEMS[option];
    return {
      label: t(label),
      value,
      action: 'update-status',
      icon,
    };
  });

  if (hasPendingChanges.value) {
    items.push({
      label: t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.DISCARD_CHANGES'),
      value: 'discard-draft',
      action: 'discard-draft',
      icon: 'i-lucide-undo-2',
    });
  }

  return items;
});

const statusText = computed(() =>
  t(
    `HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.STATUS.${props.isUpdating ? 'SAVING' : 'SAVED'}`
  )
);

const onClickGoBack = () => emit('goBack');

const previewArticle = () => emit('previewArticle');

const getStatusMessage = (status, isSuccess) => {
  const messageType = isSuccess ? 'SUCCESS' : 'ERROR';
  const statusMap = {
    [ARTICLE_STATUS_TYPES.PUBLISH]: 'PUBLISH_ARTICLE',
    [ARTICLE_STATUS_TYPES.ARCHIVE]: 'ARCHIVE_ARTICLE',
    [ARTICLE_STATUS_TYPES.DRAFT]: 'DRAFT_ARTICLE',
  };

  return statusMap[status]
    ? t(`HELP_CENTER.${statusMap[status]}.API.${messageType}`)
    : '';
};

// Pass draftAction (publishDraft/discardDraft) to resolve a draft in the same
// update; omit it for a plain status change.
const performStatusUpdate = async (value, draftAction) => {
  const status = getArticleStatus(value);
  if (status === ARTICLE_STATUS_TYPES.PUBLISH) {
    isArticlePublishing.value = true;
  }
  const { portalSlug } = route.params;

  try {
    await store.dispatch(`articles/${draftAction ?? 'update'}`, {
      portalSlug,
      articleId: props.articleId,
      status,
    });

    useAlert(getStatusMessage(status, true));

    if (status === ARTICLE_STATUS_TYPES.ARCHIVE) {
      useTrack(PORTALS_EVENTS.ARCHIVE_ARTICLE, { uiFrom: 'header' });
    } else if (status === ARTICLE_STATUS_TYPES.PUBLISH) {
      useTrack(PORTALS_EVENTS.PUBLISH_ARTICLE);
    }
  } catch (error) {
    useAlert(error?.message ?? getStatusMessage(status, false));
  } finally {
    isArticlePublishing.value = false;
  }
};

const updateArticleStatus = ({ value }) => {
  showArticleActionMenu.value = false;
  // Leaving published with unsaved draft edits — ask whether to apply or discard
  // first; the popover applies the status itself once resolved.
  if (hasPendingChanges.value) {
    pendingChangesPopoverRef.value?.open(getArticleStatus(value));
    return;
  }
  performStatusUpdate(value);
};

const publishDraftChanges = async () => {
  isArticlePublishing.value = true;
  const { portalSlug } = route.params;
  try {
    await store.dispatch('articles/publishDraft', {
      portalSlug,
      articleId: props.articleId,
    });
    useAlert(t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PUBLISH_CHANGES_SUCCESS'));
    useTrack(PORTALS_EVENTS.PUBLISH_ARTICLE);
  } catch (error) {
    useAlert(
      error?.message ??
        t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PUBLISH_CHANGES_ERROR')
    );
  } finally {
    isArticlePublishing.value = false;
  }
};

const discardDraftChanges = async () => {
  const { portalSlug } = route.params;
  try {
    await store.dispatch('articles/discardDraft', {
      portalSlug,
      articleId: props.articleId,
    });
    useAlert(t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.DISCARD_CHANGES_SUCCESS'));
  } catch (error) {
    useAlert(
      error?.message ??
        t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.DISCARD_CHANGES_ERROR')
    );
  }
};

const onPrimaryAction = () => {
  if (blockedWhileSaving()) return;
  if (hasPendingChanges.value) {
    publishDraftChanges();
  } else if (props.pendingChanges) {
    // Promote leftover draft edits on publish instead of republishing stale content.
    performStatusUpdate(ARTICLE_STATUSES.PUBLISHED, 'publishDraft');
  } else {
    updateArticleStatus({ value: ARTICLE_STATUSES.PUBLISHED });
  }
};

const onMenuAction = event => {
  showArticleActionMenu.value = false;
  // Don't resolve a draft while an autosave is still in flight — it could land
  // after and recreate the draft we just discarded/applied.
  if (blockedWhileSaving()) return;
  if (event.action === 'discard-draft') {
    discardDraftChanges();
  } else {
    updateArticleStatus(event);
  }
};

// The popover applies the draft + status itself; we just surface the outcome.
const onDraftResolved = status => {
  useAlert(getStatusMessage(status, true));
  if (status === ARTICLE_STATUS_TYPES.ARCHIVE) {
    useTrack(PORTALS_EVENTS.ARCHIVE_ARTICLE, { uiFrom: 'header' });
  } else if (status === ARTICLE_STATUS_TYPES.PUBLISH) {
    useTrack(PORTALS_EVENTS.PUBLISH_ARTICLE);
  }
};

const onDraftFailed = error => {
  useAlert(
    error?.message ??
      t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PUBLISH_CHANGES_ERROR')
  );
};
</script>

<template>
  <div class="flex items-center justify-between h-20">
    <Button
      :label="t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.BACK_TO_ARTICLES')"
      icon="i-lucide-chevron-left"
      variant="link"
      color="slate"
      size="sm"
      class="ltr:pl-3 rtl:pr-3"
      @click="onClickGoBack"
    />
    <div class="flex items-center gap-4">
      <button
        v-if="hasPendingChanges"
        type="button"
        data-diff-toggle
        :title="t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.VIEW_CHANGES')"
        class="flex items-center gap-1.5 px-2 py-1 text-xs font-medium transition-colors rounded-lg cursor-pointer text-n-amber-11 bg-n-amber-3 outline outline-1 outline-n-amber-5 hover:bg-n-amber-4"
        @click="emit('showDiff')"
      >
        <span class="rounded-full size-1.5 bg-n-amber-9 shrink-0" />
        {{ t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PENDING_CHANGES') }}
      </button>
      <span
        v-if="isUpdating || isSaved"
        class="text-xs font-medium transition-all duration-300 text-n-slate-11"
      >
        {{ statusText }}
      </span>
      <div class="relative flex items-center gap-2">
        <Button
          :label="t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PREVIEW')"
          color="slate"
          size="sm"
          :disabled="!articleId"
          @click="previewArticle"
        />
        <ButtonGroup class="flex items-center">
          <Button
            :label="
              hasPendingChanges
                ? t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PUBLISH_CHANGES')
                : t('HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PUBLISH')
            "
            size="sm"
            class="ltr:rounded-r-none rtl:rounded-l-none"
            no-animation
            :is-loading="isArticlePublishing"
            :disabled="
              !articleId ||
              isArticlePublishing ||
              (isPublished && !hasPendingChanges)
            "
            @click="onPrimaryAction"
          />
          <div class="relative">
            <OnClickOutside @trigger="showArticleActionMenu = false">
              <Button
                icon="i-lucide-chevron-down"
                size="sm"
                :disabled="!articleId"
                no-animation
                class="ltr:rounded-l-none rtl:rounded-r-none"
                @click.stop="showArticleActionMenu = !showArticleActionMenu"
              />
              <DropdownMenu
                v-if="showArticleActionMenu"
                :menu-items="articleMenuItems"
                class="mt-2 ltr:right-0 rtl:left-0 top-full"
                @action="onMenuAction($event)"
              />
            </OnClickOutside>
          </div>
        </ButtonGroup>
        <ArticlePendingChangesPopover
          ref="pendingChangesPopoverRef"
          :article-id="articleId"
          @resolved="onDraftResolved"
          @failed="onDraftFailed"
        />
      </div>
    </div>
  </div>
</template>

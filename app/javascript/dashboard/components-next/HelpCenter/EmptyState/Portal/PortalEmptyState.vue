<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ArticleCard from 'dashboard/components-next/HelpCenter/ArticleCard/ArticleCard.vue';
import articleContent from './portalEmptyStateContent';
import CreatePortalDialog from 'dashboard/components-next/HelpCenter/PortalSwitcher/CreatePortalDialog.vue';

const createPortalDialogRef = ref(null);
const openDialog = () => {
  createPortalDialogRef.value.dialogRef.open();
};

const router = useRouter();

const onPortalCreate = ({ slug: portalSlug, locale }) => {
  router.push({
    name: 'portals_articles_index',
    params: { portalSlug, locale },
  });
};
</script>

<template>
  <EmptyStateLayout
    :title="$t('HELP_CENTER.TITLE')"
    :subtitle="$t('HELP_CENTER.NEW_PAGE.DESCRIPTION')"
  >
    <template #empty-state-item>
      <div class="grid grid-cols-2 gap-4 p-px">
        <div class="space-y-4">
          <ArticleCard
            v-for="(article, index) in articleContent"
            :id="article.id"
            :key="`article-${index}`"
            :title="article.title"
            :status="article.status"
            :updated-at="article.updatedAt"
            :author="article.author"
            :category="article.category"
            :views="article.views"
          />
        </div>
        <div class="space-y-4">
          <ArticleCard
            v-for="(article, index) in articleContent.reverse()"
            :id="article.id"
            :key="`article-${index}`"
            :title="article.title"
            :status="article.status"
            :updated-at="article.updatedAt"
            :author="article.author"
            :category="article.category"
            :views="article.views"
          />
        </div>
      </div>
    </template>
    <template #actions>
      <Button
        :label="$t('HELP_CENTER.NEW_PAGE.CREATE_PORTAL_BUTTON')"
        icon="i-lucide-plus"
        @click="openDialog"
      />
      <CreatePortalDialog
        ref="createPortalDialogRef"
        @create="onPortalCreate"
      />
    </template>
  </EmptyStateLayout>
</template>

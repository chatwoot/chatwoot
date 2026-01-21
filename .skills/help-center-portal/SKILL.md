---
name: help-center-portal
description: Build and customize the Help Center (Knowledge Base) portal in Chatwoot. Use this skill when working on articles, categories, portal theming, or public documentation features.
metadata:
  author: chatwoot
  version: "1.0"
---

# Help Center Portal Development

## Overview

The Help Center (Portal) is a public-facing knowledge base that allows customers to find answers without contacting support. It's built with Vue.js and supports multiple portals per account.

## Structure

```
app/javascript/portal/
├── api/                    # Portal API client
├── components/             # Portal components
├── portalHelpers.js        # Helper functions
├── portalThemeHelper.js    # Theme utilities
└── specs/                  # Tests

app/models/
├── portal.rb              # Portal model
├── article.rb             # Article model
├── category.rb            # Category model
└── folder.rb              # Folder model
```

## Data Models

### Portal

```ruby
# app/models/portal.rb
class Portal < ApplicationRecord
  belongs_to :account
  has_many :categories, dependent: :destroy
  has_many :articles, dependent: :destroy
  has_many :folders, through: :categories

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :account_id }

  # Portal configuration
  store_accessor :config, :homepage_link, :page_title, :header_text

  def public_url
    "#{base_url}/hc/#{slug}"
  end
end
```

### Article

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  belongs_to :account
  belongs_to :portal
  belongs_to :category
  belongs_to :author, class_name: 'User'
  has_many :article_associated_articles, dependent: :destroy
  has_many :associated_articles, through: :article_associated_articles

  validates :title, presence: true
  validates :content, presence: true

  enum status: { draft: 0, published: 1, archived: 2 }

  scope :published, -> { where(status: :published) }
  scope :search, ->(query) { where('title ILIKE ? OR content ILIKE ?', "%#{query}%", "%#{query}%") }

  before_save :generate_slug

  private

  def generate_slug
    self.slug = title.parameterize if slug.blank?
  end
end
```

### Category

```ruby
# app/models/category.rb
class Category < ApplicationRecord
  belongs_to :account
  belongs_to :portal
  belongs_to :parent_category, class_name: 'Category', optional: true
  has_many :sub_categories, class_name: 'Category', foreign_key: :parent_category_id
  has_many :articles, dependent: :nullify
  has_many :folders, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :portal_id }

  acts_as_list scope: :portal
end
```

## Portal Components

### Article Display

```vue
<!-- app/javascript/portal/components/ArticleView.vue -->
<script setup>
import { ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import ArticleAPI from '../api/article';
import TableOfContents from './TableOfContents.vue';

const route = useRoute();
const article = ref(null);
const loading = ref(true);

onMounted(async () => {
  try {
    const response = await ArticleAPI.get(route.params.slug);
    article.value = response.data;
  } finally {
    loading.value = false;
  }
});
</script>

<template>
  <div v-if="loading" class="animate-pulse">
    Loading...
  </div>
  
  <article v-else class="max-w-4xl mx-auto px-4 py-8">
    <header class="mb-8">
      <nav class="text-sm text-slate-500 mb-4">
        <router-link :to="{ name: 'portal' }">Home</router-link>
        <span class="mx-2">/</span>
        <router-link :to="{ name: 'category', params: { slug: article.category.slug } }">
          {{ article.category.name }}
        </router-link>
      </nav>
      
      <h1 class="text-3xl font-bold text-slate-900 dark:text-slate-100">
        {{ article.title }}
      </h1>
      
      <div class="mt-4 flex items-center gap-4 text-sm text-slate-500">
        <span>By {{ article.author.name }}</span>
        <span>Updated {{ formatDate(article.updated_at) }}</span>
      </div>
    </header>

    <div class="flex gap-8">
      <div class="flex-1 prose dark:prose-invert max-w-none" v-html="article.content" />
      <aside class="w-64 hidden lg:block">
        <TableOfContents :content="article.content" />
      </aside>
    </div>
  </article>
</template>
```

### Search Component

```vue
<!-- app/javascript/portal/components/PublicArticleSearch.vue -->
<script setup>
import { ref, watch } from 'vue';
import { useDebounceFn } from '@vueuse/core';
import SearchAPI from '../api/search';

const query = ref('');
const results = ref([]);
const isSearching = ref(false);

const search = useDebounceFn(async () => {
  if (query.value.length < 2) {
    results.value = [];
    return;
  }

  isSearching.value = true;
  try {
    const response = await SearchAPI.articles(query.value);
    results.value = response.data;
  } finally {
    isSearching.value = false;
  }
}, 300);

watch(query, search);
</script>

<template>
  <div class="relative">
    <input
      v-model="query"
      type="search"
      placeholder="Search articles..."
      class="w-full px-4 py-3 border border-slate-200 rounded-lg focus:ring-2 focus:ring-woot-500"
    />
    
    <div
      v-if="results.length > 0"
      class="absolute top-full left-0 right-0 mt-2 bg-white border rounded-lg shadow-lg z-50"
    >
      <router-link
        v-for="article in results"
        :key="article.id"
        :to="{ name: 'article', params: { slug: article.slug } }"
        class="block px-4 py-3 hover:bg-slate-50"
      >
        <h4 class="font-medium text-slate-900">{{ article.title }}</h4>
        <p class="text-sm text-slate-500 truncate">{{ article.description }}</p>
      </router-link>
    </div>
  </div>
</template>
```

## Portal API

### Backend Controller

```ruby
# app/controllers/public/api/v1/portals/articles_controller.rb
class Public::Api::V1::Portals::ArticlesController < Public::Api::V1::Portals::BaseController
  before_action :set_article, only: [:show]

  def index
    @articles = @portal.articles
                       .published
                       .includes(:category, :author)
                       .order(updated_at: :desc)
                       .page(params[:page])
  end

  def show
    @article.increment!(:views_count)
  end

  def search
    @articles = @portal.articles
                       .published
                       .search(params[:query])
                       .limit(10)
    render :index
  end

  private

  def set_article
    @article = @portal.articles.published.find_by!(slug: params[:slug])
  end
end
```

### Frontend API Client

```javascript
// app/javascript/portal/api/article.js
import API from './index';

export default {
  getAll(portalSlug, params = {}) {
    return API.get(`/hc/${portalSlug}/articles`, { params });
  },

  get(portalSlug, articleSlug) {
    return API.get(`/hc/${portalSlug}/articles/${articleSlug}`);
  },

  search(portalSlug, query) {
    return API.get(`/hc/${portalSlug}/articles/search`, {
      params: { query },
    });
  },

  getByCategory(portalSlug, categorySlug) {
    return API.get(`/hc/${portalSlug}/categories/${categorySlug}/articles`);
  },
};
```

## Portal Theming

### Theme Configuration

```ruby
# Portal theme stored in config
portal.config = {
  primary_color: '#1f93ff',
  header_color: '#ffffff',
  homepage_link: 'https://example.com',
  custom_css: '.portal-header { background: linear-gradient(...); }'
}
```

### Theme Helper

```javascript
// app/javascript/portal/portalThemeHelper.js
export const applyTheme = (config) => {
  const root = document.documentElement;
  
  if (config.primary_color) {
    root.style.setProperty('--portal-primary-color', config.primary_color);
  }
  
  if (config.header_color) {
    root.style.setProperty('--portal-header-color', config.header_color);
  }
};

export const getContrastColor = (hexColor) => {
  const r = parseInt(hexColor.slice(1, 3), 16);
  const g = parseInt(hexColor.slice(3, 5), 16);
  const b = parseInt(hexColor.slice(5, 7), 16);
  const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  return luminance > 0.5 ? '#000000' : '#ffffff';
};
```

## Article Editor (Dashboard)

```vue
<!-- app/javascript/dashboard/components/HelpCenter/ArticleEditor.vue -->
<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Editor from '../Editor/Editor.vue';

const props = defineProps({
  article: { type: Object, default: null },
});

const emit = defineEmits(['save', 'publish']);

const { t } = useI18n();

const title = ref(props.article?.title || '');
const content = ref(props.article?.content || '');
const categoryId = ref(props.article?.category_id || null);

const isValid = computed(() => title.value && content.value && categoryId.value);

const save = () => {
  emit('save', {
    title: title.value,
    content: content.value,
    category_id: categoryId.value,
  });
};

const publish = () => {
  emit('publish', {
    title: title.value,
    content: content.value,
    category_id: categoryId.value,
    status: 'published',
  });
};
</script>

<template>
  <div class="flex flex-col h-full">
    <header class="flex items-center justify-between p-4 border-b">
      <input
        v-model="title"
        type="text"
        :placeholder="t('HELP_CENTER.ARTICLE.TITLE_PLACEHOLDER')"
        class="text-2xl font-bold w-full border-none focus:outline-none"
      />
      
      <div class="flex gap-2">
        <button
          @click="save"
          :disabled="!isValid"
          class="px-4 py-2 text-slate-700 border rounded-md hover:bg-slate-50"
        >
          {{ t('HELP_CENTER.ARTICLE.SAVE_DRAFT') }}
        </button>
        <button
          @click="publish"
          :disabled="!isValid"
          class="px-4 py-2 bg-woot-500 text-white rounded-md hover:bg-woot-600"
        >
          {{ t('HELP_CENTER.ARTICLE.PUBLISH') }}
        </button>
      </div>
    </header>

    <div class="flex-1 p-4">
      <Editor v-model="content" />
    </div>
  </div>
</template>
```

## SEO & Meta Tags

```ruby
# app/views/public/api/v1/portals/articles/show.html.erb
<% content_for :meta_tags do %>
  <title><%= @article.title %> | <%= @portal.name %></title>
  <meta name="description" content="<%= @article.description %>">
  
  <!-- Open Graph -->
  <meta property="og:title" content="<%= @article.title %>">
  <meta property="og:description" content="<%= @article.description %>">
  <meta property="og:type" content="article">
  <meta property="og:url" content="<%= article_url(@article) %>">
  
  <!-- Structured Data -->
  <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "Article",
      "headline": "<%= @article.title %>",
      "author": {
        "@type": "Person",
        "name": "<%= @article.author.name %>"
      },
      "datePublished": "<%= @article.created_at.iso8601 %>",
      "dateModified": "<%= @article.updated_at.iso8601 %>"
    }
  </script>
<% end %>
```

## Testing Portal

```ruby
# spec/requests/public/api/v1/portals/articles_spec.rb
require 'rails_helper'

RSpec.describe 'Public Portal Articles API', type: :request do
  let(:portal) { create(:portal) }
  let(:category) { create(:category, portal: portal) }
  let!(:articles) { create_list(:article, 3, portal: portal, category: category, status: :published) }

  describe 'GET /hc/:portal_slug/articles' do
    it 'returns published articles' do
      get "/hc/#{portal.slug}/articles"

      expect(response).to have_http_status(:ok)
      expect(json_response[:data].length).to eq(3)
    end
  end

  describe 'GET /hc/:portal_slug/articles/:slug' do
    let(:article) { articles.first }

    it 'returns article details' do
      get "/hc/#{portal.slug}/articles/#{article.slug}"

      expect(response).to have_http_status(:ok)
      expect(json_response[:title]).to eq(article.title)
    end

    it 'increments view count' do
      expect {
        get "/hc/#{portal.slug}/articles/#{article.slug}"
      }.to change { article.reload.views_count }.by(1)
    end
  end
end
```

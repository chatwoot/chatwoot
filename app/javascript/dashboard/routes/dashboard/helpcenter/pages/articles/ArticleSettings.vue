<template>
  <transition name="popover-animation">
    <div class="article-settings--container">
      <h3 class="block-title">
        {{ $t('HELP_CENTER.ARTICLE_SETTINGS.TITLE') }}
      </h3>
      <div class="form-wrap">
        <label>
          {{ $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.CATEGORY.LABEL') }}
          <multiselect-dropdown
            :options="categoryList"
            :selected-item="selectedCategory"
            :has-thumbnail="false"
            :multiselector-title="
              $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.CATEGORY.TITLE')
            "
            :multiselector-placeholder="
              $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.CATEGORY.PLACEHOLDER')
            "
            :no-search-result="
              $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.CATEGORY.NO_RESULT')
            "
            :input-placeholder="
              $t(
                'HELP_CENTER.ARTICLE_SETTINGS.FORM.CATEGORY.SEARCH_PLACEHOLDER'
              )
            "
            @click="onClickSelectCategory"
          />
        </label>
        <label>
          {{ $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.AUTHOR.LABEL') }}
          <multiselect-dropdown
            :options="authorList"
            :selected-item="assignedAuthor"
            :multiselector-title="
              $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.AUTHOR.TITLE')
            "
            :multiselector-placeholder="
              $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.AUTHOR.PLACEHOLDER')
            "
            :no-search-result="
              $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.AUTHOR.NO_RESULT')
            "
            :input-placeholder="
              $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.AUTHOR.SEARCH_PLACEHOLDER')
            "
            @click="onClickAssignAuthor"
          />
        </label>
        <label>
          {{ $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.META_TITLE.LABEL') }}
          <textarea
            v-model="title"
            rows="3"
            type="text"
            :placeholder="
              $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.META_TITLE.PLACEHOLDER')
            "
          />
        </label>
        <label>
          {{ $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.META_DESCRIPTION.LABEL') }}
          <textarea
            v-model="description"
            rows="3"
            type="text"
            :placeholder="
              $t(
                'HELP_CENTER.ARTICLE_SETTINGS.FORM.META_DESCRIPTION.PLACEHOLDER'
              )
            "
          />
        </label>
        <label>
          {{ $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.META_TAGS.LABEL') }}
          <multiselect
            ref="tagInput"
            v-model="values"
            :placeholder="
              $t('HELP_CENTER.ARTICLE_SETTINGS.FORM.META_TAGS.PLACEHOLDER')
            "
            label="name"
            track-by="name"
            :options="options"
            :multiple="true"
            :taggable="true"
            @tag="addTagValue"
          />
        </label>
      </div>
      <div class="action-buttons">
        <woot-button
          icon="archive"
          size="small"
          variant="clear"
          color-scheme="secondary"
          @click="onClickArchiveArticle"
        >
          {{ $t('HELP_CENTER.ARTICLE_SETTINGS.BUTTONS.ARCHIVE') }}
        </woot-button>
        <woot-button
          icon="delete"
          size="small"
          variant="clear"
          color-scheme="alert"
          @click="onClickDeleteArticle"
        >
          {{ $t('HELP_CENTER.ARTICLE_SETTINGS.BUTTONS.DELETE') }}
        </woot-button>
      </div>
    </div>
  </transition>
</template>

<script>
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown';
export default {
  components: {
    MultiselectDropdown,
  },
  data() {
    return {
      // Dummy value
      categoryList: [
        {
          id: 1,
          name: 'Getting started',
        },
        {
          id: 2,
          name: 'Features',
        },
      ],
      selectedCategory: {
        id: 1,
        name: 'Features',
      },
      authorList: [
        {
          id: 1,
          name: 'John Doe',
        },
        {
          id: 2,
          name: 'Jane Doe',
        },
      ],
      assignedAuthor: {
        id: 1,
        name: 'John Doe',
      },
      title: '',
      description: '',
      values: [],
      options: [],
    };
  },
  methods: {
    addTagValue(tagValue) {
      const tag = {
        name: tagValue,
      };
      this.values.push(tag);
      this.$refs.tagInput.$el.focus();
    },
    onClickSelectCategory() {
      this.$emit('select-category');
    },
    onClickAssignAuthor() {
      this.$emit('assign-author');
    },
    onClickArchiveArticle() {
      this.$emit('archive-article');
    },
    onClickDeleteArticle() {
      this.$emit('delete-article');
    },
  },
};
</script>

<style lang="scss" scoped>
.article-settings--container {
  flex: 0.3;
  min-width: var(--space-giga);
  overflow: scroll;
  border-left: 1px solid var(--color-border-light);
  margin-left: var(--space-normal);
  padding-left: var(--space-normal);
  padding-top: var(--space-small);
  padding-bottom: var(--space-small);

  .form-wrap {
    margin-top: var(--space-normal);
    margin-bottom: var(--space-medium);

    textarea {
      font-size: var(--font-size-small);
    }
  }

  .action-buttons {
    display: flex;
    flex-direction: column;

    ::v-deep .button {
      padding-left: 0;
    }
  }
}
::v-deep {
  .multiselect {
    margin-bottom: 0;
  }
  .multiselect__content-wrapper {
    display: none;
  }
  .multiselect--active .multiselect__tags {
    border-radius: var(--border-radius-normal);
    padding-right: var(--space-small) !important;
  }
  .multiselect__placeholder {
    color: var(--s-300);
    padding-top: var(--space-small);
    margin-bottom: 0;
  }
  .multiselect__select {
    display: none;
  }
}
</style>

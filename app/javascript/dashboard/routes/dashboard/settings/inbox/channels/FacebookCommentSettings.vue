<template>
  <div class="column content-box">
    <woot-box-header
      :header-title="$t('FACEBOOK_COMMENT.TITLE')"
      :header-content="$t('FACEBOOK_COMMENT.DESCRIPTION')"
    />
    <div class="small-12 medium-9 columns">
      <form class="row" @submit.prevent="updateConfig">
        <div class="medium-12 columns">
          <woot-input
            v-model="webhookUrl"
            :label="$t('FACEBOOK_COMMENT.WEBHOOK_URL.LABEL')"
            :help-text="$t('FACEBOOK_COMMENT.WEBHOOK_URL.HELP_TEXT')"
            :placeholder="$t('FACEBOOK_COMMENT.WEBHOOK_URL.PLACEHOLDER')"
            :error="$v.webhookUrl.$error"
            :error-text="$t('FACEBOOK_COMMENT.WEBHOOK_URL.ERROR')"
            @blur="$v.webhookUrl.$touch"
          />
        </div>
        <div class="medium-12 columns">
          <woot-input
            v-model="webhookSecret"
            :label="$t('FACEBOOK_COMMENT.WEBHOOK_SECRET.LABEL')"
            :help-text="$t('FACEBOOK_COMMENT.WEBHOOK_SECRET.HELP_TEXT')"
            :placeholder="$t('FACEBOOK_COMMENT.WEBHOOK_SECRET.PLACEHOLDER')"
            :disabled="true"
          />
          <button
            class="button clear secondary regenerate-button"
            @click.prevent="regenerateSecret"
          >
            {{ $t('FACEBOOK_COMMENT.WEBHOOK_SECRET.REGENERATE') }}
          </button>
        </div>
        <div class="medium-12 columns">
          <woot-input
            v-model="verifyToken"
            :label="$t('FACEBOOK_COMMENT.VERIFY_TOKEN.LABEL')"
            :help-text="$t('FACEBOOK_COMMENT.VERIFY_TOKEN.HELP_TEXT')"
            :placeholder="$t('FACEBOOK_COMMENT.VERIFY_TOKEN.PLACEHOLDER')"
            :disabled="true"
          />
        </div>
        <div class="medium-12 columns">
          <label>{{ $t('FACEBOOK_COMMENT.STATUS.LABEL') }}</label>
          <div class="row">
            <div class="small-12 medium-6 columns">
              <woot-toggle-button
                :value="isActive"
                :options="[
                  {
                    text: $t('FACEBOOK_COMMENT.STATUS.ACTIVE'),
                    value: true,
                  },
                  {
                    text: $t('FACEBOOK_COMMENT.STATUS.INACTIVE'),
                    value: false,
                  },
                ]"
                @toggle="toggleStatus"
              />
            </div>
          </div>
        </div>
        <div class="medium-12 columns">
          <woot-submit-button
            :loading="uiFlags.isUpdating"
            :button-text="$t('FACEBOOK_COMMENT.SUBMIT')"
          />
        </div>
      </form>
      <div class="webhook-docs">
        <h3>{{ $t('FACEBOOK_COMMENT.API_DOCS.TITLE') }}</h3>
        <p>{{ $t('FACEBOOK_COMMENT.API_DOCS.DESCRIPTION') }}</p>
        <div class="code-block">
          <h4>{{ $t('FACEBOOK_COMMENT.API_DOCS.WEBHOOK_PAYLOAD') }}</h4>
          <pre>{{ webhookPayloadExample }}</pre>
        </div>
        <div class="code-block">
          <h4>{{ $t('FACEBOOK_COMMENT.API_DOCS.REPLY_API') }}</h4>
          <pre>{{ replyApiExample }}</pre>
        </div>
        <div class="code-block">
          <h4>{{ $t('FACEBOOK_COMMENT.API_DOCS.MESSAGE_API') }}</h4>
          <pre>{{ messageApiExample }}</pre>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { required, url } from 'vuelidate/lib/validators';
import alertMixin from 'shared/mixins/alertMixin';
import configMixin from 'shared/mixins/configMixin';
import { mapGetters } from 'vuex';

export default {
  mixins: [alertMixin, configMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      webhookUrl: '',
      webhookSecret: '',
      verifyToken: '',
      isActive: true,
      uiFlags: {
        isUpdating: false,
      },
      webhookPayloadExample: JSON.stringify(
        {
          comment_id: '123456789_123456789',
          post_id: '123456789_123456789',
          user_id: '987654321',
          content: 'Tôi muốn biết thêm về sản phẩm này',
          page_id: '123456789',
          created_time: '2023-06-01T12:34:56+0000',
          account_id: 1,
          inbox_id: 2,
        },
        null,
        2
      ),
      replyApiExample: JSON.stringify(
        {
          comment_id: '123456789_123456789',
          page_id: '123456789',
          content: 'Cảm ơn bạn đã quan tâm. Vui lòng nhắn tin trực tiếp để chúng tôi hỗ trợ bạn tốt hơn.',
        },
        null,
        2
      ),
      messageApiExample: JSON.stringify(
        {
          user_id: '987654321',
          page_id: '123456789',
          content: 'Xin chào! Chúng tôi đã nhận được bình luận của bạn. Bạn có thể tiếp tục cuộc trò chuyện ở đây để chúng tôi hỗ trợ bạn tốt hơn.',
        },
        null,
        2
      ),
    };
  },
  validations: {
    webhookUrl: {
      required,
      url,
    },
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
  },
  mounted() {
    this.fetchConfig();
  },
  methods: {
    async fetchConfig() {
      try {
        this.uiFlags.isUpdating = true;
        const response = await this.$axios.get(
          `/api/v1/accounts/${this.accountId}/facebook_comments/show?inbox_id=${this.inbox.id}`
        );
        const { webhook_url, status, webhook_secret } = response.data;
        this.webhookUrl = webhook_url || '';
        this.webhookSecret = webhook_secret || '';
        this.isActive = status === 'active';
        this.verifyToken = this.globalConfig.fbCommentVerifyToken || '';
      } catch (error) {
        if (error.response && error.response.status !== 404) {
          this.showAlert(this.$t('FACEBOOK_COMMENT.API.ERROR_FETCH'));
        }
      } finally {
        this.uiFlags.isUpdating = false;
      }
    },
    toggleStatus(value) {
      this.isActive = value;
    },
    regenerateSecret() {
      this.webhookSecret = '';
    },
    async updateConfig() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }

      try {
        this.uiFlags.isUpdating = true;
        await this.$axios.post(
          `/api/v1/accounts/${this.accountId}/facebook_comments/configure`,
          {
            inbox_id: this.inbox.id,
            webhook_url: this.webhookUrl,
            status: this.isActive ? 'active' : 'inactive',
            regenerate_secret: !this.webhookSecret,
          }
        );
        this.showAlert(this.$t('FACEBOOK_COMMENT.API.SUCCESS_UPDATE'));
        this.fetchConfig();
      } catch (error) {
        this.showAlert(this.$t('FACEBOOK_COMMENT.API.ERROR_UPDATE'));
      } finally {
        this.uiFlags.isUpdating = false;
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.regenerate-button {
  margin-top: -1rem;
  margin-bottom: 1rem;
}

.webhook-docs {
  margin-top: 2rem;
  padding-top: 1rem;
  border-top: 1px solid var(--s-50);

  .code-block {
    margin-bottom: 1.5rem;

    h4 {
      margin-bottom: 0.5rem;
    }

    pre {
      background-color: var(--s-50);
      padding: 1rem;
      border-radius: 4px;
      overflow-x: auto;
    }
  }
}
</style>

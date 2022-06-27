<template>
  <div class="column content-box no-padding">
    <div class="row">
      <div class="small-8 columns">
        <div class="full-height editor-wrapper">
          <csml-monaco-editor v-model="bot.csmlContent" class="bot-editor" />
          <div v-if="$v.bot.csmlContent.$error" class="editor-error-message">
            <span>{{ $t('AGENT_BOTS.CSML_BOT_EDITOR.BOT_CONFIG.ERROR') }}</span>
          </div>
        </div>
      </div>
      <div class="small-4 columns content-box full-height">
        <form class="details-editor" @submit.prevent="">
          <div>
            <label :class="{ error: $v.bot.name.$error }">
              {{ $t('AGENT_BOTS.CSML_BOT_EDITOR.NAME.LABEL') }}
              <input
                v-model="bot.name"
                type="text"
                :placeholder="$t('AGENT_BOTS.CSML_BOT_EDITOR.NAME.PLACEHOLDER')"
              />
              <span v-if="$v.bot.name.$error" class="message">
                {{ $t('AGENT_BOTS.CSML_BOT_EDITOR.NAME.ERROR') }}
              </span>
            </label>
            <label>
              {{ $t('AGENT_BOTS.CSML_BOT_EDITOR.DESCRIPTION.LABEL') }}
              <textarea
                v-model="bot.description"
                rows="4"
                :placeholder="
                  $t('AGENT_BOTS.CSML_BOT_EDITOR.DESCRIPTION.PLACEHOLDER')
                "
              />
            </label>
            <woot-button>
              {{ $t('AGENT_BOTS.CSML_BOT_EDITOR.SUBMIT') }}
            </woot-button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import { required } from 'vuelidate/lib/validators';
import { CsmlMonacoEditor } from '@clevy/vue-csml-monaco';

export default {
  components: { CsmlMonacoEditor },
  validations: {
    bot: {
      name: { required },
      csmlContent: { required },
    },
  },
  data() {
    return {
      bot: {
        name: '',
        description: '',
        csmlContent: '',
      },
    };
  },
  methods: {
    onSubmit() {
      this.$v.$touch();
      if (this.$v.$invalid) {
        return;
      }
      this.$emit('submit', this.bot);
    },
  },
};
</script>

<style scoped>
.no-padding {
  padding: 0 !important;
}
.full-height {
  height: calc(100vh - 56px);
}

.bot-editor {
  width: 100%;
  height: 100%;
}
.details-editor {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  height: 100%;
}
.editor-wrapper {
  position: relative;
}
.editor-error-message {
  position: absolute;
  bottom: 0;
  width: 100%;
  padding: 1rem;
  background-color: #e0bbbb;
  display: flex;
  align-items: center;
  font-size: 1.2rem;
  justify-content: center;
  flex-shrink: 0;
}
</style>

<template>
  <div class="row">
    <div class="column">
      <div>
        <h5>{{ $t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.TITLE') }}</h5>
        <p>
          <span
            v-dompurify-html="$t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.BODY')"
          />
        </p>
      </div>
    </div>
  </div>
</template>

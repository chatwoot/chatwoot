<template>
  <div class="row">
    <div class="column">
      <div class="integration--description">
        <h5>{{ $t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.TITLE') }}</h5>
        <p>
          <span v-html="$t('INTEGRATION_SETTINGS.SLACK.HELP_TEXT.BODY')"></span>
        </p>
      </div>
    </div>
  </div>
</template>

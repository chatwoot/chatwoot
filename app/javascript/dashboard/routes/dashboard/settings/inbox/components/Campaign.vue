<template>
  <div class="column content-box">
    <div class="row">
      <a class="button icon success nice button--fixed-right-top">
        <i class="icon ion-android-add-circle"></i>
        {{ $t('CAMPAIGN.HEADER_BTN_TXT') }}
      </a>
    </div>

    <div class="row">
      <div class="small-8 columns">
        <p class="no-items-error-message">
          {{ $t('CAMPAIGN.LIST.404') }}
          <a>
            {{ $t('CAMPAIGN.HEADER_BTN_TXT') }}
          </a>
        </p>
      </div>

      <div class="small-4 columns">
        <span>
          <p>
            <b> {{ $t('CAMPAIGN.HEADER') }}</b>
          </p>
          <p>
            Proactive messages allows customer send outbound messages to their
            contacts which would trigger more conversations. Campaigns are tied
            to inbox. Click on
            <b>Add Campaign</b>
            to create a new campaign. You can also edit or delete an existing
            campaigns Response by clicking on the Edit or Delete button.
          </p>
        </span>
      </div>
    </div>
  </div>
</template>

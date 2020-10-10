<template>
  <header class="header">
    <h1 class="page-title">
      Contacts
    </h1>
    <div class="table-actions-wrap">
      <div class="table-search-wrap">
        <input
          type="text"
          placeholder="Search for contacts by name or email"
          class="contact-search"
        />
        <woot-submit-button
          :button-text="$t('CREATE_ACCOUNT.FORM.SUBMIT')"
          :loading="uiFlags.isCreating"
          button-class="large expanded"
        />
      </div>
    </div>
  </header>
</template>

<style lang="scss" scoped>
.header {
  margin-left: var(--space-normal);
}
.table-actions-wrap {
  display: flex;
  width: 100%;
}
.table-search-wrap {
  width: 500px;
  /* background: var(--color-background-light);
  border-top: 1px solid var(--color-border-light);
  border-bottom: 1px solid var(--color-border-light); */

  .contact-search {
    /* border-color: transparent; */
    background: var(--color-background-light);
    margin: 0;
  }
}
</style>

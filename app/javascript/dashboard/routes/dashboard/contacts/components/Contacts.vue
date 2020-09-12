<template>
  <table class="woot-table">
    <thead>
      <!-- Header -->
      <th
        v-for="thHeader in $t('CONTACTS_PAGE.LIST.TABLE_HEADER')"
        :key="thHeader"
      >
        {{ thHeader }}
      </th>
      <th><i class="ion-chevron-down" /></th>
    </thead>
    <tbody>
      <tr v-for="(cannedItem, index) in []" :key="cannedItem.short_code">
        <!-- Short Code  -->
        <td>{{ cannedItem.short_code }}</td>
        <!-- Content -->
        <td>{{ cannedItem.content }}</td>
        <!-- Action Buttons -->
        <td class="button-wrapper">
          <div @click="openEditPopup(cannedItem)">
            <woot-submit-button
              :button-text="$t('CANNED_MGMT.EDIT.BUTTON_TEXT')"
              icon-class="ion-edit"
              button-class="link hollow grey-btn"
            />
          </div>
          <div @click="openDeletePopup(cannedItem, index)">
            <woot-submit-button
              :button-text="$t('CANNED_MGMT.DELETE.BUTTON_TEXT')"
              :loading="loading[cannedItem.id]"
              icon-class="ion-close-circled"
              button-class="link hollow grey-btn"
            />
          </div>
        </td>
      </tr>
    </tbody>
  </table>
</template>

<style lang="scss" scoped>
.header {
  margin-left: var(--space-normal);
}
</style>

<template>
  <tbody>
    <tr>
      <td>
        <div class="row--user-block">
          <div class="user-block">
            <h6 class="sub-block-title text-truncate">
              <router-link
                class="user-name"
                :to="{
                  name: 'settings_inbox_show',
                  params: { inboxId: this.$route.params.inbox_id },
                }"
              >
                Setup your account
              </router-link>
            </h6>
            <div class="author">
              <span class="by">by</span> <span class="name">Eden Hazard</span>
            </div>
          </div>
        </div>
      </td>
      <td>Getting Started</td>
      <td>1.5K</td>
      <td>
        <Label title="Published" color-scheme="success" />
      </td>
      <td>30 minutes ago</td>
    </tr>
  </tbody>
</template>
<script>
import Label from 'dashboard/components/ui/Label';

export default {
  components: {
    Label,
  },
};
</script>

<style lang="scss" scoped>
.row--user-block {
  align-items: center;
  display: flex;
  text-align: left;

  .user-block {
    min-width: 0;
  }

  .sub-block-title {
    margin-bottom: 0;
  }

  .user-thumbnail-box {
    margin-right: var(--space-small);
  }

  .user-name {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-default);
    margin: 0;
    text-transform: capitalize;
    color: var(--s-900);
  }

  .view-details--button {
    color: var(--color-body);
  }

  .user-email {
    margin: 0;
  }
}
.author {
  .by {
    font-weight: var(--font-weight-normal);
    color: var(--s-500);
    font-size: var(--font-size-small);
  }
  .name {
    font-weight: var(--font-weight-medium);
    color: var(--s-600);
    font-size: var(--font-size-small);
  }
}
</style>

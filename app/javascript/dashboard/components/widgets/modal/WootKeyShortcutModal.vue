<template>
  <transition name="modal-fade">
    <div class="modal-mask">
      <div class="page-top-bar modal-container">
        <div class="title-wrap">
          <div class="title">
            <h2 class="page-title">
              Keyboard Shortcuts
            </h2>
            <div class="shortcut-key__wrap">
              <span class="shortcut-key">
                ⌘
              </span>
              <span class="shortcut-key key">
                /
              </span>
            </div>
          </div>
          <i class="ion-android-close modal--close" @click="$emit('close')"></i>
        </div>

        <div class="shortcut__wrap">
          <div class="left">
            <div class="text-key">
              <h6 class="sub-block-title">
                Open conversation
              </h6>

              <div class="shortcut-key__wrap">
                <div class="open-conversation__key">
                  <span class="shortcut-key">
                    Shift
                  </span>
                  <span class="shortcut-key key">
                    J
                  </span>
                </div>
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  K
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Resolve and move to next
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  ⌘
                </span>
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  E
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Resolve Conversation
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  E
                </span>
              </div>
            </div>

            <div class="text-key">
              <h6 class="sub-block-title">
                Switch to Private Note
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  P
                </span>
              </div>
            </div>

            <div class="text-key">
              <h6 class="sub-block-title">
                Switch to Reply
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  L
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Add Attachment
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  A
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Toggle Sidebar
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  O
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Keyboard shortcuts for dropdown
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Up
                </span>
                <span class="shortcut-key down-arrow__key">
                  Down
                </span>
              </div>
            </div>
          </div>
          <div class="right">
            <div class="text-key">
              <h6 class="sub-block-title">
                Toggle Rich Content editor
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  W
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Move to next tab in conversation list
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  N
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Switch Conversation status
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  B
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Go to Conversation Dashboard
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  C
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Go to Contacts Dashboard
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  V
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Go to Reports sidebar
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  R
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Go to Settings
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  S
                </span>
              </div>
            </div>
            <div class="text-key">
              <h6 class="sub-block-title">
                Open snooze conversations dropdown
              </h6>
              <div class="shortcut-key__wrap">
                <span class="shortcut-key">
                  Shift
                </span>
                <span class="shortcut-key key">
                  M
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<script>
export default {};
</script>

<style lang="scss" scoped>
.modal-container {
  width: fit-content;
}

.page-top-bar {
  padding: var(--space-medium) var(--space-large) var(--space-large)
    var(--space-large);
}

.title-wrap {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.title {
  display: flex;
}

.page-title {
  display: flex;
  font-size: var(--font-size-big);
}

.shortcut-key__wrap {
  display: flex;
  align-items: center;
  margin-bottom: var(--space-small);
  margin-left: var(--space-small);
}

.shortcut__wrap {
  align-content: flex-start;
  display: flex;
  justify-content: space-between;
  width: 100%;
  margin-top: var(--space-two);
}

.left {
  margin-right: var(--space-large);
}

.text-key {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.shortcut-key {
  color: var(--color-heading);
  background: var(--color-background);
  padding: var(--space-small) var(--space-one);
  font-weight: var(--font-weight-medium);
  font-size: var(--font-size-mini);
  align-items: center;
  width: fit-content;
  border-radius: var(--border-radius-normal);
  margin-right: var(--space-small);
  height: fit-content;
}

.down-arrow__key {
  margin-right: 0;
}

.key {
  display: flex;
  justify-content: center;
  width: var(--space-large);
  margin-right: 0;
}

.open-conversation__key {
  display: flex;
  margin-right: var(--space-small);
}
</style>

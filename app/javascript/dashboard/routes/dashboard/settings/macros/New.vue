<template>
  <div class="column content-box">
    <div class="row">
      <div class="small-8 columns with-right-space macros-canvas">
        <ul class="macros-feed-container">
          <!-- start flow pill -->
          <li class="macros-feed-item">
            <div class="macros-item macros-pill">
              <span>Start Flow</span>
            </div>
          </li>
          <!-- start flow pill -->
          <!-- macros actions list -->
          <draggable
            :list="macro.actions"
            animation="200"
            ghost-class="ghost"
            tag="div"
            class="macros-feed-draggable"
            handle=".drag-handle"
            @start="dragging = true"
            @end="onDragEnd"
          >
            <li
              v-for="(action, i) in macro.actions"
              :key="i"
              class="macros-feed-item"
            >
              <div class="macros-action-item-container">
                <div v-if="macro.actions.length > 1" class="drag-handle">
                  <fluent-icon size="20" icon="navigation" />
                </div>
                <div
                  class="macros-action-item"
                  :class="{
                    'has-error': hasError($v.macro.actions.$each[i]),
                  }"
                >
                  <action-input
                    v-model="macro.actions[i]"
                    :action-types="macroActionTypes"
                    :dropdown-values="
                      getActionDropdownValues(macro.actions[i].action_name)
                    "
                    :v="$v.macro.actions.$each[i]"
                    :show-action-input="
                      showActionInput(macro.actions[i].action_name)
                    "
                    :show-remove-button="false"
                    :is-macro="true"
                    @resetAction="resetAction(i)"
                  />
                  <button
                    v-if="macro.actions.length > 1"
                    v-tooltip="'Delete Action'"
                    class="macros-action-item_button delete"
                    @click="deleteActionItem(i)"
                  >
                    <fluent-icon icon="dismiss-circle" aria-hidden="true" />
                  </button>
                </div>
              </div>
            </li>
          </draggable>
          <!-- macros actions list -->
          <!-- append action button -->
          <li class="macros-feed-item">
            <button
              v-tooltip="'Add new action'"
              class="macros-item macros-action-item_button add"
              @click="appendNewAction()"
            >
              <fluent-icon icon="add-circle" aria-hidden="true" />
            </button>
          </li>
          <!-- append action button -->
          <!-- end flow pill -->
          <li class="macros-feed-item">
            <div class="macros-item macros-pill">
              <span>End Flow</span>
            </div>
          </li>
          <!-- end flow pill -->
        </ul>
      </div>
      <div class="small-4 columns">
        <div class="macros-properties-panel">
          <div>
            <woot-input
              v-model.trim="macro.name"
              label="Macro name"
              placeholder="Enter a name for your macro"
              error="Please enter a name"
              :class="{ error: $v.macro.name.$error }"
            />
          </div>
          <div>
            <p class="title">Macro Visibility</p>
            <div class="macros-form-radio-group">
              <button
                class="card"
                :class="{ active: macro.visibility === 'global' }"
                @click="macro.visibility = 'global'"
              >
                <fluent-icon
                  v-if="macro.visibility === 'global'"
                  icon="checkmark-circle"
                  type="solid"
                  class="visibility-check"
                />
                <p class="title">Global</p>
                <p class="subtitle">
                  This macro is available globally for all agents in this
                  account.
                </p>
              </button>
              <button
                class="card"
                :class="{ active: macro.visibility === 'private' }"
                @click="macro.visibility = 'private'"
              >
                <fluent-icon
                  v-if="macro.visibility === 'private'"
                  icon="checkmark-circle"
                  type="solid"
                  class="visibility-check"
                />
                <p class="title">Private</p>
                <p class="subtitle">
                  This macro will be private to you and not be available to
                  others.
                </p>
              </button>
            </div>
            <div class="macros-information-panel">
              <fluent-icon icon="info" size="20" />
              <p>
                Macros will run in the order you add yout actions. You can
                rearrange them by dragging them by the handle beside each
                action.
              </p>
            </div>
          </div>
          <div class="macros-submit-btn">
            <woot-button
              size="expanded"
              color-scheme="success"
              @click="saveMacro"
            >
              {{ $t('MACROS.HEADER_BTN_TXT_SAVE') }}
            </woot-button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import ActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import { AUTOMATION_ACTION_TYPES } from 'dashboard/routes/dashboard/settings/automation/constants.js';
import { required, requiredIf } from 'vuelidate/lib/validators';
import draggable from 'vuedraggable';
import actionQueryGenerator from 'dashboard/helper/actionQueryGenerator.js';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {
    ActionInput,
    draggable,
  },
  mixins: [alertMixin],
  validations: {
    macro: {
      name: {
        required,
      },
      visibility: {
        required,
      },
      actions: {
        required,
        $each: {
          action_params: {
            required: requiredIf(prop => {
              if (prop.action_name === 'send_email_to_team') return true;
              return !(
                prop.action_name === 'mute_conversation' ||
                prop.action_name === 'snooze_conversation' ||
                prop.action_name === 'resolve_conversation'
              );
            }),
          },
        },
      },
    },
  },
  data() {
    return {
      dragEnabled: true,
      dragging: false,
      macroActionTypes: AUTOMATION_ACTION_TYPES,
      macroVisibilityOptions: [
        {
          id: 'global',
          title: 'Global',
          checked: true,
        },
        {
          id: 'private',
          title: 'Private',
          checked: false,
        },
      ],
      macro: {
        name: '',
        actions: [
          {
            action_name: 'assign_team',
            action_params: [],
          },
        ],
        visibility: 'global',
      },
    };
  },
  methods: {
    appendNewAction() {
      this.macro.actions.push({
        action_name: 'assign_team',
        action_params: [],
      });
    },
    deleteActionItem(index) {
      this.macro.actions.splice(index, 1);
    },
    getActionDropdownValues(type) {
      switch (type) {
        case 'assign_team':
        case 'send_email_to_team':
          return this.$store.getters['teams/getTeams'];
        case 'add_label':
          return this.$store.getters['labels/getLabels'].map(i => {
            return {
              id: i.title,
              name: i.title,
            };
          });
        default:
          return undefined;
      }
    },
    showActionInput(actionName) {
      if (actionName === 'send_email_to_team' || actionName === 'send_message')
        return false;
      const type = AUTOMATION_ACTION_TYPES.find(
        action => action.key === actionName
      ).inputType;
      if (type === null) return false;
      return true;
    },
    resetAction(index) {
      this.macro.actions[index].action_params = [];
    },
    onDragEnd() {
      this.dragging = false;
    },
    hasError(v) {
      return !!(v.action_params.$dirty && v.action_params.$error);
    },
    async saveMacro() {
      this.$v.$touch();
      if (this.$v.$invalid) return;
      try {
        const macro = JSON.parse(JSON.stringify(this.macro));
        macro.actions = actionQueryGenerator(macro.actions);
        await this.$store.dispatch('macros/create', macro);
        this.showAlert('Macro created Succesfully');
        this.$router.push({ name: 'macros_wrapper' });
      } catch (error) {
        this.showAlert('Something went wrong, please try again');
      }
    },
  },
};
</script>

<style scoped lang="scss">
.row {
  height: 100%;
}
.macros-canvas {
  background-image: radial-gradient(#e0e0e0bd 1.2px, transparent 0);
  background-size: 16px 16px;
  height: 100%;
  max-height: 100%;
  padding: var(--space-normal) var(--space-three);
  max-height: 100vh;
  overflow-y: auto;
}
.macros-properties-panel {
  padding: var(--space-slab);
  background-color: var(--white);
  height: calc(100vh - 5.6rem);
  display: flex;
  flex-direction: column;
  border-left: 1px solid var(--s-50);
}

.macros-feed-container {
  list-style-type: none;
  max-width: 800px;

  .macros-feed-item:not(:last-child) {
    position: relative;
    padding-bottom: var(--space-three);
  }

  .macros-feed-item:not(:last-child):not(.sortable-chosen):after,
  .macros-feed-draggable:after {
    content: '';
    position: absolute;
    height: 30px;
    width: 3px;
    margin-left: 24px;
    background-image: url("data:image/svg+xml,%3Csvg width='3' height='31' viewBox='0 0 3 31' fill='none' xmlns='http://www.w3.org/2000/svg'%3E%3Cline x1='1.50098' y1='0.579529' x2='1.50098' y2='30.5795' stroke='%2393afc8' stroke-width='2' stroke-dasharray='5 5'/%3E%3C/svg%3E%0A");
  }
  .macros-feed-draggable {
    position: relative;
    padding-bottom: var(--space-three);
  }
  .macros-pill {
    padding: var(--space-slab);
    background-color: var(--w-500);
    max-width: max-content;
    color: var(--white);
    font-size: var(--font-size-small);
    border-radius: var(--border-radius-full);
    position: relative;
  }

  .macros-action-item_add {
    height: var(--space-three);
    width: var(--space-three);
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: var(--g-100);
    color: var(--g-600);
    font-size: var(--font-size-default);
    border-radius: var(--border-radius-rounded);
    position: relative;
    margin-left: 10px;
  }
  .macros-action-item_button {
    height: var(--space-three);
    width: var(--space-three);
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    font-size: var(--font-size-default);
    border-radius: var(--border-radius-rounded);
    position: relative;
    margin-left: 10px;

    &.add {
      background-color: var(--g-100);
      color: var(--g-600);
    }
    &.delete {
      position: absolute;
      top: calc(var(--space-three) / -2);
      right: calc(var(--space-three) / -2);
      background-color: var(--r-100);
      color: var(--r-600);
      display: none;
    }
  }
  .macros-action-item-container {
    position: relative;
    .drag-handle {
      position: absolute;
      left: var(--space-minus-medium);
      top: var(--space-smaller);
      cursor: move;
      color: var(--s-400);
    }
    .macros-action-item {
      background-color: var(--white);
      padding: var(--space-slab);
      border-radius: var(--border-radius-medium);
      box-shadow: rgb(0 0 0 / 3%) 0px 6px 24px 0px,
        rgb(0 0 0 / 6%) 0px 0px 0px 1px;
      &:hover {
        .macros-action-item_button {
          &.delete {
            display: flex;
          }
        }
      }

      &.has-error {
        animation: shake 0.3s ease-in-out 0s 2;
        background-color: var(--r-50);
      }
    }
  }
}
.macros-submit-btn {
  margin-top: auto;
}
.macros-form-radio-group {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 1rem;

  .card {
    padding: var(--space-small);
    border-radius: var(--border-radius-normal);
    border: 1px solid var(--s-200);
    text-align: left;
    cursor: pointer;
    position: relative;

    &.active {
      background-color: var(--w-25);
      border: 1px solid var(--w-300);
    }

    .subtitle {
      font-size: var(--font-size-mini);
      color: var(--s-500);
    }

    .visibility-check {
      position: absolute;
      color: var(--w-300);
      top: var(--space-small);
      right: var(--space-small);
    }
  }
}

.title {
  display: block;
  margin: 0;
  font-size: 1.4rem;
  font-weight: 500;
  line-height: 1.8;
  color: #3c4858;
}
.content-box {
  padding: 0;
  height: 100vh;
}
.macros-information-panel {
  margin-top: var(--space-small);
  display: flex;
  background-color: var(--s-50);
  padding: var(--space-small);
  border-radius: var(--border-radius-normal);
  align-items: flex-start;
  svg {
    flex-shrink: 0;
  }
  p {
    margin-left: var(--space-small);
    color: var(--s-600);
  }
}
@keyframes shake {
  0% {
    transform: translateX(0);
  }
  25% {
    transform: translateX(0.375rem);
  }
  50% {
    transform: translateX(-0.375rem);
  }
  75% {
    transform: translateX(0.375rem);
  }
  100% {
    transform: translateX(0);
  }
}
</style>

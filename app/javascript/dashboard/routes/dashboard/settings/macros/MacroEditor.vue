<template>
  <div class="column content-box">
    <div class="row">
      <div class="small-8 columns with-right-space macros-canvas">
        <p v-if="!uiFlags.isFetching && !macro" class="no-items-error-message">
          {{ $t('MACROS.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('MACROS.LOADING')"
        />
        <ul v-if="!uiFlags.isFetching && macro" class="macros-feed-container">
          <!-- start flow pill -->
          <li class="macros-feed-item">
            <div class="macros-item macros-pill">
              <span>{{ $t('MACROS.EDITOR.START_FLOW') }}</span>
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
              <span>{{ $t('MACROS.EDITOR.END_FLOW') }}</span>
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
              :label="$t('MACROS.ADD.FORM.NAME.LABEL')"
              :placeholder="$t('MACROS.ADD.FORM.NAME.PLACEHOLDER')"
              :error="
                $v.macro.name.$error ? $t('MACROS.ADD.FORM.NAME.ERROR') : null
              "
              :class="{ error: $v.macro.name.$error }"
            />
          </div>
          <div>
            <p class="title">{{ $t('MACROS.EDITOR.VISIBILITY.LABEL') }}</p>
            <div class="macros-form-radio-group">
              <button
                class="card"
                :class="isActive('global')"
                @click="macro.visibility = 'global'"
              >
                <fluent-icon
                  v-if="macro.visibility === 'global'"
                  icon="checkmark-circle"
                  type="solid"
                  class="visibility-check"
                />
                <p class="title">
                  {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL') }}
                </p>
                <p class="subtitle">
                  {{ $t('MACROS.EDITOR.VISIBILITY.GLOBAL.DESCRIPTION') }}
                </p>
              </button>
              <button
                class="card"
                :class="isActive('personal')"
                @click="macro.visibility = 'personal'"
              >
                <fluent-icon
                  v-if="macro.visibility === 'personal'"
                  icon="checkmark-circle"
                  type="solid"
                  class="visibility-check"
                />
                <p class="title">
                  {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL') }}
                </p>
                <p class="subtitle">
                  {{ $t('MACROS.EDITOR.VISIBILITY.PERSONAL.DESCRIPTION') }}
                </p>
              </button>
            </div>
            <div class="macros-information-panel">
              <fluent-icon icon="info" size="20" />
              <p>
                {{ $t('MACROS.ORDER_INFO') }}
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
import ActionInput from 'dashboard/components/widgets/AutomationActionInput';
import { AUTOMATION_ACTION_TYPES } from 'dashboard/routes/dashboard/settings/automation/constants.js';
import { required, requiredIf } from 'vuelidate/lib/validators';
import draggable from 'vuedraggable';
import actionQueryGenerator from 'dashboard/helper/actionQueryGenerator.js';
import alertMixin from 'shared/mixins/alertMixin';
import { mapGetters } from 'vuex';

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
      mode: 'CREATE',
      dragEnabled: true,
      dragging: false,
      loadingMacro: false,
      macroVisibilityOptions: [
        {
          id: 'global',
          title: this.$t('MACROS.EDITOR.VISIBILITY.GLOBAL.LABEL'),
          checked: true,
        },
        {
          id: 'personal',
          title: this.$t('MACROS.EDITOR.VISIBILITY.PERSONAL.LABEL'),
          checked: false,
        },
      ],
      macro: {},
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'macros/getUIFlags',
    }),
    macroActionTypes() {
      // Because we do not support attachments and email transcripts in macros - yet!
      const itemsToRemove = ['send_attachment', 'send_email_transcript'];
      return AUTOMATION_ACTION_TYPES.filter(
        item => !itemsToRemove.includes(item.key)
      );
    },
    macroId() {
      return this.$route.params.macroId;
    },
  },
  watch: {
    $route: {
      handler() {
        this.$v.$reset();
        if (this.$route.params.macroId) {
          this.fetchMacro();
        } else {
          this.initializeMacro();
        }
      },
      immediate: true,
    },
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
        const action = this.mode === 'EDIT' ? 'macros/update' : 'macros/create';
        const successMessage =
          this.mode === 'EDIT'
            ? this.$t('MACROS.EDIT.API.SUCCESS_MESSAGE')
            : this.$t('MACROS.ADD.API.SUCCESS_MESSAGE');
        let macro = JSON.parse(JSON.stringify(this.macro));
        macro.actions = actionQueryGenerator(macro.actions);
        await this.$store.dispatch(action, macro);
        this.showAlert(this.$t(successMessage));
        this.$router.push({ name: 'macros_wrapper' });
      } catch (error) {
        this.showAlert(this.$t('MACROS.ERROR'));
      }
    },
    formatMacro(macro) {
      const formattedActions = macro.actions.map(action => {
        let actionParams = [];
        if (action.action_params.length) {
          const inputType = this.macroActionTypes.find(
            item => item.key === action.action_name
          ).inputType;
          if (inputType === 'multi_select') {
            actionParams = [
              ...this.getActionDropdownValues(action.action_name),
            ].filter(item => [...action.action_params].includes(item.id));
          } else if (inputType === 'team_message') {
            actionParams = {
              team_ids: [
                ...this.getActionDropdownValues(action.action_name),
              ].filter(item =>
                [...action.action_params[0].team_ids].includes(item.id)
              ),
              message: action.action_params[0].message,
            };
          } else actionParams = [...action.action_params];
        }
        return {
          ...action,
          action_params: actionParams,
        };
      });
      return {
        ...macro,
        actions: formattedActions,
      };
    },
    async manifestMacro() {
      const macroAvailable = this.$store.getters['macros/getMacro'](
        this.macroId
      );
      if (macroAvailable) this.macro = this.formatMacro(macroAvailable);
      else {
        const rawMacro = await this.$store.dispatch(
          'macros/getSingleMacro',
          this.macroId
        );
        this.macro = this.formatMacro(rawMacro);
      }
    },
    fetchMacro() {
      if (this.macroId) {
        this.mode = 'EDIT';
        this.$store.dispatch('agents/get');
        this.$store.dispatch('teams/get');
        this.$store.dispatch('labels/get');
        this.manifestMacro();
      }
    },
    initializeMacro() {
      this.mode = 'CREATE';
      this.macro = {
        name: '',
        actions: [
          {
            action_name: 'assign_team',
            action_params: [],
          },
        ],
        visibility: 'global',
      };
    },
    isActive(key) {
      return { active: this.macro.visibility === key };
    },
  },
};
</script>

<style scoped lang="scss">
.row {
  height: 100%;
}
.macros-canvas {
  // dotted matrix bag for canvas
  background-image: radial-gradient(#e0e0e0bd 1.2px, transparent 0);
  background-size: var(--space-normal) var(--space-normal);
  height: 100%;
  max-height: 100%;
  padding: var(--space-normal) var(--space-three);
  max-height: 100vh;
  overflow-y: auto;
}
.macros-properties-panel {
  padding: var(--space-slab);
  background-color: var(--white);
  // full screen height subtracted by the height of the header
  height: calc(100vh - 5.6rem);
  display: flex;
  flex-direction: column;
  border-left: 1px solid var(--s-50);
}

.macros-feed-container {
  list-style-type: none;
  // max-width Makes sure the macros ui is not too wide in large screens
  max-width: 800px;

  .macros-feed-item:not(:last-child) {
    position: relative;
    padding-bottom: var(--space-three);
  }

  .macros-feed-item:not(:last-child):not(.sortable-chosen):after,
  .macros-feed-draggable:after {
    content: '';
    position: absolute;
    height: var(--space-three);
    width: 3px;
    margin-left: var(--space-medium);
    // trail line for the macros - feed
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
    margin-left: var(--space-one);
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
    margin-left: var(--space-one);

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
      // Custom shadow so it wont look to heavy over the dots.
      box-shadow: rgb(0 0 0 / 3%) 0px 6px 24px 0px,
        rgb(0 0 0 / 6%) 0px 0px 0px 1px;
      &:hover {
        .macros-action-item_button {
          &.delete {
            display: flex;
          }
        }
      }
      //Adding a custom shake animation on error because the save button and the action inputs were too far to notice that there was an error.
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
  gap: var(--space-slab);

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
      color: var(--w-500);
      top: var(--space-small);
      right: var(--space-small);
    }
  }
}

.title {
  display: block;
  margin: 0;
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  line-height: 1.8;
  color: var(--color-body);
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

<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import {
  dynamicTime,
  shortTimestamp,
  dateFormat,
} from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import ChannelIcon from 'dashboard/components-next/icon/ChannelIcon.vue';
import CardPriorityIcon from 'dashboard/components-next/Conversation/ConversationCard/CardPriorityIcon.vue';
import CardLabels from 'dashboard/components-next/Conversation/ConversationCard/CardLabels.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/Sla/SLACardLabel.vue';
import { useCrmOrigin } from '../composables/useCrmOrigin';
import CrmCardPill from './CrmCardPill.vue';

const props = defineProps({
  card: {
    type: Object,
    required: true,
  },
  // Stage accent hex (e.g. '#22c55e). Slate fallback when absent.
  stageColor: {
    type: String,
    default: '',
  },
  // Standalone variant renders a minimal card (used outside the board v-for).
  standalone: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['open', 'openConversation']);

const { t } = useI18n();
const { originFromCampaigns, formatOriginLabel, formatOriginTitle } =
  useCrmOrigin();

const STAGE_FALLBACK_COLOR = '#64748b';

const railStyle = computed(() => ({
  backgroundColor: props.stageColor || STAGE_FALLBACK_COLOR,
}));

const contactLabel = computed(
  () =>
    props.card.contact?.name ||
    props.card.contact?.phone_number ||
    props.card.inbox?.name ||
    t('CRM_KANBAN.CARD.STANDALONE')
);

// The title is backfilled from the contact (name/phone) when no custom title
// exists, so the contact line would just repeat the title. Only show it when it
// adds information beyond the title.
const showContactLine = computed(
  () => Boolean(contactLabel.value) && contactLabel.value !== props.card.title
);

// The avatar represents WHO is handling the card (the responsible), in 3 states:
//   bot   -> IA (square i-lucide-bot glyph)
//   agent -> a human (initials avatar)
//   none  -> nobody assigned and no bot (distinct dashed i-lucide-user-round-x)
const responsibleType = computed(() => props.card.responsible?.type || 'none');
const responsibleIsBot = computed(() => responsibleType.value === 'bot');
const responsibleName = computed(
  () => props.card.responsible?.name || t('CRM_KANBAN.CARD.NO_OWNER')
);
const avatarIconName = computed(() => {
  if (responsibleType.value === 'bot') return 'i-lucide-bot';
  if (responsibleType.value === 'none') return 'i-lucide-user-round-x';
  return null; // agent -> initials from name
});
const responsibleIcon = computed(() => {
  if (responsibleType.value === 'bot') return 'i-lucide-bot';
  if (responsibleType.value === 'agent') return 'i-lucide-user-round';
  return 'i-lucide-user-round-x';
});

// Demote priority to a small glyph, only for high/urgent (reuse the
// shared CardPriorityIcon).
const showPriorityGlyph = computed(() =>
  ['high', 'urgent'].includes(props.card.priority)
);

const valueLabel = computed(() => {
  const cents = Number(props.card.value_cents || 0);
  if (!cents) return null;
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: props.card.currency || 'BRL',
  }).format(cents / 100);
});

const scoreLabel = computed(() => {
  const score = Number(props.card.score || 0);
  if (!score || score <= 0) return null;
  return score;
});

const aiSuggestionLabel = computed(() => {
  const suggestion = props.card.ai_suggestion;
  if (!suggestion?.to_stage_name) return '';
  return t('CRM_KANBAN.AI_CARD.BADGE', { stage: suggestion.to_stage_name });
});

// Board sends epoch seconds; render via timeHelper (fromUnixTime). Do not mix
// with ISO date helpers.
const relativeFromEpoch = epoch => {
  const value = Number(epoch);
  if (!value || Number.isNaN(value)) return '';
  return shortTimestamp(dynamicTime(value), true);
};

const titleFromEpoch = epoch => {
  const value = Number(epoch);
  if (!value || Number.isNaN(value)) return '';
  return dateFormat(value, 'MMM d, yyyy h:mm a');
};

const lastMessageLabel = computed(() =>
  relativeFromEpoch(props.card.last_message_at)
);

const lastMessageTitle = computed(() =>
  titleFromEpoch(props.card.last_message_at)
);

// SLACardLabel expects the conversation-list "chat" shape; card.conversation
// already carries applied_sla + epoch fields from the payload builder.
const slaChat = computed(() => {
  const conversation = props.card?.conversation;
  if (!conversation?.applied_sla) return null;
  return {
    applied_sla: conversation.applied_sla,
    first_reply_created_at: conversation.first_reply_created_at,
    waiting_since: conversation.waiting_since,
    status: conversation.status,
  };
});

const followUp = computed(() => {
  const epoch = Number(props.card.next_follow_up_at);
  if (!epoch || Number.isNaN(epoch)) return null;

  const nowSeconds = Date.now() / 1000;
  const secondsUntil = epoch - nowSeconds;
  let tone = 'default';
  if (secondsUntil < 0) {
    tone = 'ruby';
  } else if (secondsUntil <= 24 * 60 * 60) {
    tone = 'amber';
  }

  // The nearest follow-up can be the AI cadence or a manual reminder; the badge
  // shows whichever is closest to due (per the locked decision) but flags its
  // type with an icon + tooltip so the two are never confused.
  const isAi = props.card.next_follow_up_source === 'ai';
  return {
    label: shortTimestamp(dynamicTime(epoch), true),
    title: isAi
      ? t('CRM_KANBAN.CARD.FOLLOW_UP_AI')
      : t('CRM_KANBAN.CARD.FOLLOW_UP_MANUAL'),
    icon: isAi ? 'i-lucide-bot' : 'i-lucide-calendar-clock',
    tone,
  };
});

// Etiquetas normais da conversa PRIMÁRIA (card.labels = array de titles);
// CardLabels resolve cor/truncagem cruzando com as labels da conta no store
// (mesmo padrão da lista de Conversas), evitando prop-drilling pelo board.
const accountLabels = useMapGetter('labels/getLabels');

// Etiquetas de CAMPANHA vivem só no Contato (CampaignImports::Importer), nunca
// sincronizadas para a conversa — mescladas aqui (mesmo chip do CardLabels,
// deduplicadas) para ficarem visíveis no card sem tocar no LabelBox da conversa.
const mergedLabels = computed(() => [
  ...new Set([
    ...(props.card.labels || []),
    ...(props.card.contact_labels || []),
  ]),
]);

// Pill de origem universal (card.campaigns = toques agregados, 1º toque primeiro).
// Texto = source i18n + headline do 1º toque; tooltip lista todos os toques;
// "+N" sinaliza os toques além do primeiro.
const campaignPill = computed(() => {
  return originFromCampaigns(props.card.campaigns);
});

// Convite de handoff em aberto (payload handoff_invite): âmbar dentro do
// prazo de pega, ruby quando o prazo estourou. Some quando o ciclo fecha
// (alguém pega, expira ou escala).
const handoffInvite = computed(() => {
  const due = Number(props.card?.handoff_invite?.pickup_due_at);
  if (!due || Number.isNaN(due)) return null;

  const isOverdue = Date.now() / 1000 > due;
  return {
    tone: isOverdue ? 'ruby' : 'amber',
    label: shortTimestamp(dynamicTime(due), true),
    title: isOverdue
      ? t('CRM_KANBAN.CARD.HANDOFF_INVITE_OVERDUE')
      : t('CRM_KANBAN.CARD.HANDOFF_INVITE_PENDING'),
  };
});

// Board card carries the primary conversation's per-account display_id (same
// field the drawer navigates by). When present on a board card, the last-message
// bubble doubles as a shortcut straight into the inbox conversation; otherwise it
// stays a plain, non-interactive label (manual/standalone cards have no thread).
const conversationDisplayId = computed(
  () => props.card?.conversation?.display_id || ''
);
const canOpenConversation = computed(
  () => Boolean(conversationDisplayId.value) && !props.standalone
);
</script>

<template>
  <div
    class="group/card relative w-full shrink-0 overflow-hidden rounded-lg border border-n-weak bg-n-surface-1 py-3 pl-4 pr-3 text-left shadow-sm transition-colors hover:bg-n-alpha-2"
  >
    <!-- Stage accent rail (inline :style per repo precedent; slate fallback,
         dark ring guards pale colors on dark surfaces) -->
    <span
      class="absolute inset-y-0 left-0 w-1 rounded-l-lg ring-1 ring-inset ring-n-alpha-1 dark:ring-n-alpha-2"
      :style="railStyle"
    />

    <!-- Primary action (open card details): a stretched, visually transparent
         button carrying the keyboard/screen-reader affordance and the full-card
         focus ring. The content layer sits above it (z-10) with pointer events
         enabled so inner tooltips/hover stay intact; content mouse-clicks open
         the drawer via their own @click, so pointer and keyboard reach the same
         action. The last-message bubble stops propagation to branch off. -->
    <button
      type="button"
      class="absolute inset-0 z-0 cursor-pointer rounded-lg focus-visible:outline focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-n-brand"
      :aria-label="t('CRM_KANBAN.CARD.OPEN_DETAILS', { name: card.title })"
      @click="$emit('open', card)"
    />

    <div class="relative z-10 cursor-pointer" @click="$emit('open', card)">
      <div class="flex items-start gap-2.5">
        <Avatar
          :name="responsibleName"
          :size="32"
          :rounded-full="!responsibleIsBot"
          :icon-name="avatarIconName"
          :title="responsibleName"
          class="mt-0.5 shrink-0"
        />

        <div class="min-w-0 flex-1">
          <div class="flex items-start justify-between gap-2">
            <p class="mb-0 truncate text-sm font-medium text-n-slate-12">
              {{ card.title }}
            </p>
            <CardPriorityIcon
              v-if="showPriorityGlyph"
              :priority="card.priority"
              class="mt-0.5 shrink-0"
            />
          </div>
          <p
            v-if="showContactLine"
            class="mb-0 mt-0.5 truncate text-xs text-n-slate-11"
          >
            {{ contactLabel }}
          </p>
        </div>
      </div>

      <p
        v-if="card.description"
        class="mb-0 mt-2 line-clamp-2 text-xs leading-5 text-n-slate-11"
      >
        {{ card.description }}
      </p>

      <!-- Etiquetas (conversa primária + contato/campanha, deduplicadas) — mesma
           linha de labels da lista de Conversas, cor resolvida via store -->
      <CardLabels
        v-if="mergedLabels.length"
        class="mt-2"
        :conversation-labels="mergedLabels"
        :account-labels="accountLabels"
      />

      <!-- Origem da campanha — linha própria, separada das signal pills -->
      <div v-if="campaignPill" class="mt-2 flex items-center">
        <CrmCardPill
          :icon="campaignPill.icon"
          tone="teal"
          :title="formatOriginTitle(campaignPill)"
        >
          {{ formatOriginLabel(campaignPill) }}
          <template v-if="campaignPill.extraCount > 0" #trail>
            <span class="shrink-0 font-semibold">
              {{ `+${campaignPill.extraCount}` }}
            </span>
          </template>
        </CrmCardPill>
      </div>

      <!-- Signal pills -->
      <div class="mt-2.5 flex flex-wrap items-center gap-1.5">
        <SLACardLabel v-if="slaChat" :chat="slaChat" />

        <CrmCardPill
          v-if="handoffInvite"
          icon="i-lucide-alarm-clock"
          :tone="handoffInvite.tone"
          :title="handoffInvite.title"
        >
          {{ handoffInvite.label }}
        </CrmCardPill>

        <CrmCardPill v-if="card.inbox?.channel_type" tone="default">
          <template #lead>
            <ChannelIcon
              :inbox="{ channel_type: card.inbox.channel_type }"
              class="size-3 shrink-0"
            />
          </template>
          {{ card.inbox.name }}
        </CrmCardPill>

        <CrmCardPill v-if="valueLabel" icon="i-lucide-banknote" tone="default">
          {{ valueLabel }}
        </CrmCardPill>

        <CrmCardPill
          v-if="followUp"
          :icon="followUp.icon"
          :tone="followUp.tone"
          :title="followUp.title"
        >
          {{ t('CRM_KANBAN.CARD.FOLLOW_UP_DUE', { time: followUp.label }) }}
        </CrmCardPill>

        <CrmCardPill
          v-if="aiSuggestionLabel"
          icon="i-lucide-sparkles"
          tone="blue"
        >
          {{ aiSuggestionLabel }}
        </CrmCardPill>

        <CrmCardPill v-if="scoreLabel" icon="i-lucide-flame" tone="default">
          {{ t('CRM_KANBAN.CARD.SCORE', { score: scoreLabel }) }}
        </CrmCardPill>
      </div>

      <div
        class="mt-2 flex items-center justify-between gap-2 text-[11px] text-n-slate-10"
      >
        <span class="flex min-w-0 items-center gap-1" :title="responsibleName">
          <span :class="responsibleIcon" class="size-3 shrink-0" />
          <span class="truncate">{{ responsibleName }}</span>
        </span>
        <button
          v-if="lastMessageLabel && canOpenConversation"
          type="button"
          class="crm-card-open-conversation -my-1 -mr-1 flex shrink-0 cursor-pointer items-center gap-1 rounded px-1 py-1 text-n-slate-10 transition-colors hover:bg-n-alpha-2 hover:text-n-brand hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:-outline-offset-1 focus-visible:outline-n-brand"
          :title="t('CRM_KANBAN.CARD.OPEN_CONVERSATION')"
          :aria-label="t('CRM_KANBAN.CARD.OPEN_CONVERSATION')"
          @click.stop="$emit('openConversation', card)"
        >
          <span class="i-lucide-message-circle size-3 shrink-0" />
          {{ lastMessageLabel }}
        </button>
        <span
          v-else-if="lastMessageLabel && !standalone"
          class="flex shrink-0 items-center gap-1"
          :title="lastMessageTitle"
        >
          <span class="i-lucide-message-circle size-3 shrink-0" />
          {{ lastMessageLabel }}
        </span>
      </div>
    </div>
  </div>
</template>

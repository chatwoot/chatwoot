<script setup>
/* global axios */
import { ref, computed, onMounted, watch, nextTick } from 'vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

/* ── API ── */
const accountId = window.location.pathname.split('/')[3];
const API = `/api/v1/accounts/${accountId}/omni_ai/comments_page`;

async function apiGet(path, params = {}) {
  const query = new URLSearchParams(
    Object.fromEntries(Object.entries(params).filter(([, v]) => v))
  ).toString();
  const url = query ? `${API}${path}?${query}` : `${API}${path}`;
  const { data } = await axios.get(url);
  return data;
}
async function apiPut(path, body) {
  const { data } = await axios.put(`${API}${path}`, body);
  return data;
}
async function apiPost(path, body) {
  const { data } = await axios.post(`${API}${path}`, body);
  return data;
}

/* ── State ── */
const search = ref('');
const platform = ref('');
const stats = ref({ total: 0, uniqueCommenters: 0, replied: 0, dmSent: 0, linked: 0 });
const posts = ref([]);
const loading = ref(false);
const expandedPostIds = ref(new Set());
const postComments = ref({});
const postCommentsLoading = ref({});
const postInfo = ref({});

// Inline reply state
const replyTargets = ref({}); // { [commenterGroupKey]: commentId }
const replyTexts = ref({}); // { [commenterGroupKey]: text }
const replyLoading = ref({});

// DM state
const dmDialogRef = ref(null);
const dmComment = ref(null);
const dmText = ref('');
const dmLoading = ref(false);

// Detail modal state
const detailDialogRef = ref(null);
const detailComment = ref(null);
const detailCommenterHistory = ref([]);
const detailPostInfo = ref(null);
const detailManualReply = ref('');
const detailReplyLoading = ref(false);
const detailHistoryVisible = ref(5);

// Collapsible commenter groups: tracks how many comments to show per group
// key = `${postId}_${commenterId}`, value = number of visible comments
const COMMENTS_INITIAL = 2;
const COMMENTS_STEP = 5;
const groupVisibleCount = ref({});

function visibleCommentsForGroup(group, postId) {
  const key = `${postId}_${group.commenterId}`;
  const limit = groupVisibleCount.value[key] || COMMENTS_INITIAL;
  // Show the LAST N comments (most recent)
  return group.comments.slice(-limit);
}
function hiddenCount(group, postId) {
  const key = `${postId}_${group.commenterId}`;
  const limit = groupVisibleCount.value[key] || COMMENTS_INITIAL;
  return Math.max(0, group.comments.length - limit);
}
function showMore(group, postId) {
  const key = `${postId}_${group.commenterId}`;
  const current = groupVisibleCount.value[key] || COMMENTS_INITIAL;
  groupVisibleCount.value = { ...groupVisibleCount.value, [key]: current + COMMENTS_STEP };
}
function collapseGroup(group, postId) {
  const key = `${postId}_${group.commenterId}`;
  groupVisibleCount.value = { ...groupVisibleCount.value, [key]: COMMENTS_INITIAL };
}
function isGroupExpanded(group, postId) {
  const key = `${postId}_${group.commenterId}`;
  return (groupVisibleCount.value[key] || COMMENTS_INITIAL) > COMMENTS_INITIAL;
}
function showMoreDetailHistory() {
  detailHistoryVisible.value += 5;
}

/* ── KPI definitions ── */
const kpis = computed(() => [
  { key: 'Total', value: stats.value.total, icon: 'i-lucide-message-square', color: 'text-n-slate-11' },
  { key: 'Unique Leads', value: stats.value.uniqueCommenters, icon: 'i-lucide-users', color: 'text-violet-500 dark:text-violet-400' },
  { key: 'Replied', value: stats.value.replied, icon: 'i-lucide-message-circle', color: 'text-n-blue-text' },
  { key: 'DM Sent', value: stats.value.dmSent, icon: 'i-lucide-send', color: 'text-emerald-500 dark:text-emerald-400' },
  { key: 'Linked', value: stats.value.linked, icon: 'i-lucide-link-2', color: 'text-n-brand' },
]);

/* ── Fetch helpers ── */
async function fetchStats() {
  try {
    stats.value = await apiGet('/stats');
  } catch { /* ignore */ }
}

async function fetchPosts() {
  loading.value = true;
  try {
    const res = await apiGet('/by-post', { platform: platform.value, q: search.value });
    posts.value = res.posts || [];
  } catch {
    posts.value = [];
  } finally {
    loading.value = false;
  }
}

async function fetchPostComments(postId) {
  postCommentsLoading.value = { ...postCommentsLoading.value, [postId]: true };
  try {
    const res = await apiGet(`/post/${encodeURIComponent(postId)}`);
    postComments.value = { ...postComments.value, [postId]: res.items || [] };
  } catch {
    postComments.value = { ...postComments.value, [postId]: [] };
  } finally {
    postCommentsLoading.value = { ...postCommentsLoading.value, [postId]: false };
  }
}

async function fetchPostInfo(postId, plt) {
  if (postId === 'ungrouped' || postInfo.value[postId]) return;
  try {
    const res = await apiGet(`/post-info/${encodeURIComponent(postId)}`, { platform: plt });
    postInfo.value = { ...postInfo.value, [postId]: res };
  } catch { /* ignore */ }
}

/* ── Actions ── */
function togglePost(post) {
  const id = post.post_id;
  const set = new Set(expandedPostIds.value);
  if (set.has(id)) {
    set.delete(id);
  } else {
    set.add(id);
    if (!postComments.value[id]) fetchPostComments(id);
    fetchPostInfo(id, post.platform);
  }
  expandedPostIds.value = set;
}

async function sendInlineReply(commentId, groupKey) {
  const text = (replyTexts.value[groupKey] || '').trim();
  if (!text) return;
  replyLoading.value = { ...replyLoading.value, [groupKey]: true };
  try {
    await apiPut(`/${encodeURIComponent(commentId)}/reply`, { reply: text });
    replyTexts.value = { ...replyTexts.value, [groupKey]: '' };
    replyTargets.value = { ...replyTargets.value, [groupKey]: null };
    // Refresh the post's comments
    const postId = findPostIdForComment(commentId);
    if (postId) await fetchPostComments(postId);
    fetchStats();
  } catch { /* ignore */ }
  replyLoading.value = { ...replyLoading.value, [groupKey]: false };
}

function findPostIdForComment(commentId) {
  for (const [postId, comments] of Object.entries(postComments.value)) {
    if (comments.some(c => c.id === commentId)) return postId;
  }
  return null;
}

function openDmDialog(comment) {
  dmComment.value = comment;
  dmText.value = '';
  dmLoading.value = false;
  nextTick(() => dmDialogRef.value?.open());
}

async function sendDm() {
  if (!dmComment.value || !dmText.value.trim()) return;
  dmLoading.value = true;
  try {
    await apiPost(`/${encodeURIComponent(dmComment.value.id)}/dm`, {
      dm_text: dmText.value.trim(),
      platform: dmComment.value.platform,
    });
    dmDialogRef.value?.close();
    const postId = findPostIdForComment(dmComment.value.id);
    if (postId) await fetchPostComments(postId);
    fetchStats();
  } catch { /* ignore */ }
  dmLoading.value = false;
}

async function openDetailModal(comment) {
  detailComment.value = comment;
  detailManualReply.value = '';
  detailReplyLoading.value = false;
  detailCommenterHistory.value = [];
  detailPostInfo.value = null;
  detailHistoryVisible.value = 5;
  nextTick(() => detailDialogRef.value?.open());
  // Fetch commenter history
  if (comment.commenter_id) {
    try {
      const res = await apiGet(`/commenter/${encodeURIComponent(comment.commenter_id)}`);
      detailCommenterHistory.value = res.items || [];
    } catch { /* ignore */ }
  }
  // Fetch post info
  if (comment.post_id && comment.post_id !== 'ungrouped') {
    try {
      const res = await apiGet(`/post-info/${encodeURIComponent(comment.post_id)}`, { platform: comment.platform });
      detailPostInfo.value = res;
    } catch { /* ignore */ }
  }
}

async function sendDetailReply() {
  if (!detailComment.value || !detailManualReply.value.trim()) return;
  detailReplyLoading.value = true;
  try {
    await apiPut(`/${encodeURIComponent(detailComment.value.id)}/reply`, {
      reply: detailManualReply.value.trim(),
    });
    // Update local state
    const now = new Date().toISOString();
    const prev = detailComment.value.reply_history
      ? (() => { try { return JSON.parse(detailComment.value.reply_history); } catch { return []; } })()
      : [];
    const newEntry = { text: detailManualReply.value.trim(), model: 'manual', timestamp: now };
    detailComment.value = {
      ...detailComment.value,
      comment_reply: detailManualReply.value.trim(),
      ai_model: 'manual',
      reply_history: JSON.stringify([...prev, newEntry]),
      updated_at: now,
    };
    detailManualReply.value = '';
    const postId = findPostIdForComment(detailComment.value.id);
    if (postId) fetchPostComments(postId);
    fetchStats();
  } catch { /* ignore */ }
  detailReplyLoading.value = false;
}

/* ── Helpers ── */
const STATUS_DOT = {
  new: 'bg-n-slate-10',
  replied: 'bg-blue-500',
  dm_sent: 'bg-emerald-500',
  reply_failed: 'bg-red-500',
  dm_failed: 'bg-amber-500',
  linked: 'bg-violet-500',
};

function statusDot(status) {
  return STATUS_DOT[status] || STATUS_DOT.new;
}

function statusLabel(status) {
  return (status || 'new').replace(/_/g, ' ');
}

function statusColor(status) {
  const map = {
    new: 'bg-n-alpha-2 text-n-slate-11',
    replied: 'bg-blue-50 text-blue-600 dark:bg-blue-950/40 dark:text-blue-400',
    dm_sent: 'bg-emerald-50 text-emerald-600 dark:bg-emerald-950/40 dark:text-emerald-400',
    reply_failed: 'bg-red-50 text-red-600 dark:bg-red-950/40 dark:text-red-400',
    dm_failed: 'bg-amber-50 text-amber-600 dark:bg-amber-950/40 dark:text-amber-400',
    linked: 'bg-violet-50 text-violet-600 dark:bg-violet-950/40 dark:text-violet-400',
  };
  return map[status] || map.new;
}

function platformClasses(plt) {
  if (plt === 'instagram') return 'bg-pink-100 text-pink-600 dark:bg-pink-950/40 dark:text-pink-400';
  if (plt === 'facebook') return 'bg-blue-100 text-blue-600 dark:bg-blue-950/40 dark:text-blue-400';
  return 'bg-n-alpha-2 text-n-slate-11';
}

function relTime(d) {
  const now = Date.now();
  const then = new Date(d).getTime();
  const diff = now - then;
  if (diff < 60000) return 'now';
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m`;
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h`;
  if (diff < 604800000) return `${Math.floor(diff / 86400000)}d`;
  return formatDate(d);
}

function formatDate(d) {
  try {
    return new Intl.DateTimeFormat('en-US', {
      month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit',
    }).format(new Date(d));
  } catch { return d; }
}

function buildPermalink(post) {
  const info = postInfo.value[post.post_id];
  if (info?.permalink) return info.permalink;
  if (post.post_id !== 'ungrouped' && post.platform === 'facebook' && post.post_id.includes('_')) {
    const parts = post.post_id.split('_');
    return `https://www.facebook.com/${parts[0]}/posts/${parts[1]}`;
  }
  return null;
}

function groupCommentsByCommenter(comments) {
  const groups = [];
  const map = new Map();
  for (const c of comments) {
    const cid = c.commenter_id || c.id;
    if (map.has(cid)) {
      groups[map.get(cid)].comments.push(c);
    } else {
      map.set(cid, groups.length);
      groups.push({
        commenterId: cid,
        name: c.commenter_name || c.commenter_username || 'User',
        comments: [c],
      });
    }
  }
  return groups;
}

function getDefaultReplyTarget(comments) {
  return comments.find(c => !c.comment_reply)?.id || comments[comments.length - 1]?.id;
}

function parseReplyHistory(comment) {
  if (!comment?.reply_history) return [];
  try { return JSON.parse(comment.reply_history); } catch { return []; }
}

/* ── Lifecycle ── */
import { onUnmounted } from 'vue';
import { emitter } from 'shared/helpers/mitt';

onMounted(() => {
  fetchStats();
  fetchPosts();
});

// WebSocket-driven updates: listen for omni_comments:updated events
function onOmniCommentsUpdated(data) {
  fetchStats();
  if (data?.post_id) {
    // Refresh only the affected post's comments if expanded
    if (expandedPostIds.value.has(data.post_id)) {
      fetchPostComments(data.post_id);
    }
    // Also refresh post list to update counts
    fetchPosts();
  } else {
    fetchPosts();
  }
}
onMounted(() => {
  emitter.on('omni_comments:updated', onOmniCommentsUpdated);
});
onUnmounted(() => {
  emitter.off('omni_comments:updated', onOmniCommentsUpdated);
});

// Soft fallback polling every 5 minutes (in case WebSocket event missed)
let fallbackInterval;
onMounted(() => {
  fallbackInterval = setInterval(() => {
    fetchStats();
    fetchPosts();
  }, 300000);
});
onUnmounted(() => {
  if (fallbackInterval) clearInterval(fallbackInterval);
});

// Re-fetch on filter change
watch([search, platform], () => {
  fetchPosts();
});
</script>

<template>
  <div class="flex flex-col flex-1 h-full overflow-auto bg-n-surface-1">
    <div class="max-w-[1200px] w-full mx-auto px-6 py-6 space-y-5">

      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-xl font-bold text-n-slate-12 flex items-center gap-2">
            <span class="i-lucide-message-square-text w-6 h-6 text-n-brand" />
            Comments
          </h1>
          <p class="text-sm text-n-slate-10 mt-0.5">
            Monitor and reply to social media comments
          </p>
        </div>
        <button
          class="p-2 rounded-lg text-n-slate-11 hover:bg-n-alpha-2 transition-colors"
          title="Refresh"
          @click="fetchStats(); fetchPosts()"
        >
          <span class="i-lucide-refresh-cw w-4 h-4" />
        </button>
      </div>

      <!-- KPI Cards -->
      <div class="grid grid-cols-2 md:grid-cols-5 gap-3">
        <div
          v-for="kpi in kpis"
          :key="kpi.key"
          class="flex items-center gap-3 p-4 rounded-xl bg-n-solid-2 border border-n-container"
        >
          <div
            class="p-2 rounded-lg bg-n-alpha-2"
            :class="kpi.color"
          >
            <span :class="kpi.icon" class="w-5 h-5 block" />
          </div>
          <div>
            <p class="text-xs text-n-slate-10">{{ kpi.key }}</p>
            <p class="text-xl font-bold text-n-slate-12">{{ kpi.value }}</p>
          </div>
        </div>
      </div>

      <!-- Filters -->
      <div class="flex flex-wrap gap-3 items-center">
        <div class="relative flex-1 min-w-[200px]">
          <span class="i-lucide-search w-4 h-4 absolute start-3 top-1/2 -translate-y-1/2 text-n-slate-10" />
          <input
            v-model="search"
            type="text"
            placeholder="Search comments..."
            class="w-full ps-9 pe-3 py-2 text-sm bg-n-alpha-1 border border-n-container rounded-lg text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-1 focus:ring-n-brand"
          />
        </div>
        <select
          v-model="platform"
          class="px-3 py-2 text-sm bg-n-alpha-1 border border-n-container rounded-lg text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
        >
          <option value="">All Platforms</option>
          <option value="instagram">Instagram</option>
          <option value="facebook">Facebook</option>
        </select>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="space-y-3">
        <div
          v-for="i in 3"
          :key="i"
          class="h-20 rounded-xl bg-n-alpha-2 animate-pulse"
        />
      </div>

      <!-- Empty state -->
      <div
        v-else-if="!posts.length"
        class="flex flex-col items-center justify-center py-16 rounded-xl bg-n-solid-2 border border-n-container"
      >
        <span class="i-lucide-layout-list w-10 h-10 text-n-slate-10 mb-3" />
        <p class="text-n-slate-11 font-medium">No posts with comments yet</p>
        <p class="text-xs text-n-slate-10 mt-1">Comments will be grouped by post once they arrive</p>
      </div>

      <!-- Posts list -->
      <div v-else class="space-y-2">
        <div
          v-for="post in posts"
          :key="post.post_id"
          class="rounded-xl bg-n-solid-2 border border-n-container overflow-hidden"
        >
          <!-- Post header (clickable) -->
          <button
            type="button"
            class="w-full text-start hover:bg-n-alpha-1 transition-colors"
            @click="togglePost(post)"
          >
            <div class="p-4 pb-3 flex gap-3">
              <!-- Platform icon -->
              <div
                class="w-11 h-11 rounded-lg shrink-0 flex items-center justify-center"
                :class="platformClasses(post.platform)"
              >
                <span
                  v-if="post.post_id === 'ungrouped'"
                  class="i-lucide-layout-list w-5 h-5"
                />
                <span
                  v-else-if="post.platform === 'instagram'"
                  class="i-lucide-instagram w-5 h-5"
                />
                <span
                  v-else-if="post.platform === 'facebook'"
                  class="i-lucide-facebook w-5 h-5"
                />
                <span v-else class="i-lucide-message-square w-5 h-5" />
              </div>

              <div class="flex-1 min-w-0">
                <!-- Post text -->
                <p class="text-[13px] text-n-slate-12 line-clamp-2 leading-snug">
                  <template v-if="post.post_id === 'ungrouped'">
                    Ungrouped Comments
                  </template>
                  <template v-else-if="postInfo[post.post_id]?.message">
                    {{ postInfo[post.post_id].message.length > 120
                      ? postInfo[post.post_id].message.slice(0, 120) + '…'
                      : postInfo[post.post_id].message }}
                  </template>
                  <template v-else>
                    <span class="text-n-slate-10 font-mono text-xs italic">
                      Post {{ post.post_id.includes('_') ? '#' + post.post_id.split('_')[1]?.slice(-8) : post.post_id.slice(-12) }}
                      <span
                        v-if="postInfo[post.post_id]?._error"
                        class="i-lucide-alert-circle w-3 h-3 inline ms-1 text-amber-400"
                        :title="`Error: ${postInfo[post.post_id]._error}`"
                      />
                    </span>
                  </template>
                </p>

                <!-- Stats row -->
                <div class="flex items-center gap-2.5 mt-1.5 text-[11px] text-n-slate-10">
                  <span class="flex items-center gap-1">
                    <span class="i-lucide-message-square w-3 h-3" />
                    {{ post.comment_count }}
                  </span>
                  <span
                    v-if="post.replied_count > 0"
                    class="flex items-center gap-1 text-blue-500 dark:text-blue-400"
                  >
                    <span class="i-lucide-reply w-3 h-3" />
                    {{ post.replied_count }}
                  </span>
                  <span
                    v-if="post.dm_count > 0"
                    class="flex items-center gap-1 text-emerald-500 dark:text-emerald-400"
                  >
                    <span class="i-lucide-send w-3 h-3" />
                    {{ post.dm_count }}
                  </span>
                  <span
                    v-if="post.new_count > 0"
                    class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium bg-amber-50 text-amber-600 dark:bg-amber-950/40 dark:text-amber-400"
                  >
                    {{ post.new_count }} new
                  </span>
                  <span class="ms-auto">{{ relTime(post.latest_comment_at) }}</span>
                  <a
                    v-if="buildPermalink(post)"
                    :href="buildPermalink(post)"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="text-n-brand hover:opacity-80"
                    @click.stop
                  >
                    <span class="i-lucide-external-link w-3 h-3" />
                  </a>
                  <span
                    :class="expandedPostIds.has(post.post_id) ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
                    class="w-3.5 h-3.5 text-n-slate-10"
                  />
                </div>
              </div>
            </div>
          </button>

          <!-- Expanded: comment threads grouped by commenter -->
          <div
            v-if="expandedPostIds.has(post.post_id)"
            class="border-t border-n-container"
          >
            <!-- Loading state -->
            <div v-if="postCommentsLoading[post.post_id]" class="p-4 space-y-3">
              <div
                v-for="i in 3"
                :key="i"
                class="flex gap-2.5"
              >
                <div class="w-8 h-8 rounded-full bg-n-alpha-2 animate-pulse shrink-0" />
                <div class="flex-1 space-y-1.5">
                  <div class="h-3 w-24 rounded bg-n-alpha-2 animate-pulse" />
                  <div class="h-10 rounded-xl bg-n-alpha-2 animate-pulse" />
                </div>
              </div>
            </div>

            <!-- No comments -->
            <div
              v-else-if="!postComments[post.post_id]?.length"
              class="p-6 text-center text-sm text-n-slate-10"
            >
              No comments found
            </div>

            <!-- Commenter groups -->
            <div v-else class="p-3 space-y-2">
              <div
                v-for="group in groupCommentsByCommenter(postComments[post.post_id])"
                :key="group.commenterId"
                class="rounded-xl border border-n-container bg-n-alpha-1 overflow-hidden"
              >
                <!-- Commenter header -->
                <div class="flex items-center gap-2.5 px-3 pt-3 pb-1">
                  <div class="w-7 h-7 rounded-full bg-n-alpha-3 flex items-center justify-center text-xs font-bold text-n-slate-11 shrink-0">
                    {{ group.name.slice(0, 1).toUpperCase() }}
                  </div>
                  <span class="text-xs font-semibold text-n-slate-12">{{ group.name }}</span>
                  <span
                    v-if="group.comments.length > 1"
                    class="text-[10px] text-n-slate-10"
                  >
                    {{ group.comments.length }} comments
                  </span>
                </div>

                <!-- "Show N earlier" button -->
                <div v-if="hiddenCount(group, post.post_id) > 0" class="px-3 pt-1">
                  <button
                    type="button"
                    class="w-full flex items-center justify-center gap-1.5 py-1.5 rounded-lg text-[11px] font-medium text-n-brand hover:bg-n-alpha-2 transition-colors"
                    @click="showMore(group, post.post_id)"
                  >
                    <span class="i-lucide-chevrons-up w-3 h-3" />
                    Show {{ Math.min(hiddenCount(group, post.post_id), COMMENTS_STEP) }} earlier
                    <span class="text-n-slate-10 font-normal">({{ hiddenCount(group, post.post_id) }} hidden)</span>
                  </button>
                </div>

                <!-- Comments (only visible slice) -->
                <div class="px-3 pb-1 space-y-0.5">
                  <div
                    v-for="c in visibleCommentsForGroup(group, post.post_id)"
                    :key="c.id"
                  >
                    <!-- User comment -->
                    <div
                      class="flex gap-2 py-1.5 px-1.5 rounded-lg cursor-pointer transition-colors"
                      :class="replyTargets[`${post.post_id}_${group.commenterId}`] === c.id
                        ? 'bg-blue-50/50 dark:bg-blue-950/20 ring-1 ring-blue-300/30 dark:ring-blue-500/20'
                        : 'hover:bg-n-alpha-1'"
                      @click="replyTargets[`${post.post_id}_${group.commenterId}`] =
                        replyTargets[`${post.post_id}_${group.commenterId}`] === c.id ? null : c.id"
                    >
                      <div :class="statusDot(c.status)" class="w-2 h-2 rounded-full mt-2 shrink-0" />
                      <div class="flex-1 min-w-0">
                        <p class="text-[13px] text-n-slate-12 break-words leading-snug">
                          {{ c.comment_text }}
                        </p>
                        <div class="flex items-center gap-2 mt-0.5 text-[10px] text-n-slate-10">
                          <span>{{ relTime(c.created_at) }}</span>
                          <span
                            class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium"
                            :class="statusColor(c.status)"
                          >
                            {{ statusLabel(c.status) }}
                          </span>
                          <span
                            v-if="c.error_message"
                            class="text-red-400 truncate max-w-[160px]"
                            :title="c.error_message"
                          >
                            <span class="i-lucide-alert-circle w-3 h-3 inline me-0.5" />{{ c.error_message }}
                          </span>
                          <button
                            type="button"
                            class="text-n-brand hover:underline font-medium ms-auto"
                            @click.stop="openDetailModal(c)"
                          >
                            Details
                          </button>
                        </div>
                      </div>
                    </div>

                    <!-- Our page reply (nested) -->
                    <div
                      v-if="c.comment_reply?.trim()"
                      class="flex gap-2 ms-5 py-1"
                    >
                      <span class="i-lucide-reply w-3 h-3 mt-1 text-n-brand shrink-0" />
                      <div class="flex-1 min-w-0">
                        <div class="inline-block rounded-xl bg-blue-50 dark:bg-blue-950/20 px-2.5 py-1.5 max-w-full border border-blue-200/40 dark:border-blue-500/15">
                          <span class="text-[11px] font-medium text-blue-600 dark:text-blue-400 me-1.5">Your page</span>
                          <span class="text-[12px] text-n-slate-12 break-words">{{ c.comment_reply }}</span>
                        </div>
                        <!-- DM button appears after reply -->
                        <button
                          v-if="!c.dm_text?.trim()"
                          type="button"
                          class="mt-1 flex items-center gap-1 text-[11px] text-emerald-600 dark:text-emerald-400 hover:underline font-medium"
                          @click.stop="openDmDialog(c)"
                        >
                          <span class="i-lucide-send w-3 h-3" />
                          Send DM
                        </button>
                      </div>
                    </div>

                    <!-- DM sent (nested) -->
                    <div
                      v-if="c.dm_text?.trim()"
                      class="flex gap-2 ms-5 py-1"
                    >
                      <span class="i-lucide-send w-3 h-3 mt-1 text-emerald-500 dark:text-emerald-400 shrink-0" />
                      <div class="flex-1 min-w-0">
                        <div class="inline-block rounded-xl bg-emerald-50 dark:bg-emerald-950/20 px-2.5 py-1.5 max-w-full border border-emerald-200/40 dark:border-emerald-500/15">
                          <span class="text-[11px] font-medium text-emerald-600 dark:text-emerald-400 me-1.5">DM</span>
                          <span class="text-[12px] text-n-slate-12 break-words line-clamp-1">{{ c.dm_text }}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Collapse button (when expanded beyond default) -->
                <div v-if="isGroupExpanded(group, post.post_id)" class="px-3 pt-0.5">
                  <button
                    type="button"
                    class="w-full flex items-center justify-center gap-1.5 py-1 rounded-lg text-[11px] font-medium text-n-slate-10 hover:text-n-slate-12 hover:bg-n-alpha-2 transition-colors"
                    @click="collapseGroup(group, post.post_id)"
                  >
                    <span class="i-lucide-chevrons-down w-3 h-3" />
                    Collapse
                  </button>
                </div>

                <!-- Inline reply input -->
                <div class="px-3 pb-3 pt-1">
                  <div class="flex gap-2 items-center">
                    <input
                      :value="replyTexts[`${post.post_id}_${group.commenterId}`] || ''"
                      type="text"
                      class="flex-1 text-xs bg-n-alpha-1 border border-n-container rounded-lg px-3 py-1.5 text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-1 focus:ring-n-brand"
                      :placeholder="replyTargets[`${post.post_id}_${group.commenterId}`]
                        ? 'Reply to selected comment…'
                        : `Reply to ${group.name}…`"
                      @input="replyTexts[`${post.post_id}_${group.commenterId}`] = $event.target.value"
                      @keydown.enter.prevent="sendInlineReply(
                        replyTargets[`${post.post_id}_${group.commenterId}`] || getDefaultReplyTarget(visibleCommentsForGroup(group, post.post_id)),
                        `${post.post_id}_${group.commenterId}`
                      )"
                    />
                    <button
                      type="button"
                      :disabled="!(replyTexts[`${post.post_id}_${group.commenterId}`] || '').trim() || replyLoading[`${post.post_id}_${group.commenterId}`]"
                      class="p-1.5 rounded-lg transition-colors"
                      :class="(replyTexts[`${post.post_id}_${group.commenterId}`] || '').trim()
                        ? 'text-n-brand hover:bg-n-alpha-2'
                        : 'text-n-slate-10 cursor-not-allowed'"
                      @click="sendInlineReply(
                        replyTargets[`${post.post_id}_${group.commenterId}`] || getDefaultReplyTarget(visibleCommentsForGroup(group, post.post_id)),
                        `${post.post_id}_${group.commenterId}`
                      )"
                    >
                      <span
                        v-if="replyLoading[`${post.post_id}_${group.commenterId}`]"
                        class="i-lucide-loader-2 w-3.5 h-3.5 animate-spin"
                      />
                      <span v-else class="i-lucide-send w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>

    <!-- DM Dialog -->
    <Dialog
      ref="dmDialogRef"
      title="Send Direct Message"
      width="lg"
      :show-confirm-button="false"
      :show-cancel-button="false"
      @close="dmComment = null"
    >
      <div v-if="dmComment" class="space-y-4">
        <div class="flex items-center gap-2 text-sm text-n-slate-11">
          <span class="i-lucide-send w-4 h-4 text-emerald-500" />
          <span>
            Send DM to
            <strong class="text-n-slate-12">{{ dmComment.commenter_name || dmComment.commenter_username || dmComment.commenter_id }}</strong>
          </span>
        </div>
        <div class="p-3 rounded-xl bg-n-alpha-1 border border-n-container text-sm text-n-slate-11">
          <p class="text-[10px] font-medium text-n-slate-10 mb-1">Original comment:</p>
          {{ dmComment.comment_text }}
        </div>
        <textarea
          v-model="dmText"
          rows="4"
          placeholder="Type your DM message..."
          class="w-full px-3 py-2 text-sm bg-n-alpha-1 border border-n-container rounded-lg text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-1 focus:ring-n-brand resize-none"
        />
        <div class="flex justify-end gap-2">
          <button
            type="button"
            class="px-3 py-1.5 text-sm font-medium text-n-slate-11 hover:bg-n-alpha-2 rounded-lg transition-colors"
            @click="dmDialogRef?.close()"
          >
            Cancel
          </button>
          <button
            type="button"
            :disabled="!dmText.trim() || dmLoading"
            class="px-3 py-1.5 text-sm font-medium text-white bg-n-brand rounded-lg hover:opacity-90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-1.5"
            @click="sendDm()"
          >
            <span v-if="dmLoading" class="i-lucide-loader-2 w-3.5 h-3.5 animate-spin" />
            <span v-else class="i-lucide-send w-3.5 h-3.5" />
            Send DM
          </button>
        </div>
      </div>
    </Dialog>

    <!-- Detail Dialog -->
    <Dialog
      ref="detailDialogRef"
      title="Comment Details"
      width="2xl"
      :show-confirm-button="false"
      :show-cancel-button="false"
      @close="detailComment = null"
    >
      <div v-if="detailComment" class="space-y-4 max-h-[70vh] overflow-y-auto">
        <!-- Commenter info -->
        <div class="flex items-center gap-3">
          <div
            class="p-2.5 rounded-xl"
            :class="platformClasses(detailComment.platform)"
          >
            <span
              :class="detailComment.platform === 'instagram' ? 'i-lucide-instagram' : detailComment.platform === 'facebook' ? 'i-lucide-facebook' : 'i-lucide-message-square'"
              class="w-4 h-4"
            />
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <p class="font-semibold text-n-slate-12 truncate">
                {{ detailComment.commenter_name || detailComment.commenter_username || detailComment.commenter_id }}
              </p>
              <span
                v-if="detailCommenterHistory.length > 1"
                class="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded text-[10px] font-medium bg-amber-50 text-amber-600 dark:bg-amber-950/40 dark:text-amber-400"
              >
                <span class="i-lucide-repeat-2 w-3 h-3" />
                {{ detailCommenterHistory.length }}x
              </span>
            </div>
            <p
              v-if="detailComment.commenter_username"
              class="text-xs text-n-slate-10"
            >
              @{{ detailComment.commenter_username }}
            </p>
          </div>
          <span
            class="inline-flex items-center px-2 py-1 rounded text-xs font-medium"
            :class="statusColor(detailComment.status)"
          >
            {{ statusLabel(detailComment.status) }}
          </span>
        </div>

        <!-- Post info -->
        <div
          v-if="detailPostInfo?.message || detailPostInfo?.permalink"
          class="p-3 rounded-xl bg-violet-50 dark:bg-violet-950/20 border border-violet-200/50 dark:border-violet-800/40"
        >
          <div class="flex items-center gap-2 mb-2">
            <span class="i-lucide-layout-list w-3.5 h-3.5 text-violet-500" />
            <p class="text-xs font-medium text-violet-600 dark:text-violet-400">Post</p>
            <a
              v-if="detailPostInfo?.permalink"
              :href="detailPostInfo.permalink"
              target="_blank"
              rel="noopener noreferrer"
              class="ms-auto text-xs text-violet-500 hover:text-violet-700 dark:hover:text-violet-300 flex items-center gap-1"
            >
              <span class="i-lucide-external-link w-3 h-3" />
              Open
            </a>
          </div>
          <p
            v-if="detailPostInfo?.message"
            class="text-xs text-n-slate-11 line-clamp-3"
          >
            {{ detailPostInfo.message }}
          </p>
        </div>

        <!-- Original comment -->
        <div class="p-3 rounded-xl bg-n-alpha-1 border border-n-container">
          <p class="text-xs font-medium text-n-slate-10 mb-1">Comment</p>
          <p class="text-sm text-n-slate-12">{{ detailComment.comment_text }}</p>
        </div>

        <!-- Reply history -->
        <template v-if="parseReplyHistory(detailComment).length > 0">
          <div class="space-y-2">
            <p class="text-xs font-medium text-blue-600 dark:text-blue-400">
              Reply ({{ parseReplyHistory(detailComment).length }})
            </p>
            <div
              v-for="(entry, idx) in parseReplyHistory(detailComment)"
              :key="idx"
              class="p-3 rounded-xl bg-blue-50 dark:bg-blue-950/30 border border-blue-200/50 dark:border-blue-800/40"
            >
              <p class="text-sm text-n-slate-12">{{ entry.text }}</p>
              <div class="flex items-center gap-2 mt-1">
                <span v-if="entry.model" class="text-[10px] text-n-slate-10">Model: {{ entry.model }}</span>
                <span v-if="entry.timestamp" class="text-[10px] text-n-slate-10">{{ formatDate(entry.timestamp) }}</span>
              </div>
            </div>
          </div>
        </template>
        <template v-else-if="detailComment.comment_reply">
          <div class="p-3 rounded-xl bg-blue-50 dark:bg-blue-950/30 border border-blue-200/50 dark:border-blue-800/40">
            <p class="text-xs font-medium text-blue-600 dark:text-blue-400 mb-1">Reply</p>
            <p class="text-sm text-n-slate-12">{{ detailComment.comment_reply }}</p>
            <p v-if="detailComment.ai_model" class="text-[10px] text-n-slate-10 mt-1">Model: {{ detailComment.ai_model }}</p>
          </div>
        </template>

        <!-- DM info -->
        <div
          v-if="detailComment.dm_text"
          class="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200/50 dark:border-emerald-800/40"
        >
          <p class="text-xs font-medium text-emerald-600 dark:text-emerald-400 mb-1">DM</p>
          <p class="text-sm text-n-slate-12">{{ detailComment.dm_text }}</p>
          <p
            v-if="detailComment.dm_conversation_id"
            class="text-[10px] text-n-slate-10 mt-1"
          >
            Conversation: {{ detailComment.dm_conversation_id }}
          </p>
        </div>

        <!-- Error -->
        <div
          v-if="detailComment.error_message"
          class="p-3 rounded-xl bg-red-50 dark:bg-red-950/30 border border-red-200/40"
        >
          <p class="text-xs font-medium text-red-600 dark:text-red-400 mb-1">Error</p>
          <p class="text-xs text-red-700 dark:text-red-300">{{ detailComment.error_message }}</p>
        </div>

        <!-- Other comments by this user -->
        <div
          v-if="detailCommenterHistory.filter(x => x.id !== detailComment.id).length > 0"
          class="border-t border-n-container pt-3"
        >
          <p class="text-xs font-medium text-n-slate-10 mb-2 flex items-center gap-1.5">
            <span class="i-lucide-repeat-2 w-3.5 h-3.5" />
            Other comments by this user ({{ detailCommenterHistory.filter(x => x.id !== detailComment.id).length }})
          </p>
          <div class="space-y-1.5 max-h-48 overflow-y-auto">
            <div
              v-for="oc in detailCommenterHistory.filter(x => x.id !== detailComment.id).slice(0, detailHistoryVisible)"
              :key="oc.id"
              class="text-xs p-2 rounded-lg bg-n-alpha-1 flex items-start gap-2"
            >
              <span
                class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-medium shrink-0 mt-0.5"
                :class="statusColor(oc.status)"
              >
                {{ statusLabel(oc.status) }}
              </span>
              <p class="text-n-slate-11 line-clamp-1 flex-1">{{ oc.comment_text }}</p>
              <span class="text-n-slate-10 shrink-0">{{ formatDate(oc.created_at) }}</span>
            </div>
            <button
              v-if="detailCommenterHistory.filter(x => x.id !== detailComment.id).length > detailHistoryVisible"
              type="button"
              class="w-full flex items-center justify-center gap-1 py-1.5 rounded-lg text-[11px] font-medium text-n-brand hover:bg-n-alpha-2 transition-colors"
              @click="showMoreDetailHistory()"
            >
              <span class="i-lucide-chevrons-down w-3 h-3" />
              Show {{ Math.min(detailCommenterHistory.filter(x => x.id !== detailComment.id).length - detailHistoryVisible, 5) }} more
            </button>
          </div>
        </div>

        <!-- Manual reply form -->
        <div class="border-t border-n-container pt-4">
          <p class="text-sm font-medium text-n-slate-12 mb-2">Manual Reply</p>
          <textarea
            v-model="detailManualReply"
            rows="3"
            placeholder="Type your reply..."
            class="w-full px-3 py-2 text-sm bg-n-alpha-1 border border-n-container rounded-lg text-n-slate-12 placeholder:text-n-slate-10 focus:outline-none focus:ring-1 focus:ring-n-brand resize-none"
          />
          <div class="flex justify-end mt-3 gap-2">
            <button
              type="button"
              class="px-3 py-1.5 text-sm font-medium text-n-slate-11 hover:bg-n-alpha-2 rounded-lg transition-colors"
              @click="detailDialogRef?.close()"
            >
              Cancel
            </button>
            <button
              type="button"
              :disabled="!detailManualReply.trim() || detailReplyLoading"
              class="px-3 py-1.5 text-sm font-medium text-white bg-n-brand rounded-lg hover:opacity-90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-1.5"
              @click="sendDetailReply()"
            >
              <span v-if="detailReplyLoading" class="i-lucide-loader-2 w-3.5 h-3.5 animate-spin" />
              <span v-else class="i-lucide-send w-3.5 h-3.5" />
              Reply
            </button>
          </div>
        </div>

        <!-- Timestamps -->
        <div class="text-[10px] text-n-slate-10 flex flex-wrap gap-4">
          <span>Created: {{ formatDate(detailComment.created_at) }}</span>
          <span v-if="detailComment.updated_at">Updated: {{ formatDate(detailComment.updated_at) }}</span>
          <span v-if="detailComment.post_id">Post: {{ detailComment.post_id }}</span>
          <span v-if="detailComment.comment_id">Comment ID: {{ detailComment.comment_id }}</span>
        </div>
      </div>
    </Dialog>
  </div>
</template>

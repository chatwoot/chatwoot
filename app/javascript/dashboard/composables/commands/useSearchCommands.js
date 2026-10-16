import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { usePolicy } from 'dashboard/composables/usePolicy';
import SearchAPI from 'dashboard/api/search';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import {
  ROLES,
  CONVERSATION_PERMISSIONS,
  CONTACT_PERMISSIONS,
  PORTAL_PERMISSIONS,
} from 'dashboard/constants/permissions';
import { conversationUrl, frontendURL } from 'dashboard/helper/URLHelper';
import { fuzzyScore } from '@bysivin/jumpbar';

const LIMIT = 6;

export function useSearchCommands() {
  const { t } = useI18n();
  const router = useRouter();
  const { checkPermissions, isFeatureFlagEnabled } = usePolicy();

  const accountId = useMapGetter('getCurrentAccountId');
  const loadedConversations = useMapGetter('getAllConversations');
  const getInbox = useMapGetter('inboxes/getInbox');

  const canSearchConversations = () =>
    checkPermissions([...ROLES, ...CONVERSATION_PERMISSIONS]);
  const canSearchContacts = () =>
    checkPermissions([...ROLES, CONTACT_PERMISSIONS]);
  const canSearchArticles = () =>
    isFeatureFlagEnabled(FEATURE_FLAGS.HELP_CENTER) &&
    checkPermissions([...ROLES, PORTAL_PERMISSIONS]);

  const conversationItem = ({ id, name, thumbnail, inboxName, snippet }) => ({
    id: `conversation-${id}`,
    title: name,
    subtitle: snippet?.replace(/\s+/g, ' ').trim(),
    badge: inboxName,
    section: t('COMMAND_BAR.SECTIONS.CONVERSATIONS'),
    avatar: { name, src: thumbnail },
    run: () =>
      router.push(
        frontendURL(conversationUrl({ accountId: accountId.value, id }))
      ),
  });

  const searchLoadedConversations = ({ text }) => {
    if (!canSearchConversations()) return [];

    return loadedConversations.value
      .map(conversation => ({
        conversation,
        score: fuzzyScore(
          text,
          `${conversation.meta.sender.name} ${conversation.id}`
        ),
      }))
      .filter(entry => entry.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, LIMIT)
      .map(({ conversation }) =>
        conversationItem({
          id: conversation.id,
          name: conversation.meta.sender.name,
          thumbnail: conversation.meta.sender.thumbnail,
          inboxName: getInbox.value(conversation.inbox_id)?.name,
          snippet: conversation.last_non_activity_message?.content,
        })
      );
  };

  const searchConversations = async ({ text, signal }) => {
    if (!canSearchConversations()) return [];

    const { data } = await SearchAPI.conversations({ q: text, signal });
    return data.payload.conversations.slice(0, LIMIT).map(result =>
      conversationItem({
        id: result.id,
        name: result.contact?.name,
        thumbnail: result.contact?.thumbnail,
        inboxName: result.inbox?.name,
        snippet: result.message?.content,
      })
    );
  };

  const searchContacts = async ({ text, signal }) => {
    if (!canSearchContacts()) return [];

    const { data } = await SearchAPI.contacts({ q: text, signal });
    return data.payload.contacts.slice(0, LIMIT).map(contact => ({
      id: `contact-${contact.id}`,
      title: contact.name,
      subtitle: contact.email || contact.phone_number,
      section: t('COMMAND_BAR.SECTIONS.CONTACTS'),
      avatar: { name: contact.name, src: contact.thumbnail },
      run: () =>
        router.push(
          frontendURL(`accounts/${accountId.value}/contacts/${contact.id}`)
        ),
    }));
  };

  const searchArticles = async ({ text, signal }) => {
    if (!canSearchArticles()) return [];

    const { data } = await SearchAPI.articles({ q: text, signal });
    return data.payload.articles.slice(0, LIMIT).map(article => ({
      id: `article-${article.id}`,
      title: article.title,
      subtitle: article.category_name,
      section: t('COMMAND_BAR.SECTIONS.ARTICLES'),
      icon: 'i-lucide-file-text',
      run: () =>
        router.push(
          frontendURL(
            `accounts/${accountId.value}/portals/${article.portal_slug}/${article.locale}/articles/edit/${article.id}`
          )
        ),
    }));
  };

  const searchEverything = ({ text }) => {
    if (!canSearchConversations() && !canSearchContacts()) return [];

    return [
      {
        id: 'search_everything',
        title: t('COMMAND_BAR.COMMANDS.SEE_ALL_RESULTS', { query: text }),
        icon: 'i-lucide-search',
        run: () => router.push({ name: 'search', query: { q: text } }),
      },
    ];
  };

  return {
    searchLoadedConversations,
    searchConversations,
    searchContacts,
    searchArticles,
    searchEverything,
  };
}

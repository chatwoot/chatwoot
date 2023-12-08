import Dexie from 'dexie';

const db = new Dexie('ConversationDatabase');
db.version(1).stores({
  conversations: '++id,inboxId,teamId,assigneeId',
  contacts: '++id,name,email,phone_number,identifier',
  messages: '++id,content,message_type',
});

export default db;

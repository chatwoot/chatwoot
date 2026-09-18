# Chatwoot domain language

This glossary records the language used for account data management in Chatwoot.

## Data management

**Data import**: An account-scoped operation that brings records from an external source into Chatwoot. Its source and the kinds of records it imports are separate concepts.

**Import source**: The origin of the records being imported, such as an uploaded contact CSV, Intercom, or Freshdesk.
_Avoid_: Using the source name as the name of the imported record type.

**File import**: A data import whose source is a file supplied by a user. The contact file format covered by this feature is CSV.

**Integration import**: A data import that reads records from an external service, such as Intercom or Freshdesk.

**Import item**: One source record tracked within a data import, with its own processing outcome. A contact CSV record is one import item even when it updates an existing contact.

**Import attempt**: One execution of a data import, including its background processing. Resuming an interrupted import starts another attempt of the same import.
_Avoid_: Using “new import” for a retry of an existing import.

**Data export**: An account-scoped operation that produces a downloadable representation of selected Chatwoot records.

**Export scope**: The selection of records requested for an export, such as all eligible contacts, a label, or a set of contact filters.

**Rejected row**: A contact CSV record that could be read but could not be applied because its values or relationships were invalid.
_Avoid_: Using “skipped” to imply that a rejected row succeeded.

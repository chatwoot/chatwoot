### 2.7.0 (2025/07/20)

* [#554](https://github.com/slack-ruby/slack-ruby-client/pull/557): Require Faraday >= 2.0.1 - [@anrichvs](https://github.com/AnrichVS).
* [#559](https://github.com/slack-ruby/slack-ruby-client/pull/559): Enable name-to-id translation of non-public channels - [@eizengan](https://github.com/eizengan).
* [#560](https://github.com/slack-ruby/slack-ruby-client/pull/560): Name-to-id translation can supply all sensible list options - [@eizengan](https://github.com/eizengan).
* [#561](https://github.com/slack-ruby/slack-ruby-client/issues/563): Raise InvalidSignature when verifying a request without a signature - [@wesleyjellis](https://github.com/wesleyjellis).
* [#567](https://github.com/slack-ruby/slack-ruby-client/pull/567): Add support for multiple files in `files_upload_v2` - [@dblock](https://github.com/dblock).

### 2.6.0 (2025/05/24)

* [#549](https://github.com/slack-ruby/slack-ruby-client/pull/549): Add group ID formatting support for message mentions - [@n0h0](https://github.com/n0h0).
* [#553](https://github.com/slack-ruby/slack-ruby-client/pull/553): Use `secure_compare` during signature verification - [@hieuk09](https://github.com/hieuk09).
* [#555](https://github.com/slack-ruby/slack-ruby-client/pull/555): Make page size in resolving IDs configurable - [@eizengan](https://github.com/eizengan).
* [#547](https://github.com/slack-ruby/slack-ruby-client/pull/547): Update API from [slack-api-ref@1ee282e](https://github.com/slack-ruby/slack-api-ref/commit/1ee282e) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).

### 2.5.2 (2025/02/19)

* [#548](https://github.com/slack-ruby/slack-ruby-client/pull/548): Fix: `files_upload_v2` with `#channel` - [@dblock](https://github.com/dblock).

### 2.5.1 (2025/02/11)

* [#542](https://github.com/slack-ruby/slack-ruby-client/pull/542): Add support for ruby 3.4 - [@dblock](https://github.com/dblock).
* [#544](https://github.com/slack-ruby/slack-ruby-client/pull/544): Fix: do not resolve channel name for `chat_postMessage` - [@dblock](https://github.com/dblock).

### 2.5.0 (2025/02/09)

* [#525](https://github.com/slack-ruby/slack-ruby-client/pull/525): Exclude spec files from gem package - [@amatsuda](https://github.com/amatsuda).
* [#527](https://github.com/slack-ruby/slack-ruby-client/pull/527): Explicitly require `racc` and `ostruct` - [@dblock](https://github.com/dblock).
* [#528](https://github.com/slack-ruby/slack-ruby-client/pull/528): Don't treat asterisks in list items as italic in markdown - [@rspeicher](https://github.com/rspeicher).
* [#530](https://github.com/slack-ruby/slack-ruby-client/pull/530): Specify dependency on `logger` - [@rwstauner](https://github.com/rwstauner).
* [#533](https://github.com/slack-ruby/slack-ruby-client/pull/533), [#536](https://github.com/slack-ruby/slack-ruby-client/pull/536): Added `files_upload_v2` - [@gregsaab](https://github.com/gregsaab).
* [#538](https://github.com/slack-ruby/slack-ruby-client/pull/538): Translate channel names and support an array of channels in `files_upload_v2` - [@dblock](https://github.com/dblock).
* [#540](https://github.com/slack-ruby/slack-ruby-client/pull/540): Added support for `channel` and `channel_id`, do not require channel in `files_upload_v2` - [@dblock](https://github.com/dblock).
* [#541](https://github.com/slack-ruby/slack-ruby-client/pull/541): Added samples for `oauth_v2` and `files_upload_v2` - [@dblock](https://github.com/dblock).
* [#524](https://github.com/slack-ruby/slack-ruby-client/pull/524): Update API from [slack-api-ref@3ec3c10](https://github.com/slack-ruby/slack-api-ref/commit/3ec3c10) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).

### 2.4.0 (2024/07/14)

* [#516](https://github.com/slack-ruby/slack-ruby-client/pull/516): Add support for Ruby 3.3 - [@olleolleolle](https://github.com/olleolleolle).
* [#520](https://github.com/slack-ruby/slack-ruby-client/pull/520): Add support for basic markdown formatting - [@nbgoodall](https://github.com/nbgoodall).
* [#523](https://github.com/slack-ruby/slack-ruby-client/pull/523): Fix coveralls handling parallel jobs - [@dblock](https://github.com/dblock).
* [#522](https://github.com/slack-ruby/slack-ruby-client/pull/522): Update API from [slack-api-ref@8a22e57](https://github.com/slack-ruby/slack-api-ref/commit/8a22e57) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).

### 2.3.0 (2024/01/31)

* [#494](https://github.com/slack-ruby/slack-ruby-client/pull/494): Configure Dependabot to update GitHub Actions - [@olleolleolle](https://github.com/olleolleolle).
* [#508](https://github.com/slack-ruby/slack-ruby-client/pull/508): Fix `Slack::Events::Request#verify!` compatibility with Rack 3.x - [@dblock](https://github.com/dblock).
* [#503](https://github.com/slack-ruby/slack-ruby-client/pull/503): Update Slack API Update API from [slack-api-ref@bc545649](https://github.com/slack-ruby/slack-api-ref/commit/bc545649) - [@dblock](https://github.com/dblock).
* [#504](https://github.com/slack-ruby/slack-ruby-client/pull/504): Update API from [slack-api-ref@bc54564](https://github.com/slack-ruby/slack-api-ref/commit/bc54564) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).

### 2.2.0 (2023/09/17)

* [#458](https://github.com/slack-ruby/slack-ruby-client/pull/458): Add workflow for automatic API updates - [@duffn](https://github.com/duffn).
* [#455](https://github.com/slack-ruby/slack-ruby-client/pull/455): Update Slack API: Added pagination to `team.accessLogs` and `AppsDatastore` methods - [@marfoldi](https://github.com/marfoldi).
* [#454](https://github.com/slack-ruby/slack-ruby-client/pull/454): Added `Slack::Messages::Formatting#escape` - [@marfoldi](https://github.com/marfoldi).
* [#452](https://github.com/slack-ruby/slack-ruby-client/pull/452): Automatically generate Web API multi-argument requirements from docs - [@jmanian](https://github.com/jmanian).
* [#448](https://github.com/slack-ruby/slack-ruby-client/pull/448), [#453](https://github.com/slack-ruby/slack-ruby-client/pull/453): Automatically convert more Web API arguments to JSON-encoded strings - [@jmanian](https://github.com/jmanian).
* [#465](https://github.com/slack-ruby/slack-ruby-client/pull/465): Update API from [slack-api-ref@878be8f](https://github.com/slack-ruby/slack-api-ref/commit/878be8f) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).
* [#473](https://github.com/slack-ruby/slack-ruby-client/pull/473): Update API from [slack-api-ref@a29b520](https://github.com/slack-ruby/slack-api-ref/commit/a29b520) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).
* [#474](https://github.com/slack-ruby/slack-ruby-client/pull/474): Update API from [slack-api-ref@629967e](https://github.com/slack-ruby/slack-api-ref/commit/629967e) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).
* [#475](https://github.com/slack-ruby/slack-ruby-client/pull/475): Update API from [slack-api-ref@977dad5](https://github.com/slack-ruby/slack-api-ref/commit/977dad5) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).
* [#476](https://github.com/slack-ruby/slack-ruby-client/pull/476): Update API from [slack-api-ref@d0b2989](https://github.com/slack-ruby/slack-api-ref/commit/d0b2989) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).
* [#478](https://github.com/slack-ruby/slack-ruby-client/pull/478): Update API from [slack-api-ref@d797055](https://github.com/slack-ruby/slack-api-ref/commit/d797055) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).
* [#480](https://github.com/slack-ruby/slack-ruby-client/pull/480): Add common message formatting utilities - [@chrisbloom7](https://github.com/chrisbloom7).
* [#481](https://github.com/slack-ruby/slack-ruby-client/pull/481): Update API from [slack-api-ref@7c22d0b](https://github.com/slack-ruby/slack-api-ref/commit/7c22d0b) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).
* [#488](https://github.com/slack-ruby/slack-ruby-client/pull/488): Update API from [slack-api-ref@a45def2](https://github.com/slack-ruby/slack-api-ref/commit/a45def2) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).
* [#490](https://github.com/slack-ruby/slack-ruby-client/pull/490): Add changelog uri to gemspec - [@MatheusRich](https://github.com/MatheusRich).
* [#491](https://github.com/slack-ruby/slack-ruby-client/pull/491): Added code coverage - [@dblock](https://github.com/dblock).
* [#486](https://github.com/slack-ruby/slack-ruby-client/pull/486): Async handler support for Slack::RealTime::Config and Client - [@milestruecar](https://github.com/milestruecar).
* [#489](https://github.com/slack-ruby/slack-ruby-client/pull/489): Update API from [slack-api-ref@0d3f0b6](https://github.com/slack-ruby/slack-api-ref/commit/0d3f0b6) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).
* [#493](https://github.com/slack-ruby/slack-ruby-client/pull/493): Update API from [slack-api-ref@f2e768a](https://github.com/slack-ruby/slack-api-ref/commit/f2e768a) - [@slack-ruby-ci-bot](https://github.com/apps/slack-ruby-ci-bot).

### 2.1.0 (2023/03/17)

* [#440](https://github.com/slack-ruby/slack-ruby-client/pull/440): Added Enterprise support [via TideLift](https://tidelift.com/subscription/request-a-demo?utm_source=rubygems-slack-ruby-client&utm_medium=referral&utm_campaign=enterprise) - [@dblock](https://github.com/dblock).
* [#436](https://github.com/slack-ruby/slack-ruby-client/pull/436): Removed dependency on unused websocket-driver - [@blowfishpro](https://github.com/blowfishpro).
* [#434](https://github.com/slack-ruby/slack-ruby-client/pull/434): Fixed incompatibility with Faraday >= 2.7.0 and GLI usage in the `slack` script - [@blowfishpro](https://github.com/blowfishpro).
* [#446](https://github.com/slack-ruby/slack-ruby-client/pull/446): Added support for Ruby 3.2 - [@duffn](https://github.com/duffn).
* [#447](https://github.com/slack-ruby/slack-ruby-client/pull/447): Added `admin_conversations_bulkArchive`, `admin_conversations_bulkDelete`, `admin_conversations_bulkMove`, `admin_conversations_convertToPublic`, `admin_conversations_lookup`, `admin_roles_addAssignments`, `admin_roles_listAssignments`, `admin_roles_removeAssignments`, `functions_workflows_steps_list`, and `functions_workflows_steps_responses_export` - [@dblock](https://github.com/dblock).
* [#447](https://github.com/slack-ruby/slack-ruby-client/pull/447): Added pagination to `team_accessLogs` - [@dblock](https://github.com/dblock).

### 2.0.0 (2022/10/19)

* [#416](https://github.com/slack-ruby/slack-ruby-client/pull/416): Removes default values for Faraday's SSL settings `ca_file` and `ca_path` - [@irphilli](https://github.com/irphilli).
* [#417](https://github.com/slack-ruby/slack-ruby-client/pull/417): Raise rescuable errors - [@zachahn](https://github.com/zachahn).
* [#419](https://github.com/slack-ruby/slack-ruby-client/pull/419): Use `rtm.connect` instead of `rtm.start` - [@kstole](https://github.com/kstole).
* [#420](https://github.com/slack-ruby/slack-ruby-client/pull/420): Fix default store missing event hooks - [@kstole](https://github.com/kstole).
* [#421](https://github.com/slack-ruby/slack-ruby-client/pull/421): Added `admin_audit_anomaly_allow_getItem`, `admin_audit_anomaly_allow_updateItem`, `files_completeUploadExternal`, `files_getUploadURLExternal` - [@kstole](https://github.com/kstole).
* [#421](https://github.com/slack-ruby/slack-ruby-client/pull/421): Raise error for mutually exclusive required options in views methods - [@kstole](https://github.com/kstole).
* [#424](https://github.com/slack-ruby/slack-ruby-client/pull/424): Updated real_time.rake to remove outdated event hooks and organize alphabetically - [@kstole](https://github.com/kstole).
* [#423](https://github.com/slack-ruby/slack-ruby-client/pull/423): Changed default store to `Slack::RealTime::Stores::Starter` and removed `Slack::RealTime::Store` - [@kstole](https://github.com/kstole).
* [#423](https://github.com/slack-ruby/slack-ruby-client/pull/423): Replaced `channels` and `groups` caches with `public_channels` and `private_channels` - [@kstole](https://github.com/kstole).
* [#423](https://github.com/slack-ruby/slack-ruby-client/pull/423): Added configurable `hello` hook to initialize `Slack::RealTime::Stores::Store` upon successful connection - [@kstole](https://github.com/kstole).
* [#425](https://github.com/slack-ruby/slack-ruby-client/pull/425): Updated web.rake to remove outdated endpoints and commands - [@kstole](https://github.com/kstole).

### 1.1.0 (2022/06/05)

* [#400](https://github.com/slack-ruby/slack-ruby-client/pull/400): Replace Travis-CI with GitHub Actions - [@dblock](https://github.com/dblock).
* [#401](https://github.com/slack-ruby/slack-ruby-client/pull/401): Upgraded RuboCop to 1.26.0 - [@dblock](https://github.com/dblock).
* [#401](https://github.com/slack-ruby/slack-ruby-client/pull/401): Added support for Ruby 3.1.1 - [@dblock](https://github.com/dblock).
* [#405](https://github.com/slack-ruby/slack-ruby-client/pull/405): Added `admin_apps_requests_cancel`, `admin_users_unsupportedVersions_export`, `bookmarks_add`, `bookmarks_edit`, `bookmarks_list`, `bookmarks_remove` - [@dblock](https://github.com/dblock).
* [#404](https://github.com/slack-ruby/slack-ruby-client/pull/404): Update `chat_update` method not to raise error with parameter which contains only `reply_broadcast` - [@colorbox](https://github.com/colorbox).
* [#406](https://github.com/slack-ruby/slack-ruby-client/pull/406): Update Faraday to `>= 2.0` - [@schinery](https://github.com/slack-ruby/slack-ruby-client/pull/406).
* [#406](https://github.com/slack-ruby/slack-ruby-client/pull/406): Removed support for Ruby 2.5 and 2.6 - [@schinery](https://github.com/slack-ruby/slack-ruby-client/pull/406).
* [#406](https://github.com/slack-ruby/slack-ruby-client/pull/406): Test against latest Ruby 2.7, 3.0 and 3.1 - [@schinery](https://github.com/slack-ruby/slack-ruby-client/pull/406).
* [#406](https://github.com/slack-ruby/slack-ruby-client/pull/406): Upgraded RuboCop to 1.26.1 and lock to version - [@schinery](https://github.com/slack-ruby/slack-ruby-client/pull/406).
* [#406](https://github.com/slack-ruby/slack-ruby-client/pull/406): Updated Danger PR Linter GitHub action to use separate `Gemfile`  - [@schinery](https://github.com/slack-ruby/slack-ruby-client/pull/406).

### 1.0.0 (2021/12/21)

* [#394](https://github.com/slack-ruby/slack-ruby-client/pull/394): Added support for Ruby 3.0 - [@dblock](https://github.com/dblock).
* [#394](https://github.com/slack-ruby/slack-ruby-client/pull/394): Upgraded to RuboCop 0.93.1 - [@dblock](https://github.com/dblock).
* [#393](https://github.com/slack-ruby/slack-ruby-client/pull/393): Removed deprecated `oauth_token`, and leftover traces of `channels` and `groups` APIs - [@dblock](https://github.com/dblock).
* [#393](https://github.com/slack-ruby/slack-ruby-client/pull/393): Added `admin_auth_policy_assignEntities`, `admin_auth_policy_getEntities` and `admin_auth_policy_removeEntities` `admin_conversations_disconnectShared`, `admin_users_session_clearSettings`, `admin_users_session_getSettings`, `admin_users_session_resetBulk`, `admin_users_session_setSettings`, `apps_manifest_create`, `apps_manifest_delete`, `apps_manifest_export`, `apps_manifest_update`, `apps_manifest_validate`, `conversations_acceptSharedInvite`, `conversations_approveSharedInvite`, `conversations_declineSharedInvite`, `conversations_inviteShared`, `conversations_listConnectInvites`, `oauth_v2_exchange`, `openid_connect_token`, `openid_connect_userInfo`, `team_billing_info`, `team_preferences_list`, `tooling_tokens_rotate` - [@dblock](https://github.com/dblock).
* [#386](https://github.com/slack-ruby/slack-ruby-client/pull/386): Gemspec: drop unused `test_files` directive - [@olleolleolle](https://github.com/olleolleolle).
* [#380](https://github.com/slack-ruby/slack-ruby-client/pull/380): Updates to server error classes and hierarchy - [@jmanian](https://github.com/jmanian).
* [#387](https://github.com/slack-ruby/slack-ruby-client/pull/387): Send token in Authorization header - [@chrisbloom7](https://github.com/chrisbloom7).

### 0.17.0 (2021/03/07)

* [#370](https://github.com/slack-ruby/slack-ruby-client/pull/370): Removed deprecated `im_`, `mpim_`, `channels_`, and `groups_` methods - [@dblock](https://github.com/dblock).
* [#368](https://github.com/slack-ruby/slack-ruby-client/pull/368): Removed `admin_conversations_whitelist` and `admin_conversations_disconnectShared` - [@dblock](https://github.com/dblock).
* [#359](https://github.com/slack-ruby/slack-ruby-client/pull/359): Handle non-JSON 500 errors - [@agrobbin](https://github.com/agrobbin).
* [#360](https://github.com/slack-ruby/slack-ruby-client/pull/360): Remove faye-websocket from the concurrency detection error message - [@dblock](https://github.com/dblock).
* [#369](https://github.com/slack-ruby/slack-ruby-client/pull/369): Support rack requests in `Slack::Events::Request` - [@wedgex](https://github.com/wedgex).

### 0.16.0 (2021/01/24)

* [#350](https://github.com/slack-ruby/slack-ruby-client/pull/350): Handle server errors such as timeouts & non-JSON responses - [@ojab](https://github.com/ojab).
* [#354](https://github.com/slack-ruby/slack-ruby-client/pull/354): Rewind body after checking request signature - [@sunny](https://github.com/sunny).
* [#355](https://github.com/slack-ruby/slack-ruby-client/pull/355), [#357](https://github.com/slack-ruby/slack-ruby-client/pull/357): Removed `celluloid-io` and `faye-websocket` support - [@wasabigeek](https://github.com/wasabigeek).
* [#356](https://github.com/slack-ruby/slack-ruby-client/pull/356): Added `admin_apps_clearResolution`, `admin_conversations_getCustomRetention`, `admin_conversations_removeCustomRetention`, `admin_conversations_setCustomRetention`, `admin_users_session_list` and `auth_teams_list` endpoints - [@dblock](https://github.com/dblock).
* [#348](https://github.com/slack-ruby/slack-ruby-client/pull/348): Added `admin_conversations_archive`, `admin_conversations_convertToPrivate`, `admin_conversations_create`, `admin_conversations_delete`, `admin_conversations_disconnectShared`, `admin_conversations_getConversationPrefs`, `admin_conversations_getTeams`, `admin_conversations_invite`, `admin_conversations_rename`, `admin_conversations_search`, `admin_conversations_setConversationPrefs`, `admin_conversations_unarchive`, `admin_conversations_ekm_listOriginalConnectedChannelInfo`, `admin_users_session_invalidate`, `apps_event_authorizations_list`, `conversations_mark`, `workflows_stepCompleted`, `workflows_stepFailed` and `workflows_updateStep` endpoints - [@wasabigeek](https://github.com/wasabigeek).

### 0.15.1 (2020/9/3)

* [#336](https://github.com/slack-ruby/slack-ruby-client/pull/336): Fix: handle nil events - [@pyama86](https://github.com/pyama86).
* [#339](https://github.com/slack-ruby/slack-ruby-client/pull/339): Fix: `channel_not_found` resolving channel IDs with 100+ channels - [@dblock](https://github.com/dblock).
* [#340](https://github.com/slack-ruby/slack-ruby-client/pull/340): Added `adapter` configuration setting to change the `Faraday` HTTP adapter - [@watsonjon](https://github.com/watsonjon).

### 0.15.0 (2020/7/26)

* [#322](https://github.com/slack-ruby/slack-ruby-client/pull/322): Cache `Faraday::Connection` for persistent adapters - [@drbrain](https://github.com/drbrain).
* [#324](https://github.com/slack-ruby/slack-ruby-client/pull/324): Require Faraday >= 1.0 - [@dblock](https://github.com/dblock).
* [#324](https://github.com/slack-ruby/slack-ruby-client/pull/324): Upgrade slack-ruby-danger, rubocop, rubocop-rspec and rubocop-performance - [@dblock](https://github.com/dblock).
* [#327](https://github.com/slack-ruby/slack-ruby-client/pull/327), [#326](https://github.com/slack-ruby/slack-ruby-client/pull/326): Added `admin_conversations_whitelist`, `admin_usergroups`, `calls` and `calls_participants` endpoints  - [@wasabigeek](https://github.com/wasabigeek).
* [#329](https://github.com/slack-ruby/slack-ruby-client/pull/329): Log when methods are deprecated - [@wasabigeek](https://github.com/wasabigeek).
* [#325](https://github.com/slack-ruby/slack-ruby-client/pull/325): Remove activesupport dependency - [@ianks](https://github.com/ianks).
* [#331](https://github.com/slack-ruby/slack-ruby-client/pull/331): Use `conversations_list` instead of deprecated `channels_list`. Added `admin_conversations_restrictAccess_addGroup`, `admin_conversations_restrictAccess_listGroups` and `admin_conversations_restrictAccess_removeGroup` endpoints - [@wasabigeek](https://github.com/wasabigeek).

### 0.14.6 (2020/3/28)

* [#305](https://github.com/slack-ruby/slack-ruby-client/pull/305): Added `admin_inviteRequests_approve`, `admin_inviteRequests_deny`, `admin_inviteRequests_list`, `admin_inviteRequests_approved_list`, `admin_inviteRequests_denied_list`, `admin_teams_create`, `admin_teams_list`, `admin_teams_admins_list`, `admin_teams_owners_list`, `admin_teams_settings`, `admin_teams_settings_setIcon`, `admin_teams_settings_setName`, `admin_teams_settings_setDescription`, `admin_users_assign`, `admin_users_invite`, `admin_users_remove`, `admin_users_setAdmin`, `admin_users_setOwner` and `admin_users_setRegular` endpoints - [@manuelmeurer](https://github.com/manuelmeurer).
* [#311](https://github.com/slack-ruby/slack-ruby-client/pull/311): Made Web API `response_metadata` more accessible in errors - [@jmanian](https://github.com/jmanian).
* [#312](https://github.com/slack-ruby/slack-ruby-client/pull/312): Added specific error classes for Web API - [@jmanian](https://github.com/jmanian).
* [#313](https://github.com/slack-ruby/slack-ruby-client/pull/313): Added `admin_teams_settings_info`, `admin_users_list`, `admin_users_setExpiration`, `admin_apps_approved_list`, `admin_apps_restricted_list`, `admin_conversations_setTeams`, `admin_emoji_add`, `admin_emoji_addAlias`, `admin_emoji_list`, `admin_emoji_remove` and `admin_emoji_rename` endpoints - [@dblock](https://github.com/dblock).

### 0.14.5 (2019/12/23)

* [#293](https://github.com/slack-ruby/slack-ruby-client/pull/293): Rubocop auto-correct and comprehensive todo - [@jcraigk](https://github.com/jcraigk).
* [#297](https://github.com/slack-ruby/slack-ruby-client/pull/297): Various Rubocop fixes - [@jcraigk](https://github.com/jcraigk).
* [#298](https://github.com/slack-ruby/slack-ruby-client/pull/298): Added `admin_apps`, `admin_app_requests` and `views` endpoints - [@jmanian](https://github.com/jmanian).
* [#303](https://github.com/slack-ruby/slack-ruby-client/pull/303): Added `oauth_v2_access` and `views_publish` endpoints - [@jwright](https://github.com/jwright).
* [#309](https://github.com/slack-ruby/slack-ruby-client/pull/309): Stop ping on `inactive_account` and `invalid_auth` - [@dblock](https://github.com/dblock).

### 0.14.4 (2019/7/28)

* [#289](https://github.com/slack-ruby/slack-ruby-client/pull/289): Fix reconnects when ping timers under/overshoot - [@georgyangelov](https://github.com/georgyangelov).
* [#290](https://github.com/slack-ruby/slack-ruby-client/pull/290): Expose Slack::RealTime::Client.logger accessor publicly - [@jcraigk](https://github.com/jcraigk).

### 0.14.3 (2019/7/23)

* [#279](https://github.com/slack-ruby/slack-ruby-client/pull/279): Prevent ping worker from dying on unexpected errors - [@dblock](https://github.com/dblock).
* [#281](https://github.com/slack-ruby/slack-ruby-client/pull/281): Added `admin_users_session_reset` to Web API - [@dblock](https://github.com/dblock).
* [#283](https://github.com/slack-ruby/slack-ruby-client/pull/283): Fail when used with incompatible async-websocket > 0.8.0 - [@dblock](https://github.com/dblock).
* [#284](https://github.com/slack-ruby/slack-ruby-client/pull/284): Include team id, name and domain in log output - [@dblock](https://github.com/dblock).

### 0.14.2 (2019/4/12)

* [#256](https://github.com/slack-ruby/slack-ruby-client/pull/256): Added support for specifying signing secrets on a per-request basis via optional parameters to the `Slack::Events::Request` constructor - [@gabrielmdeal](https://github.com/gabrielmdeal).
* [#257](https://github.com/slack-ruby/slack-ruby-client/pull/257), [#262](https://github.com/slack-ruby/slack-ruby-client/pull/262): Fixed occasional failures to reconnect - [@ioquatix](https://github.com/ioquatix), [@dblock](https://github.com/dblock).
* [#264](https://github.com/slack-ruby/slack-ruby-client/pull/264): Added `chat_scheduleMessage`, `chat_deleteScheduledMessage` and `chat_scheduledMessages_list` - [@dblock](https://github.com/dblock).
* [#264](https://github.com/slack-ruby/slack-ruby-client/pull/264): Removed `files_comments_add` and `files_comments_edit` - [@dblock](https://github.com/dblock).

### 0.14.1 (2019/2/26)

* [#254](https://github.com/slack-ruby/slack-ruby-client/issues/254): Fix: celluloid infinite reconnect loop - [@dblock](https://github.com/dblock).

### 0.14.0 (2019/2/25)

* [#238](https://github.com/slack-ruby/slack-ruby-client/issues/238): Added `Slack::Events::Request#verify!` to check whether an event request is coming from Slack - [@dblock](https://github.com/dblock).
* [#226](https://github.com/slack-ruby/slack-ruby-client/pull/226), [#232](https://github.com/slack-ruby/slack-ruby-client/pull/232), [#236](https://github.com/slack-ruby/slack-ruby-client/pull/236), [#234](https://github.com/slack-ruby/slack-ruby-client/pull/234): Added periodic ping that reconnects on failure - [@RodneyU215](https://github.com/RodneyU215), [@dblock](https://github.com/dblock), [@ioquatix](https://github.com/ioquatix).
* [#242](https://github.com/slack-ruby/slack-ruby-client/pull/242): Added `thread_ts` option to `chat_postEphemeral` - [@dblock](https://github.com/dblock).
* [#242](https://github.com/slack-ruby/slack-ruby-client/pull/242): Added `apps_uninstall` to Web API - [@dblock](https://github.com/dblock).
* [#244](https://github.com/slack-ruby/slack-ruby-client/pull/244): Implementing #restart for the celluloid socket class - [@RodneyU215](https://github.com/RodneyU215).
* [#246](https://github.com/slack-ruby/slack-ruby-client/pull/246): Added TOC to README and danger-toc - [@dblock](https://github.com/dblock).
* [#253](https://github.com/slack-ruby/slack-ruby-client/pull/253): Support for Block Kit - [@JrmKrb](https://github.com/JrmKrb).

### 0.13.1 (2018/9/30)

* [#228](https://github.com/slack-ruby/slack-ruby-client/pull/228): Replace `Thread` with `Actor` in Celluloid async support - [@dblock](https://github.com/dblock).

### 0.13.0 (2018/9/8)

* [#219](https://github.com/slack-ruby/slack-ruby-client/pull/219): Added support for `async-websocket` - [@dblock](https://github.com/dblock), [@ioquatix](https://github.com/ioquatix).
* [#224](https://github.com/slack-ruby/slack-ruby-client/pull/224): Celluloid async support now uses a thread per client - [@dblock](https://github.com/dblock).
* [#224](https://github.com/slack-ruby/slack-ruby-client/pull/224): Attempt to shutdown EventMachine if a reactor wasn't already running on start - [@dblock](https://github.com/dblock).

### 0.12.0 (2018/8/20)

* [#216](https://github.com/slack-ruby/slack-ruby-client/pull/216): Handle `Errno::ECONNRESET` and empty buffer reads with celluloid-io - [@dblock](https://github.com/dblock).
* [#215](https://github.com/slack-ruby/slack-ruby-client/pull/215): Web API `groups_list`, `files_info`, `mpim_list`, `reactions_list` and `stars_list` now support cursor pagination - [@hotwatermorning](https://github.com/hotwatermorning).
* [#215](https://github.com/slack-ruby/slack-ruby-client/pull/215): Added `apps_permissions_users_list` and `apps_permissions_users_request` - [@hotwatermorning](https://github.com/hotwatermorning).
* [#209](https://github.com/slack-ruby/slack-ruby-client/pull/209): Changed `chat_postEphemeral`to check for existence of either `text` or `attachments` - [@peterzhu2118](https://github.com/peterzhu2118).
* [#207](https://github.com/slack-ruby/slack-ruby-client/pull/207): Added `apps_permissions_resources_list` and `apps_permissions_scopes_list` - [@jmanian](https://github.com/jmanian).
* [#207](https://github.com/slack-ruby/slack-ruby-client/pull/207): Added `users_conversations` - [@jmanian](https://github.com/jmanian).
* [#206](https://github.com/slack-ruby/slack-ruby-client/pull/206): Fix 100% cpu usage in async examples - [@felixbuenemann](https://github.com/felixbuenemann).
* [#217](https://github.com/slack-ruby/slack-ruby-client/pull/217): Upgraded RuboCop to 0.58.2 - [@dblock](https://github.com/dblock).
* [#217](https://github.com/slack-ruby/slack-ruby-client/pull/217): No longer tested with Ruby 2.1, added 2.5 - [@dblock](https://github.com/dblock).

### 0.11.1 (2018/1/23)

* [#187](https://github.com/slack-ruby/slack-ruby-client/pull/187): Concatenate error message when multiple errors present - [@chrislopresto](https://github.com/chrislopresto).
* [#188](https://github.com/slack-ruby/slack-ruby-client/pull/188): Fixed `NoMethodError` when Slack is unavailable - [@sonicdoe](https://github.com/sonicdoe).
* [#196](https://github.com/slack-ruby/slack-ruby-client/pull/196): Added `users_lookupByEmail` - [@manuelmeurer](https://github.com/manuelmeurer).
* [#185](https://github.com/slack-ruby/slack-ruby-client/pull/185): Calling undocumented endpoints will now produce a warning - [@aviflombaum](https://github.com/aviflombaum).

### 0.11.0 (2017/11/25)

* [#173](https://github.com/slack-ruby/slack-ruby-client/issues/173): Added dialog support - [@alexagranov](https://github.com/alexagranov).
* [#176](https://github.com/slack-ruby/slack-ruby-client/issues/176): Drop dependency on `json` gem - [@seuros](https://github.com/seuros).
* [#177](https://github.com/slack-ruby/slack-ruby-client/pull/177): Fix api ref repo - [@manuelmeurer](https://github.com/manuelmeurer).
* [#180](https://github.com/slack-ruby/slack-ruby-client/pull/180): Upgraded RuboCop 0.51.0 - [@dblock](https://github.com/dblock).
* [#181](https://github.com/slack-ruby/slack-ruby-client/pull/181): Added `chat_getPermalink`, `migration_exchange` - [@dblock](https://github.com/dblock).
* [#182](https://github.com/slack-ruby/slack-ruby-client/pull/182): Added undocumented methods support with `channels_delete`, `chat_command`, `files_edit`, `files_share`, `users_admin_invite`, `users_admin_setInactive` and `users_prefs_get` - [@dblock](https://github.com/dblock).

### 0.10.0 (2017/9/19)

* [#169](https://github.com/slack-ruby/slack-ruby-client/pull/169): Added [Conversations API](https://api.slack.com/docs/conversations-api) - [@jmanian](https://github.com/jmanian).
* [#169](https://github.com/slack-ruby/slack-ruby-client/pull/169): Added `include_locale` parameter to several methods (`channels_info`, `groups_info`, `im_open`, `rtm_start`, `users_info`, `users_list`) - [@jmanian](https://github.com/jmanian).
* [#169](https://github.com/slack-ruby/slack-ruby-client/pull/169): Removed `groups_close` - [@jmanian](https://github.com/jmanian).
* [#167](https://github.com/slack-ruby/slack-ruby-client/pull/167): Added support for pausing between paginated requests that can cause Slack rate limiting - [@jmanian](https://github.com/jmanian).
* [#163](https://github.com/slack-ruby/slack-ruby-client/pull/164): Use `OpenSSL::X509::DEFAULT_CERT_DIR` and `OpenSSL::X509::DEFAULT_CERT_FILE` for default ca_cert and ca_file - [@leifcr](https://github.com/leifcr).
* [#161](https://github.com/slack-ruby/slack-ruby-client/pull/161): Added support for cursor pagination - [@dblock](https://github.com/dblock).
* [#162](https://github.com/slack-ruby/slack-ruby-client/pull/162): Gracefully close websocket on `Errno::EPIPE` - [@johanoskarsson](https://github.com/johanoskarsson).
* [#172](https://github.com/slack-ruby/slack-ruby-client/pull/172): Use `rtm.start` when store is a subclass of `Slack::RealTime::Stores::Store` (default) - [@kstole](https://github.com/kstole).

### 0.9.1 (2017/8/24)

* [#158](https://github.com/slack-ruby/slack-ruby-client/issues/158): Updated to latest slack-api-ref; Updated chat.3.update patch to reflect argument reordering; Added chat.4.postEphemeral patch to apply the attachments JSON fix (whitespace last line of diff matters! ;-) - [@alexagranov](https://github.com/alexagranov).

### 0.9.0 (2017/8/6)

* [#146](https://github.com/slack-ruby/slack-ruby-client/issues/146): Fix: `undefined method running?` and `ThreadError: Target thread must not be current thread` with `Celluloid::IO` - [@dblock](https://github.com/dblock).
* [#145](https://github.com/slack-ruby/slack-ruby-client/pull/145): Automatically select `rtm_connect` vs. `rtm_start` - [@dblock](https://github.com/dblock).
* [#154](https://github.com/slack-ruby/slack-ruby-client/pull/154): Raise a dedicated error class with 429 responses - [@greggroth](https://github.com/greggroth).
* [#154](https://github.com/slack-ruby/slack-ruby-client/pull/154): Namespace error classes under `Slack::Web::Api::Errors` module - [@greggroth](https://github.com/greggroth).

### 0.8.1 (2017/4/28)

* Added `exclude_members` option to `channels_list` Web API - [@dblock](https://github.com/dblock).
* Added `chat_unfurl` to Web API - [@dblock](https://github.com/dblock).
* Added `rtm_connect` to RTM API - [@dblock](https://github.com/dblock).
* Added `no_latest` support to `rm_start` RTM API - [@dblock](https://github.com/dblock).

### 0.8.0 (2017/3/12)

* [#135](https://github.com/slack-ruby/slack-ruby-client/issues/135): Added `timeout` and `open_timeout` options to Web API - [@dblock](https://github.com/dblock).
* [#134](https://github.com/slack-ruby/slack-ruby-client/issues/134): Set `start_options[:request][:timeout]`, used with `rtm.start` in `Slack::RealTime::Client`, to 180 seconds - [@dblock](https://github.com/dblock).
* [#136](https://github.com/slack-ruby/slack-ruby-client/pull/136): Pass request options in web client calls - [@dblock](https://github.com/dblock).
* [#121](https://github.com/slack-ruby/slack-ruby-client/pull/121): Fix: check that the current Celluloid actor is running before calling `terminate` - [@newdark](https://github.com/newdark).
* [#138](https://github.com/slack-ruby/slack-ruby-client/pull/138): Added `validate` option to `channels_create`, `channels_join`, `channels_rename`, `groups_create` and `groups_rename` Web APIs - [@dblock](https://github.com/dblock).
* [#138](https://github.com/slack-ruby/slack-ruby-client/pull/138): Removed `channel` option from `files_comments_add` Web API - [@dblock](https://github.com/dblock).

### 0.7.9 (2017/2/9)

* [#132](https://github.com/slack-ruby/slack-ruby-client/issues/132): Fix: you are setting a key that conflicts with a built-in method Slack::Messages::Message#presence - [@dblock](https://github.com/dblock).

### 0.7.8 (2017/1/23)

* [#127](https://github.com/slack-ruby/slack-ruby-client/pull/127): Added `thread_ts` and `reply_broadcast` options to `chat_postMessage` in Web API - [@dblock](https://github.com/dblock).
* [#127](https://github.com/slack-ruby/slack-ruby-client/pull/127): Added `channels_replies`, `groups_replies` and `im_replies` to Web API - [@dblock](https://github.com/dblock).
* [#127](https://github.com/slack-ruby/slack-ruby-client/pull/127): Added `goodbye` event to the RTM API - [@dblock](https://github.com/dblock).
* [#127](https://github.com/slack-ruby/slack-ruby-client/pull/127): Added `before` to `team_accessLogs` - [@dblock](https://github.com/dblock).
* [#108](https://github.com/slack-ruby/slack-ruby-client/pull/108): Use slack-ruby-danger gem - [@dblock](https://github.com/dblock).
* [#116](https://github.com/slack-ruby/slack-ruby-client/pull/116): Use [slack-ruby/slack-api-ref](https://github.com/slack-ruby/slack-api-ref) as machine API reference - [@dblock](https://github.com/dblock).
* [#116](https://github.com/slack-ruby/slack-ruby-client/pull/116): Added `users_setPhoto` and `users_deletePhoto` to Web API - [@dblock](https://github.com/dblock).
* [#81](https://github.com/slack-ruby/slack-ruby-client/pull/81): Require faraday 0.9.0 or newer - [@leppert](https://github.com/leppert).
* [#123](https://github.com/slack-ruby/slack-ruby-client/pull/123): Fix a warning about duplicate definitions - [@michaelherold](https://github.com/michaelherold).

### 0.7.7 (2016/8/29)

* [#103](https://github.com/slack-ruby/slack-ruby-client/pull/103): Added Danger, PR linting - [@dblock](https://github.com/dblock).
* [#101](https://github.com/slack-ruby/slack-ruby-client/issues/101): Fix: protected method `close` called with EventMachine - [@dblock](https://github.com/dblock).
* [#104](https://github.com/slack-ruby/slack-ruby-client/issues/104): Fix: thread leak in `start_async` with Celluloid - [@dblock](https://github.com/dblock).

### 0.7.6 (2016/8/7)

* Added `url_verification`, `message.mpim`, `message.im`, `message.groups` and `message.channels` RealTime events - [@dblock](https://github.com/dblock).
* The `im_open` method accepts `return_im` - [@dblock](https://github.com/dblock).

### 0.7.5 (2016/6/27)

* Added `bots_info` to Web API - [@dblock](https://github.com/dblock).
* Added `team_profile_get` and `team_billableInfo` to Web API - [@dblock](https://github.com/dblock).
* Added `chat_meMessage` to Web API - [@dblock](https://github.com/dblock), [@aaronpk](https://github.com/aaronpk).
* Added `users_profile_get` and `users_profile_set` to Web API - [@dblock](https://github.com/dblock).
* The `stars_list` method no longer takes a user - [@dblock](https://github.com/dblock).

### 0.7.4 (2016/5/28)

* [#93](https://github.com/slack-ruby/slack-ruby-client/pull/93): Fix: When using Celluloid concurrency, handle input from the TCP socket asynchronously from reading more - [@benzrf](https://github.com/benzrf).
* Added `auth_revoke` and `users_identity` to Web API - [@dblock](https://github.com/dblock).
* Added `channel` parameter to `files_comments_add` Web API - [@dblock](https://github.com/dblock).

### 0.7.3 (2016/5/14)

* [#90](https://github.com/slack-ruby/slack-ruby-client/issues/90): Fix: Celluloid concurrency handles server-side connection closing - [@dblock](https://github.com/dblock).

### 0.7.2 (2016/5/5)

* [#84](https://github.com/slack-ruby/slack-ruby-client/issues/84): Fix: Celluloid concurrency doesn't parallelize the connection setup - [@dblock](https://github.com/dblock).

### 0.7.1 (2016/5/2)

* [#82](https://github.com/slack-ruby/slack-ruby-client/pull/82): Fix `usergroups.users.{list,update}` and `files.comments.{add,edit,delete}` APIs - [@masatomo](https://github.com/masatomo).
* [#73](https://github.com/slack-ruby/slack-ruby-client/issues/73): Added a `closed` event - [@rkadyb](https://github.com/rkadyb).
* [#69](https://github.com/slack-ruby/slack-ruby-client/issues/69): Added attachments support for `Slack::Web::Api::Endpoints::Chat.chat_update` - [@nicka](https://github.com/nicka).
* [#85](https://github.com/slack-ruby/slack-ruby-client/issues/85): Compatibility with WebMock 2.0 - [@dblock](https://github.com/dblock).
* Added `as_user` to `chat_delete` Web API - [@dblock](https://github.com/dblock).
* Added `reminders_add`, `reminders_complete`, `reminders_delete`, `reminders_info` and `reminders_list` to Web API - [@dblock](https://github.com/dblock).

### 0.7.0 (2016/3/6)

* [#68](https://github.com/slack-ruby/slack-ruby-client/issues/68): The `Slack::RealTime::Config#store_class` is now globally configurable - [@dblock](https://github.com/dblock).
* [#67](https://github.com/slack-ruby/slack-ruby-client/pull/67): Make `logger` configurable and log HTTP requests and responses as well as RealTime events and socket data - [@mikz](https://github.com/mikz), [@dblock](https://github.com/dblock).
* Added `Slack::RealTime::Stores::Store` and `Slack::RealTime::Stores::Starter` - [@dblock](https://github.com/dblock).
* Added `files_revokePublicURL` and `files_sharedPublicURL` to Web API - [@dblock](https://github.com/dblock).
* [#60](https://github.com/slack-ruby/slack-ruby-client/issues/60): Exceptions in event handlers and commands are no longer fatal - [@dblock](https://github.com/dblock).

### 0.6.0 (2016/2/4)

* [#54](https://github.com/slack-ruby/slack-ruby-client/issues/54): RealTime client maintains a local store of team data for `client.self`, `team`, `users`, `channels`, `groups`, `ims` and `bots` data - [@dblock](https://github.com/dblock).
* [#56](https://github.com/slack-ruby/slack-ruby-client/issues/56): API responses in both Web and RealTime clients are now instances of [Slack::Messages::Message](lib/slack/messages/message), which provides method access to properties - [@dblock](https://github.com/dblock).
* [#57](https://github.com/slack-ruby/slack-ruby-client/issues/57): Configure arguments to pass to `rtm.start` via `config.start_options` - [@dblock](https://github.com/dblock).
* [#52](https://github.com/slack-ruby/slack-ruby-client/issues/52): Added `users_search` - [@dblock](https://github.com/dblock).

### 0.5.4 (2016/1/23)

* [#45](https://github.com/slack-ruby/slack-ruby-client/issues/45): Added `channels_id`, `groups_id` and `users_id` - [@dblock](https://github.com/dblock).
* [#45](https://github.com/slack-ruby/slack-ruby-client/issues/45): Automatically lookup channel, group and user ID in Web API methods when Slack API doesn't accept #channel or @user names - [@dblock](https://github.com/dblock).
* [#49](https://github.com/slack-ruby/slack-ruby-client/pull/49): Fix: Celluloid `#connected?` method - [@mikz](https://github.com/mikz), [@kandadaboggu](https://github.com/kandadaboggu).

### 0.5.3 (2016/1/11)

* [#47](https://github.com/slack-ruby/slack-ruby-client/pull/47): Fix: default to Celluloid newer API - [@jlyonsmith](https://github.com/jlyonsmith), [@dblock](https://github.com/dblock).
* Fixed JRuby file encoding regression - [@dblock](https://github.com/dblock).

### 0.5.2 (2016/1/8)

* [#41](https://github.com/slack-ruby/slack-ruby-client/issues/41): Added `Slack::Messages::Formatting#unescape` - [@dblock](https://github.com/dblock).
* Added `files_comments` to Web API - [@dblock](https://github.com/dblock).

### 0.5.1 (2016/1/4)

* Added `dnd_teamInfo`, `dnd_setSnooze`, `dnd_info`, `dnd_endSnooze` and `dnd_endDnd` to Web API - [@dblock](https://github.com/dblock).
* The `files_upload` method now requires both `file` and `filename` to Web API - [@dblock](https://github.com/dblock).

### 0.5.0 (2015/12/7)

* Added `usergroups_create`, `usergroups_disable`, `usergroups_enable`, `usergroups_list`, `usergroups_update` and `usergroups_users` to Web API - [@dblock](https://github.com/dblock).
* Added command-line `slack` client - [@dblock](https://github.com/dblock).
* [#5](https://github.com/slack-ruby/slack-ruby-client/issues/5): Added Celluloid support - [@mikz](https://github.com/mikz), [@dblock](https://github.com/dblock).
* [#34](https://github.com/slack-ruby/slack-ruby-client/pull/34): Added `Slack::RealTime::Client#start_async` - [@mikz](https://github.com/mikz), [@dblock](https://github.com/dblock).
* `Slack::RealTime::Client` supports `:open` and `:close` callbacks - [@dblock](https://github.com/dblock).
* [#32](https://github.com/slack-ruby/slack-ruby-client/issues/32): Fix: `on_complete: undefined method [] for nil:NilClass` when responding to Slack 400-500 errors - [@dblock](https://github.com/dblock).
* [#22](https://github.com/slack-ruby/slack-ruby-client/issues/22): Added `Slack::Web::Api::Error#response` - [@dblock](https://github.com/dblock).
* Added `logger` to `Slack::Web::Client` configuration that logs HTTP requests - [@dblock](https://github.com/dblock).

### 0.4.0 (2015/11/8)

* Added `team_integrationLogs` to Web API - [@dblock](https://github.com/dblock).
* [#11](https://github.com/slack-ruby/slack-ruby-client/pull/11): Web API `chat_postMessage` errors only if both `attachments` and `text` are missing - [@dblock](https://github.com/dblock).
* [#20](https://github.com/slack-ruby/slack-ruby-client/issues/20): Web API `chat_postMessage` will automatically `to_json` attachments - [@dblock](https://github.com/dblock).
* Added `mpim_aware` to `rtm_start` to Web API - [@dblock](https://github.com/dblock).
* Added `mpim_close`, `mpim_history`, `mpim_list`, `mpim_mark` and `mpim_open` to Web API - [@dblock](https://github.com/dblock).
* Added `unreads` to `channels_history`, `groups_history` and `im_history` to Web API - [@dblock](https://github.com/dblock).
* Added `stars_add` and `stars_remove` to Web API - [@dblock](https://github.com/dblock).

### 0.3.1 (2015/10/16)

* Added `stars_list`, `stars_add` and `stars_remove` to Web API - [@dblock](https://github.com/dblock).
* Added `attachments`, `parse` and `link_names` to `chat_update` in Web API - [@dblock](https://github.com/dblock).

### 0.3.0 (2015/9/1)

* Added `team.info` and `accessLogs` to Web API - [@dblock](https://github.com/dblock).
* Removed obsolete `presence` Web API - [@dblock](https://github.com/dblock).
* Added `pins_add`, `pins_list` and `pins_remove` from Web API - [@dblock](https://github.com/dblock).
* Added `presence` to `users_list` in Web API - [@dblock](https://github.com/dblock).
* Added `groups_info` to Web API - [@dblock](https://github.com/dblock).
* Added `inclusive` to `groups_history` and `im_history` in Web API - [@dblock](https://github.com/dblock).
* Added `files_delete` to Web API - [@dblock](https://github.com/dblock).
* Added `as_user` to `chat_postMessage` in Web API - [@dblock](https://github.com/dblock).
* Use API reference schema from [github.com/dblock/slack-api-ref](https://github.com/dblock/slack-api-ref) - [@dblock](https://github.com/dblock).
* Added `reactions_add`, `reactions_list`, `reactions_get` and `reactions_remove` to Web API - [@jakedahn](https://github.com/jakedahn).

### 0.2.1 (2015/8/2)

* Set Slack API token via `Slack::RealTime::Client.new(token: 'token')` and `Slack::Web::Client.new(token: 'token')` - [@dblock](https://github.com/dblock).
* Set Slack API token via `Slack::RealTime::Client.configure` and `Slack::Web::Client.configure` - [@dblock](https://github.com/dblock).

### 0.2.0 (2015/7/31)

* [#2](https://github.com/slack-ruby/slack-ruby-client/pull/2): `Slack::RealTime::Socket` now pings frames every 30s, as recommended by Slack - [@samdoiron](https://github.com/samdoiron).
* [#3](https://github.com/slack-ruby/slack-ruby-client/issues/3): RealTime client WebSocket frame ping frequency is now configurable with `Slack::RealTime::Client.websocket_ping` - [@dblock](https://github.com/dblock).
* [#3](https://github.com/slack-ruby/slack-ruby-client/issues/3): RealTime client WebSocket proxy is now configurable with `Slack::RealTime::Client.websocket_proxy` - [@dblock](https://github.com/dblock).
* [#3](https://github.com/slack-ruby/slack-ruby-client/issues/3): Added global `Slack::Web::Client` and `Slack::RealTime::Client` configuration options via `Slack::Web::Client.configure` and `Slack::RealTime::Client.configure` - [@dblock](https://github.com/dblock).
* Exposed `Slack::RealTime::Client.url`, `team`, `self`, `users`, `channels`, `groups`, `ims` and `bots` - [@dblock](https://github.com/dblock).
* Default user-agent for `Slack::Web::Client` now includes a slash, eg. _Slack Ruby Client/0.1.1_ - [@dblock](https://github.com/dblock).
* Fix: set `Slack::Web::Client` connection options for `ca_path`, `ca_file`, and `proxy` - [@dblock](https://github.com/dblock).

### 0.1.0 (2015/7/25)

* Initial public release with Web and RealTime Messaging API support - [@dblock](https://github.com/dblock).

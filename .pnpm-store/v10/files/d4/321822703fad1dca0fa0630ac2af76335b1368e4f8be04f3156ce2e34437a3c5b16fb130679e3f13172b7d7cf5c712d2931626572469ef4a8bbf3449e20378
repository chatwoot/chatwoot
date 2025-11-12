# Glossary

**Playlist**: This is a representation of an HLS or DASH manifest.

**Media Playlist**: This is a manifest that represents a single rendition or media stream of the source.

**Master Playlist Controller**: This acts as the main controller for the playback engine. It interacts with the SegmentLoaders, PlaylistLoaders, PlaybackWatcher, etc.

**Playlist Loader**: This will request the source and load the master manifest. It is also instructed by the ABR algorithm to load a media playlist or wraps a media playlist if it is provided as the source. There are more details about the playlist loader [here](./arch.md).

**DASH Playlist Loader**: This will do as the PlaylistLoader does, but for DASH sources. It also handles DASH specific functionaltiy, such as refreshing the MPD according to the minimumRefreshPeriod and synchronizing to a server clock.

**Segment Loader**: This determines which segment should be loaded, requests it via the Media Segment Loader and passes the result to the Source Updater.

**Media Segment Loader**: This requests a given segment, decrypts the segment if necessary, and returns it to the Segment Loader.

**Source Updater**: This manages the browser's [SourceBuffers](https://developer.mozilla.org/en-US/docs/Web/API/SourceBuffer). It appends decrypted segment bytes provided by the Segment Loader to the corresponding Source Buffer.

**ABR(Adaptive Bitrate) Algorithm**: This concept is described more in detail [here](https://en.wikipedia.org/wiki/Adaptive_bitrate_streaming). Our chosen ABR algorithm is referenced by [selectPlaylist](../README.md#hlsselectplaylist) and is described more [here](./bitrate-switching.md).

**Playback Watcher**: This attemps to resolve common playback stalls caused by improper seeking, gaps in content and browser issues.

**Sync Controller**: This will attempt to create a mapping between the segment index and a display time on the player.

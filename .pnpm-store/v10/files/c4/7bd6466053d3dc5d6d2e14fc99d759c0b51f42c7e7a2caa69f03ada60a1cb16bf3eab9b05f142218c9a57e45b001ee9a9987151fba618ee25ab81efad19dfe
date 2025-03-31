# Multiple Alternative Audio Tracks
## General
m3u8 manifests with multiple audio streams will have those streams added to `video.js` in an `AudioTrackList`. The `AudioTrackList` can be accessed using `player.audioTracks()` or `tech.audioTracks()`.

## Mapping m3u8 metadata to AudioTracks
The mapping between `AudioTrack` and the parsed m3u8  file is fairly straight forward. The table below shows the mapping

| m3u8    | AudioTrack |
|---------|------------|
| label   | label      |
| lang    | language   |
| default | enabled    |
| ???     | kind       |
| ???     | id         |

As you can see m3u8's do not have a property for `AudioTrack.id`, which means that we let `video.js` randomly generate the id for `AudioTrack`s. This will have no real impact on any part of the system as we do not use the `id` anywhere.

The other property that does not have a mapping in the m3u8 is `AudioTrack.kind`. It was decided that we would set the `kind` to `main` when `default` is set to `true` and in other cases we set it to `alternative` unless the track has `characteristics` which include `public.accessibility.describes-video`, in which case we set it to `main-desc` (note that this `kind` indicates that the track is a mix of the main track and description, so it can be played *instead* of the main track; a track with kind `description` *only* has the description, not the main track).

Below is a basic example of a mapping
m3u8 layout
``` JavaScript
{
	'media-group-1': [{
		'audio-track-1': {
			default: true,
			lang: 'eng'
		},
		'audio-track-2': {
			default: false,
			lang: 'fr'
    },
		'audio-track-3': {
			default: false,
			lang: 'eng',
      characteristics: 'public.accessibility.describes-video'
		}
	}]
}
```

Corresponding AudioTrackList when media-group-1 is used (before any tracks have been changed)
``` JavaScript
[{
	label: 'audio-tracks-1',
	enabled: true,
	language: 'eng',
	kind: 'main',
	id: 'random'
}, {
	label: 'audio-tracks-2',
	enabled: false,
	language: 'fr',
	kind: 'alternative',
	id: 'random'
}, {
	label: 'audio-tracks-3',
	enabled: false,
	language: 'eng',
	kind: 'main-desc',
	id: 'random'
}]
```

## Startup (how tracks are added and used)
> AudioTrack & AudioTrackList live in video.js

1. `HLS` creates a `MasterPlaylistController` and watches for the `loadedmetadata` event
1. `HLS` parses the m3u8 using the `MasterPlaylistController`
1. `MasterPlaylistController` creates a `PlaylistLoader` for the master m3u8
1. `MasterPlaylistController` creates `PlaylistLoader`s for every audio playlist
1. `MasterPlaylistController` creates a `SegmentLoader` for the main m3u8
1. `MasterPlaylistController` creates a `SegmentLoader` for a potential audio playlist
1. `HLS` sees the `loadedmetadata` and finds the currently selected MediaGroup and all the metadata
1. `HLS` removes all `AudioTrack`s from the `AudioTrackList`
1. `HLS` created `AudioTrack`s for the MediaGroup and adds them to the `AudioTrackList`
1. `HLS` calls `MasterPlaylistController`s `useAudio` with no arguments (causes it to use the currently enabled audio)
1. `MasterPlaylistController` turns off the current audio `PlaylistLoader` if it is on
1. `MasterPlaylistController` maps the `label` to the `PlaylistLoader` containing the audio
1. `MasterPlaylistController` turns on that `PlaylistLoader` and the Corresponding `SegmentLoader` (master or audio only)
1. `MediaSource`/`mux.js` determine how to mux

## How tracks are switched
> AudioTrack & AudioTrackList live in video.js

1. `HLS` is setup to watch for the `changed` event on the `AudioTrackList`
1. User selects a new `AudioTrack` from a menu (where only one track can be enabled)
1. `AudioTrackList` enables the new `Audiotrack` and disables all others
1. `AudioTrackList` triggers a `changed` event
1. `HLS` sees the `changed` event and finds the newly enabled `AudioTrack`
1. `HLS` sends the `label` for the new `AudioTrack` to `MasterPlaylistController`s `useAudio` function
1. `MasterPlaylistController` turns off the current audio `PlaylistLoader` if it is on
1. `MasterPlaylistController` maps the `label` to the `PlaylistLoader` containing the audio
1. `MasterPlaylistController` maps the `label` to the `PlaylistLoader` containing the audio
1. `MasterPlaylistController` turns on that `PlaylistLoader` and the Corresponding `SegmentLoader` (master or audio only)
1. `MediaSource`/`mux.js` determine how to mux

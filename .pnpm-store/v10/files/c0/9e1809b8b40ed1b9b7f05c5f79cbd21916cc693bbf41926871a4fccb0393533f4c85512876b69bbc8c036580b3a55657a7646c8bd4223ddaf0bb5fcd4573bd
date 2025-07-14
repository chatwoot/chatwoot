# Streams

mux.js uses a concept of `streams` to allow a flexible architecture to read and manipulate video bitstreams. The `streams` are loosely based on [Node Streams][node-streams] and are meant to be composible into a series of streams: a `pipeline`.

## Stream API

Take a look at the base [Stream][stream] to get an idea of the methods and events available. In general, data is `push`ed into a stream and is `flush`ed out of a stream. Streams can be connected by calling `pipe` on the source `Stream` and passing in the destination `Stream`. `data` events correspond to `push`es and `done` events correspond to `flush`es.

## MP4 Transmuxer

An example of a `pipeline` is contained in the [MP4 Transmuxer][mp4-transmuxer]. This is a diagram showing the whole pipeline, including the flow of data from beginning to end:

![mux.js diagram](./diagram.png)

You can gain a better understanding of what is going on by using our [debug page][debug-demo] and following the bytes through the pipeline:

```bash
npm start
```

and go to `http://localhost:9999/debug/`

[node-streams]: https://nodejs.org/api/stream.html
[mp4-transmuxer]: ../lib/mp4/transmuxer.js
[stream]: ../lib/utils/stream.js
[debug-demo]: ../debug/index.html

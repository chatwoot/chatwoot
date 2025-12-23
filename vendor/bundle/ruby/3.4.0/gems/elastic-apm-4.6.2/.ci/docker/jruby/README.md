# JRuby docker images

Builds jruby docker images.

## Build

To build the images run

```bash
  ./run.sh --action build
```

You can set your own docker registry with the flag `--registry x.y.z/org`

You can exclude what images can be built with the flag `--exclude jdk-7`. Multiple usages of `--exclude` are accepted.

## Test

To test the images run

```bash
  ./run.sh --action test
```

## Push

To push the images run

```bash
  ./run.sh --action push
```

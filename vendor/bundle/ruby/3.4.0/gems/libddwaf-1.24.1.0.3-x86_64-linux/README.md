# libddwaf Ruby bindings

``libddwaf-rb`` is library exposing the libddwaf C++ library to Ruby, packaging it in a multiplatform gem.

For the libddwaf implementation, see this repository:
 - [``libddwaf``: libddwaf](https://github.com/DataDog/libddwaf.git)



## Rake tasks

### Outline

A typical workflow is as follows:

```
rake fetch    # fetch prebuilt libddwaf binaries tarball in vendor/libddwaf
rake extract  # extract downloaded tarball in vendor/libddwaf
rake spec     # run rspec
rake binary   # build the gem
```

Note that each depends on the previous one, but `fetch` and `extract` are lazy, which proves useful to produce manual builds.

### Platform selection

By default the above will automatically use the local Ruby platform.

Since libddwaf binary builds are available upstream, it's possible to build gems for any platform on any other platform. To that end `fetch`, `extract`, and `binary` can take an argument to specify the Ruby platform for which these operations should apply:

```
rake fetch[x86_64-linux-musl]
rake extract[x86_64-linux-musl]
rake binary[x86_64-linux-musl]
```

Of course you can't force the platform for `rspec` since that requires running code; see the Docker section below for ways to achieve that.

Note that zsh gives special meaning to brackets, therefore you may need to quote the argument:

```
rake 'fetch[x86_64-linux-musl]'
```

Available platforms are:

```
x86_64-linux-musl   # Alpine build: targets musl-based Linux
x86_64-linux-gnu    # Debian build: targets glibc-based Linux
x86_64-linux        # Portable build: targets multiple linux libc
x86_64-darwin       # Darwin build: targets macOS
aarch64-linux-musl  # Same as above, for ARMv8
aarch64-linux-gnu   # Same as above, for ARMv8
aarch64-linux       # Same as above, for ARMv8
arm64-darwin        # Same as above, for Apple Silicon
java                # JRuby build, universal
```

Note: since it is not (yet) possible to package gems for the `java` Ruby platform any other way than `java`, it has to package all the native architectures.

In addition, options can be specified for the portable build:

```
rake binary[x86_64-linux:gnu+musl]  # Combined build: combine musl and glibc builds, selecting one at runtime
rake binary[x86_64-linux:llvm]      # Hybrid build: linked to llvm static libs and built against a musl sysroot
```

See upstream libddwaf for details about the [hybrid portable build](https://github.com/DataDog/libddwaf/blob/master/docker/libddwaf/README.md).

## Testing with Docker

Unless using Docker for Mac, remember to enable foreign CPU emulation via QEMU:

```
# aarch64 on x86_64 hardware
docker run --privileged --rm tonistiigi/binfmt --install arm64
# x86_64 on aarch64 hardware
docker run --privileged --rm tonistiigi/binfmt --install amd64
```

Then you can substitute e.g `--platform linux/x86_64` with `--platform linux/aarch64` below.

### GNU (Debian)

```
# this is too old for aarch64
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.1 sh -c 'rm -fv Gemfile.lock && gem install bundler -v "~> 1.17" && bundle install && bundle exec rake spec'
# these are fine for aarch64
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.2 sh -c 'rm -fv Gemfile.lock && gem install bundler -v "~> 1.17" && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.3 sh -c 'rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.4 sh -c 'rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.5 sh -c 'rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.6 sh -c 'rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.7 sh -c 'rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:3.0 sh -c 'rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:3.1 sh -c 'rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
```

### musl (Alpine)

```
# these are too old for aarch64
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.1-alpine sh -c 'apk update && apk add build-base git && rm -fv Gemfile.lock && gem install bundler -v "~> 1.17" && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.2-alpine sh -c 'apk update && apk add build-base git && rm -fv Gemfile.lock && gem install bundler -v "~> 1.17" && bundle install && bundle exec rake spec'
# these are fine for aarch64
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.3-alpine sh -c 'apk update && apk add build-base git && rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.4-alpine sh -c 'apk update && apk add build-base git && rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.5-alpine sh -c 'apk update && apk add build-base git && rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.6-alpine sh -c 'apk update && apk add build-base git && rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:2.7-alpine sh -c 'apk update && apk add build-base git && rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:3.0-alpine sh -c 'apk update && apk add build-base git && rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:3.1-alpine sh -c 'apk update && apk add build-base git && rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" ruby:3.1-alpine sh -c 'apk update && apk add build-base git && rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
```

### JRuby

```
# these are too old for aarch64
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" jruby:9.2.8.0 sh -c 'apt-get update && apt-get install -y build-essential git && rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" jruby:9.3.0.0 sh -c 'apt-get update && apt-get install -y build-essential git && rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
# this is fine for aarch64
docker run --rm -it --platform linux/x86_64 -v "${PWD}":"${PWD}" -w "${PWD}" jruby:9.3.4.0 sh -c 'apt-get update && apt-get install -y build-essential git && rm -fv Gemfile.lock && gem install bundler:2.2.22 && bundle install && bundle exec rake spec'
```

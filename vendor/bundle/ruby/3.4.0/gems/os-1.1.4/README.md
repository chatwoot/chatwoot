The OS gem allows for some easy telling if you're on windows or not. 

```ruby
require 'os'

>> OS.windows?
=> true   # or OS.doze?

>> OS.bits
=> 32

>> OS.java?
=> true # if you're running in jruby.  Also OS.jruby?

>> OS.ruby_bin
=> "c:\ruby18\bin\ruby.exe" # or "/usr/local/bin/ruby" or what not

>> OS.posix?
=> false # true for linux, os x, cygwin

>> OS.mac? # or OS.osx? or OS.x?
=> false

>> OS.dev_null
=> "NUL" # or "/dev/null" depending on which platform

>> OS.rss_bytes
=> 12300033 # number of rss bytes this process is using currently.  Basically "total in memory footprint" (doesn't include RAM used by the process that's in swap/page file)

>> puts OS.report
==> # a yaml report of helpful values
--- 
arch: x86_64-darwin10.6.0
target_os: darwin10.6.0
target_vendor: apple
target_cpu: x86_64
target: x86_64-apple-darwin10.6.0
host_os: darwin10.6.0
host_vendor: apple
host_cpu: i386
host: i386-apple-darwin10.6.0
RUBY_PLATFORM: x86_64-darwin10.6.0

>> OS.cpu_count  
=> 2 # number of cores, doesn't include hyper-threaded cores.

>> OS.open_file_command
=> "start" # or open on mac, or xdg-open on linux (all designed to open a file)

>> OS::Underlying.windows?
=> true # true for cygwin or MRI, whereas OS.windows? is false for cygwin

>> OS::Underlying.bsd?
=> true # true for OS X

>> OS::Underlying.docker?
=> false # true if running inside a Docker container

>> pp OS.parse_os_release
==> # A hash of details on the current Linux distro (or an exception if not Linux)
{:NAME=>"Ubuntu",
 :VERSION=>"18.04.4 LTS (Bionic Beaver)",
 :ID=>"ubuntu",
 :ID_LIKE=>"debian",
 :PRETTY_NAME=>"Ubuntu 18.04.4 LTS",
 :VERSION_ID=>"18.04",
 :HOME_URL=>"https://www.ubuntu.com/",
 :SUPPORT_URL=>"https://help.ubuntu.com/",
 :BUG_REPORT_URL=>"https://bugs.launchpad.net/ubuntu/",
 :PRIVACY_POLICY_URL=>
  "https://www.ubuntu.com/legal/terms-and-policies/privacy-policy",
 :VERSION_CODENAME=>"bionic",
 :UBUNTU_CODENAME=>"bionic"}
```
  
If there are any other features you'd like, let me know, I'll do what I can to add them :)

http://github.com/rdp/os for feedback et al

Related projects:

rubygems:

```ruby
Gem::Platform.local
Gem.ruby
```

  The reason Gem::Platform.local felt wrong to me is that it treated cygwin as windows--which for most build environments, is wrong.  Hence the creation of this gem.

the facets gem (has a class similar to rubygems, above)

```ruby
require 'facets/platform'
Platform.local
```

the ["platform" gem](http://rubydoc.info/github/ffi/ffi/master/FFI/Platform), itself (a different gem)

```ruby
FFI::Platform::OS
```

License: MIT (see LICENSE file)

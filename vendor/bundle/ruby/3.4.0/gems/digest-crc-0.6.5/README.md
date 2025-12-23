# Digest CRC

[![CI](https://github.com/postmodern/digest-crc/actions/workflows/ruby.yml/badge.svg)](https://github.com/postmodern/digest-crc/actions/workflows/ruby.yml)

* [Source](https://github.com/postmodern/digest-crc)
* [Issues](https://github.com/postmodern/digest-crc/issues)
* [Documentation](http://rubydoc.info/gems/digest-crc/frames)

## Description

Adds support for calculating Cyclic Redundancy Check (CRC) to the Digest
module.

## Features

* Provides support for the following CRC algorithms:
  * [CRC1](https://rubydoc.info/gems/digest-crc/Digest/CRC1)
  * [CRC5](https://rubydoc.info/gems/digest-crc/Digest/CRC5)
  * [CRC8](https://rubydoc.info/gems/digest-crc/Digest/CRC8)
  * [CRC8 1-Wire](https://rubydoc.info/gems/digest-crc/Digest/CRC8_1Wire)
  * [CRC15](https://rubydoc.info/gems/digest-crc/Digest/CRC15)
  * [CRC16](https://rubydoc.info/gems/digest-crc/Digest/CRC16)
  * [CRC16 CCITT](https://rubydoc.info/gems/digest-crc/Digest/CRC16CCITT)
  * [CRC16 DNP](https://rubydoc.info/gems/digest-crc/Digest/CRC16DNP)
  * [CRC16 Genibus](https://rubydoc.info/gems/digest-crc/Digest/CRC16Genibus)
  * [CRC16 Kermit](https://rubydoc.info/gems/digest-crc/Digest/CRC16Kermit)
  * [CRC16 Modbus](https://rubydoc.info/gems/digest-crc/Digest/CRC16Modbus)
  * [CRC16 USB](https://rubydoc.info/gems/digest-crc/Digest/CRC16USB)
  * [CRC16 X25](https://rubydoc.info/gems/digest-crc/Digest/CRC16X25)
  * [CRC16 XModem](https://rubydoc.info/gems/digest-crc/Digest/CRC16XModem)
  * [CRC16 ZModem](https://rubydoc.info/gems/digest-crc/Digest/CRC16ZModem)
  * [CRC16 QT](https://rubydoc.info/gems/digest-crc/Digest/CRC16QT)
  * [CRC24](https://rubydoc.info/gems/digest-crc/Digest/CRC24)
  * [CRC32](https://rubydoc.info/gems/digest-crc/Digest/CRC32)
  * [CRC32 BZip2](https://rubydoc.info/gems/digest-crc/Digest/CRC32BZip2)
  * [CRC32c](https://rubydoc.info/gems/digest-crc/Digest/CRC32c)
  * [CRC32 Jam](https://rubydoc.info/gems/digest-crc/Digest/CRC32Jam)
  * [CRC32 MPEG](https://rubydoc.info/gems/digest-crc/Digest/CRC32MPEG)
  * [CRC32 POSIX](https://rubydoc.info/gems/digest-crc/Digest/CRC32POSIX)
  * [CRC32 XFER](https://rubydoc.info/gems/digest-crc/Digest/CRC32XFER)
  * [CRC64](https://rubydoc.info/gems/digest-crc/Digest/CRC64)
  * [CRC64 Jones](https://rubydoc.info/gems/digest-crc/Digest/CRC64Jones)
  * [CRC64 XZ](https://rubydoc.info/gems/digest-crc/Digest/CRC64XZ)
* Pure Ruby implementation.
* Provides CRC Tables for optimized calculations.
* Supports _optional_ C extensions which increases performance by ~40x.
  * If the C extensions cannot be compiled for whatever reason, digest-crc
    will automatically fallback to the pure-Ruby implementation.

## Install

```
gem install digest-crc
```

**Note:** to enable the C extensions ensure that you are using CRuby and have
a C compiler (`gcc` or `clang`) and `make` installed, _before_ installing
digest-crc.

* Debian / Ubuntu:

      $ sudo apt install gcc make

* RedHat / Fedora:

      $ sudo dnf install gcc make

* Alpine Linux:

      $ apk add build-base

* macOS: install XCode

## Examples

Calculate a CRC32:

```ruby
require 'digest/crc32'

Digest::CRC32.hexdigest('hello')
# => "3610a686"
```

Calculate a CRC32 of a file:

```ruby
Digest::CRC32.file('README.md')
# => #<Digest::CRC32: 127ad531>
```

Incrementally calculate a CRC32:

```ruby
crc = Digest::CRC32.new
crc << 'one'
crc << 'two'
crc << 'three'
crc.hexdigest
# => "09e1c092"
```

Directly access the checksum:

```ruby
crc.checksum
# => 165789842
```

Defining your own CRC class:

```ruby
require 'digest/crc32'

module Digest
  class CRC3000 < CRC32

    WIDTH = 4

    INIT_CRC = 0xffffffff

    XOR_MASK = 0xffffffff

    TABLE = [
      # ....
    ].freeze

    def update(data)
      data.each_byte do |b|
        @crc = (((@crc >> 8) & 0x00ffffff) ^ @table[(@crc ^ b) & 0xff])
      end

      return self
    end
  end
end
```

## Benchmarks

### Ruby 2.7.4 (pure Ruby)

    $ bundle exec rake clean
    $ bundle exec ./benchmarks.rb
    Loading Digest::CRC classes ...
    Generating 1000 8Kb lengthed strings ...
    Benchmarking Digest::CRC classes ...
                                      user     system      total        real
    Digest::CRC1#update           0.423741   0.000000   0.423741 (  0.425887)
    Digest::CRC5#update           1.486578   0.000011   1.486589 (  1.493215)
    Digest::CRC8#update           1.261386   0.000000   1.261386 (  1.266399)
    Digest::CRC8_1Wire#update     1.250344   0.000000   1.250344 (  1.255009)
    Digest::CRC15#update          1.482515   0.000000   1.482515 (  1.488131)
    Digest::CRC16#update          1.216744   0.000811   1.217555 (  1.222228)
    Digest::CRC16CCITT#update     1.480490   0.000000   1.480490 (  1.486745)
    Digest::CRC16DNP#update       1.200067   0.000000   1.200067 (  1.204835)
    Digest::CRC16Genibus#update   1.492910   0.000000   1.492910 (  1.498923)
    Digest::CRC16Modbus#update    1.217449   0.000003   1.217452 (  1.222348)
    Digest::CRC16QT#update        1.223311   0.000000   1.223311 (  1.229211)
    Digest::CRC16USB#update       1.233744   0.000000   1.233744 (  1.238615)
    Digest::CRC16X25#update       1.223077   0.000000   1.223077 (  1.227607)
    Digest::CRC16XModem#update    1.487674   0.000000   1.487674 (  1.493316)
    Digest::CRC16ZModem#update    1.484288   0.000000   1.484288 (  1.490096)
    Digest::CRC24#update          1.490272   0.000000   1.490272 (  1.496027)
    Digest::CRC32#update          1.225311   0.000000   1.225311 (  1.230572)
    Digest::CRC32BZip2#update     1.503096   0.000000   1.503096 (  1.509202)
    Digest::CRC32c#update         1.220390   0.000000   1.220390 (  1.225487)
    Digest::CRC32Jam#update       1.216066   0.000000   1.216066 (  1.220591)
    Digest::CRC32MPEG#update      1.486808   0.000000   1.486808 (  1.492611)
    Digest::CRC32POSIX#update     1.494508   0.000957   1.495465 (  1.503262)
    Digest::CRC32XFER#update      1.504802   0.005830   1.510632 (  1.522066)
    Digest::CRC64#update          3.260784   0.015674   3.276458 (  3.310506)
    Digest::CRC64Jones#update     3.195204   0.000000   3.195204 (  3.213054)
    Digest::CRC64XZ#update        3.173597   0.000000   3.173597 (  3.190438)

### Ruby 2.7.4 (C extensions)

    $ bundle exec rake build:c_exts
    ...
    $ bundle exec ./benchmarks.rb
    Loading Digest::CRC classes ...
    Generating 1000 8Kb lengthed strings ...
    Benchmarking Digest::CRC classes ...
                                      user     system      total        real
    Digest::CRC1#update           0.443619   0.000007   0.443626 (  0.446545)
    Digest::CRC5#update           0.025134   0.000806   0.025940 (  0.026129)
    Digest::CRC8#update           0.022564   0.000000   0.022564 (  0.022775)
    Digest::CRC8_1Wire#update     0.021427   0.000008   0.021435 (  0.021551)
    Digest::CRC15#update          0.030377   0.000833   0.031210 (  0.031406)
    Digest::CRC16#update          0.024004   0.000002   0.024006 (  0.024418)
    Digest::CRC16CCITT#update     0.026930   0.000001   0.026931 (  0.027238)
    Digest::CRC16DNP#update       0.024279   0.000000   0.024279 (  0.024446)
    Digest::CRC16Genibus#update   0.026477   0.000004   0.026481 (  0.026656)
    Digest::CRC16Modbus#update    0.023568   0.000000   0.023568 (  0.023704)
    Digest::CRC16QT#update        0.024161   0.000000   0.024161 (  0.024316)
    Digest::CRC16USB#update       0.023891   0.000000   0.023891 (  0.024038)
    Digest::CRC16X25#update       0.023849   0.000000   0.023849 (  0.023991)
    Digest::CRC16XModem#update    0.026254   0.000000   0.026254 (  0.026523)
    Digest::CRC16ZModem#update    0.026391   0.000000   0.026391 (  0.026529)
    Digest::CRC24#update          0.028805   0.000854   0.029659 (  0.029830)
    Digest::CRC32#update          0.024030   0.000000   0.024030 (  0.024200)
    Digest::CRC32BZip2#update     0.026942   0.000000   0.026942 (  0.027244)
    Digest::CRC32c#update         0.023989   0.000000   0.023989 (  0.024159)
    Digest::CRC32Jam#update       0.023940   0.000000   0.023940 (  0.024066)
    Digest::CRC32MPEG#update      0.027063   0.000000   0.027063 (  0.027213)
    Digest::CRC32POSIX#update     0.027137   0.000000   0.027137 (  0.028160)
    Digest::CRC32XFER#update      0.026956   0.000002   0.026958 (  0.027103)
    Digest::CRC64#update          0.024222   0.000005   0.024227 (  0.024796)
    Digest::CRC64Jones#update     0.025331   0.000000   0.025331 (  0.025789)
    Digest::CRC64XZ#update        0.024131   0.000001   0.024132 (  0.024348)

### Ruby 3.0.2 (pure Ruby)

    $ bundle exec rake clean
    $ bundle exec ./benchmarks.rb
    Loading Digest::CRC classes ...
    Generating 1000 8Kb lengthed strings ...
    Benchmarking Digest::CRC classes ...
                                      user     system      total        real
    Digest::CRC1#update           0.331405   0.000002   0.331407 (  0.333588)
    Digest::CRC5#update           1.206847   0.000020   1.206867 (  1.224072)
    Digest::CRC8#update           1.018571   0.000000   1.018571 (  1.023002)
    Digest::CRC8_1Wire#update     1.018802   0.000000   1.018802 (  1.023292)
    Digest::CRC15#update          1.207586   0.000000   1.207586 (  1.212691)
    Digest::CRC16#update          1.032505   0.000965   1.033470 (  1.040862)
    Digest::CRC16CCITT#update     1.198079   0.000000   1.198079 (  1.203134)
    Digest::CRC16DNP#update       0.994582   0.000000   0.994582 (  1.006520)
    Digest::CRC16Genibus#update   1.190596   0.000000   1.190596 (  1.196087)
    Digest::CRC16Modbus#update    1.007826   0.000000   1.007826 (  1.012934)
    Digest::CRC16QT#update        0.996298   0.000001   0.996299 (  1.000255)
    Digest::CRC16USB#update       0.995806   0.000000   0.995806 (  0.999822)
    Digest::CRC16X25#update       1.019589   0.000000   1.019589 (  1.031010)
    Digest::CRC16XModem#update    1.146947   0.000000   1.146947 (  1.150817)
    Digest::CRC16ZModem#update    1.145145   0.000000   1.145145 (  1.149483)
    Digest::CRC24#update          1.149009   0.000000   1.149009 (  1.152854)
    Digest::CRC32#update          0.970976   0.000000   0.970976 (  0.974227)
    Digest::CRC32BZip2#update     1.148596   0.000000   1.148596 (  1.152381)
    Digest::CRC32c#update         0.972566   0.000000   0.972566 (  0.975790)
    Digest::CRC32Jam#update       0.975854   0.000000   0.975854 (  0.979217)
    Digest::CRC32MPEG#update      1.148578   0.000000   1.148578 (  1.153088)
    Digest::CRC32POSIX#update     1.146218   0.000986   1.147204 (  1.152460)
    Digest::CRC32XFER#update      1.149823   0.000000   1.149823 (  1.153692)
    Digest::CRC64#update          2.869948   0.000016   2.869964 (  2.884261)
    Digest::CRC64Jones#update     2.867662   0.000000   2.867662 (  2.886559)
    Digest::CRC64XZ#update        2.858847   0.000000   2.858847 (  2.874058)

### Ruby 3.0.2 (C extensions)

    $ bundle exec rake build:c_exts
    ...
    $ bundle exec ./benchmarks.rb
    Loading Digest::CRC classes ...
    Generating 1000 8Kb lengthed strings ...
    Benchmarking Digest::CRC classes ...
                                      user     system      total        real
    Digest::CRC1#update           0.349055   0.000000   0.349055 (  0.350454)
    Digest::CRC5#update           0.023144   0.000000   0.023144 (  0.023248)
    Digest::CRC8#update           0.021378   0.000000   0.021378 (  0.021522)
    Digest::CRC8_1Wire#update     0.021019   0.000000   0.021019 (  0.021145)
    Digest::CRC15#update          0.030063   0.000003   0.030066 (  0.030245)
    Digest::CRC16#update          0.024395   0.000000   0.024395 (  0.024572)
    Digest::CRC16CCITT#update     0.026979   0.000000   0.026979 (  0.027138)
    Digest::CRC16DNP#update       0.024665   0.000000   0.024665 (  0.024844)
    Digest::CRC16Genibus#update   0.027054   0.000000   0.027054 (  0.027217)
    Digest::CRC16Modbus#update    0.023963   0.000000   0.023963 (  0.024257)
    Digest::CRC16QT#update        0.024218   0.000000   0.024218 (  0.024360)
    Digest::CRC16USB#update       0.024393   0.000000   0.024393 (  0.024561)
    Digest::CRC16X25#update       0.025127   0.000000   0.025127 (  0.025292)
    Digest::CRC16XModem#update    0.028123   0.000000   0.028123 (  0.028377)
    Digest::CRC16ZModem#update    0.028205   0.000000   0.028205 (  0.028571)
    Digest::CRC24#update          0.031386   0.000000   0.031386 (  0.031740)
    Digest::CRC32#update          0.023832   0.000000   0.023832 (  0.023948)
    Digest::CRC32BZip2#update     0.027159   0.000000   0.027159 (  0.027315)
    Digest::CRC32c#update         0.024172   0.000000   0.024172 (  0.024310)
    Digest::CRC32Jam#update       0.024376   0.000000   0.024376 (  0.024494)
    Digest::CRC32MPEG#update      0.026035   0.000784   0.026819 (  0.026940)
    Digest::CRC32POSIX#update     0.026784   0.000000   0.026784 (  0.026907)
    Digest::CRC32XFER#update      0.026770   0.000000   0.026770 (  0.026893)
    Digest::CRC64#update          0.024400   0.000009   0.024409 (  0.024531)
    Digest::CRC64Jones#update     0.023477   0.000781   0.024258 (  0.024390)
    Digest::CRC64XZ#update        0.024611   0.000000   0.024611 (  0.024779)

### JRuby 9.2.18.0 (pure Ruby)

    $ bundle exec ./benchmarks.rb
    Loading Digest::CRC classes ...
    Generating 1000 8Kb lengthed strings ...
    Benchmarking Digest::CRC classes ...
                                      user     system      total        real
    Digest::CRC1#update           1.080000   0.050000   1.130000 (  0.676022)
    Digest::CRC5#update           2.030000   0.040000   2.070000 (  1.089240)
    Digest::CRC8#update           1.590000   0.000000   1.590000 (  0.999138)
    Digest::CRC8_1Wire#update     0.920000   0.010000   0.930000 (  0.873813)
    Digest::CRC15#update          1.470000   0.030000   1.500000 (  1.118886)
    Digest::CRC16#update          1.780000   0.010000   1.790000 (  1.067874)
    Digest::CRC16CCITT#update     1.500000   0.070000   1.570000 (  1.185564)
    Digest::CRC16DNP#update       1.250000   0.000000   1.250000 (  0.972322)
    Digest::CRC16Genibus#update   1.700000   0.010000   1.710000 (  1.092047)
    Digest::CRC16Modbus#update    1.000000   0.010000   1.010000 (  0.915328)
    Digest::CRC16QT#update        1.250000   0.000000   1.250000 (  0.968528)
    Digest::CRC16USB#update       1.150000   0.010000   1.160000 (  0.990387)
    Digest::CRC16X25#update       0.940000   0.000000   0.940000 (  0.926926)
    Digest::CRC16XModem#update    1.390000   0.010000   1.400000 (  1.100584)
    Digest::CRC16ZModem#update    1.760000   0.020000   1.780000 (  1.094003)
    Digest::CRC24#update          1.690000   0.010000   1.700000 (  1.106875)
    Digest::CRC32#update          1.410000   0.020000   1.430000 (  1.082506)
    Digest::CRC32BZip2#update     1.510000   0.010000   1.520000 (  1.104225)
    Digest::CRC32c#update         1.270000   0.010000   1.280000 (  1.023881)
    Digest::CRC32Jam#update       1.190000   0.010000   1.200000 (  0.998146)
    Digest::CRC32MPEG#update      1.580000   0.010000   1.590000 (  1.099086)
    Digest::CRC32POSIX#update     1.550000   0.010000   1.560000 (  1.142051)
    Digest::CRC32XFER#update      1.360000   0.000000   1.360000 (  1.071381)
    Digest::CRC64#update          3.730000   0.020000   3.750000 (  2.780390)
    Digest::CRC64Jones#update     2.710000   0.020000   2.730000 (  2.608007)
    Digest::CRC64XZ#update        2.910000   0.020000   2.930000 (  2.629401)

### TruffleRuby 21.2.0 (pure Ruby)

    $ bundle exec rake clean
    $ bundle exec ./benchmarks.rb
    Loading Digest::CRC classes ...
    Generating 1000 8Kb lengthed strings ...
    Benchmarking Digest::CRC classes ...
                                      user     system      total        real
    Digest::CRC1#update           0.455340   0.000000   0.455340 (  0.457710)
    Digest::CRC5#update           1.406700   0.000000   1.406700 (  1.412535)
    Digest::CRC8#update           1.248323   0.000000   1.248323 (  1.255452)
    Digest::CRC8_1Wire#update     1.269434   0.000000   1.269434 (  1.275315)
    Digest::CRC15#update          1.428752   0.000000   1.428752 (  1.434836)
    Digest::CRC16#update          1.220394   0.000967   1.221361 (  1.229684)
    Digest::CRC16CCITT#update     1.434932   0.001000   1.435932 (  1.452391)
    Digest::CRC16DNP#update       1.191351   0.000000   1.191351 (  1.202262)
    Digest::CRC16Genibus#update   1.434067   0.000000   1.434067 (  1.440300)
    Digest::CRC16Modbus#update    1.200827   0.000000   1.200827 (  1.205658)
    Digest::CRC16QT#update        1.195077   0.000000   1.195077 (  1.200328)
    Digest::CRC16USB#update       1.196266   0.000000   1.196266 (  1.201262)
    Digest::CRC16X25#update       1.206690   0.000000   1.206690 (  1.211781)
    Digest::CRC16XModem#update    1.430468   0.000000   1.430468 (  1.436801)
    Digest::CRC16ZModem#update    1.442524   0.000000   1.442524 (  1.448624)
    Digest::CRC24#update          1.447611   0.000018   1.447629 (  1.454534)
    Digest::CRC32#update          1.214314   0.000000   1.214314 (  1.219838)
    Digest::CRC32BZip2#update     1.427408   0.000000   1.427408 (  1.433626)
    Digest::CRC32c#update         1.204985   0.000000   1.204985 (  1.210273)
    Digest::CRC32Jam#update       1.235039   0.000000   1.235039 (  1.240686)
    Digest::CRC32MPEG#update      1.429731   0.000000   1.429731 (  1.435404)
    Digest::CRC32POSIX#update     1.458886   0.000000   1.458886 (  1.465914)
    Digest::CRC32XFER#update      1.422109   0.000000   1.422109 (  1.427635)
    Digest::CRC64#update          3.283506   0.000000   3.283506 (  3.303129)
    Digest::CRC64Jones#update     3.297402   0.000000   3.297402 (  3.317357)
    Digest::CRC64XZ#update        3.278551   0.001875   3.280426 (  3.315165)


### TruffleRuby 21.2.0 (C extensions)

    $ bundle exec rake build:c_exts
    ...
    $ bundle exec ./benchmarks.rb
    Loading Digest::CRC classes ...
    Generating 1000 8Kb lengthed strings ...
    Benchmarking Digest::CRC classes ...
                                      user     system      total        real
    Digest::CRC1#update           0.480586   0.000014   0.480600 (  0.482817)
    Digest::CRC5#update           0.023795   0.000000   0.023795 (  0.023941)
    Digest::CRC8#update           0.020619   0.000000   0.020619 (  0.020747)
    Digest::CRC8_1Wire#update     0.020571   0.000000   0.020571 (  0.020700)
    Digest::CRC15#update          0.031224   0.000000   0.031224 (  0.031412)
    Digest::CRC16#update          0.024013   0.000000   0.024013 (  0.024174)
    Digest::CRC16CCITT#update     0.026790   0.000000   0.026790 (  0.027079)
    Digest::CRC16DNP#update       0.024253   0.000000   0.024253 (  0.024427)
    Digest::CRC16Genibus#update   0.027237   0.000000   0.027237 (  0.027390)
    Digest::CRC16Modbus#update    0.024376   0.000000   0.024376 (  0.024548)
    Digest::CRC16QT#update        0.024361   0.000000   0.024361 (  0.024518)
    Digest::CRC16USB#update       0.024142   0.000000   0.024142 (  0.024311)
    Digest::CRC16X25#update       0.024098   0.000000   0.024098 (  0.024222)
    Digest::CRC16XModem#update    0.026306   0.000000   0.026306 (  0.026502)
    Digest::CRC16ZModem#update    0.026536   0.000000   0.026536 (  0.026688)
    Digest::CRC24#update          0.029732   0.000000   0.029732 (  0.029902)
    Digest::CRC32#update          0.024219   0.000000   0.024219 (  0.024391)
    Digest::CRC32BZip2#update     0.026817   0.000000   0.026817 (  0.027044)
    Digest::CRC32c#update         0.023681   0.000000   0.023681 (  0.023798)
    Digest::CRC32Jam#update       0.024243   0.000000   0.024243 (  0.024419)
    Digest::CRC32MPEG#update      0.026865   0.000000   0.026865 (  0.027020)
    Digest::CRC32POSIX#update     0.026583   0.000000   0.026583 (  0.026748)
    Digest::CRC32XFER#update      0.027423   0.000000   0.027423 (  0.027615)
    Digest::CRC64#update          0.024150   0.000000   0.024150 (  0.024310)
    Digest::CRC64Jones#update     0.024218   0.000000   0.024218 (  0.024363)
    Digest::CRC64XZ#update        0.024124   0.000000   0.024124 (  0.024255)

## Crystal

[crystal-crc] is a [Crystal][crystal-lang] port of this library.

[crystal-crc]: https://github.com/postmodern/crystal-crc
[crystal-lang]: https://www.crystal-lang.org/

## Thanks

Special thanks go out to the [pycrc](http://www.tty1.net/pycrc/) library
which is able to generate C source-code for all of the CRC algorithms,
including their CRC Tables.

## License

Copyright (c) 2010-2021 Hal Brodigan

See {file:LICENSE.txt} for license information.

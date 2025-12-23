# -*- encoding: utf-8 -*-
require 'rubygems' unless defined?(Gem)
require 'pathname'
require 'date'
require 'time'
require 'rake/clean'

raise "unable to find xcodebuild" unless system('which', 'xcodebuild')


FSEVENT_WATCH_EXE_VERSION = '0.1.5'

$this_dir = Pathname.new(__FILE__).dirname.expand_path
$final_exe = $this_dir.parent.join('bin/fsevent_watch')

$src_dir = $this_dir.join('fsevent_watch')
$obj_dir = $this_dir.join('build')

SRC = Pathname.glob("#{$src_dir}/*.c")
OBJ = SRC.map {|s| $obj_dir.join("#{s.basename('.c')}.o")}

$now = DateTime.now.xmlschema rescue Time.now.xmlschema

$CC = ENV['CC'] || `which clang || which gcc`.strip
$CFLAGS = ENV['CFLAGS'] || '-fconstant-cfstrings -fasm-blocks -fstrict-aliasing -Wall'
$ARCHFLAGS = ENV['ARCHFLAGS'] || '-arch x86_64'
$DEFINES = "-DNS_BUILD_32_LIKE_64 -DNS_BLOCK_ASSERTIONS -DPROJECT_VERSION=#{FSEVENT_WATCH_EXE_VERSION}"

$GCC_C_LANGUAGE_STANDARD = ENV['GCC_C_LANGUAGE_STANDARD'] || 'gnu11'

# generic developer id name so it'll match correctly for anyone who has only
# one developer id in their keychain (not that I expect anyone else to bother)
$CODE_SIGN_IDENTITY = 'Developer ID Application'

$arch = `uname -m`.strip
$os_release = `uname -r`.strip
$BUILD_TRIPLE = "#{$arch}-apple-darwin#{$os_release}"

$CCVersion = `#{$CC} --version | head -n 1`.strip


CLEAN.include OBJ.map(&:to_s)
CLEAN.include $obj_dir.join('Info.plist').to_s
CLEAN.include $obj_dir.join('fsevent_watch').to_s
CLOBBER.include $final_exe.to_s


task :sw_vers do
  $mac_product_version = `sw_vers -productVersion`.strip
  $mac_build_version = `sw_vers -buildVersion`.strip
  $MACOSX_DEPLOYMENT_TARGET = ENV['MACOSX_DEPLOYMENT_TARGET'] || $mac_product_version.sub(/\.\d*$/, '')
  $CFLAGS = "#{$CFLAGS} -mmacosx-version-min=#{$MACOSX_DEPLOYMENT_TARGET}"
end

task :get_sdk_info => :sw_vers do
  $SDK_INFO = {}
  version_info = `xcodebuild -version -sdk macosx#{$MACOSX_DEPLOYMENT_TARGET}`
  raise "invalid SDK" unless !!$?.exitstatus
  version_info.strip.each_line do |line|
    next if line.strip.empty?
    next unless line.include?(':')
    match = line.match(/([^:]*): (.*)/)
    next unless match
    $SDK_INFO[match[1]] = match[2]
  end
end

task :debug => :sw_vers do
  $DEFINES = "-DDEBUG #{$DEFINES}"
  $CFLAGS = "#{$CFLAGS} -O0 -fno-omit-frame-pointer -g"
end

task :release => :sw_vers do
  $DEFINES = "-DNDEBUG #{$DEFINES}"
  $CFLAGS = "#{$CFLAGS} -Ofast"
end

desc 'configure build type depending on whether ENV var FWDEBUG is set'
task :set_build_type => :sw_vers do
  if ENV['FWDEBUG']
    Rake::Task[:debug].invoke
  else
    Rake::Task[:release].invoke
  end
end

desc 'set build arch to ppc'
task :ppc do
  $ARCHFLAGS = '-arch ppc'
end

desc 'set build arch to x86_64'
task :x86_64 do
  $ARCHFLAGS = '-arch x86_64'
end

desc 'set build arch to i386'
task :x86 do
  $ARCHFLAGS = '-arch i386'
end

desc 'set build arch to arm64'
task :arm64 do
  $ARCHFLAGS = '-arch arm64'
end

task :setup_env => [:set_build_type, :sw_vers, :get_sdk_info]

directory $obj_dir.to_s
file $obj_dir.to_s => :setup_env

SRC.zip(OBJ).each do |source, object|
  file object.to_s => [source.to_s, $obj_dir.to_s] do
    cmd = [
      $CC,
      $ARCHFLAGS,
      "-std=#{$GCC_C_LANGUAGE_STANDARD}",
      $CFLAGS,
      $DEFINES,
      "-I#{$src_dir}",
      '-isysroot',
      $SDK_INFO['Path'],
      '-c', source,
      '-o', object
    ]
    sh(cmd.map {|s| s.to_s}.join(' '))
  end
end

file $obj_dir.join('Info.plist').to_s => [$obj_dir.to_s, :setup_env] do
  File.open($obj_dir.join('Info.plist').to_s, 'w+') do |file|
    indentation = ''
    indent      =  lambda {|num|    indentation = ' ' * num               }
    add         =  lambda {|str| file << "#{indentation}#{str}\n"   }
    key         =  lambda {|str| add["<key>#{str}</key>"]           }
    string      =  lambda {|str| add["<string>#{str}</string>"]     }


    add['<?xml version="1.0" encoding="UTF-8"?>']
    add['<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">']
    add['<plist version="1.0">']

    indent[2]
    add['<dict>']
    indent[4]

    key['CFBundleExecutable']
    string['fsevent_watch']
    key['CFBundleIdentifier']
    string['com.teaspoonofinsanity.fsevent_watch']
    key['CFBundleName']
    string['fsevent_watch']
    key['CFBundleDisplayName']
    string['FSEvent Watch CLI']
    key['NSHumanReadableCopyright']
    string['Copyright (C) 2011-2017 Travis Tilley']

    key['CFBundleVersion']
    string["#{FSEVENT_WATCH_EXE_VERSION}"]
    key['LSMinimumSystemVersion']
    string["#{$MACOSX_DEPLOYMENT_TARGET}"]
    key['DTSDKBuild']
    string["#{$SDK_INFO['ProductBuildVersion']}"]
    key['DTSDKName']
    string["macosx#{$SDK_INFO['SDKVersion']}"]
    key['DTSDKPath']
    string["#{$SDK_INFO['Path']}"]
    key['BuildMachineOSBuild']
    string["#{$mac_build_version}"]
    key['BuildMachineOSVersion']
    string["#{$mac_product_version}"]
    key['FSEWCompiledAt']
    string["#{$now}"]
    key['FSEWVersionInfoBuilder']
    string["#{`whoami`.strip}"]
    key['FSEWBuildTriple']
    string["#{$BUILD_TRIPLE}"]
    key['FSEWCC']
    string["#{$CC}"]
    key['FSEWCCVersion']
    string["#{$CCVersion}"]
    key['FSEWCFLAGS']
    string["#{$CFLAGS}"]

    indent[2]
    add['</dict>']
    indent[0]

    add['</plist>']
  end
end

desc 'generate an Info.plist used for code signing as well as embedding build settings into the resulting binary'
task :plist => $obj_dir.join('Info.plist').to_s


file $obj_dir.join('fsevent_watch').to_s => [$obj_dir.to_s, $obj_dir.join('Info.plist').to_s] + OBJ.map(&:to_s) do
  cmd = [
    $CC,
    $ARCHFLAGS,
    "-std=#{$GCC_C_LANGUAGE_STANDARD}",
    $CFLAGS,
    $DEFINES,
    "-I#{$src_dir}",
    '-isysroot',
    $SDK_INFO['Path'],
    '-framework CoreFoundation -framework CoreServices',
    '-sectcreate __TEXT __info_plist',
    $obj_dir.join('Info.plist')
  ] + OBJ + [
    '-o', $obj_dir.join('fsevent_watch')
  ]
  sh(cmd.map {|s| s.to_s}.join(' '))
end

desc 'compile and link build/fsevent_watch'
task :build => $obj_dir.join('fsevent_watch').to_s

desc 'codesign build/fsevent_watch binary'
task :codesign => :build do
  sh "codesign -s '#{$CODE_SIGN_IDENTITY}' #{$obj_dir.join('fsevent_watch')}"
end

directory $this_dir.parent.join('bin')

desc 'replace bundled fsevent_watch binary with build/fsevent_watch'
task :replace_exe => [$this_dir.parent.join('bin'), :build] do
  sh "mv #{$obj_dir.join('fsevent_watch')} #{$final_exe}"
end

task :default => [:replace_exe, :clean]

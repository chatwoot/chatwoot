# systemd

[systemd](https://www.freedesktop.org/wiki/Software/systemd/) is a commonly
available init system (PID 1) on many Linux distributions. It offers process
monitoring (including automatic restarts) and other useful features for running
Puma in production.

## Service Configuration

Below is a sample puma.service configuration file for systemd, which can be
copied or symlinked to `/etc/systemd/system/puma.service`, or if desired, using
an application or instance-specific name.

Note that this uses the systemd preferred "simple" type where the start command
remains running in the foreground (does not fork and exit).

~~~~ ini
[Unit]
Description=Puma HTTP Server
After=network.target

# Uncomment for socket activation (see below)
# Requires=puma.socket

[Service]
# Puma supports systemd's `Type=notify` and watchdog service
# monitoring, as of Puma 5.1 or later.
# On earlier versions of Puma or JRuby, change this to `Type=simple` and remove
# the `WatchdogSec` line.
Type=notify

# If your Puma process locks up, systemd's watchdog will restart it within seconds.
WatchdogSec=10

# Preferably configure a non-privileged user
# User=

# The path to your application code root directory.
# Also replace the "<YOUR_APP_PATH>" placeholders below with this path.
# Example /home/username/myapp
WorkingDirectory=<YOUR_APP_PATH>

# Helpful for debugging socket activation, etc.
# Environment=PUMA_DEBUG=1

# SystemD will not run puma even if it is in your path. You must specify
# an absolute URL to puma. For example /usr/local/bin/puma
# Alternatively, create a binstub with `bundle binstubs puma --path ./sbin` in the WorkingDirectory
ExecStart=/<FULLPATH>/bin/puma -C <YOUR_APP_PATH>/puma.rb

# Variant: Rails start.
# ExecStart=/<FULLPATH>/bin/puma -C <YOUR_APP_PATH>/config/puma.rb ../config.ru

# Variant: Use `bundle exec puma` instead of binstub
# Variant: Specify directives inline.
# ExecStart=/<FULLPATH>/puma -b tcp://0.0.0.0:9292 -b ssl://0.0.0.0:9293?key=key.pem&cert=cert.pem


Restart=always

[Install]
WantedBy=multi-user.target
~~~~

See
[systemd.exec](https://www.freedesktop.org/software/systemd/man/systemd.exec.html)
for additional details.

## Socket Activation

systemd and Puma also support socket activation, where systemd opens the
listening socket(s) in advance and provides them to the Puma master process on
startup. Among other advantages, this keeps listening sockets open across puma
restarts and achieves graceful restarts, including when upgraded Puma, and is
compatible with both clustered mode and application preload.

**Note:** Any wrapper scripts which `exec`, or other indirections in `ExecStart`
may result in activated socket file descriptors being closed before reaching the
puma master process.

**Note:** Socket activation doesn't currently work on JRuby. This is tracked in
[#1367].

Configure one or more `ListenStream` sockets in a companion `*.socket` unit file
to use socket activation. Also, uncomment the associated `Requires` directive
for the socket unit in the service file (see above.) Here is a sample
puma.socket, matching the ports used in the above puma.service:

~~~~ ini
[Unit]
Description=Puma HTTP Server Accept Sockets

[Socket]
ListenStream=0.0.0.0:9292
ListenStream=0.0.0.0:9293

# AF_UNIX domain socket
# SocketUser, SocketGroup, etc. may be needed for Unix domain sockets
# ListenStream=/run/puma.sock

# Socket options matching Puma defaults
NoDelay=true
ReusePort=true
Backlog=1024

[Install]
WantedBy=sockets.target
~~~~

See
[systemd.socket](https://www.freedesktop.org/software/systemd/man/systemd.socket.html)
for additional configuration details.

Note that the above configurations will work with Puma in either single process
or cluster mode.

### Sockets and symlinks

When using releases folders, you should set the socket path using the shared
folder path (ex. `/srv/projet/shared/tmp/puma.sock`), not the release folder
path (`/srv/projet/releases/1234/tmp/puma.sock`).

Puma will detect the release path socket as different than the one provided by
systemd and attempt to bind it again, resulting in the exception `There is
already a server bound to:`.

### Binding

By default, you need to configure Puma to have binds matching with all
ListenStream statements. Any mismatched systemd ListenStreams will be closed by
Puma.

To automatically bind to all activated sockets, the option
`--bind-to-activated-sockets` can be used. This matches the config DSL
`bind_to_activated_sockets` statement. This will cause Puma to create a bind
automatically for any activated socket. When systemd socket activation is not
enabled, this option does nothing.

This also accepts an optional argument `only` (DSL: `'only'`) to discard any
binds that's not socket activated.

## Usage

Without socket activation, use `systemctl` as root (i.e., via `sudo`) as with
other system services:

~~~~ sh
# After installing or making changes to puma.service
systemctl daemon-reload

# Enable so it starts on boot
systemctl enable puma.service

# Initial startup.
systemctl start puma.service

# Check status
systemctl status puma.service

# A normal restart. Warning: listener's sockets will be closed
# while a new puma process initializes.
systemctl restart puma.service
~~~~

With socket activation, several but not all of these commands should be run for
both socket and service:

~~~~ sh
# After installing or making changes to either puma.socket or
# puma.service.
systemctl daemon-reload

# Enable both socket and service, so they start on boot.  Alternatively
# you could leave puma.service disabled, and systemd will start it on
# the first use (with startup lag on the first request)
systemctl enable puma.socket puma.service

# Initial startup. The Requires directive (see above) ensures the
# socket is started before the service.
systemctl start puma.socket puma.service

# Check the status of both socket and service.
systemctl status puma.socket puma.service

# A "hot" restart, with systemd keeping puma.socket listening and
# providing to the new puma (master) instance.
systemctl restart puma.service

# A normal restart, needed to handle changes to
# puma.socket, such as changing the ListenStream ports. Note
# daemon-reload (above) should be run first.
systemctl restart puma.socket puma.service
~~~~

Here is sample output from `systemctl status` with both service and socket
running:

~~~~
● puma.socket - Puma HTTP Server Accept Sockets
   Loaded: loaded (/etc/systemd/system/puma.socket; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2016-04-07 08:40:19 PDT; 1h 2min ago
   Listen: 0.0.0.0:9233 (Stream)
           0.0.0.0:9234 (Stream)

Apr 07 08:40:19 hx systemd[874]: Listening on Puma HTTP Server Accept Sockets.

● puma.service - Puma HTTP Server
   Loaded: loaded (/etc/systemd/system/puma.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2016-04-07 08:40:19 PDT; 1h 2min ago
 Main PID: 28320 (ruby)
   CGroup: /system.slice/puma.service
           ├─28320 puma 3.3.0 (tcp://0.0.0.0:9233,ssl://0.0.0.0:9234?key=key.pem&cert=cert.pem) [app]
           ├─28323 puma: cluster worker 0: 28320 [app]
           └─28327 puma: cluster worker 1: 28320 [app]

Apr 07 08:40:19 hx puma[28320]: Puma starting in cluster mode...
Apr 07 08:40:19 hx puma[28320]: * Version 3.3.0 (ruby 2.2.4-p230), codename: Jovial Platypus
Apr 07 08:40:19 hx puma[28320]: * Min threads: 0, max threads: 16
Apr 07 08:40:19 hx puma[28320]: * Environment: production
Apr 07 08:40:19 hx puma[28320]: * Process workers: 2
Apr 07 08:40:19 hx puma[28320]: * Phased restart available
Apr 07 08:40:19 hx puma[28320]: * Activated tcp://0.0.0.0:9233
Apr 07 08:40:19 hx puma[28320]: * Activated ssl://0.0.0.0:9234?key=key.pem&cert=cert.pem
Apr 07 08:40:19 hx puma[28320]: Use Ctrl-C to stop
~~~~

### capistrano3-puma

By default, [capistrano3-puma](https://github.com/seuros/capistrano-puma) uses
`pumactl` for deployment restarts outside of systemd. To learn the exact
commands that this tool would use for `ExecStart` and `ExecStop`, use the
following `cap` commands in dry-run mode, and update from the above forking
service configuration accordingly. Note also that the configured `User` should
likely be the same as the capistrano3-puma `:puma_user` option.

~~~~ sh
stage=production # or different stage, as needed
cap $stage puma:start --dry-run
cap $stage puma:stop  --dry-run
~~~~

[Restart]: https://www.freedesktop.org/software/systemd/man/systemd.service.html#Restart=
[#1367]: https://github.com/puma/puma/issues/1367
[#1499]: https://github.com/puma/puma/issues/1499

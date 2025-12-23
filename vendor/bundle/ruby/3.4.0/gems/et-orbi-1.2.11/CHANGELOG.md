
# CHANGELOG.md


## et-orbi 1.2.11  released 2024-03-23

- Cache @rweek and @rday, not @ref, gh-38


## et-orbi 1.2.10  released 2024-03-22

- Refine #rweek computation, aim more at noon instead of midnight, gh-38


## et-orbi 1.2.9  released 2024-03-13

- Refine #rweek computation, aim at noon instead of midnight, gh-38


## et-orbi 1.2.8  released 2024-03-11  (13 ans)

- Cache the @ref time used in the #rweek and #rday computation


## et-orbi 1.2.7  released 2022-03-09

- Fix the wday_in_month computation for floraison/fugit#67


## et-orbi 1.2.6  released 2021-10-30

- Favour IANA timezone name in EtOrbi.make_time


## et-orbi 1.2.5  released 2021-09-18

- Re-use the DateTime.parse result


## et-orbi 1.2.4  released 2020-03-18

- Do not call Chronic (even if enabled) from make_from_array, gh-28
- Be modern, use strftime '%6N', join Ruby 2.x :-)


## et-orbi 1.2.3  released 2020-03-06

- Introduce EtOrbi.chronic_enabled = false and EtOrbi.chronic_enabled?, gh-26


## et-orbi 1.2.2  released 2019-08-19

- Let EoTime#== accept EoTime or ::Time instances, gh-20, gh-7


## et-orbi 1.2.1  released 2019-05-01

- More US time zone corrections, Vais Salikhov, gh-19


## et-orbi 1.2.0  released 2019-04-25

- Add missing US time zone aliases, Vais Salikhov, gh-18
- Stop fooling around and stick to https://semver.org, start with 1.2.0


## et-orbi 1.1.8  released 2019-04-11

- Work hard to make it work on Windows
- Implement EoTime#rweek and #rday (reference week, reference day)
- Alias EoTime#in_time_zone(zone) to #localtime(zone)
- Stop fooling around and stick to https://semver.org


## et-orbi 1.1.7  released 2019-01-14

- Rework Chronic integration, prevent conflict with ActiveSupport Time.zone
- Implement EtOrbi.extract_zone(s) (returns s1 and zone name)
- Adapt specs and EoTime#to_debug_s to Windows on Appveyor


## et-orbi 1.1.6  released 2018-09-05

- Ensure Olson timezone name regex covers all timezone names
  https://github.com/floraison/fugit/issues/9


## et-orbi 1.1.5  released 2018-08-25

- Prevent encoding issue on Windows with "Mitteleuropaeische Sommerzeit", gh-15


## et-orbi 1.1.4  released 2018-07-25

- Silence 3 Ruby warnings (thanks Jamie Stackhouse, gh-13)
- Introduce EtOrbi::Eotime.reach(points)


## et-orbi 1.1.3  released 2018-07-14

- Introduce EtOrbi::EoTime#ambiguous?
- Introduce EtOrbi::EoTime#to_z for precise timezones (not offsets)


## et-orbi 1.1.2  released 2018-05-24

- Let EtOrbi.get_tzone understand "CST+0800"
- Introduce EtOrbi.to_windows_tz (Asia/Kolkata to IST-5:30)


## et-orbi 1.1.1  released 2018-05-04

- Stop caching the local tzone, cache the tools used for determining it


## et-orbi 1.1.0  released 2018-03-25

- Implement EoTime .utc and .local (based on Time .utc and .local)
- Add EoTime#translate(target_zone) as #localtime(target_zone) alias
- Correct EoTime#iso8601 (was always returning zulu iso8601 string)


## et-orbi 1.0.9  released 2018-01-19

- Silence EoTime#strfz warning
- Silence warnings reported by @mdave16, gh-10
- @philr added support for upcoming tzinfo 2.x, gh-9


## et-orbi 1.0.8  released 2017-10-24

- Ensure ::EoTime.new accepts ActiveSupport::TimeZone, closes gh-8


## et-orbi 1.0.7  released 2017-10-07

- Leverage ActiveSupport::TimeWithZone when present, gh-6
- Start error messages with a capital


## et-orbi 1.0.6  released 2017-10-05

- Introduce `make info`
- Alias EoTime#to_utc_time to #utc
- Alias EoTime#to_t to #to_local_time
- Implement EoTime#to_local_time (since #to_time returns a UTC Time instance)


## et-orbi 1.0.5  released 2017-06-23

- Rework EtOrbi.make_time
- Let EtOrbi.make_time accept array or array of args
- Implement EoTime#localtime(zone=nil)
- Move Fugit#wday_in_month into EoTime
- Clarify #add, #subtract, #- and #+ contracts
- Ensure #add and #subtract return `self`
- Make #inc(seconds, direction) public
- Implement EoTime#utc?


## et-orbi 1.0.4  released 2017-05-10

- Survive older versions of TZInfo with poor `<=>` impl, gh-1


## et-orbi 1.0.3  released 2017-04-07

- Let not #render_nozone_time fail when local_tzone is nil


## et-orbi 1.0.2  released 2017-03-24

- Enhance no zone ArgumentError data
- Separate module methods from EoTime methods


## et-orbi 1.0.1  released 2017-03-22

- Detail Rails and Active Support info in nozone err


## et-orbi 1.0.0  released 2017-03-22

- First release for rufus-scheduler


## et-orbi 0.9.5  released 2017-03-17

- Empty, initial release, 圓さんの家で


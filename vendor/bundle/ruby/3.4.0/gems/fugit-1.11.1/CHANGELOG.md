
# CHANGELOG.md


## fugit 1.11.1 released 2024-08-15

* Prevent nat parsing chocking on long input (> 256 chars), gh-104


## fugit 1.11.0 released 2024-04-24

* Revert gh-86 ban on `every 27 hours` / `* */27 * * *` for gh-103


## fugit 1.10.1 released 2024-02-29

* Fix on Ruby 2.2.6 thanks to @aunghtain, gh-93


## fugit 1.10.0 released 2024-02-22

* Implement `Fugit::Cron#within(time_start, time_end)`
* Implement `Fugit::Cron#within(time_range)`
* Implement iterator-returning `Fugit::Cron#next` and `#prev`


## fugit 1.9.0 released 2023-10-24

* Let nat parse "last", gh-88
* Change that I am not sure about, gh-86


## fugit 1.8.1 released 2023-01-20

* Fix for month subtraction, gh-84, @mreinsch
* Fix duration - time, gh-85, @mreinsch


## fugit 1.8.0 released 2022-12-06

* Introduce Fugit.parse_cronish and .do_parse_cronish, gh-70


## fugit 1.7.2 released 2022-11-03

* Fix 'every day at 12:15 am', gh-81
* Fix 'every day at 5:00pm', gh-81


## fugit 1.7.1 released 2022-09-21

* Change behaviour for "0 0/5 * * *", gh-79
  go "every 5h start hour 0", previous behaviour only triggered at hour 0


## fugit 1.7.0 released 2022-09-15

* Introduce the & cron syntax (day-of-month AND day-of-week), gh-78
* Change how cron deals with modulo and offset, gh-76
* Be liberal with extra commas, gh-77


## fugit 1.6.0 release 2022-08-25

* Ensure input strings are stripped before parsing, gh-74


## fugit 1.5.3 released 2022-04-02

* Fix Fugit::Cron.to_s vs "0 13 * * wed%2", gh-68


## fugit 1.5.2 released 2021-09-18

* Simplify inc_day, gh-62


## fugit 1.5.1 released 2021-08-18

* Fix #next_time break issue for America/Santiago into DST, gh-60


## fugit 1.5.0 released 2021-06-08

* Accept "at 12 noon" and "at 12 midday" as "* 12 * * *", gh-57
* Accept "at 12pm" as "0 12 * * *", not "0 24 * * *", gh-57
* Accept "15/30 * * * *" as "15-59/30 * * * *", gh-56


## fugit 1.4.5 released 2021-04-22

* Accept "* * * Mon%2+2", gh-47


## fugit 1.4.4 released 2021-03-25

* Ensure leaving ZH DST is OK, gh-53


## fugit 1.4.3 released 2021-03-23

* Fix entering DST issue, gh-53


## fugit 1.4.2 released 2021-01-12

* Fix Fugit::Cron.previous_time vs last day of month, gh-51
* Let Fugit::Cron.parse('') return nil, gh-49


## fugit 1.4.1 released 2020-11-25

* Suppress warning, gh-46, thanks @amatsuda


## fugit 1.4.0 released 2020-10-27

* Ensure cron accepts "25-L" for monthday, gh-45
* Allow for "every weekday 8am to 5pm", gh-44
* Allow "every day from the 25th to the last", gh-45
* Rework nat parser


## fugit 1.3.9 released 2020-09-17

* Prevent "New York skip", gh-43, thanks @honglooker


## fugit 1.3.8 released 2020-08-06

* Parse 'every day at 8:30' and ' at 8:30 pm', gh-42


## fugit 1.3.7 released 2020-08-05

* Parse 'every 12 hours at minute 50', gh-41


## fugit 1.3.6 released 2020-06-01

* Introduce new nat syntaxed, gh-38
* Rework nat parser


## fugit 1.3.5 released 2020-05-07

* Implement cron @noon, gh-37
* Normalize "every x", gh-37


## fugit 1.3.4 released 2020-04-06

* Prevent #rough_frequency returning 0, gh-36


## fugit 1.3.3 released 2019-08-29

* Fix Cron#match?(t) with respect to the cron's timezone, gh-31


## fugit 1.3.2 released 2019-08-14

* Allow for "* 0-24 * * *", gh-30


## fugit 1.3.1 released 2019-07-27

* Fix nat parsing for 'every day at 18:00 and 18:15', gh-29
*   and for 'every day at 18:00, 18:15, 20:00, and 20:15', gh-29
* Ensure multi: :fail doesn't force into multi, gh-28
* Fix nat parsing for 'every Fri-Sun at 18:00', gh-27


## fugit 1.3.0 released 2019-07-21

* Introduce Fugit.parse_nat('every day at 18:00 and 19:15', multi: true)
* Rework AM/PM parsing


## fugit 1.2.3 released 2019-07-16

* Allow for "from Monday to Friday at 19:22", gh-25
* Allow for "every Monday to Friday at 18:20", gh-25
* Allow for "every day at 18:00 and 20:00", gh-24


## fugit 1.2.2 released 2019-06-21

* Fix Fugit.parse vs "every 15 minutes", gh-22


## fugit 1.2.1 released 2019-05-04

* Return nil when parsing a cron with February 30 and friend, gh-21


## fugit 1.2.0 released 2019-04-22

* Accept "/15 * * * *" et al, gh-19 and resque/resque-scheduler#649
* Stop fooling around and stick to https://semver.org


## fugit 1.1.10 released 2019-04-12

* Implement `"0 9 * * sun%2+1"`
* Simplify cron parser


## fugit 1.1.9  released 2019-03-26

* Fix cron `"0 9 29 feb *"` endless loop, gh-18
* Fix cron endless loop when #previous_time(t) and t matches, gh-15
* Simplify Cron #next_time / #previous_time breaker system, gh-15
  Thanks @godfat and @conet


## fugit 1.1.8  released 2019-01-17

* Ensure Cron#next_time happens in cron's time zone, gh-12


## fugit 1.1.7  released 2019-01-15

* Add breaker to Cron #next_time / #previous_time, gh-13
* Prevent 0 as a month in crons, gh-10
* Prevent 0 as a day of month in crons, gh-10


## fugit 1.1.6  released 2018-09-05

* Ensure `Etc/GMT-11` and all Olson timezone names are recognized
  in cron and nat strings, gh-9


## fugit 1.1.5  released 2018-07-30

* Add Fugit::Cron#rough_frequency (for https://github.com/jmettraux/rufus-scheduler/pull/276)


## fugit 1.1.4  released 2018-07-20

* Add duration support for Fugit::Nat (@cristianbica gh-7)
* Fix Duration not correctly parsing minutes and seconds long format (@cristianbica gh-7)
* Add timezone support for Fugit::Nat (@cristianbica gh-7)
* Use timezone name when converting a Fugit::Cron to cron string (@cristianbica gh-7)


## fugit 1.1.3  released 2018-06-21

* Silenced Ruby warnings (Utilum in gh-4)


## fugit 1.1.2  released 2018-06-20

* Added Fugit::Cron#seconds (Tero Marttila in gh-3)


## fugit 1.1.1  released 2018-05-04

* Depend on et-orbi 1.1.1 and better


## fugit 1.1.0  released 2018-03-27

* Travel in Cron zone in #next_time and #previous_time, return from zone
* Parse and store timezone in Fugit::Cron
* Introduce Fugit::Duration#deflate month: d / year: d
* Introduce Fugit::Duration#drop_seconds
* Alias Fugit::Duration#to_h to Fugit::Duration#h
* Introduce to_rufus_s (1y2M3d) vs to_plain_s (1Y2M3D)
* Ensure Duration#deflate preserves at least `{ sec: 0 }`
* Stringify 0 seconds as "0s"
* Ignore "-5" and "-5.", only accept "-5s" and "-5.s"
* Introduce "signed durations", "-1Y+2Y-3m"
* Ensure `1.0d1.0w1.0d` gets parsed correctly
* Ensure Fugit::Cron.next_time returns plain seconds (.0, not .1234...)
* Introduce Fugit::Frequency for cron


## fugit 1.0.0  released 2017-06-23

* Introduce et-orbi dependency (1.0.5 or better)
* Wire #deflate into Duration.to_long_s / .to_iso_s / .to_plain_s


## fugit 0.9.6  released 2017-05-24

* Provide Duration.to_long_s / .to_iso_s / .to_plain_s at class level


## fugit 0.9.5  released 2017-01-07

* Implement Fugit.determine_type(s)
* Rename core.rb to parse.rb


## fugit 0.9.4  released 2017-01-06

* Accept cron strings with seconds


## fugit 0.9.3  released 2017-01-05

* First version of Fugit::Nat


## fugit 0.9.2  released 2017-01-04

* Accept decimal places for duration seconds
* Alias Fugit .parse_in to .parse_duration


## fugit 0.9.1  released 2017-01-03

* Implement Fugit::Duration #inflate and #deflate
* Bring in Fugit::Duration
* Implement Fugit .parse, .parse_at and .parse_cron


## fugit 0.9.0  released 2017-01-03

* Initial release


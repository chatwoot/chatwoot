![logotype a happy-07](https://user-images.githubusercontent.com/36028424/40263395-4318481e-5b44-11e8-92e5-3dcc1ce169b3.png)

# Faker
[![Tests](https://github.com/faker-ruby/faker/workflows/Tests/badge.svg)](https://github.com/faker-ruby/faker/actions?query=workflow%3ATests)
[![Gem Version](https://badge.fury.io/rb/faker.svg)](https://badge.fury.io/rb/faker)
[![Inline docs](https://inch-ci.org/github/faker-ruby/faker.svg?branch=main)](https://inch-ci.org/github/faker-ruby/faker)
[![Test Coverage](https://api.codeclimate.com/v1/badges/ef54c7f9df86e965d64b/test_coverage)](https://codeclimate.com/github/stympy/faker/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/ef54c7f9df86e965d64b/maintainability)](https://codeclimate.com/github/stympy/faker/maintainability)

Faker is a port of [Perl's Data::Faker library](https://metacpan.org/pod/Data::Faker).
It's a library for generating fake data such as names, addresses, and phone numbers.

Faker helps you generate realistic test data, and populate your
database with more than a couple of records while you're doing development.

It comes in very handy for taking screenshots (taking screenshots for a personal project)
and it was the original impetus for the creation of this gem).

## Quick links

- 📖 **[Read the documentation for the latest version][rubydocs].**
- 📢 **[See what's changed in recent versions][changelog].**

[rubydocs]: https://www.rubydoc.info/gems/faker/
[changelog]: CHANGELOG.md

## Table of Contents

- [Faker](#faker)
  - [Quick links](#quick-links)
  - [Table of Contents](#table-of-contents)
    - [Notes](#notes)
  - [Getting Started](#getting-started)
  - [Usage](#usage)
      - [A note about the Generators versions](#a-note-about-the-generators-versions)
    - [Ensuring unique values](#ensuring-unique-values)
    - [Deterministic Random](#deterministic-random)
    - [Customization](#customization)
    - [Minitest and Faker \>= 2.22](#minitest-and-faker--222)
  - [Generators](#generators)
  - [Contributing](#contributing)
  - [Versioning](#versioning)
  - [License](#license)

### Notes

* While Faker generates data at random, returned values are not guaranteed to be unique by default.
  To explicitly specify when you require unique values, see [Ensuring Unique Values](#ensuring-unique-values).
  Values also can be deterministic if you use the deterministic feature, see [Deterministic Random](#deterministic-random)
* This is the `main` branch of Faker and may contain changes that are not yet released.
  Please refer to the README of your version for the available methods.
  The list of all versions is [available here](https://github.com/stympy/faker/releases).

## Getting Started

Start by including `faker` in your Gemfile:

```ruby
gem 'faker'
```

Then run `bundle install`.

## Usage

Here are some examples of how to use Faker:

```ruby
require 'faker'

Faker::Name.name      #=> "Christophe Bartell"

Faker::Address.full_address #=> "5479 William Way, East Sonnyhaven, LA 63637"

Faker::Markdown.emphasis #=> "Quo qui aperiam. Amet corrupti distinctio. Sit quia *dolor.*"

Faker::TvShows::RuPaul.queen #=> "Violet Chachki"

Faker::Alphanumeric.alpha(number: 10) #=> "zlvubkrwga"

Faker::ProgrammingLanguage.name #=> "Ruby"
```

For a complete list of the generators, see [Generators](#generators).

#### A note about the Generators versions

If you get a `uninitialized constant Faker::[some_class]` error, your version of
the gem is behind main.

To make sure that your gem is the one
documented here, change the line in your Gemfile to:

```ruby
gem 'faker', :git => 'https://github.com/faker-ruby/faker.git', :branch => 'main'
```

The generators have the `@faker.version` tag on top of their implementation.
From the tags, you can identify the version the generator was added:

```ruby
# Faker::TvShows::ParksAndRec.character

# @faker.version 1.9.0
def character
  fetch('parks_and_rec.characters')
end
```

### Ensuring unique values

To ensure Faker generates unique values, prefix your method call with `unique`:

```ruby
Faker::Name.unique.name # This will return a unique name every time it is called
```

If too many unique values are requested from a generator that has a limited
number of potential values, a `Faker::UniqueGenerator::RetryLimitExceeded`
exception may be raised. It is possible to clear the record of unique values
that have been returned, for example between tests.

```ruby
Faker::Name.unique.clear # Clears used values for Faker::Name
Faker::UniqueGenerator.clear # Clears used values for all generators
```

You also can give some already used values to the unique generator if you have
collisions with the generated data (i.e: using FactoryBot with random and
manually set values).

```ruby
# Usage:
# Faker::<generator>.unique.exclude(method, arguments, list)

# Add 'azerty' and 'wxcvbn' to the string generator with 6 char length
Faker::Lorem.unique.exclude :string, [number: 6], %w[azerty wxcvbn]
```

### Deterministic Random

Faker supports seeding of its pseudo-random number generator (PRNG)
to provide deterministic output of repeated method calls.

```ruby
Faker::Config.random = Random.new(42)
Faker::Company.bs #=> "seize collaborative mindshare"
Faker::Company.bs #=> "engage strategic platforms"
Faker::Config.random = Random.new(42)
Faker::Company.bs #=> "seize collaborative mindshare"
Faker::Company.bs #=> "engage strategic platforms"

Faker::Config.random = nil # seeds the PRNG using default entropy sources
Faker::Config.random.seed #=> 185180369676275068918401850258677722187
Faker::Company.bs #=> "cultivate viral synergies"
```

### Customization

You may want Faker to print information depending on your location in the world.
To assist you in this, Faker uses the `I18n` gem to store strings and formats to
represent the names and postal codes of the area of your choosing.

Just set the locale you want as shown below, and Faker will take care of the rest.

```ruby
Faker::Config.locale = 'es'
# or
Faker::Config.locale = :es
```

Note: Overriding the default locale might not be thread-safe. See [Locale setting can be ignored #2563](https://github.com/faker-ruby/faker/issues/2563) for more details.

To override Faker's locales,
check out the [locales README](lib/locales/README.md).

### Minitest and Faker >= 2.22

To prevent Faker (version >= 2.22) from generating duplicate values when using Minitest,
you might need to add the following to the `test_helper.rb` or `rails_helper.rb` file:

```ruby
  Faker::Config.random = Random.new
```

See [Issue #2534](https://github.com/faker-ruby/faker/issues/2534) for more details.

## Generators

This is the full list of generators available with this gem. If you need details about any of them, make sure to consult the documentation.

**NOTE: Some of the generators below aren't released yet. If you want to use them, change the line in your gemfile to:**

```ruby
gem 'faker', :git => 'https://github.com/faker-ruby/faker.git', :branch => 'main'
```

<details>
  <summary>Default</summary>

  - [Faker::Address](doc/default/address.md)
  - [Faker::Alphanumeric](doc/default/alphanumeric.md)
  - [Faker::Ancient](doc/default/ancient.md)
  - [Faker::App](doc/default/app.md)
  - [Faker::Appliance](doc/default/appliance.md)
  - [Faker::Artist](doc/default/artist.md)
  - [Faker::Avatar](doc/default/avatar.md)
  - [Faker::Bank](doc/default/bank.md)
  - [Faker::Barcode](doc/default/barcode.md)
  - [Faker::Beer](doc/default/beer.md)
  - [Faker::Blood](doc/default/blood.md)
  - [Faker::Boolean](doc/default/boolean.md)
  - [Faker::BossaNova](doc/default/bossa_nova.md)
  - [Faker::Business](doc/default/business.md)
  - [Faker::Camera](doc/default/camera.md)
  - [Faker::Cannabis](doc/default/cannabis.md)
  - [Faker::ChileRut](doc/default/chile_rut.md)
  - [Faker::ChuckNorris](doc/default/chuck_norris.md)
  - [Faker::Code](doc/default/code.md)
  - [Faker::Coffee](doc/default/coffee.md)
  - [Faker::Coin](doc/default/coin.md)
  - [Faker::Color](doc/default/color.md)
  - [Faker::Commerce](doc/default/commerce.md)
  - [Faker::Company](doc/default/company.md)
  - [Faker::Compass](doc/default/compass.md)
  - [Faker::Computer](doc/default/computer.md)
  - [Faker::Construction](doc/default/construction.md)
  - [Faker::Cosmere](doc/default/cosmere.md)
  - [Faker::Crypto](doc/default/crypto.md)
  - [Faker::CryptoCoin](doc/default/crypto_coin.md)
  - [Faker::Currency](doc/default/currency.md)
  - [Faker::Date](doc/default/date.md)
  - [Faker::DcComics](doc/default/dc_comics.md)
  - [Faker::Demographic](doc/default/demographic.md)
  - [Faker::Dessert](doc/default/dessert.md)
  - [Faker::Device](doc/default/device.md)
  - [Faker::DrivingLicence](doc/default/driving_licence.md)
  - [Faker::Drone](doc/drone/drone.md)
  - [Faker::Educator](doc/default/educator.md)
  - [Faker::ElectricalComponents](doc/default/electrical_components.md)
  - [Faker::Emotion](doc/default/emotion.md)
  - [Faker::Esport](doc/default/esport.md)
  - [Faker::File](doc/default/file.md)
  - [Faker::Finance](doc/default/finance.md)
  - [Faker::Food](doc/default/food.md)
  - [Faker::FunnyName](doc/default/funny_name.md)
  - [Faker::Gender](doc/default/gender.md)
  - [Faker::GreekPhilosophers](doc/default/greek_philosophers.md)
  - [Faker::Hacker](doc/default/hacker.md)
  - [Faker::Hipster](doc/default/hipster.md)
  - [Faker::Hobby](doc/default/hobby.md)
  - [Faker::House](doc/default/house.md)
  - [Faker::IDNumber](doc/default/id_number.md)
  - [Faker::IndustrySegments](doc/default/industry_segments.md)
  - [Faker::Internet](doc/default/internet.md)
  - [Faker::Invoice](doc/default/invoice.md)
  - [Faker::Job](doc/default/job.md)
  - [Faker::Json](doc/default/json.md)
  - [Faker::Kpop](doc/default/kpop.md)
  - [Faker::Lorem](doc/default/lorem.md)
  - [Faker::LoremFlickr](doc/default/lorem_flickr.md)
  - [Faker::Markdown](doc/default/markdown.md)
  - [Faker::Marketing](doc/default/marketing.md)
  - [Faker::Measurement](doc/default/measurement.md)
  - [Faker::Military](doc/default/military.md)
  - [Faker::Mountain](doc/default/mountain.md)
  - [Faker::Name](doc/default/name.md)
  - [Faker::Nation](doc/default/nation.md)
  - [Faker::NatoPhoneticAlphabet](doc/default/nato_phonetic_alphabet.md)
  - [Faker::NationalHealthService](doc/default/national_health_service.md)
  - [Faker::Number](doc/default/number.md)
  - [Faker::Omniauth](doc/default/omniauth.md)
  - [Faker::PhoneNumber](doc/default/phone_number.md)
  - [Faker::Placeholdit](doc/default/placeholdit.md)
  - [Faker::ProgrammingLanguage](doc/default/programming_language.md)
  - [Faker::Relationship](doc/default/relationship.md)
  - [Faker::Restaurant](doc/default/restaurant.md)
  - [Faker::Science](doc/default/science.md)
  - [Faker::SlackEmoji](doc/default/slack_emoji.md)
  - [Faker::Source](doc/default/source.md)
  - [Faker::SouthAfrica](doc/default/south_africa.md)
  - [Faker::Space](doc/default/space.md)
  - [Faker::String](doc/default/string.md)
  - [Faker::Stripe](doc/default/stripe.md)
  - [Faker::Subscription](doc/default/subscription.md)
  - [Faker::Superhero](doc/default/superhero.md)
  - [Faker::Tea](doc/default/tea.md)
  - [Faker::Team](doc/default/team.md)
  - [Faker::Time](doc/default/time.md)
  - [Faker::Twitter](doc/default/twitter.md)
  - [Faker::Types](doc/default/types.md)
  - [Faker::University](doc/default/university.md)
  - [Faker::Vehicle](doc/default/vehicle.md)
  - [Faker::Verbs](doc/default/verbs.md)
  - [Faker::VulnerabilityIdentifier](doc/default/vulnerability_identifier.md)
  - [Faker::WorldCup](doc/default/world_cup.md)
</details>

<details>
  <summary>Blockchain</summary>

  - [Faker::Blockchain::Aeternity](doc/blockchain/aeternity.md)
  - [Faker::Blockchain::Bitcoin](doc/blockchain/bitcoin.md)
  - [Faker::Blockchain::Ethereum](doc/blockchain/ethereum.md)
  - [Faker::Blockchain::Tezos](doc/blockchain/tezos.md)
</details>

<details>
  <summary>Books</summary>

  - [Faker::Book](doc/books/book.md)
  - [Faker::Books::CultureSeries](doc/books/culture_series.md)
  - [Faker::Books::Dune](doc/books/dune.md)
  - [Faker::Books::Lovecraft](doc/books/lovecraft.md)
  - [Faker::Books::TheKingkillerChronicle](doc/books/the_kingkiller_chronicle.md)
</details>

<details>
  <summary>Fantasy</summary>

  - [Faker::Fantasy::Tolkien](doc/fantasy/tolkien.md)
</details>

<details>
  <summary>Travel</summary>

  - [Faker:Travel::Airport](doc/travel/airport.md)
</details>

<details>
  <summary>Creature</summary>

  - [Faker::Creature::Animal](doc/creature/animal.md)
  - [Faker::Creature::Bird](doc/creature/bird.md)
  - [Faker::Creature::Cat](doc/creature/cat.md)
  - [Faker::Creature::Dog](doc/creature/dog.md)
  - [Faker::Creature::Horse](doc/creature/horse.md)
</details>

<details>
  <summary>Games</summary>

  - [Faker::Game](doc/games/game.md)
  - [Faker::Games::ClashOfClans](doc/games/clash_of_clans.md)
  - [Faker::Games::DnD](doc/games/dnd.md)
  - [Faker::Games::Dota](doc/games/dota.md)
  - [Faker::Games::ElderScrolls](doc/games/elder_scrolls.md)
  - [Faker::Games::Fallout](doc/games/fallout.md)
  - [Faker::Games::HalfLife](doc/games/half_life.md)
  - [Faker::Games::Heroes](doc/games/heroes.md)
  - [Faker::Games::HeroesOfTheStorm](doc/games/heroes_of_the_storm.md)
  - [Faker::Games::LeagueOfLegends](doc/games/league_of_legends.md)
  - [Faker::Games::Minecraft](doc/games/minecraft.md)
  - [Faker::Games::Myst](doc/games/myst.md)
  - [Faker::Games::Overwatch](doc/games/overwatch.md)
  - [Faker::Games::Pokemon](doc/games/pokemon.md)
  - [Faker::Games::SonicTheHedgehog](doc/games/sonic_the_hedgehog.md)
  - [Faker::Games::StreetFighter](doc/games/street_fighter.md)
  - [Faker::Games::SuperMario](doc/games/super_mario.md)
  - [Faker::Games::SuperSmashBros](doc/games/super_smash_bros.md)
  - [Faker::Games::Touhou](doc/games/touhou.md)
  - [Faker::Games::WarhammerFantasy](doc/games/warhammer_fantasy.md)
  - [Faker::Games::Witcher](doc/games/witcher.md)
  - [Faker::Games::WorldOfWarcraft](doc/games/world_of_warcraft.md)
  - [Faker::Games::Zelda](doc/games/zelda.md)
</details>

<details>
  <summary>Japanese Media</summary>

  - [Faker::JapaneseMedia::CowboyBebop](doc/japanese_media/cowboy_bebop.md)
  - [Faker::JapaneseMedia::DragonBall](doc/japanese_media/dragon_ball.md)
  - [Faker::JapaneseMedia::OnePiece](doc/japanese_media/one_piece.md)
  - [Faker::JapaneseMedia::StudioGhibli](doc/japanese_media/studio_ghibli.md)
  - [Faker::JapaneseMedia::SwordArtOnline](doc/japanese_media/sword_art_online.md)
  - [Faker::JapaneseMedia::Naruto](doc/japanese_media/naruto.md)
  - [Faker::JapaneseMedia::Doraemon](doc/japanese_media/doraemon.md)
  - [Faker::JapaneseMedia::Conan](doc/japanese_media/conan.md)
  - [Faker::JapaneseMedia::FmaBrotherhood](doc/japanese_media/fullmetal_alchemist_brotherhood.md)
</details>

<details>
  <summary>Movies</summary>

  - [Faker::Movie](doc/movies/movie.md)
  - [Faker::Movies::Avatar](doc/movies/avatar.md)
  - [Faker::Movies::BackToTheFuture](doc/movies/back_to_the_future.md)
  - [Faker::Movies::Departed](doc/movies/departed.md)
  - [Faker::Movies::Ghostbusters](doc/movies/ghostbusters.md)
  - [Faker::Movies::HarryPotter](doc/movies/harry_potter.md)
  - [Faker::Movies::HitchhikersGuideToTheGalaxy](doc/movies/hitchhikers_guide_to_the_galaxy.md)
  - [Faker::Movies::Hobbit](doc/movies/hobbit.md)
  - [Faker::Movies::HowToTrainYourDragon](doc/movies/how_to_train_your_dragon.md)
  - [Faker::Movies::Lebowski](doc/movies/lebowski.md)
  - [Faker::Movies::LordOfTheRings](doc/movies/lord_of_the_rings.md)
  - [Faker::Movies::PrincessBride](doc/movies/princess_bride.md)
  - [Faker::Movies::StarWars](doc/movies/star_wars.md)
  - [Faker::Movies::TRON](doc/movies/tron.md)
  - [Faker::Movies::VForVendetta](doc/movies/v_for_vendetta.md)
</details>

<details>
  <summary>Music</summary>

  - [Faker::Music](doc/music/music.md)
  - [Faker::Music::GratefulDead](doc/music/grateful_dead.md)
  - [Faker::Music::Hiphop](doc/music/hiphop.md)
  - [Faker::Music::Opera](doc/music/opera.md)
  - [Faker::Music::PearlJam](doc/music/pearl_jam.md)
  - [Faker::Music::Phish](doc/music/phish.md)
  - [Faker::Music::Prince](doc/music/prince.md)
  - [Faker::Music::RockBand](doc/music/rock_band.md)
  - [Faker::Music::Rush](doc/music/rush.md)
  - [Faker::Music::UmphreysMcgee](doc/music/umphreys_mcgee.md)
</details>

<details>
  <summary>Quotes</summary>

  - [Faker::Quote](doc/quotes/quote.md)
  - [Faker::Quotes::Chiquito](doc/quotes/chiquito.md)
  - [Faker::Quotes::Rajnikanth](doc/quotes/rajnikanth.md)
  - [Faker::Quotes::Shakespeare](doc/quotes/shakespeare.md)
</details>

<details>
  <summary>Sports</summary>

  - [Faker::Sports](doc/sports/sports.md)
  - [Faker::Sports::Basketball](doc/sports/basketball.md)
  - [Faker::Sports::Chess](doc/sports/chess.md)
  - [Faker::Sports::Football](doc/sports/football.md)
  - [Faker::Sports::Mountaineering](doc/sports/mountaineering.md)
  - [Faker::Sports::Volleyball](doc/sports/volleyball.md)
</details>

<details>
  <summary>Tv Shows</summary>

  - [Faker::TvShows::AquaTeenHungerForce](doc/tv_shows/aqua_teen_hunger_force.md)
  - [Faker::TvShows::BigBangTheory](doc/tv_shows/big_bang_theory.md)
  - [Faker::TvShows::BojackHorseman](doc/tv_shows/bojack_horseman.md)
  - [Faker::TvShows::BreakingBad](doc/tv_shows/breaking_bad.md)
  - [Faker::TvShows::BrooklynNineNine](doc/tv_shows/brooklyn_nine_nine.md)
  - [Faker::TvShows::Buffy](doc/tv_shows/buffy.md)
  - [Faker::TvShows::Community](doc/tv_shows/community.md)
  - [Faker::TvShows::DrWho](doc/tv_shows/dr_who.md)
  - [Faker::TvShows::DumbAndDumber](doc/tv_shows/dumb_and_dumber.md)
  - [Faker::TvShows::FamilyGuy](doc/tv_shows/family_guy.md)
  - [Faker::TvShows::FinalSpace](doc/tv_shows/final_space.md)
  - [Faker::TvShows::Friends](doc/tv_shows/friends.md)
  - [Faker::TvShows::GameOfThrones](doc/tv_shows/game_of_thrones.md)
  - [Faker::TvShows::HeyArnold](doc/tv_shows/hey_arnold.md)
  - [Faker::TvShows::HowIMetYourMother](doc/tv_shows/how_i_met_your_mother.md)
  - [Faker::TvShows::MichaelScott](doc/tv_shows/michael_scott.md)
  - [Faker::TvShows::NewGirl](doc/tv_shows/new_girl.md)
  - [Faker::TvShows::ParksAndRec](doc/tv_shows/parks_and_rec.md)
  - [Faker::TvShows::RickAndMorty](doc/tv_shows/rick_and_morty.md)
  - [Faker::TvShows::RuPaul](doc/tv_shows/rupaul.md)
  - [Faker::TvShows::Seinfeld](doc/tv_shows/seinfeld.md)
  - [Faker::TvShows::SiliconValley](doc/tv_shows/silicon_valley.md)
  - [Faker::TvShows::Simpsons](doc/tv_shows/simpsons.md)
  - [Faker::TvShows::SouthPark](doc/tv_shows/south_park.md)
  - [Faker::TvShows::Spongebob](doc/tv_shows/spongebob.md)
  - [Faker::TvShows::StarTrek](doc/tv_shows/star_trek.md)
  - [Faker::TvShows::Stargate](doc/tv_shows/stargate.md)
  - [Faker::TvShows::StrangerThings](doc/tv_shows/stranger_things.md)
  - [Faker::TvShows::Suits](doc/tv_shows/suits.md)
  - [Faker::TvShows::Supernatural](doc/tv_shows/supernatural.md)
  - [Faker::TvShows::TheExpanse](doc/tv_shows/the_expanse.md)
  - [Faker::TvShows::TheFreshPrinceOfBelAir](doc/tv_shows/the_fresh_prince_of_bel_air.md)
  - [Faker::TvShows::TheITCrowd](doc/tv_shows/the_it_crowd.md)
  - [Faker::TvShows::TheThickOfIt](doc/tv_shows/the_thick_of_it.md)
  - [Faker::TvShows::TwinPeaks](doc/tv_shows/twin_peaks.md)
  - [Faker::TvShows::VentureBros](doc/tv_shows/venture_bros.md)
</details>

## Contributing

If you have problems, please create a [GitHub Issue](/.github/ISSUE_TEMPLATE/bug-report.md).

Take a look at the [Contributing](CONTRIBUTING.md) document for
instructions on setting up the repo on your machine, understanding the codebase,
and creating a good pull request.

There is a [Discord channel](https://discord.gg/RMumTwB) to discuss anything
regarding improvements or feature requests.

Thank you, contributors!

## Versioning

Faker follows Semantic Versioning 2.0 as defined at https://semver.org.

## License

This code is free to use under the terms of the MIT license.

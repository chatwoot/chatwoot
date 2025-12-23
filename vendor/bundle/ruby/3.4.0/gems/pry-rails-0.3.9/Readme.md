# Description

Avoid repeating yourself, use pry-rails instead of copying the initializer to every rails project.
This is a small gem which causes `rails console` to open [pry](http://pry.github.com/). It therefore depends on *pry*.

# Prerequisites

- A Rails >= 3.0 Application
- Ruby >= 1.9

# Installation

Add this line to your gemfile:

	gem 'pry-rails', :group => :development

`bundle install` and enjoy pry.

# Usage

```
$ rails console
[1] pry(main)> show-routes
     pokemon POST   /pokemon(.:format)      pokemons#create
 new_pokemon GET    /pokemon/new(.:format)  pokemons#new
edit_pokemon GET    /pokemon/edit(.:format) pokemons#edit
             GET    /pokemon(.:format)      pokemons#show
             PUT    /pokemon(.:format)      pokemons#update
             DELETE /pokemon(.:format)      pokemons#destroy
        beer POST   /beer(.:format)         beers#create
    new_beer GET    /beer/new(.:format)     beers#new
   edit_beer GET    /beer/edit(.:format)    beers#edit
             GET    /beer(.:format)         beers#show
             PUT    /beer(.:format)         beers#update
             DELETE /beer(.:format)         beers#destroy
[2] pry(main)> show-routes --grep beer
        beer POST   /beer(.:format)         beers#create
    new_beer GET    /beer/new(.:format)     beers#new
   edit_beer GET    /beer/edit(.:format)    beers#edit
             GET    /beer(.:format)         beers#show
             PUT    /beer(.:format)         beers#update
             DELETE /beer(.:format)         beers#destroy
[3] pry(main)> show-routes --grep new
 new_pokemon GET    /pokemon/new(.:format)  pokemons#new
    new_beer GET    /beer/new(.:format)     beers#new
[4] pry(main)> show-models
Beer
  id: integer
  name: string
  type: string
  rating: integer
  ibu: integer
  abv: integer
  created_at: datetime
  updated_at: datetime
  belongs_to hacker
Hacker
  id: integer
  social_ability: integer
  created_at: datetime
  updated_at: datetime
  has_many pokemons
  has_many beers
Pokemon
  id: integer
  name: string
  caught: binary
  species: string
  abilities: string
  created_at: datetime
  updated_at: datetime
  belongs_to hacker
  has_many beers through hacker

$ DISABLE_PRY_RAILS=1 rails console
irb(main):001:0>
```

## Custom Rails prompt

If you want to permanently include the current Rails environment and project name
in the Pry prompt, put the following lines in your project's `.pryrc`:

```ruby
Pry.config.prompt = Pry::Prompt[:rails][:value]
```

If `.pryrc` could be loaded without pry-rails being available or installed,
guard against setting `Pry.config.prompt` to `nil`:

```ruby
if Pry::Prompt[:rails]
  Pry.config.prompt = Pry::Prompt[:rails][:value]
end
```

Check out `change-prompt --help` for information about temporarily
changing the prompt for the current Pry session.

# Developing and Testing

This repo uses [Roadshow] to generate a [Docker Compose] file for each
supported version of Rails (with a compatible version of Ruby for each one).

To run specs across all versions, you can either [get the Roadshow tool] and
run `roadshow run`, or use Docker Compose directly:

```
$ for fn in scenarios/*.docker-compose-yml; do docker-compose -f $fn run --rm scenario; done
```

You can also manually run the Rails console and server on each version with
`roadshow run rake console` and `roadshow run rake server`, or run them on a
specific version with, e.g., `roadshow run -s rails40 rake console`.

To update the set of scenarios, edit `scenarios.yml` and run `roadshow
generate`, although the Gemfiles in the `scenarios` directory need to be
maintained manually.

[Roadshow]: https://github.com/rf-/roadshow
[Docker Compose]: https://docs.docker.com/compose/
[get the Roadshow tool]: https://github.com/rf-/roadshow/releases

# Alternative

If you want to enable pry everywhere, make sure to check out
[pry everywhere](http://lucapette.me/pry-everywhere).

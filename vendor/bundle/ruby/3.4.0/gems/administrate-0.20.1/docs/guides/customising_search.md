---
title: Customising the search
---

Administrate dashboards provide a search function, but it is quite basic.
Things like search across complex associations, inside JSON columns, or outside
the database (eg: an Elasticsearch index) are not possible out of the box.

Fortunately, Administrate is just Rails, so you can use your existing Rails
knowledge to customize the search feature. Let's look into that.

## In short

Override the `filter_resources` method in your admin controllers in order
to customize the search.

It has two parameters:

* `resources`: an ActiveRecord relation for the model on whose dashboard the
               search originated.
* `search_term:`: a string representing the search query entered by the user.

Return an ActiveRecord relation for the same model as `resources`, matching
the desired search results.

## In more detail

When you install Administrate in your application, it generates an admin
controller for each of your ActiveRecord models, as well as a base controller
that all of these inherit from.

For example, if you have two ActiveRecord models: `Person` and `Address`,
running `rails generate administrate:install` will get you the following
files (plus others that are not relevant here):

* `app/controllers/admin/people_controller.rb`
* `app/controllers/admin/addresses_controller.rb`
* `app/controllers/admin/application_controller.rb`

By default, searches are handled by the `index` action of the controller that
the user was visiting when they performed the search. For example, if a user
is visiting the People dashboard and submits a search, the user is sent to
the path `/admin/people?search=<search query>`. This is routed to
`Admin::PeopleController#index`, where the search query can be read as
`params[:search]`.

By default, these controllers are empty. Administrate's code is implemented
at `Administrate::ApplicationController`, from which all inherit. This is
where search is implemented. You can read the code yourself at:
https://github.com/thoughtbot/administrate/blob/main/app/controllers/administrate/application_controller.rb.

It is in the linked code that you can see what Administrate actually does.
For example, this is the `index` action at the time of writing these lines:

```ruby
    def index
      authorize_resource(resource_class)
      search_term = params[:search].to_s.strip
      resources = filter_resources(scoped_resource, search_term: search_term)
      resources = apply_collection_includes(resources)
      resources = order.apply(resources)
      resources = resources.page(params[:_page]).per(records_per_page)
      page = Administrate::Page::Collection.new(dashboard, order: order)

      render locals: {
        resources: resources,
        search_term: search_term,
        page: page,
        show_search_bar: show_search_bar?,
      }
    end
```

What the above does is applying a few transforms
to the variable `resources`, filtering it, applying includes for associations,
ordering the results, paginating them, and finally handing them over to the
template in order to be rendered. All this is pretty standard Rails, although
split into individual steps that can be overriden by developers in order
to add customizations, and ultimately wrapped in an instance of
`Administrate::Page::Collection` which will read your dashboard definitions
and figure out what fields you want displayed.

It is the filtering part where the search is implemented. You will notice the
`filter_resources` method, which takes a parameter `search_term`. This is what
this method looks like at the moment:

```ruby
    def filter_resources(resources, search_term:)
      Administrate::Search.new(
        resources,
        dashboard,
        search_term,
      ).run
    end
```

The class `Administrate::Search` implements the default search facilities
within Administrate... but you do not have to worry about it! You can ignore
it and implement your own search in `filter_resources`. For example, you
could write your own version in your controller, to override Administrate's
own. Something like this:

```ruby
    def filter_resources(resources, search_term:)
      resources.where(first_name: search_term)
        .or(People.where(last_name: search_term))
    end
```

It can be as complex (or simple) as you want, as long as the return value
of the method is an ActiveRecord relation.

What if you do not want to search in the DB? For example, say that your records
are indexed by Elasticsearch or something like that. You can still search
in your external index and convert the results to an ActiveRecord relation.
Here's an example:

```ruby
    def filter_resources(resources, search_term:)
      # Run the search term through your search facility
      results = MySuperDuperSearchSystem.search_people(search_term)

      # Collect the ids of the results. This assumes that they will
      # be the same ones as in the DB.
      record_ids = results.entries.map(&:id)

      # Use the ids to create an ActiveRecord relation and return it
      People.where(id: record_ids)
    end
```

Note though: the records must still exist in the DB. Administrate does
require ActiveRecord in order to show tables, and to display, create and edit
records.

## A working example

The [Administrate demo app](https://administrate-demo.herokuapp.com/admin)
includes an example of custom search in the "Log Entries" dashboard.
In this app, each `LogEntry` instance has a polymorphic `belongs_to`
association to a `:logeable`. Logeables are other models for which logs can be
created. At the moment these are `Order` and `Customer`.

Administrate's default search is not able to search across polymorphic
associations, and therefore it is not possible to search logs by the contents
of their logeables. Fortunately this can be fixed with a custom search. This is
done by implementing `Admin::LogEntriesController#filter_resources` to override
the default search. You can see the code at
https://github.com/thoughtbot/administrate/blob/main/spec/example_app/app/controllers/admin/log_entries_controller.rb

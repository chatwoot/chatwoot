# [pg_search](http://github.com/Casecommons/pg_search/)

[![Gem Version](https://img.shields.io/gem/v/pg_search.svg?style=flat)](https://rubygems.org/gems/pg_search)
[![Build Status](https://github.com/Casecommons/pg_search/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/Casecommons/pg_search/actions/workflows/ci.yml)
[![Join the chat at https://gitter.im/Casecommons/pg_search](https://img.shields.io/badge/gitter-join%20chat-blue.svg)](https://gitter.im/Casecommons/pg_search?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

## DESCRIPTION

PgSearch builds named scopes that take advantage of PostgreSQL's full text
search.

Read the blog post introducing PgSearch at https://tanzu.vmware.com/content/blog/pg-search-how-i-learned-to-stop-worrying-and-love-postgresql-full-text-search

## REQUIREMENTS

*   Ruby 2.6+
*   ActiveRecord 5.2+
*   PostgreSQL 9.2+
*   [PostgreSQL extensions](https://github.com/Casecommons/pg_search/wiki/Installing-PostgreSQL-Extensions) for certain features

## INSTALL

```
$ gem install pg_search
```

or add this line to your Gemfile:

```ruby
gem 'pg_search'
```

### Non-Rails projects

In addition to installing and requiring the gem, you may want to include the
PgSearch rake tasks in your Rakefile. This isn't necessary for Rails projects,
which gain the Rake tasks via a Railtie.

```ruby
load "pg_search/tasks.rb"
```

## USAGE

To add PgSearch to an Active Record model, simply include the PgSearch module.

```ruby
class Shape < ActiveRecord::Base
  include PgSearch::Model
end
```    

### Contents
* [Multi-search vs. search scopes](#multi-search-vs-search-scopes)
* [Multi-search](#multi-search)
  * [Setup](#setup)
  * [`multisearchable`](#multisearchable)
  * [More Options ](#more-options)
  * [Multi-search associations](#multi-search-associations)
  * [Searching in the global search index](#searching-in-the-global-search-index)
  * [Chaining method calls onto the results](#chaining-method-calls-onto-the-results)
  * [Configuring multi-search](#configuring-multi-search)
  * [Rebuilding search documents for a given class](#rebuilding-search-documents-for-a-given-class)
  * [Disabling multi-search indexing temporarily](#disabling-multi-search-indexing-temporarily)
* [`pg_search_scope`](#pg_search_scope)
  * [Searching against one column](#searching-against-one-column)
  * [Searching against multiple columns](#searching-against-multiple-columns)
  * [Dynamic search scopes](#dynamic-search-scopes)
  * [Searching through associations](#searching-through-associations)
* [Searching using different search features](#searching-using-different-search-features)
  * [`:tsearch` (Full Text Search)](#tsearch-full-text-search)
    * [Weighting](#weighting)
    * [`:prefix` (PostgreSQL 8.4 and newer only)](#prefix-postgresql-84-and-newer-only)
    * [`:negation`](#negation)
    * [`:dictionary`](#dictionary)
    * [`:normalization`](#normalization)
    * [`:any_word`](#any_word)
    * [`:sort_only`](#sort_only)
    * [`:highlight`](#highlight)
  * [`:dmetaphone` (Double Metaphone soundalike search)](#dmetaphone-double-metaphone-soundalike-search)
  * [`:trigram` (Trigram search)](#trigram-trigram-search)
    * [`:threshold`](#threshold)
    * [`:word_similarity`](#word_similarity)
* [Limiting Fields When Combining Features](#limiting-fields-when-combining-features)
* [Ignoring accent marks](#ignoring-accent-marks)
* [Using tsvector columns](#using-tsvector-columns)
  * [Combining multiple tsvectors](#combining-multiple-tsvectors)
* [Configuring ranking and ordering](#configuring-ranking-and-ordering)
  * [`:ranked_by` (Choosing a ranking algorithm)](#ranked_by-choosing-a-ranking-algorithm)
  * [`:order_within_rank` (Breaking ties)](#order_within_rank-breaking-ties)
  * [`PgSearch#pg_search_rank` (Reading a record's rank as a Float)](#pgsearchpg_search_rank-reading-a-records-rank-as-a-float)
  * [Search rank and chained scopes](#search-rank-and-chained-scopes)

### Multi-search vs. search scopes

pg_search supports two different techniques for searching, multi-search and
search scopes.

The first technique is multi-search, in which records of many different Active
Record classes can be mixed together into one global search index across your
entire application. Most sites that want to support a generic search page will
want to use this feature.

The other technique is search scopes, which allow you to do more advanced
searching against only one Active Record class. This is more useful for
building things like autocompleters or filtering a list of items in a faceted
search.

### Multi-search

#### Setup

Before using multi-search, you must generate and run a migration to create the
pg_search_documents database table.

```bash
$ rails g pg_search:migration:multisearch
$ rake db:migrate
```

#### multisearchable

To add a model to the global search index for your application, call
multisearchable in its class definition.

```ruby
class EpicPoem < ActiveRecord::Base
  include PgSearch::Model
  multisearchable against: [:title, :author]
end

class Flower < ActiveRecord::Base
  include PgSearch::Model
  multisearchable against: :color
end
```

If this model already has existing records, you will need to reindex this
model to get existing records into the pg_search_documents table. See the
rebuild task below.

Whenever a record is created, updated, or destroyed, an Active Record callback
will fire, leading to the creation of a corresponding PgSearch::Document
record in the pg_search_documents table. The :against option can be one or
several methods which will be called on the record to generate its search
text.

You can also pass a Proc or method name to call to determine whether or not a
particular record should be included.

```ruby
class Convertible < ActiveRecord::Base
  include PgSearch::Model
  multisearchable against: [:make, :model],
                  if: :available_in_red?
end

class Jalopy < ActiveRecord::Base
  include PgSearch::Model
  multisearchable against: [:make, :model],
                  if: lambda { |record| record.model_year > 1970 }
end
```

Note that the Proc or method name is called in an after_save hook. This means
that you should be careful when using Time or other objects. In the following
example, if the record was last saved before the published_at timestamp, it
won't get listed in global search at all until it is touched again after the
timestamp.

```ruby
class AntipatternExample
  include PgSearch::Model
  multisearchable against: [:contents],
                  if: :published?

  def published?
    published_at < Time.now
  end
end

problematic_record = AntipatternExample.create!(
  contents: "Using :if with a timestamp",
  published_at: 10.minutes.from_now
)

problematic_record.published?     # => false
PgSearch.multisearch("timestamp") # => No results

sleep 20.minutes

problematic_record.published?     # => true
PgSearch.multisearch("timestamp") # => No results

problematic_record.save!

problematic_record.published?     # => true
PgSearch.multisearch("timestamp") # => Includes problematic_record
```

#### More Options 

**Conditionally update pg_search_documents**

You can specify an `:update_if` parameter to conditionally update pg_search documents. For example:

```ruby
multisearchable(
    against: [:body],
    update_if: :body_changed?
  )
```

**Specify additional attributes to be saved on the pg_search_documents table**

You can specify `:additional_attributes` to be saved within the `pg_search_documents` table. For example, perhaps you are indexing a book model and an article model and wanted to include the author_id.

First, we need to add a reference to author to the migration creating our `pg_search_documents` table.

```ruby
  create_table :pg_search_documents do |t|
    t.text :content
    t.references :author, index: true
    t.belongs_to :searchable, polymorphic: true, index: true
    t.timestamps null: false
  end
```

Then, we can send in this additional attribute in a lambda

```ruby
  multisearchable(
    against: [:title, :body],
    additional_attributes: -> (article) { { author_id: article.author_id } }
  )
```

This allows much faster searches without joins later on by doing something like:

```ruby
PgSearch.multisearch(params['search']).where(author_id: 2)
```

*NOTE: You must currently manually call `record.update_pg_search_document` for the additional attribute to be included in the pg_search_documents table*

#### Multi-search associations

Two associations are built automatically. On the original record, there is a
has_one :pg_search_document association pointing to the PgSearch::Document
record, and on the PgSearch::Document record there is a belongs_to :searchable
polymorphic association pointing back to the original record.

```ruby
odyssey = EpicPoem.create!(title: "Odyssey", author: "Homer")
search_document = odyssey.pg_search_document #=> PgSearch::Document instance
search_document.searchable #=> #<EpicPoem id: 1, title: "Odyssey", author: "Homer">
```

#### Searching in the global search index

To fetch the PgSearch::Document entries for all of the records that match a
given query, use PgSearch.multisearch.

```ruby
odyssey = EpicPoem.create!(title: "Odyssey", author: "Homer")
rose = Flower.create!(color: "Red")
PgSearch.multisearch("Homer") #=> [#<PgSearch::Document searchable: odyssey>]
PgSearch.multisearch("Red") #=> [#<PgSearch::Document searchable: rose>]
```

#### Chaining method calls onto the results

PgSearch.multisearch returns an ActiveRecord::Relation, just like scopes do,
so you can chain scope calls to the end. This works with gems like Kaminari
that add scope methods. Just like with regular scopes, the database will only
receive SQL requests when necessary.

```ruby
PgSearch.multisearch("Bertha").limit(10)
PgSearch.multisearch("Juggler").where(searchable_type: "Occupation")
PgSearch.multisearch("Alamo").page(3).per(30)
PgSearch.multisearch("Diagonal").find_each do |document|
  puts document.searchable.updated_at
end
PgSearch.multisearch("Moro").reorder("").group(:searchable_type).count(:all)
PgSearch.multisearch("Square").includes(:searchable)
```

#### Configuring multi-search

PgSearch.multisearch can be configured using the same options as
`pg_search_scope` (explained in more detail below). Just set the
PgSearch.multisearch_options in an initializer:

```ruby
PgSearch.multisearch_options = {
  using: [:tsearch, :trigram],
  ignoring: :accents
}
```

#### Rebuilding search documents for a given class

If you change the :against option on a class, add multisearchable to a class
that already has records in the database, or remove multisearchable from a
class in order to remove it from the index, you will find that the
pg_search_documents table could become out-of-sync with the actual records in
your other tables.

The index can also become out-of-sync if you ever modify records in a way that
does not trigger Active Record callbacks. For instance, the #update_attribute
instance method and the .update_all class method both skip callbacks and
directly modify the database.

To remove all of the documents for a given class, you can simply delete all of
the PgSearch::Document records.

```ruby
PgSearch::Document.delete_by(searchable_type: "Animal")
```

To regenerate the documents for a given class, run:

```ruby
PgSearch::Multisearch.rebuild(Product)
```

The ```rebuild``` method will delete all the documents for the given class
before regenerating them. In some situations this may not be desirable,
such as when you're using single-table inheritance and ```searchable_type```
is your base class. You can prevent ```rebuild``` from deleting your records
like so:

```ruby
PgSearch::Multisearch.rebuild(Product, clean_up: false)
```

```rebuild``` runs inside a single transaction. To run outside of a transaction,
you can pass ```transactional: false``` like so:

```ruby
PgSearch::Multisearch.rebuild(Product, transactional: false)
```

Rebuild is also available as a Rake task, for convenience.

    $ rake pg_search:multisearch:rebuild[BlogPost]

A second optional argument can be passed to specify the PostgreSQL schema
search path to use, for multi-tenant databases that have multiple
pg_search_documents tables. The following will set the schema search path to
"my_schema" before reindexing.

    $ rake pg_search:multisearch:rebuild[BlogPost,my_schema]

For models that are multisearchable :against methods that directly map to
Active Record attributes, an efficient single SQL statement is run to update
the pg_search_documents table all at once. However, if you call any dynamic
methods in :against, the following strategy will be used:

```ruby
PgSearch::Document.delete_all(searchable_type: "Ingredient")
Ingredient.find_each { |record| record.update_pg_search_document }
```

You can also provide a custom implementation for rebuilding the documents by
adding a class method called `rebuild_pg_search_documents` to your model.

```ruby
class Movie < ActiveRecord::Base
  belongs_to :director

  def director_name
    director.name
  end

  multisearchable against: [:name, :director_name]

  # Naive approach
  def self.rebuild_pg_search_documents
    find_each { |record| record.update_pg_search_document }
  end

  # More sophisticated approach
  def self.rebuild_pg_search_documents
    connection.execute <<~SQL.squish
     INSERT INTO pg_search_documents (searchable_type, searchable_id, content, created_at, updated_at)
       SELECT 'Movie' AS searchable_type,
              movies.id AS searchable_id,
              CONCAT_WS(' ', movies.name, directors.name) AS content,
              now() AS created_at,
              now() AS updated_at
       FROM movies
       LEFT JOIN directors
         ON directors.id = movies.director_id
    SQL
  end
end
```
**Note:** If using PostgreSQL before 9.1, replace the `CONCAT_WS()` function call with double-pipe concatenation, eg. `(movies.name || ' ' || directors.name)`. However, now be aware that if *any* of the joined values is NULL then the final `content` value will also be NULL, whereas `CONCAT_WS()` will selectively ignore NULL values.

#### Disabling multi-search indexing temporarily

If you have a large bulk operation to perform, such as importing a lot of
records from an external source, you might want to speed things up by turning
off indexing temporarily. You could then use one of the techniques above to
rebuild the search documents off-line.

```ruby
PgSearch.disable_multisearch do
  Movie.import_from_xml_file(File.open("movies.xml"))
end
```

### pg_search_scope

You can use pg_search_scope to build a search scope. The first parameter is a
scope name, and the second parameter is an options hash. The only required
option is :against, which tells pg_search_scope which column or columns to
search against.

#### Searching against one column

To search against a column, pass a symbol as the :against option.

```ruby
class BlogPost < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :search_by_title, against: :title
end
```

We now have an ActiveRecord scope named search_by_title on our BlogPost model.
It takes one parameter, a search query string.

```ruby
BlogPost.create!(title: "Recent Developments in the World of Pastrami")
BlogPost.create!(title: "Prosciutto and You: A Retrospective")
BlogPost.search_by_title("pastrami") # => [#<BlogPost id: 2, title: "Recent Developments in the World of Pastrami">]
```

#### Searching against multiple columns

Just pass an Array if you'd like to search more than one column.

```ruby
class Person < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :search_by_full_name, against: [:first_name, :last_name]
end
```

Now our search query can match either or both of the columns.

```ruby
person_1 = Person.create!(first_name: "Grant", last_name: "Hill")
person_2 = Person.create!(first_name: "Hugh", last_name: "Grant")

Person.search_by_full_name("Grant") # => [person_1, person_2]
Person.search_by_full_name("Grant Hill") # => [person_1]
```

#### Dynamic search scopes

Just like with Active Record named scopes, you can pass in a Proc object that
returns a hash of options. For instance, the following scope takes a parameter
that dynamically chooses which column to search against.

Important: The returned hash must include a :query key. Its value does not
necessary have to be dynamic. You could choose to hard-code it to a specific
value if you wanted.

```ruby
class Person < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :search_by_name, lambda { |name_part, query|
    raise ArgumentError unless [:first, :last].include?(name_part)
    {
      against: name_part,
      query: query
    }
  }
end

person_1 = Person.create!(first_name: "Grant", last_name: "Hill")
person_2 = Person.create!(first_name: "Hugh", last_name: "Grant")

Person.search_by_name :first, "Grant" # => [person_1]
Person.search_by_name :last, "Grant" # => [person_2]
```

#### Searching through associations

It is possible to search columns on associated models. Note that if you do
this, it will be impossible to speed up searches with database indexes.
However, it is supported as a quick way to try out cross-model searching.

You can pass a Hash into the :associated_against option to set up searching
through associations. The keys are the names of the associations and the value
works just like an :against option for the other model. Right now, searching
deeper than one association away is not supported. You can work around this by
setting up a series of :through associations to point all the way through.

```ruby
class Cracker < ActiveRecord::Base
  has_many :cheeses
end

class Cheese < ActiveRecord::Base
end

class Salami < ActiveRecord::Base
  include PgSearch::Model

  belongs_to :cracker
  has_many :cheeses, through: :cracker

  pg_search_scope :tasty_search, associated_against: {
    cheeses: [:kind, :brand],
    cracker: :kind
  }
end

salami_1 = Salami.create!
salami_2 = Salami.create!
salami_3 = Salami.create!

limburger = Cheese.create!(kind: "Limburger")
brie = Cheese.create!(kind: "Brie")
pepper_jack = Cheese.create!(kind: "Pepper Jack")

Cracker.create!(kind: "Black Pepper", cheeses: [brie], salami: salami_1)
Cracker.create!(kind: "Ritz", cheeses: [limburger, pepper_jack], salami: salami_2)
Cracker.create!(kind: "Graham", cheeses: [limburger], salami: salami_3)

Salami.tasty_search("pepper") # => [salami_1, salami_2]
```

### Searching using different search features

By default, pg_search_scope uses the built-in [PostgreSQL text
search](http://www.postgresql.org/docs/current/static/textsearch-intro.html).
If you pass the :using option to pg_search_scope, you can choose alternative
search techniques.

```ruby
class Beer < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :search_name, against: :name, using: [:tsearch, :trigram, :dmetaphone]
end
```

The currently implemented features are

*   :tsearch - [Full text search](http://www.postgresql.org/docs/current/static/textsearch-intro.html), which is built-in to PostgreSQL
*   :trigram - [Trigram search](http://www.postgresql.org/docs/current/static/pgtrgm.html), which
    requires the trigram extension
*   :dmetaphone - [Double Metaphone search](http://www.postgresql.org/docs/current/static/fuzzystrmatch.html#AEN177521), which requires the fuzzystrmatch extension


#### :tsearch (Full Text Search)

PostgreSQL's built-in full text search supports weighting, prefix searches,
and stemming in multiple languages.

##### Weighting
Each searchable column can be given a weight of "A", "B", "C", or "D". Columns
with earlier letters are weighted higher than those with later letters. So, in
the following example, the title is the most important, followed by the
subtitle, and finally the content.

```ruby
class NewsArticle < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :search_full_text, against: {
    title: 'A',
    subtitle: 'B',
    content: 'C'
  }
end
```

You can also pass the weights in as an array of arrays, or any other structure
that responds to #each and yields either a single symbol or a symbol and a
weight. If you omit the weight, a default will be used.

```ruby
class NewsArticle < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :search_full_text, against: [
    [:title, 'A'],
    [:subtitle, 'B'],
    [:content, 'C']
  ]
end

class NewsArticle < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :search_full_text, against: [
    [:title, 'A'],
    {subtitle: 'B'},
    :content
  ]
end
```

##### :prefix (PostgreSQL 8.4 and newer only)

PostgreSQL's full text search matches on whole words by default. If you want
to search for partial words, however, you can set :prefix to true. Since this
is a :tsearch-specific option, you should pass it to :tsearch directly, as
shown in the following example.

```ruby
class Superhero < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :whose_name_starts_with,
                  against: :name,
                  using: {
                    tsearch: { prefix: true }
                  }
end

batman = Superhero.create name: 'Batman'
batgirl = Superhero.create name: 'Batgirl'
robin = Superhero.create name: 'Robin'

Superhero.whose_name_starts_with("Bat") # => [batman, batgirl]
```
##### :negation

PostgreSQL's full text search matches all search terms by default. If you want
to exclude certain words, you can set :negation to true. Then any term that begins with
an exclamation point `!` will be excluded from the results. Since this
is a :tsearch-specific option, you should pass it to :tsearch directly, as
shown in the following example.

Note that combining this with other search features can have unexpected results. For
example, :trigram searches don't have a concept of excluded terms, and thus if you
use both :tsearch and :trigram in tandem, you may still find results that contain the
term that you were trying to exclude.

```ruby
class Animal < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :with_name_matching,
                  against: :name,
                  using: {
                    tsearch: {negation: true}
                  }
end

one_fish = Animal.create(name: "one fish")
two_fish = Animal.create(name: "two fish")
red_fish = Animal.create(name: "red fish")
blue_fish = Animal.create(name: "blue fish")

Animal.with_name_matching("fish !red !blue") # => [one_fish, two_fish]
```

##### :dictionary

PostgreSQL full text search also support multiple dictionaries for stemming.
You can learn more about how dictionaries work by reading the [PostgreSQL
documention](http://www.postgresql.org/docs/current/static/textsearch-dictionaries.html). 
If you use one of the language dictionaries, such as "english",
then variants of words (e.g. "jumping" and "jumped") will match each other. If
you don't want stemming, you should pick the "simple" dictionary which does
not do any stemming. If you don't specify a dictionary, the "simple"
dictionary will be used.

```ruby
class BoringTweet < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :kinda_matching,
                  against: :text,
                  using: {
                    tsearch: {dictionary: "english"}
                  }
  pg_search_scope :literally_matching,
                  against: :text,
                  using: {
                    tsearch: {dictionary: "simple"}
                  }
end

sleepy = BoringTweet.create! text: "I snoozed my alarm for fourteen hours today. I bet I can beat that tomorrow! #sleepy"
sleeping = BoringTweet.create! text: "You know what I like? Sleeping. That's what. #enjoyment"
sleeper = BoringTweet.create! text: "Have you seen Woody Allen's movie entitled Sleeper? Me neither. #boycott"

BoringTweet.kinda_matching("sleeping") # => [sleepy, sleeping, sleeper]
BoringTweet.literally_matching("sleeping") # => [sleeping]
```

##### :normalization

PostgreSQL supports multiple algorithms for ranking results against queries.
For instance, you might want to consider overall document size or the distance
between multiple search terms in the original text. This option takes an
integer, which is passed directly to PostgreSQL. According to the latest
[PostgreSQL documentation](http://www.postgresql.org/docs/current/static/textsearch-controls.html),
the supported algorithms are:

    0 (the default) ignores the document length
    1 divides the rank by 1 + the logarithm of the document length
    2 divides the rank by the document length
    4 divides the rank by the mean harmonic distance between extents
    8 divides the rank by the number of unique words in document
    16 divides the rank by 1 + the logarithm of the number of unique words in document
    32 divides the rank by itself + 1

This integer is a bitmask, so if you want to combine algorithms, you can add
their numbers together.
(e.g. to use algorithms 1, 8, and 32, you would pass 1 + 8 + 32 = 41)

```ruby
class BigLongDocument < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :regular_search,
                  against: :text

  pg_search_scope :short_search,
                  against: :text,
                  using: {
                    tsearch: {normalization: 2}
                  }

long = BigLongDocument.create!(text: "Four score and twenty years ago")
short = BigLongDocument.create!(text: "Four score")

BigLongDocument.regular_search("four score") #=> [long, short]
BigLongDocument.short_search("four score") #=> [short, long]
```

##### :any_word

Setting this attribute to true will perform a search which will return all
models containing any word in the search terms.

```ruby
class Number < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :search_any_word,
                  against: :text,
                  using: {
                    tsearch: {any_word: true}
                  }

  pg_search_scope :search_all_words,
                  against: :text
end

one = Number.create! text: 'one'
two = Number.create! text: 'two'
three = Number.create! text: 'three'

Number.search_any_word('one two three') # => [one, two, three]
Number.search_all_words('one two three') # => []
```

##### :sort_only

Setting this attribute to true will make this feature available for sorting,
but will not include it in the query's WHERE condition.

```ruby
class Person < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :search,
                  against: :name,
                  using: {
                    tsearch: {any_word: true},
                    dmetaphone: {any_word: true, sort_only: true}
                  }
end

exact = Person.create!(name: 'ash hines')
one_exact_one_close = Person.create!(name: 'ash heinz')
one_exact = Person.create!(name: 'ash smith')
one_close = Person.create!(name: 'leigh heinz')

Person.search('ash hines') # => [exact, one_exact_one_close, one_exact]
```

##### :highlight

Adding .with_pg_search_highlight after the pg_search_scope you can access to
`pg_highlight` attribute for each object.


```ruby
class Person < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :search,
                  against: :bio,
                  using: {
                    tsearch: {
                      highlight: {
                        StartSel: '<b>',
                        StopSel: '</b>',
                        MaxWords: 123,
                        MinWords: 456,
                        ShortWord: 4,
                        HighlightAll: true,
                        MaxFragments: 3,
                        FragmentDelimiter: '&hellip;'
                      }
                    }
                  }
end

Person.create!(:bio => "Born in rural Alberta, where the buffalo roam.")

first_match = Person.search("Alberta").with_pg_search_highlight.first
first_match.pg_search_highlight # => "Born in rural <b>Alberta</b>, where the buffalo roam."
```

The highlight option accepts all [options supported by
ts_headline](https://www.postgresql.org/docs/current/static/textsearch-controls.html),
and uses PostgreSQL's defaults.

See the
[documentation](https://www.postgresql.org/docs/current/static/textsearch-controls.html)
for details on the meaning of each option.

#### :dmetaphone (Double Metaphone soundalike search)

[Double Metaphone](http://en.wikipedia.org/wiki/Double_Metaphone) is an
algorithm for matching words that sound alike even if they are spelled very
differently. For example, "Geoff" and "Jeff" sound identical and thus match.
Currently, this is not a true double-metaphone, as only the first metaphone is
used for searching.

Double Metaphone support is currently available as part of the [fuzzystrmatch
extension](http://www.postgresql.org/docs/current/static/fuzzystrmatch.html)
that must be installed before this feature can be used. In addition to the
extension, you must install a utility function into your database. To generate 
and run a migration for this, run:

    $ rails g pg_search:migration:dmetaphone
    $ rake db:migrate

The following example shows how to use :dmetaphone.

```ruby
class Word < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :that_sounds_like,
                  against: :spelling,
                  using: :dmetaphone
end

four = Word.create! spelling: 'four'
far = Word.create! spelling: 'far'
fur = Word.create! spelling: 'fur'
five = Word.create! spelling: 'five'

Word.that_sounds_like("fir") # => [four, far, fur]
```

#### :trigram (Trigram search)

Trigram search works by counting how many three-letter substrings (or
"trigrams") match between the query and the text. For example, the string
"Lorem ipsum" can be split into the following trigrams:

    [" Lo", "Lor", "ore", "rem", "em ", "m i", " ip", "ips", "psu", "sum", "um ", "m  "]

Trigram search has some ability to work even with typos and misspellings in
the query or text.

Trigram support is currently available as part of the 
[pg_trgm extension](http://www.postgresql.org/docs/current/static/pgtrgm.html) that must be installed before this
feature can be used.

```ruby
class Website < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :kinda_spelled_like,
                  against: :name,
                  using: :trigram
end

yahooo = Website.create! name: "Yahooo!"
yohoo = Website.create! name: "Yohoo!"
gogle = Website.create! name: "Gogle"
facebook = Website.create! name: "Facebook"

Website.kinda_spelled_like("Yahoo!") # => [yahooo, yohoo]
```

##### :threshold

By default, trigram searches find records which have a similarity of at least 0.3
using pg_trgm's calculations. You may specify a custom threshold if you prefer.
Higher numbers match more strictly, and thus return fewer results. Lower numbers
match more permissively, letting in more results. Please note that setting a trigram
threshold will force a table scan as the derived query uses the
`similarity()` function instead of the `%` operator.

```ruby
class Vegetable < ActiveRecord::Base
  include PgSearch::Model

  pg_search_scope :strictly_spelled_like,
                  against: :name,
                  using: {
                    trigram: {
                      threshold: 0.5
                    }
                  }

  pg_search_scope :roughly_spelled_like,
                  against: :name,
                  using: {
                    trigram: {
                      threshold: 0.1
                    }
                  }
end

cauliflower = Vegetable.create! name: "cauliflower"

Vegetable.roughly_spelled_like("couliflower") # => [cauliflower]
Vegetable.strictly_spelled_like("couliflower") # => [cauliflower]

Vegetable.roughly_spelled_like("collyflower") # => [cauliflower]
Vegetable.strictly_spelled_like("collyflower") # => []
```

##### :word_similarity

Allows you to match words in longer strings.
By default, trigram searches use `%` or `similarity()` as a similarity value.
Set `word_similarity` to `true` to opt for `<%` and `word_similarity` instead.
This causes the trigram search to use the similarity of the query term 
and the word with greatest similarity.

```ruby
class Sentence < ActiveRecord::Base
  include PgSearch::Model

  pg_search_scope :similarity_like,
                  against: :name,
                  using: {
                    trigram: {
                      word_similarity: true
                    }
                  }

  pg_search_scope :word_similarity_like,
                  against: :name,
                  using: [:trigram]
end

sentence = Sentence.create! name: "Those are two words."

Sentence.similarity_like("word") # => []
Sentence.word_similarity_like("word") # => [sentence]
```

### Limiting Fields When Combining Features 

Sometimes when doing queries combining different features you 
might want to searching against only some of the fields with certain features.
For example perhaps you want to only do a trigram search against the shorter fields
so that you don't need to reduce the threshold excessively. You can specify 
which fields using the 'only' option:

```ruby
class Image < ActiveRecord::Base
  include PgSearch::Model

  pg_search_scope :combined_search,
                  against: [:file_name, :short_description, :long_description]
                  using: {
                    tsearch: { dictionary: 'english' },
                    trigram: {
                      only: [:file_name, :short_description]
                    }
                  }

end
```

Now you can succesfully retrieve an Image with a file_name: 'image_foo.jpg' 
and long_description: 'This description is so long that it would make a trigram search
fail any reasonable threshold limit' with:

```ruby
Image.combined_search('reasonable') # found with tsearch
Image.combined_search('foo') # found with trigram
```

### Ignoring accent marks

Most of the time you will want to ignore accent marks when searching. This
makes it possible to find words like "piñata" when searching with the query
"pinata". If you set a pg_search_scope to ignore accents, it will ignore
accents in both the searchable text and the query terms.

Ignoring accents uses the [unaccent extension](http://www.postgresql.org/docs/current/static/unaccent.html) that
must be installed before this feature can be used.

```ruby
class SpanishQuestion < ActiveRecord::Base
  include PgSearch::Model
  pg_search_scope :gringo_search,
                  against: :word,
                  ignoring: :accents
end

what = SpanishQuestion.create(word: "Qué")
how_many = SpanishQuestion.create(word: "Cuánto")
how = SpanishQuestion.create(word: "Cómo")

SpanishQuestion.gringo_search("Que") # => [what]
SpanishQuestion.gringo_search("Cüåñtô") # => [how_many]
```

Advanced users may wish to add indexes for the expressions that pg_search
generates. Unfortunately, the unaccent function supplied by this extension
is not indexable (as of PostgreSQL 9.1). Thus, you may want to write
your own wrapper function and use it instead. This can be configured by
calling the following code, perhaps in an initializer.

```ruby
PgSearch.unaccent_function = "my_unaccent"
```

### Using tsvector columns

PostgreSQL allows you the ability to search against a column with type
tsvector instead of using an expression; this speeds up searching dramatically
as it offloads creation of the tsvector that the tsquery is evaluated against.

To use this functionality you'll need to do a few things:

*   Create a column of type tsvector that you'd like to search against. If you
    want to search using multiple search methods, for example tsearch and
    dmetaphone, you'll need a column for each.
*   Create a trigger function that will update the column(s) using the
    expression appropriate for that type of search. See:
    [the PostgreSQL documentation for text search triggers](http://www.postgresql.org/docs/current/static/textsearch-features.html#TEXTSEARCH-UPDATE-TRIGGERS)
*   Should you have any pre-existing data in the table, update the
    newly-created tsvector columns with the expression that your trigger
    function uses.
*   Add the option to pg_search_scope, e.g:

    ```ruby
    pg_search_scope :fast_content_search,
                    against: :content,
                    using: {
                      dmetaphone: {
                        tsvector_column: 'tsvector_content_dmetaphone'
                      },
                      tsearch: {
                        dictionary: 'english',
                        tsvector_column: 'tsvector_content_tsearch'
                      },
                      trigram: {} # trigram does not use tsvectors
                    }
    ```

Please note that the :against column is only used when the tsvector_column is
not present for the search type.

#### Combining multiple tsvectors

It's possible to search against more than one tsvector at a time. This could be useful if you want to maintain multiple search scopes but do not want to maintain separate tsvectors for each scope. For example:

```ruby
pg_search_scope :search_title,
                against: :title,
                using: {
                  tsearch: {
                    tsvector_column: "title_tsvector"
                  }
                }

pg_search_scope :search_body,
                against: :body,
                using: {
                  tsearch: {
                    tsvector_column: "body_tsvector"
                  }
                }

pg_search_scope :search_title_and_body,
                against: [:title, :body],
                using: {
                  tsearch: {
                    tsvector_column: ["title_tsvector", "body_tsvector"]
                  }
                }
```

### Configuring ranking and ordering

#### :ranked_by (Choosing a ranking algorithm)

By default, pg_search ranks results based on the :tsearch similarity between
the searchable text and the query. To use a different ranking algorithm, you
can pass a :ranked_by option to pg_search_scope.

```ruby
pg_search_scope :search_by_tsearch_but_rank_by_trigram,
                against: :title,
                using: [:tsearch],
                ranked_by: ":trigram"
```

Note that :ranked_by using a String to represent the ranking expression. This
allows for more complex possibilities. Strings like ":tsearch", ":trigram",
and ":dmetaphone" are automatically expanded into the appropriate SQL
expressions.

```ruby
# Weighted ranking to balance multiple approaches
ranked_by: ":dmetaphone + (0.25 * :trigram)"

# A more complex example, where books.num_pages is an integer column in the table itself
ranked_by: "(books.num_pages * :trigram) + (:tsearch / 2.0)"
```

#### :order_within_rank (Breaking ties)

PostgreSQL does not guarantee a consistent order when multiple records have
the same value in the ORDER BY clause. This can cause trouble with pagination.
Imagine a case where 12 records all have the same ranking value. If you use a
pagination library such as [kaminari](https://github.com/amatsuda/kaminari) or
[will_paginate](https://github.com/mislav/will_paginate) to return results in
pages of 10, then you would expect to see 10 of the records on page 1, and the
remaining 2 records at the top of the next page, ahead of lower-ranked
results.

But since there is no consistent ordering, PostgreSQL might choose to
rearrange the order of those 12 records between different SQL statements. You
might end up getting some of the same records from page 1 on page 2 as well,
and likewise there may be records that don't show up at all.

pg_search fixes this problem by adding a second expression to the ORDER BY
clause, after the :ranked_by expression explained above. By default, the
tiebreaker order is ascending by id.

    ORDER BY [complicated :ranked_by expression...], id ASC

This might not be desirable for your application, especially if you do not
want old records to outrank new records. By passing an :order_within_rank, you
can specify an alternate tiebreaker expression. A common example would be
descending by updated_at, to rank the most recently updated records first.

```ruby
pg_search_scope :search_and_break_ties_by_latest_update,
                against: [:title, :content],
                order_within_rank: "blog_posts.updated_at DESC"
```

#### PgSearch#pg_search_rank (Reading a record's rank as a Float)

It may be useful or interesting to see the rank of a particular record. This
can be helpful for debugging why one record outranks another. You could also
use it to show some sort of relevancy value to end users of an application.

To retrieve the rank, call `.with_pg_search_rank` on a scope, and then call
`.pg_search_rank` on a returned record.

```ruby
shirt_brands = ShirtBrand.search_by_name("Penguin").with_pg_search_rank
shirt_brands[0].pg_search_rank #=> 0.0759909
shirt_brands[1].pg_search_rank #=> 0.0607927
```

#### Search rank and chained scopes

Each PgSearch scope generates a named subquery for the search rank.  If you
chain multiple scopes then PgSearch will generate a ranking query for each
scope, so the ranking queries must have unique names.  If you need to reference
the ranking query (e.g. in a GROUP BY clause) you can regenerate the subquery
name with the `PgScope::Configuration.alias` method by passing the name of the
queried table.

```ruby
shirt_brands = ShirtBrand.search_by_name("Penguin")
  .joins(:shirt_sizes)
  .group("shirt_brands.id, #{PgSearch::Configuration.alias('shirt_brands')}.rank")
```

## ATTRIBUTIONS

PgSearch would not have been possible without inspiration from texticle (now renamed
[textacular](https://github.com/textacular/textacular)). Thanks to [Aaron
Patterson](http://tenderlovemaking.com/) for the original version and to Casebook PBC (https://www.casebook.net) for gifting the community with it!

## CONTRIBUTIONS AND FEEDBACK

Please read our [CONTRIBUTING guide](https://github.com/Casecommons/pg_search/blob/master/CONTRIBUTING.md).

We also have a [Google Group](http://groups.google.com/group/casecommons-dev)
for discussing pg_search and other Casebook PBC open source projects.

## LICENSE

Copyright © 2010–2021 [Casebook PBC](http://www.casebook.net).
Licensed under the MIT license, see [LICENSE](/LICENSE) file.

# Neighbor

Nearest neighbor search for Rails and Postgres

[![Build Status](https://github.com/ankane/neighbor/workflows/build/badge.svg?branch=master)](https://github.com/ankane/neighbor/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "neighbor"
```

## Choose An Extension

Neighbor supports two extensions: [cube](https://www.postgresql.org/docs/current/cube.html) and [vector](https://github.com/pgvector/pgvector). cube ships with Postgres, while vector supports approximate nearest neighbor search.

For cube, run:

```sh
rails generate neighbor:cube
rails db:migrate
```

For vector, [install pgvector](https://github.com/pgvector/pgvector#installation) and run:

```sh
rails generate neighbor:vector
rails db:migrate
```

## Getting Started

Create a migration

```ruby
class AddNeighborVectorToItems < ActiveRecord::Migration[7.0]
  def change
    add_column :items, :embedding, :cube
    # or
    add_column :items, :embedding, :vector, limit: 3 # dimensions
  end
end
```

Add to your model

```ruby
class Item < ApplicationRecord
  has_neighbors :embedding
end
```

Update the vectors

```ruby
item.update(embedding: [1.0, 1.2, 0.5])
```

Get the nearest neighbors to a record

```ruby
item.nearest_neighbors(:embedding, distance: "euclidean").first(5)
```

Get the nearest neighbors to a vector

```ruby
Item.nearest_neighbors(:embedding, [0.9, 1.3, 1.1], distance: "euclidean").first(5)
```

## Distance

Supported values are:

- `euclidean`
- `cosine`
- `taxicab` (cube only)
- `chebyshev` (cube only)
- `inner_product` (vector only)

For cosine distance with cube, vectors must be normalized before being stored.

```ruby
class Item < ApplicationRecord
  has_neighbors :embedding, normalize: true
end
```

For inner product with cube, see [this example](examples/disco_user_recs_cube.rb).

Records returned from `nearest_neighbors` will have a `neighbor_distance` attribute

```ruby
nearest_item = item.nearest_neighbors(:embedding, distance: "euclidean").first
nearest_item.neighbor_distance
```

## Dimensions

The cube data type can have up to 100 dimensions by default. See the [Postgres docs](https://www.postgresql.org/docs/current/cube.html) for how to increase this. The vector data type can have up to 16,000 dimensions, and vectors with up to 2,000 dimensions can be indexed.

For cube, it’s a good idea to specify the number of dimensions to ensure all records have the same number.

```ruby
class Item < ApplicationRecord
  has_neighbors :embedding, dimensions: 3
end
```

## Indexing

For vector, add an approximate index to speed up queries. Create a migration with:

```ruby
class AddIndexToItemsNeighborVector < ActiveRecord::Migration[7.0]
  def change
    add_index :items, :embedding, using: :ivfflat, opclass: :vector_l2_ops
  end
end
```

Use `:vector_cosine_ops` for cosine distance and `:vector_ip_ops` for inner product.

Set the number of probes

```ruby
Item.connection.execute("SET ivfflat.probes = 3")
```

## Examples

- [OpenAI Embeddings](#openai-embeddings)
- [Disco Recommendations](#disco-recommendations)

### OpenAI Embeddings

Generate a model

```sh
rails generate model Article content:text embedding:vector{1536}
rails db:migrate
```

And add `has_neighbors`

```ruby
class Article < ApplicationRecord
  has_neighbors :embedding
end
```

Create a method to call the [embeddings API](https://platform.openai.com/docs/guides/embeddings)

```ruby
def fetch_embeddings(input)
  url = "https://api.openai.com/v1/embeddings"
  headers = {
    "Authorization" => "Bearer #{ENV.fetch("OPENAI_API_KEY")}",
    "Content-Type" => "application/json"
  }
  data = {
    input: input,
    model: "text-embedding-ada-002"
  }

  response = Net::HTTP.post(URI(url), data.to_json, headers)
  JSON.parse(response.body)["data"].map { |v| v["embedding"] }
end
```

Pass your input

```ruby
input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = fetch_embeddings(input)
```

Store the embeddings

```ruby
articles = []
input.zip(embeddings) do |content, embedding|
  articles << {content: content, embedding: embedding}
end
Article.insert_all!(articles) # use create! for Active Record < 6
```

And get similar articles

```ruby
article = Article.first
article.nearest_neighbors(:embedding, distance: "inner_product").first(5).map(&:content)
```

See the [complete code](examples/openai_embeddings.rb)

### Disco Recommendations

You can use Neighbor for online item-based recommendations with [Disco](https://github.com/ankane/disco). We’ll use MovieLens data for this example.

Generate a model

```sh
rails generate model Movie name:string factors:cube
rails db:migrate
```

And add `has_neighbors`

```ruby
class Movie < ApplicationRecord
  has_neighbors :factors, dimensions: 20, normalize: true
end
```

Fit the recommender

```ruby
data = Disco.load_movielens
recommender = Disco::Recommender.new(factors: 20)
recommender.fit(data)
```

Store the item factors

```ruby
movies = []
recommender.item_ids.each do |item_id|
  movies << {name: item_id, factors: recommender.item_factors(item_id)}
end
Movie.insert_all!(movies) # use create! for Active Record < 6
```

And get similar movies

```ruby
movie = Movie.find_by(name: "Star Wars (1977)")
movie.nearest_neighbors(:factors, distance: "cosine").first(5).map(&:name)
```

See the complete code for [cube](examples/disco_item_recs_cube.rb) and [vector](examples/disco_item_recs_vector.rb)

## Upgrading

### 0.2.0

The `distance` option has been moved from `has_neighbors` to `nearest_neighbors`, and there is no longer a default. If you use cosine distance, set:

```ruby
class Item < ApplicationRecord
  has_neighbors normalize: true
end
```

## History

View the [changelog](https://github.com/ankane/neighbor/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/neighbor/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/neighbor/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/neighbor.git
cd neighbor
bundle install
createdb neighbor_test

# cube
bundle exec rake test

# vector
EXT=vector bundle exec rake test
```

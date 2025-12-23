---
title: Scoping HasMany Relations
---

To show a subset of a has_many relationship, create a new [has_many](https://apidock.com/rails/ActiveRecord/Associations/ClassMethods/has_many) relationship in your model (using the `scope` argument) and add it to the model's dashboard.

## Creating a scoped has_many relationship

Models can define subsets of a `has_many` relationship by passing a callable (i.e. proc or lambda) as its second argument.

```ruby
class Customer < ApplicationRecord
   has_many :orders
   has_many :processed_orders, ->{ where(processed: true) }, class_name: "Order"
```

Since ActiveRecord infers the class name from the first argument, the new `has_many` relation needs to specify the model using the `class_name` option.

## Add new relationship to dashboard

Your new scoped relation can be used in the dashboard just like the original `HasMany`. Notice the new field needs to specifiy the class name as an option like you did in the model.

```ruby
ATTRIBUTE_TYPES = {
  orders: Field::HasMany,
  processed_orders: Field::HasMany.with_options(class_name: 'Order')
```

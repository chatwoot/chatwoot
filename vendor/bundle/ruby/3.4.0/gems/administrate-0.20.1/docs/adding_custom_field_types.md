---
title: Adding Custom Field Types
---

If your application deals with a nonstandard data type,
you can create an `Administrate::Field` object to help display
the custom data type across the dashboard.

`Administrate::Field` objects consist of two parts:
a Ruby class and associated views.

For example, let's create a `Field` that displays [Gravatars] based on an email.

[Gravatars]: https://gravatar.com/

First, we'll run a generator to set us up with the files we need:

```bash
rails generate administrate:field gravatar
```

This creates a few files:

- `app/fields/gravatar_field.rb`
- `app/views/fields/gravatar_field/_show.html.erb`
- `app/views/fields/gravatar_field/_index.html.erb`
- `app/views/fields/gravatar_field/_form.html.erb`

We can edit the `app/fields/gravatar_field.rb` to add some custom logic:

```ruby
# app/fields/gravatar_field.rb
require 'digest/md5'

class GravatarField < Administrate::Field::Base
  def gravatar_url
    email_address = data.downcase
    hash = Digest::MD5.hexdigest(email_address)
    "http://www.gravatar.com/avatar/#{hash}"
  end
end
```

Next, we can customize the partials to display data how we'd like.
Open up the `app/views/fields/gravatar_field/_show.html.erb` partial.
By default, it looks like:

```eruby
<%= field.to_s %>
```

Since we want to display an image, we can change it to:

```eruby
<%= image_tag field.gravatar_url %>
```

You can customize the other generated partials in the same way
for custom behavior on the index and form pages.

## Using your custom field

We need to tell Administrate which attributes we'd like to be displayed as a
gravatar image.

Open up a dashboard file, and add the gravatar field into the `ATTRIBUTE_TYPES`
hash. It should look something like:

```ruby
class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
    name: Field::String,
    email: GravatarField,    # Update this email to use your new field class
    # ...
  }
end
```

[Customizing Attribute Partials]: /customizing_attribute_partials

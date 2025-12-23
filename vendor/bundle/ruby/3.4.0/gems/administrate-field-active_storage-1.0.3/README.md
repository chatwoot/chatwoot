# Administrate::Field::ActiveStorage
![rails](https://img.shields.io/badge/rails-%3E%3D5.2.0-red.svg)
![CI](https://github.com/Dreamersoul/administrate-field-active_storage/workflows/CI/badge.svg)

## Things To Know:
- To preview pdf files you need to install `mupdf` or `Poppler`.
- To preview video files you need to install `ffmpeg`.
- To preview Office files as pictures you need to install [activestorage-office-previewer](https://github.com/basecamp/activestorage-office-previewer) by basecamp

## How To Use:
Add `administrate-field-active_storage` and `image_processing` to your Gemfile (Rails 6+):

```ruby
gem "administrate-field-active_storage"
gem "image_processing"
```

for Rails 5.x use the following
```ruby
gem "administrate-field-active_storage", "0.1.8"
```

Install:

```
$ bundle install
```

### `has_one_attached`:
Assuming your model name is `Model` and field name is `attachment`
```ruby
class ModelDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    attachment: Field::ActiveStorage,
  }
# ...
```
Then add `:attachment` to `FORM_ATTRIBUTES` and `SHOW_PAGE_ATTRIBUTES`.
Adding `:attachment` `COLLECTION_ATTRIBUTES` will work but will probably look too big.

### `has_many_attached`:
Assuming your model name is `Model` and field name is `attachments` the process is identical the only issue is that the form field isn't being permitted, in order to permit it we apply the following method to the dashboard:

```ruby
class ModelDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    attachments: Field::ActiveStorage,
  }

  # ...
  FORM_ATTRIBUTES = {
    #...
    :attachments
  }

  # permitted for has_many_attached
  def permitted_attributes
    super + [:attachments => []]
  end
```
I know it is not ideal, if you have a workaround please submit a PR.

Note: Rails 6 introduced a new config to determine the behavior on updates to `has_many_attached`.  Setting `Rails.application.config.active_storage.replace_on_assign_to_many` to `true` will overwrite any existing values (purging the old ones), and setting it to `false` will append the new values. Please note that this configuation was [deprecated with Rails 7.1](https://github.com/rails/rails/blob/v7.0.2.3/activestorage/lib/active_storage/attached/model.rb#L150)
>config.active_storage.replace_on_assign_to_many is deprecated and will be removed in Rails 7.1. Make sure that your code works well with config.active_storage.replace_on_assign_to_many set to true before upgrading. To append new attachables to the Active Storage association, prefer using attach. Using association setter would result in purging the existing attached attachments and replacing them with new ones.


### Prevent N+1 queries
In order to prevent N+1 queries from active storage you have to modify your admin model controller, below an example for a model called `User` and with attached avatars
```ruby
module Admin
  class UsersController < ApplicationController
    def scoped_resource
      resource_class.with_attached_avatars
    end
  end
end
```

### Removing/Deleting an Attachment

`Administrate::Field::ActiveStorage` expects the presence of a route
DELETE `/<namespace>/<resource>/:id/:attachment_name`, which will receive an optional parameter
`attachment_id` in the case of an `ActiveStorage::Attached::Many`. For instance:

```rb
# routes.rb
...
namespace :admin do
  ...
  resources :users do
    delete :avatars, on: :member, action: :destroy_avatar
  end
end

# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < ApplicationController

    # For illustrative purposes only.
    #
    # **SECURITY NOTICE**: first verify whether current user is authorized to perform the action.
    def destroy_avatar
      avatar = requested_resource.avatars.find(params[:attachment_id])
      avatar.purge
      redirect_back(fallback_location: requested_resource)
    end
  end
end
```
For `has_one_attached` cases, you will use:

```rb
# routes.rb
...
namespace :admin do
  ...
  resources :users do
    delete :avatar, on: :member, action: :destroy_avatar
  end
end

# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < ApplicationController

    # For illustrative purposes only.
    #
    # **SECURITY NOTICE**: first verify whether current user is authorized to perform the action.
    def destroy_avatar
      avatar = requested_resource.avatar
      avatar.purge
      redirect_back(fallback_location: requested_resource)
    end
  end
end
```
This route can be customized with `destroy_url`. The option expects a `proc` receiving 3 arguments:
the Administrate `namespace`, the `resource`, and the `attachment`. The proc can return anything
accepted by `link_to`:

```rb
# routes.rb
delete :custom_user_avatar_destroy, to: 'users#destroy_avatar'

# user_dashboard.rb
class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    avatars: Field::ActiveStorage.with_options(
      destroy_url: proc do |namespace, resource, attachment|
        [:custom_user_avatar_destroy, { attachment_id: attachment.id }]
      end
    ),
    # ...
  end
  # ...
end
```

## Options

Various options can be passed to `Administrate::Field::ActiveStorage#with_options`
as illustrated below:

```rb
class ModelDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    attachments: Field::ActiveStorage.with_options(index_display_preview: false),
    # ...
  }
  # ...
end
```

### show_display_preview

Display attachment preview.

Defaults to `true`.

### index_display_preview

Displays the first attachment (which is the only attachment in case of `has_one`)
in the `index` action.

Defaults to `true`.

### index_preview_only

If true, will show only the preview in the `index` action, and not the filename or destroy link (if set).

### index_preview_size and show_preview_size

Indicate the size of the image preview for the `index` and `show` actions, respectively.
Refer to [mini_magic#resize_to_limit](https://github.com/janko/image_processing/blob/master/doc/minimagick.md#methods)
for documentation.

Default to `[150, 150]` and `[800, 800]`, respectively.

### index_preview_variant and show_preview_variant

Use a named variant for image preview for the `index` and `show` actions, respectively.
Named image variants were [added in Rails 7](https://guides.rubyonrails.org/v7.0/active_storage_overview.html#has-one-attached).

It might be necessary to add to app/assets/config/manifest.js:
```rb
 //= link 'administrate-field-active_storage/application.css'
```
When set, this takes precedence over `index_preview_size` and `show_preview_size`.

Setting this to `false` displays original images instead of variants.

Defaults to `nil`.

### index_display_count

Displays the number of attachments in the `index` action.

Defaults to `true` if number of attachments is not 1.

### direct_upload

Enables direct upload from the browser to the cloud.

Defaults to `false`.

Don't forget to include [ActiveStorage JavaScript](https://edgeguides.rubyonrails.org/active_storage_overview.html#direct-uploads). You can use `rails generate administrate:assets:javascripts` to be able to customize Administrate JavaScripts in your application.

## I18n

You can see translation example [here](https://github.com/Dreamersoul/administrate-field-active_storage/blob/master/config/locales/administrate-field-active_storage.en.yml).

## Things To Do:
- [x] upload single file
- [x] adding image support through url_for to support 3rd party cloud storage
- [x] use html 5 video element for video files
- [x] use html audio element for audio files
- [x] download link to other files
- [x] preview videos
- [x] preview pdfs
- [x] upload multiple files
- [x] find a way to delete attachments
- [x] preview office files as pictures

## Contribution Guide:
1. contributers are welcome (code, suggestions, and bugs).
2. please test your code: `cd test_app && bundle && bundle exec rails test`.
3. please document your code.
4. add your name to the `contribute.md`.

---
Based on the [Administrate::Field::Image](https://github.com/thoughtbot/administrate-field-image) template, and inspired by [Administrate::Field::Paperclip](https://github.com/picandocodigo/administrate-field-paperclip).

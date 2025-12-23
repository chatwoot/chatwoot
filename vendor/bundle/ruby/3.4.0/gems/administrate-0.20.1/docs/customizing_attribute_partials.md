---
title: Customizing attribute partials
---

Occasionally you might want to change how specific types of attributes appear
across all dashboards. You can customize the following built in field types:

- `belongs_to`
- `boolean`
- `date_time`
- `date`
- `email`
- `has_many`
- `has_one`
- `number`
- `polymorphic`
- `select`
- `string`
- `text`

For example, you might want all `Number` values to round to three decimal points.

To get started, run the appropriate rails generator:

```bash
rails generate administrate:views:field number
```

This will generate three files:

- `app/view/fields/number/_form.html.erb`
- `app/view/fields/number/_index.html.erb`
- `app/view/fields/number/_show.html.erb`

You can generate the partials for all field types by passing `all` to the generator.

```bash
rails generate administrate:views:field all
```

The generated templates will have documentation
describing which variables are in scope.
The rendering part of the partial will look like:

```eruby
<%= field.data %>
```

Changing numbers to display to three decimal places might look like this:

```eruby
<%= field.data.round(3) %>
```

If you only want to change how an attribute appears
on a single page (e.g. `index`), you may delete the unnecessary templates.

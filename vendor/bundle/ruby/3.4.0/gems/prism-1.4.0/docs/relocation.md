# Relocation

Prism parses deterministically for the same input. This provides a nice property that is exposed through the `#node_id` API on nodes. Effectively this means that for the same input, these values will remain consistent every time the source is parsed. This means we can reparse the source same with a `#node_id` value and find the exact same node again.

The `Relocation` module provides an API around this property. It allows you to "save" nodes and locations using a minimal amount of memory (just the node_id and a field identifier) and then reify them later. This minimizes the amount of memory you need to allocate to store this information because it does not keep around a pointer to the source string.

## Getting started

To get started with the `Relocation` module, you would first instantiate a `Repository` object. You do this through a DSL that chains method calls for configuration. For example, if for every entry in the repository you want to store the start and end lines, the start and end code unit columns for in UTF-16, and the leading comments, you would:

```ruby
repository = Prism::Relocation.filepath("path/to/file").lines.code_unit_columns(Encoding::UTF_16).leading_comments
```

Now that you have the repository, you can pass it into any of the `save*` APIs on nodes or locations to create entries in the repository that will be lazily reified.

```ruby
# assume that node is a Prism::ClassNode object
entry = node.constant_path.save(repository)
```

Now that you have the entry object, you do not need to keep around a reference to the repository, it will be cleaned up on its own when the last entry is reified. Now, whenever you need to, you may call the associated field methods on the entry object, as in:

```ruby
entry.start_line
entry.end_line

entry.start_code_units_column
entry.end_code_units_column

entry.leading_comments
```

Note that if you had configured other fields to be saved, you would be able to access them as well. The first time one of these fields is accessed, the repository will reify every entry it knows about and then clean itself up. In this way, you can effectively treat them as if you had kept around lightweight versions of `Prism::Node` or `Prism::Location` objects.

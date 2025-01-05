*Pydantic* allows auto creation of JSON Schemas from models:

{!.tmp_examples/schema_main.md!}


The generated schemas are compliant with the specifications:
[JSON Schema Core](https://json-schema.org/latest/json-schema-core.html),
[JSON Schema Validation](https://json-schema.org/latest/json-schema-validation.html) and
[OpenAPI](https://github.com/OAI/OpenAPI-Specification).

`BaseModel.schema` will return a dict of the schema, while `BaseModel.schema_json` will return a JSON string
representation of that dict.

Sub-models used are added to the `definitions` JSON attribute and referenced, as per the spec.

All sub-models' (and their sub-models') schemas are put directly in a top-level `definitions` JSON key for easy re-use
and reference.

"Sub-models" with modifications (via the `Field` class) like a custom title, description or default value,
are recursively included instead of referenced.

The `description` for models is taken from either the docstring of the class or the argument `description` to
the `Field` class.

The schema is generated by default using aliases as keys, but it can be generated using model
property names instead by calling `MainModel.schema/schema_json(by_alias=False)`.

The format of `$ref`s (`"#/definitions/FooBar"` above) can be altered by calling `schema()` or `schema_json()`
with the `ref_template` keyword argument, e.g. `ApplePie.schema(ref_template='/schemas/{model}.json#/')`, here `{model}`
will be replaced with the model naming using `str.format()`.

## Getting schema of a specified type

_Pydantic_ includes two standalone utility functions `schema_of` and `schema_json_of` that can be used to
apply the schema generation logic used for _pydantic_ models in a more ad-hoc way.
These functions behave similarly to `BaseModel.schema` and `BaseModel.schema_json`,
but work with arbitrary pydantic-compatible types.

{!.tmp_examples/schema_ad_hoc.md!}


## Field customization

Optionally, the `Field` function can be used to provide extra information about the field and validations.
It has the following arguments:

* `default`: (a positional argument) the default value of the field.
    Since the `Field` replaces the field's default, this first argument can be used to set the default.
    Use ellipsis (`...`) to indicate the field is required.
* `default_factory`: a zero-argument callable that will be called when a default value is needed for this field.
    Among other purposes, this can be used to set dynamic default values.
    It is forbidden to set both `default` and `default_factory`.
* `alias`: the public name of the field
* `title`: if omitted, `field_name.title()` is used
* `description`: if omitted and the annotation is a sub-model,
    the docstring of the sub-model will be used
* `exclude`: exclude this field when dumping (`.dict` and `.json`) the instance. The exact syntax and configuration options are described in details in the [exporting models section](exporting_models.md#advanced-include-and-exclude).
* `include`: include (only) this field when dumping (`.dict` and `.json`) the instance. The exact syntax and configuration options are described in details in the [exporting models section](exporting_models.md#advanced-include-and-exclude).
* `const`: this argument *must* be the same as the field's default value if present.
* `gt`: for numeric values (``int``, `float`, `Decimal`), adds a validation of "greater than" and an annotation
  of `exclusiveMinimum` to the JSON Schema
* `ge`: for numeric values, this adds a validation of "greater than or equal" and an annotation of `minimum` to the
  JSON Schema
* `lt`: for numeric values, this adds a validation of "less than" and an annotation of `exclusiveMaximum` to the
  JSON Schema
* `le`: for numeric values, this adds a validation of "less than or equal" and an annotation of `maximum` to the
  JSON Schema
* `multiple_of`: for numeric values, this adds a validation of "a multiple of" and an annotation of `multipleOf` to the
  JSON Schema
* `max_digits`: for `Decimal` values, this adds a validation to have a maximum number of digits within the decimal. It
  does not include a zero before the decimal point or trailing decimal zeroes.
* `decimal_places`: for `Decimal` values, this adds a validation to have at most a number of decimal places allowed. It
  does not include trailing decimal zeroes.
* `min_items`: for list values, this adds a corresponding validation and an annotation of `minItems` to the
  JSON Schema
* `max_items`: for list values, this adds a corresponding validation and an annotation of `maxItems` to the
  JSON Schema
* `unique_items`: for list values, this adds a corresponding validation and an annotation of `uniqueItems` to the
  JSON Schema
* `min_length`: for string values, this adds a corresponding validation and an annotation of `minLength` to the
  JSON Schema
* `max_length`: for string values, this adds a corresponding validation and an annotation of `maxLength` to the
  JSON Schema
* `allow_mutation`: a boolean which defaults to `True`. When False, the field raises a `TypeError` if the field is
  assigned on an instance.  The model config must set `validate_assignment` to `True` for this check to be performed.
* `regex`: for string values, this adds a Regular Expression validation generated from the passed string and an
  annotation of `pattern` to the JSON Schema

  !!! note
      *pydantic* validates strings using `re.match`,
      which treats regular expressions as implicitly anchored at the beginning.
      On the contrary,
      JSON Schema validators treat the `pattern` keyword as implicitly unanchored,
      more like what `re.search` does.

      For interoperability, depending on your desired behavior,
      either explicitly anchor your regular expressions with `^`
      (e.g. `^foo` to match any string starting with `foo`),
      or explicitly allow an arbitrary prefix with `.*?`
      (e.g. `.*?foo` to match any string containing the substring `foo`).

      See [#1631](https://github.com/pydantic/pydantic/issues/1631)
      for a discussion of possible changes to *pydantic* behavior in **v2**.

* `repr`: a boolean which defaults to `True`. When False, the field shall be hidden from the object representation.
* `**` any other keyword arguments (e.g. `examples`) will be added verbatim to the field's schema

Instead of using `Field`, the `fields` property of [the Config class](model_config.md) can be used
to set all of the arguments above except `default`.

### Unenforced Field constraints

If *pydantic* finds constraints which are not being enforced, an error will be raised. If you want to force the
constraint to appear in the schema, even though it's not being checked upon parsing, you can use variadic arguments
to `Field()` with the raw schema attribute name:

{!.tmp_examples/schema_unenforced_constraints.md!}

### typing.Annotated Fields

Rather than assigning a `Field` value, it can be specified in the type hint with `typing.Annotated`:

{!.tmp_examples/schema_annotated.md!}

`Field` can only be supplied once per field - an error will be raised if used in `Annotated` and as the assigned value.
Defaults can be set outside `Annotated` as the assigned value or with `Field.default_factory` inside `Annotated` - the
`Field.default` argument is not supported inside `Annotated`.

For versions of Python prior to 3.9, `typing_extensions.Annotated` can be used.

## Modifying schema in custom fields

Custom field types can customise the schema generated for them using the `__modify_schema__` class method;
see [Custom Data Types](types.md#custom-data-types) for more details.

`__modify_schema__` can also take a `field` argument which will have type `Optional[ModelField]`.
*pydantic* will inspect the signature of `__modify_schema__` to determine whether the `field` argument should be
included.

{!.tmp_examples/schema_with_field.md!}


## JSON Schema Types

Types, custom field types, and constraints (like `max_length`) are mapped to the corresponding spec formats in the
following priority order (when there is an equivalent available):

1. [JSON Schema Core](http://json-schema.org/latest/json-schema-core.html#rfc.section.4.3.1)
2. [JSON Schema Validation](http://json-schema.org/latest/json-schema-validation.html)
3. [OpenAPI Data Types](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.2.md#data-types)
4. The standard `format` JSON field is used to define *pydantic* extensions for more complex `string` sub-types.

The field schema mapping from Python / *pydantic* to JSON Schema is done as follows:

{!.tmp_schema_mappings.html!}

## Top-level schema generation

You can also generate a top-level JSON Schema that only includes a list of models and related
sub-models in its `definitions`:

{!.tmp_examples/schema_top_level.md!}


## Schema customization

You can customize the generated `$ref` JSON location: the definitions are always stored under the key
`definitions`, but a specified prefix can be used for the references.

This is useful if you need to extend or modify the JSON Schema default definitions location. E.g. with OpenAPI:

{!.tmp_examples/schema_custom.md!}


It's also possible to extend/override the generated JSON schema in a model.

To do it, use the `Config` sub-class attribute `schema_extra`.

For example, you could add `examples` to the JSON Schema:

{!.tmp_examples/schema_with_example.md!}


For more fine-grained control, you can alternatively set `schema_extra` to a callable and post-process the generated schema.
The callable can have one or two positional arguments.
The first will be the schema dictionary.
The second, if accepted, will be the model class.
The callable is expected to mutate the schema dictionary *in-place*; the return value is not used.

For example, the `title` key can be removed from the model's `properties`:

{!.tmp_examples/schema_extra_callable.md!}



```
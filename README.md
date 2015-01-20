Database to Contentful exporter
=================

## Description

Migrate content from a relational database to [Contentful.com](https://www.contentful.com).

This tool allows you to fetch content from your database system and prepare it for the import.


## Installation

```bash
gem install database-exporter
```

This will install the `database-exporter` executable on your system.

## Usage

Once you installed the Gem and created the `settings.yml` file, you can invoke the tool using:

```bash
database-exporter --config-file settings.yml  --action
```


## Configuration File

You need to create a configuration file and fill in the following information:

```yml
data_dir: PATH_TO_ALL_DATA
table_names: PATH_TO_ALL_DATA/table_names.json
```


## Actions

To display all actions use the `-h` option:

```bash
database-exporter -h
```

#### --list-tables

This action will create a JSON file including all table names from your database and write them to `data_dir/table_names.json`. The table names are needed to extract the content from the database.

#### --extract-to-json

In the [settings.yml](https://github.com/contentful/generic-importer.rb#setting-file) file, you need to define the table names that should be exported from the database.

The recommended way to get the table names, is using [--list-tables](https://github.com/contentful/database-adapter#--list-tables).

After specifying the table names you want to extract in your settings, run the `--extract-to-json` command.
This will save each object from the database into its own JSON file, ready to be transformed and imported.

Path to JSON data: ***data_dir/entries/content_type_name_defined_in_mapping_json_file***

#### --prepare-json

Prepares the generated JSON files so they can be imported to Contentful.


### FIELDS

To change name of a field in the database for new one, we need to add a new mapping for that field:
```
 "fields": {
             "model_name": "new_api_contentful_field_name",
             "model_name": "new_api_contentful_field_name",
             "model_name": "new_api_contentful_field_name"
         },
```


### Relation Types/Joins

The following relational associations behave similar to the Active Record associations.

#### belongs_to

The `belongs_to` method should only be used if this table contains the foreign key. If the other table contains the foreign key, then you should use `has_one` instead.

At the beginning and we are looking for `type` and `id` of linked object in file `contentful_structure.json`.
It's very important to maintain consistency for the content type names  in `mapping.json` and `contentful_structure.json`.
The next step is to check if the object has defined a foreign key itself. After that an object with type and ID is created.

Example:

```javascript
    "Comments": {
        "content_type": "Comments",
        "type": "entry",
        "fields": {
        },
        "links": {
           "belongs_to": [
                          {
                              "relation_to": "ModelName",
                              "foreign_id": "model_foreign_id"
                          }
                      ]
        }
    }
 ```

It will assign the associated object and save its ID `(model_name + id)` in the JSON file.

Result:

```javascript
{
  "id": "model_name_ID",
  ...
  "job_add_id": {
    "type": "Entry",
    "id": "model_name_3"
  },
}
```

#### has_one

The `has_one` method should be used if the other table contains the foreign key. If the current table contains the foreign key, then you should use belongs_to instead.

At the beginning the tool builds a helper file which contains the primary id as key and the foreign id as values. This file lives in `data_dir/helpers`.

After that we modify only those files whose ID is located in the helper file as a key. Value is written as a Hash value.

 Example:

```javascript
"Users": {
 "content_type": "Users",
 "type": "entry",
 "fields": {
  ...
 },
 "links": {
     "has_one": [
         {
             "relation_to": "ModelName",
             "primary_id": "primary_key_name"
         }
     ]
 }
}
```

Result:

It will assign the associated object, save his ID ```(model_name + id)``` in JSON file.

```javascript
...
"model_name": {
    "type": "profiles",
    "id": "content_type_id_3"
}
```


#### many

The resulting file will be generated in a similar way as for the `has_one` relation.
At the beginning the tool builds a helper file which contains the primary id as key and the foreign id as values. This file lives in `data_dir/helpers`.

After that we modify only those files whose ID is located in the helper file as a key. Related objects are written always as an Array.

Example:

```javascript
"ModelName": {
...
},
"links": {
    "many": [
                {
                    "relation_to": "related_model_name",
                    "primary_id": "primary_key_name"
                }
            ],
        }
}
```

It will assign the associated objects, save its ID ```(model_name + id)``` in JSON file.

Result:

```javascript
{
  "id": "content_type_id",
  "comments": [
    {
      "type": "related_content_type_name",
      "id": "related_model_name_id"
    },
    {
      "type": "related_content_type_name",
      "id": "related_model_name_id"
    },
    {
      "type": "related_content_type_name",
      "id": "related_model_name_id"
    },
    {
      "type": "related_content_type_name",
      "id": "related_model_name_id"
    }
  ]
}
```

#### many_through

The resulting file will be generated in a similar way as for the `has_one` relation.
After that we modify only those files whose ID is located in the helper file as a key. Related objects are written always as an Array.

Attributes:

```
relation_to: Name of related model, defined in  mapping.json file as a key.
primary_id: Name of primary key located in joining table.
foreign_id: Name of foreign key, located in joining table. Object with this ID will be added mapped object.
through: Name of joining model.
```


Example:

```javascript
"ModelName": {
    ...
    "links": {
        "many_through": [
            {
                "relation_to": "related_model_name",
                "primary_id": "primary_key_name",
                "foreign_id": "foreign_key_name",
                "through": "join_table_name"
            }
        ]
    }
}
```

It will map the join table and save objects IDs in current model.

Result:

```javascript
  "content_type_name": [
    {
      "type": "content_type_name",
      "id": "related_model_foreign_id"
    },
    {
      "type": "content_type_name",
      "id": "related_model_foreign_id"
    },
    {
      "type": "content_type_name",
      "id": "related_model_foreign_id"
    }
  ]
```

#### aggregate_belongs

`aggregate_belongs` allows to fetch a value from an related model.
To add the value, the table must have the `foreign_id` to the related table. Through this value the object is found and selected the wanted data is extracted.

Attributes:

```
relation_to: Name of related model, defined in  mapping.json file as a key.
primary_id: Name of primary key in model.
field: Name of the attribute, which you want to add.
save_as: Name of the attribute whose value is assigned.
```

Example:

```javascript
"links": {
    "aggregate_belongs": [
        {
            "relation_to": "related_model_name",
            "primary_id": "primary_key_name",
            "field": "aggregated_field_name",
            "save_as": "name_of_field"
        }
    ]
}
```

Result:

```javascript
{
  "id": "model_name_id",
   "name_of_field": "aggregated_value"
}
```

#### aggregate_has_one

It will save value with key of the related model.
To add `has_one` value, the table must have `primary_id` of related table.

Attributes:

```
relation_to: Name of related model, defined in  mapping.json file as a key.
primary_id: Name of primary key in model.
field: Name of the attribute, which you want to add.
save_as: Name of the attribute whose value is assigned.
```

Example:

```javascript
"links": {
    "aggregate_has_one": [
        {
          "primary_id": "primary_id",
          "relation_to": "related_model_name",
          "field": "name_of_field_to_aggregate",
          "save_as": "save_as_field_name"
        }
    ]
}
```

Result:

```javascript
{
  "id": "model_name_id",
   "name_of_field": "aggregated_value"
}
```

#### aggregate_many

It will save the value with key of related table.
To add the `has_many` value, related table must have the `primary_id` of the related model. This will create a new attribute in model with the Array type.

Example:

```javascript
"links": {
    "aggregate_many": [
        {
          "primary_id": "primary_id",
          "relation_to": "related_model_name",
          "field": "name_of_field_to_aggregate",
          "save_as": "save_as_field_name"
        }
    ]
}
```

Result:

```javascript
{
"id": "model_name_id",
"name_of_field": [
    "aggregated_value1",
    "aggregated_value2",
    "aggregated_value3",
    "aggregated_value4"
    ]
}
```

#### aggregate_through

It will save value with key of related model.
To add the `has_many, through` value, you need to define the `join model` which contains `primary_id` and `foreign_id`. Through `foreign_id` the searched object will be found.

Attributes:

```
relation_to: Name of related model, defined in  mapping.json file as a key.
primary_id: Name of primary key located in joining table.
foreign_id: Name of foreign key, located in joining table. Object with this ID will be added mapped object.
through: Name of joining model.
```

Example:

```javascript
"links": {
    "aggregate_through": [
        {
           "relation_to": "related_model_name",
           "primary_id": "primary_key_name",
           "foreign_id": "foreign_key_name",
           "through": "join_table_name",
           "field": '"name_of_field_to_aggregate",
           "save_as": "save_as_field_name"
        }
    ]
}
```

Result:

```javascript
{
"id": "model_name_id",
 "name_of_field": ["aggregated_value1",
                   "aggregated_value2",
                   "aggregated_value3",
                   "aggregated_value4"
                   ]
}
```

## Contentful Structure

This file represents our Contentful structure.
This structure file defines the remote data types and how they are formed.

Example:

```javascript
{
    "Comments": {
        "id": "comment",
        "description": "",
        "displayField": "title",
        "fields": {
            "title": "Text",
            "content": "Text"
        }
    },
    "JobAdd": {
        "id": "job_add",
        "description": "Add new job form",
        "displayField": "name",
        "fields": {
            "name": "Text",
            "specification": "Text",
            "Images": {
                "id": "image",
                "link_type": "Asset"
            },
            "Comments": {
                "id": "comments",
                "link_type": "Array",
                "type": "Entry"
            },
            "Skills": {
                "id": "skills",
                "link_type": "Array",
                "type": "Entry"
            }
        }
    }
```
They keys "Images", "Comments", "Skills" are the equivalent of the content types IDs specified in the file **mapping.json**.

Example:
```javascript
"SkillsTableName": {
    "content_type": "Skills",
    "type": "entry",
    "fields": { ... }
```

**IMPORTANT**

To create any relationship between tables, we must remember that the content names given in the  **mapping.json** file, must be equal with names in the **contentful_structure.json** file.

## Setting file

To be able to extract any content you need to create a `settings.yml` file and define all needed parameters.

#### Database Connection - Define Adapter

Assuming we are going to work with a MySQL, SQLite or PostgreSQL database we need to setup the credentials:
Following is the example of connecting to a MySQL database `test_import`.

```yml
adapter: mysql2
user: username
host: localhost
database: test_import
password: secret_password
```

**Available Adapters**

```
PostgreSQL => postgres
MySQL => mysql2
SQlite => sqlite
```

**Define Exporter**

The default command is the database export.

``` database-exporter --config-file settings.yml --action ```

#### Mapped tables

Before we can start exporting the data from the database, the to be used tables need to be specified.
The fastest way to get the names is using the [--list-tables](https://github.com/contentful/generic-importer.rb#--list-tables) action.

Add those to the `settings.yml` file in the following manner:

 ```yml
mapped:
    tables:
```
Example:

 ```yml
mapped:
 tables:
  - :example_1
  - :example_2
  - :example_3
  - :example_4
```

There is no need to specify the names of a join table unless you want to save them as a separate content type.

### Mapping

* JSON file with mapping structure that defines relations between models.

```yml
mapping_dir: example_path/mapping.json
```

* JSON file with contentful structure
```yml
contentful_structure_dir: contentful_import_files/contentful_structure.json
```
* [Dump JSON file](https://github.com/contentful/generic-importer.rb#--convert-content-model-to-json) with content types from content model:

```yml
import_form_dir: contentful_import_files/contentful_structure.json
```

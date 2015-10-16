require_relative '03_associatable'
require 'byebug'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]
      id = self.send(through_options.primary_key)
      query = <<-SQL
        SELECT
          #{source_options.table_name}.*
        FROM
          #{source_options.table_name}
        JOIN
          #{through_options.table_name}
        ON
          (#{source_options.table_name}.#{source_options.primary_key} =
          #{through_options.table_name}.#{source_options.foreign_key})
        WHERE
          #{through_options.table_name}.#{through_options.primary_key} = ?
        LIMIT 1
      SQL
      result = DBConnection.execute(query, id)
      source_options.model_class.parse_all(result).first
    end
  end
end

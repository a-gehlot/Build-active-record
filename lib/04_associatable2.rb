require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    # ...
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      source_table = source_options.table_name
      source_p = source_options.primary_key
      source_f = source_options.foreign_key

      through_table = through_options.table_name
      through_p = through_options.primary_key
      through_f = through_options.foreign_key

      key = self.send(through_f)

      results = DBConnection.execute(<<-SQL, key)
      SELECT
        #{source_table}.*
      FROM
        #{through_table}
      JOIN
        #{source_table}
      ON 
        #{through_table}.#{source_f} = #{source_table}.#{source_p}
      WHERE
        #{through_table}.#{through_p} = ?
      SQL

      source_options.model_class.parse_all(results).first

    end
  end
end

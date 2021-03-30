require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    # ...
    return @columns[0] if @columns
    @columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @columns[0].map!(&:to_sym)
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) { self.attributes[column] }
      define_method("#{column}=") { |val| self.attributes[column] = val }
    end
  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # ...
    @table_name || self.name.underscore.pluralize
  end

  def self.all
    # ...
    all = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL

    self.parse_all(all)

  end

  def self.parse_all(results)
    # ...
    all = []
    results.each do |result|
      all << self.new(result)
    end
    all
  end

  def self.find(id)
    # ...
    self.all[id - 1]
  end

  def initialize(params = {})
    # ...
    params.each do |attr_name, val|
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        self.send("#{attr_name}=", val)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end

  end

  def attributes
    # ...
    @attributes ||= {}
  end

  def attribute_values
    # ...
    self.class.columns.map { |col_name| self.send(col_name) }
  end

  def insert
    # ...
    col_num = self.class.columns.length - 1
    col_names = self.class.columns.drop(1).join(", ")
    question_marks = Array.new(col_num, "?").join(", ")
    values = attribute_values.drop(1)
    DBConnection.execute(<<-SQL, *values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    # ...
    updates = self.class.columns.map { |col| "#{col} = ?"}.join(", ")
    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{updates}
      WHERE
        id = ?
    SQL
  end

  def save
    # ...
    self.id.nil? ? insert : update
  end
end

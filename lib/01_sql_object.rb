require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    query_result = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @columns = query_result.first.map(&:to_sym)
  end

  def self.finalize!
    columns.each do |name|
      define_method(name) do
        attributes[name]
      end

      define_method("#{name}=") do |value|
        attributes[name] = value
      end
    end
    nil
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |hash| self.new(hash) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    result.map { |hash| self.new(hash) }.first
  end

  def initialize(params = {})
    cols = self.class.columns
    params.each do |attr_name, value|
      name_sym = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless cols.include?(name_sym)
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    cols = self.class.columns
    cols.map { |col| self.send(col) }
  end

  def insert
    cols = self.class.columns
    col_names = cols.map(&:to_s).join(',')
    question_marks = (["?"]*(cols.count)).join(",")
    DBConnection.execute(<<-SQL,*attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    @attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns
    set_line = cols.map { |attr_name| "#{attr_name} = ?" }.join(',')
    id = @attributes[:id]

    DBConnection.execute(<<-SQL,*attribute_values,id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    attributes
    @attributes[:id].nil? ? insert : update
  end
end

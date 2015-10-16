require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    vals = params.values
    where_line = params.keys.map { |key| "#{key} = ?"}.join(" AND ")
    result = DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
    SQL
    result.map { |hash| self.new(hash) }
  end
end

class SQLObject
  extend Searchable
end

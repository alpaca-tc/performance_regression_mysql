require 'fileutils'
require 'active_record'
require 'pry'
require 'mysql2'

LOGGER = File.new('result.dump', 'w')

configuration = {
  adapter: 'mysql2',
  encoding: 'utf8mb4',
  charset: 'utf8mb4',
  collation: 'utf8mb4_bin',
  host: '127.0.0.1',
  username: 'root',
  database: 'performance_regression_test'
}

# Re-create database
# ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection(configuration.merge(database: nil))

ActiveRecord::Base.connection.drop_database(configuration[:database])
ActiveRecord::Base.connection.create_database(configuration[:database], charset: 'utf8mb4')

ActiveRecord::Base.establish_connection(configuration)

# Setup tables
ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
  end
end

def test_case(query)
  LOGGER.puts '----------------------------------------'
  LOGGER.puts ActiveRecord::Base.connection.explain(query)
  LOGGER.puts '----------------------------------------'
  LOGGER.puts ActiveRecord::Base.connection.query_values(query)
  LOGGER.puts
end

test_case(<<~SQL)
  SELECT COLUMN_NAME
  FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
  WHERE CONSTRAINT_NAME = 'PRIMARY'
    AND TABLE_SCHEMA = database()
    AND TABLE_NAME = 'users'
  ORDER BY ORDINAL_POSITION
SQL

test_case(<<~SQL)
  SELECT COLUMN_NAME
  FROM INFORMATION_SCHEMA.STATISTICS
  WHERE TABLE_SCHEMA = database()
    AND INDEX_NAME = 'PRIMARY'
    AND TABLE_NAME = 'users'
  ORDER BY SEQ_IN_INDEX
SQL

LOGGER.fsync

puts File.read('result.dump')

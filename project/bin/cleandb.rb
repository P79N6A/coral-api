#encoding: utf-8
$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib')

require 'database'
require 'configration'
require 'utility'
require 'yaml'

puts 'Start Clean DB'

begin
  ##读取Database.yml
  clean_dbs = (Configration.new.envdata)['CLEAN_DBS']
  configdb = (Configration.new.testdata)['DBNAME']
  db_config = YAML.load_file(getrootpath+'\\config\\database.yml')
  #清空数据库

  clean_dbs.each do |database|
    tables = db_config[configdb]['clean_tables']
    tables_except = db_config[configdb]['clean_tables_except']
    case db_config[configdb]['adapter'].downcase
      when 'mysql'
        include DB::Mysql
        #   #连接数据库
        db_init(configdb)
        db_conn(database)
        #   #获取数据表列表
        table_list = []
        if (String===tables and tables.downcase.eql? 'all')or(Array===tables and tables[0].downcase.eql?'all')
          query('USE ' + database)
          ret_table_list = query('SHOW TABLES')
          ret_table_list.each do |key,value|
            table_list << value['Tables_in_'+database]
          end
        else
          table_list = tables
        end
      when 'oracle'
        include DB::Mysql
        db_init(configdb)
        db_conn(database)
        #   #获取数据表列表
        table_list = []
        if (String===tables and tables.downcase.eql? 'all')or(Array===tables and tables[0].downcase.eql?'all')
          ret_table_list = query('select TABLE_NAME from user_tables')
          ret_table_list.each_value do |value|
            table_list << value['TABLE_NAME']
          end
        else
          table_list = tables
        end
    end
    #祛除不能删除的数据表
    if !tables_except.nil?
      tables_except.each do |except_item|
        table_list.delete(except_item)
      end
    end
    table_list.each do |table|
        #清空数据表
       results = execute('DELETE FROM '+ table)
       if(results.nil?)
         puts '清空数据表' + database + "." +table + '成功!'
       else
         puts '清空数据表' + database + "." + table + '失败!'
       end
    end
  end

puts "All Done!"
rescue StandardError => e
  puts e.to_s
end



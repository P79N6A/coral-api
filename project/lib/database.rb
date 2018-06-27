#encoding: utf-8
$LOAD_PATH << File.join(File.dirname(__FILE__), '../jar')
require 'yaml'
require 'dbi'
require 'dbd/Jdbc'
require 'jdbc/mysql'
require 'ojdbc6.jar'
require 'utility'
require 'fileoperation'
require 'redis'

include FileOperation

module DB
  module Mysql
    attr_accessor :sqlstring
    #初始化mysql类，载入配置文件和节点
    def db_init(nodename,configpath=getrootpath+'config/database.yml')
      begin
        @sqlstring = ''
        dbconfig = YAML.load_file(configpath)
        if dbconfig[nodename]['adapter'].downcase != 'mysql'
          raise 'adapter is error,please check database.yml!'
          return
        end
        @host = dbconfig[nodename]['host']
        @user = dbconfig[nodename]['username']
        @pwd = dbconfig[nodename]['password']
        @dbname = dbconfig[nodename]['database']
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def db_conn(dbname="#{@dbname}")
      begin
        Jdbc::MySQL.load_driver
        @dbh =DBI.connect(
            'DBI:Jdbc:mysql://'+ "#{@host}" + '/'+dbname + '?useOldAliasMetadataBehavior=true',
            "#{@user}", "#{@pwd}",
            'driver' => 'com.mysql.jdbc.Driver'
        )
      rescue DBI::DatabaseError => e
        puts "Error code:    #{e.err}"
        puts "Error message: #{e.errstr}"
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
        @dbh.rollback
      end
    end

    ################################################
    #  输出二维hash结果集，无结果返回{}
    ################################################
    def query(sqlstring)
      begin
        recorder = {}
        res = @dbh.prepare(sqlstring)
        res.execute
        i = 1
        res.fetch_hash do |row|
          recorder[i]  = row
          i += 1
        end
        res.finish
        recorder
      rescue DBI::DatabaseError => e
        puts "Error code:    #{e.err}"
        puts "Error message: #{e.errstr}"
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
        @dbh.rollback
      end
    end

    def execute(sqlstring)
      begin
        res = @dbh.do(sqlstring)
      rescue DBI::DatabaseError => e
        puts "Error code:    #{e.err}"
        puts "Error message: #{e.errstr}"
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
        dbh.rollback
      end
    end

    def disconnect
      begin
        @dbh.disconnect if @dbh
      rescue DBI::DatabaseError => e
        puts "Error code:    #{e.err}"
        puts "Error message: #{e.errstr}"
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
        dbh.rollback
      end
    end
  end

  module ActiveMysql
    def db_init(nodename,configpath=getrootpath+'config/database.yml')
      @dbconfig = YAML.load_file(configpath)[nodename]
    end
    def db_conn
      ActiveRecord::Base.establish_connection(@dbconfig)
    end
  end

  module Oracle
    attr_accessor :sqlstring
    def db_init(nodename,configpath=getrootpath+'config/database.yml')
      begin
        @sqlstring = ''
        dbconfig = YAML.load_file(configpath)
        if dbconfig[nodename]['adapter'].downcase != 'oracle'
          raise 'adapter is error,please check database.yml!'
          return
        end
        @host = dbconfig[nodename]['host']
        @user = dbconfig[nodename]['username']
        @pwd = dbconfig[nodename]['password']
        @dbname = dbconfig[nodename]['database']
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def db_conn(dbname="#{@dbname}")
      begin
        Java::JavaClass.for_name('oracle.jdbc.driver.OracleDriver')
        url = 'jdbc:oracle:thin:@'+@host+':1521:'+dbname
        # puts url
        @conn = java.sql.DriverManager.getConnection(url, "#{@user}", "#{@pwd}");
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    ################################################
    #  输出二维hash结果集，无结果返回{}
    ################################################
    def query(sqlstring)
      begin
        data = {}
        stmt = @conn.createStatement
        res = stmt.executeQuery(sqlstring);
        rsmd = res.getMetaData();
        columnheader = []
        1.upto(rsmd.getColumnCount()){|i|columnheader << rsmd.getColumnName(i)}
        # puts columns
        rowcount = 1
        while res.next
          row = []
          1.upto(rsmd.getColumnCount()){|i| row << res.getString(i)}
          alist = columnheader.zip(row)
          data[rowcount] = Hash[*alist.flatten]
          rowcount +=1
        end
        data
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def execute(sqlstring)
      begin
        stmt = @conn.createStatement
        stmt.executeQuery(sqlstring);
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def disconnect
      begin
        @conn.close if @conn
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end
  end

  module RedisDB
    def db_init(nodename,configpath=getrootpath+'config/database.yml')
      dbconfig = YAML.load_file(configpath)
      @host = dbconfig[nodename]['Redis.ip']
      @user = dbconfig[nodename]['Redis.port']
      @redis = Redis.new(host: "#{ip}", port: "#{port}")
    end

    def get_value(key)
      begin
        (@redis.get(key)!=nil)?JSON(@redis.get(key)):nil
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
        {'errorMsg'=> e.to_s }.to_json
      end
    end

    def set_value(params)
      begin
        @redis.set(params[:key],params[:value])
        {'responseCode'=>'10000'}.to_json
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
        {'errorMsg'=> e.to_s}.to_json
      end
    end

  end
end


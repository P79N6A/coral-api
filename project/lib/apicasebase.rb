#encoding:utf-8
# $LOAD_PATH << File.join(File.dirname(__FILE__), '../lib')
require 'configration'
require 'fileoperation'
require 'httprequest'
require 'utility'
require 'database'
require 'json'
require 'json_spec'
require 'erb'
require 'matchers'

include FileOperation
include FileOperation::Excel
include DB::Mysql

class ApiCaseBase
  attr_accessor :testdata,:envdata
  #初始化请求sheet数据
  def self.inherited(subclass)
    @@env = $envdata["TESTENV"].downcase     #环境配置参数
    path = $0.split("/")
    path.each_index{|index|@@sub_dir = path[index+1..-2].join('/') if path[index] == 'ext'}

    class << subclass
      attr_accessor :request,:expect,:flow_request,:flow_expect
    end
    subclass.request = gen_sheetdata(subclass.name)
    subclass.expect = gen_sheetdata(subclass.name,'Expection')
    subclass.flow_request = gen_sheetdata(subclass.name,'Flow')
    subclass.flow_expect = gen_sheetdata(subclass.name,'Flow_Expection')
  end

  class << self

    def gen_sheetdata(filename,idxorname=0)
      begin
        rows_with_header(getrootpath+"data/"+ @@env + "/#{@@sub_dir}/" + filename + ".xls",idxorname)
      rescue StandardError => e
        puts self.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def gen_nodelist(filename,idxorname)
      begin
        transactionList = rows_onlydata(getrootpath+"data/"+ @@env + "/#{@@sub_dir}" + filename + ".xls",idxorname)
        transactionList.each do |k,v|
          transarray=[]
          v.each_index do |i|
            transarray[i] = Hash[*transactionList[k][i].split(/\:|,/)]
          end
          transactionList[k] = transarray.dup
        end
      rescue StandardError => e
        puts self.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def add_node(datahash,*args)
      begin
        idxorname = args.delete_at(0)
        if (idxorname.include?'_')
          nodename = idxorname.split('_')[1]
        else
          nodename = idxorname
        end
        params = args[0]
        @subnode = gen_sheetdata(self.name,idxorname)
        if params.eql?nil
          update_node datahash, "#{nodename}=@subnode"
        else
          update @subnode,params
          update_node datahash, "#{nodename}=@subnode"
        end
      rescue StandardError => e
        puts self.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def add_node_force(datahash,*args)
      begin
        idxorname = args.delete_at(0)
        if (idxorname.include?'_')
          nodename = idxorname.split('_')[1]
        else
          nodename = idxorname
        end
        params = args[0]
        @subnode = {}
        for num in 1..datahash.size do
          @subnode[num] = deep_clone(datahash[1][nodename])
        end
        if params.eql?nil
          update_node_force datahash, "#{nodename}=@subnode"
        else
          update_force @subnode,params
          update_node_force datahash, "#{nodename}=@subnode"
        end

      rescue StandardError => e
        puts self.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def add_list(datahash,*args)
      begin
        idxorname = args.delete_at(0)
        if (idxorname.include?'_')
          nodename = idxorname.split('_')[1]
        else
          nodename = idxorname
        end
        params = args[0]
        @subnodelist = gen_nodelist(self.name,idxorname)
        if params.eql?nil
          add_nodelist datahash,"#{nodename}=@subnodelist"
        else
          update_nodelist @subnodelist,params
          add_nodelist datahash,"#{nodename}=@subnodelist"
        end
      rescue StandardError => e
        puts self.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def add_list_force(datahash,*args)
      begin
        idxorname = args.delete_at(0)
        if (idxorname.include?'_')
          nodename = idxorname.split('_')[1]
        else
          nodename = idxorname
        end
        params = args[0]
        @subnodelist = {}
        for num in 1..datahash.size do
          @subnodelist[num] = deep_clone(datahash[1][nodename])
        end
        if params.eql?nil
          add_nodelist_force datahash,"#{nodename}=@subnodelist"
        else
          update_nodelist_force @subnodelist,params
          add_nodelist_force datahash,"#{nodename}=@subnodelist"
        end
      rescue StandardError => e
        puts self.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def code_gen(dir,extname,para,sub_dir=nil)
      classname = para
      libtemplate = getrootpath+'bin/template/'+dir+'Template.erb'
      (!sub_dir.nil? && (dir=='spec'||dir=='validate')) ? path=getrootpath+dir+"/#{sub_dir}/" : path=getrootpath+dir+"/"
      # raise "#{path} is not exist!" unless Dir.exist?(path)
      Dir.mkdir(path) unless Dir.exist?(path)
      file = path + classname + extname
      f = File.new(file, "w")
      File.open( libtemplate ) { |fh|
        rbfile = ERB.new( fh.read )
        f.print rbfile.result( binding )
        f.close
      }
    end

    def generate_data (classname,sheethash={})
      requestSheet = sheethash
      requestData = {}
      requestData['Main'] = classname.request
      requestData['Expection'] = classname.expect
      requestData['Flow'] = classname.flow_request
      requestData['FlowExpection'] = classname.flow_expect
      if !requestSheet.empty?
        requestSheet.each do |k,v|
          @data = {}
          request1 = classname.request[1].clone
          (1..v).each do |i|
            @data[i] = request1.clone
          end
          #变化与修改部分
          yield if block_given?
          requestData[k] = @data
        end
      end
      to_yaml_file(requestData, "#{@@sub_dir}/"+classname.name)
      code_gen('validate','_validate.rb',classname.name,@@sub_dir) unless File.exists?(getrootpath+"/validate/#{@@sub_dir}/"+classname.name+'_validate.rb')
      code_gen('spec','_spec.rb',classname.name,@@sub_dir) unless File.exists?(getrootpath+"/spec/#{@@sub_dir}/"+classname.name+'_spec.rb')
      # requestData
    end
  end
end

module ApiTestBase
  
  def self.included(kclass)

    classname = kclass.name[0..-5]
    @@ds = from_yaml_file_with_erb(classname)

    class << kclass
      @@ds.each_key do |key|
        attr_accessor :"#{key}" unless ["Main","Expection","Flow","FlowExpection"].include?(key)
      end
      attr_accessor :request,:expect,:flow_request,:flow_expect
    end

    kclass.request = @@ds["Main"]
    kclass.expect = @@ds["Expection"]
    kclass.flow_request = @@ds["Flow"]
    kclass.flow_expect = @@ds["FlowExpection"]

    @@ds.each do |key,value|
      eval("kclass.#{key}=#{value}") unless ["Main","Expection","Flow","FlowExpection"].include?(key)
    end

    kclass.extend ApiDefine
    kclass.extend DbValidate
  end

  module ApiDefine

    def fill_header(cookies=nil)
      header = $testdata['header']
      unless cookies.eql?nil
        case cookies
          when Array
            header['Cookie'] = cookies.join(';')
          when String
            header['Cookie'] = cookies
          else
            raise 'params error......'
        end
      end
      header
    end

    def set_cookie(cookies=nil)
      @header = fill_header(cookies)
    end

    def set_domain(domain,cookies=nil)
      @domain = $testdata["#{domain}"]
    end

    def send_request(params=nil)
      conf = $envdata
      if ((conf["HTTP_ERROR_CODE"].class!=Array)||(conf["HTTP_RETRY_TIMES"].eql?(nil)))
          raise "Http Expection Config Error......"
      end
      begin
        response = http_request(@domain,@port,@path,params,@header,@method,false).response
        1.upto conf["HTTP_RETRY_TIMES"] do
          if conf["HTTP_ERROR_CODE"].include? response.code.to_i
            puts "HTTP ERROR! Retrying......"
            sleep 10
            response = http_request(@domain,@port,@path,params,@header,@method,false).response
          else
            break
          end
        end

        if response.code.to_i==200
          response.body.force_encoding('utf-8').encode
        else
          raise "http code not eql 200"
        end

      rescue StandardError => e
        puts e.to_s
      rescue HTTPError => e
          puts "Http Exception Occourred:Retrying......"
          Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
          sleep 30
          http_request(@domain,@port,@path,params,@header,@method,false).response

          if response.code.to_i==200
            response.body.force_encoding('utf-8').encode
          else
            raise "http code not eql 200"
          end
      end
    end

    def response_of(count=1)
      self.send_request(self.request[count])
    end

    def flow_response_of(count=1)
      self.send_request(self.flow_request[count])
    end

    def method_missing(name,*args,&block)
      begin
        if name.to_s =~/set_[\w]+/
          var = ((/_.+\z/.match(name.to_s)).to_s)[1..-1]
          self.instance_variable_set "@#{var}",args.first
          eval("attr_accessor :#{var}")
        else
          super
        end
      rescue StandardError => e
        puts e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end
  end

  def respond_to?(method_name, include_private = false)
    method_name.to_s.start_with?('set_') || super
  end

  module DbValidate
    attr_accessor :l
    def initdb
      begin
        @db = db_init($testdata["DBNAME"])  #数据库连接对象
        @l = Flog.new
      rescue StandardError => e
        puts e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def db_do (dbname,sql)
      @db.db_conn(dbname)
      @db.execute(sql)
      @db.disconnect
    end

    def db_validate (dbname,sql,&block)
      @db.db_conn(dbname)
      # @db.query(sql)
      block.call @db.query(sql) if block_given?
      @db.disconnect
    end
  end
end


#定义通用全局变量
$token = $testdata["token"]

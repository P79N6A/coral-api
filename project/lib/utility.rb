#encoding: utf-8
require 'pathname'
require 'securerandom'
require 'yaml'
require 'net/smtp'
require 'csv'
require 'addressable/uri'
require 'hashdiff'
require 'jsonpath'

  #获取项目根路径，返回为 D:\Jruby\FrameWork\API\
  def getrootpath
    path = Pathname.new(__FILE__).realpath.to_s
    path[0..path.rindex("/lib/", -1)]
  end

  #获取文件实际路径目录，返回为 D:/Jruby/FrameWork/API/lib
  def getrealpath
    Pathname.new(File.dirname($0)).realpath.to_s
  end

  #获取UUID
  def gen_uuid
    SecureRandom.uuid
  end

  #按照传入参数，返回给定位数的随机数
  def gen_randcode(n)
    SecureRandom.random_number(10**n).to_s
  end

  #返回 2016-03-21 12:12:12 格式的时间格式
  def get_datetime
    Time.new.strftime("%Y-%m-%d %H:%M:%S")
  end

  #返回给定字符串的md5值
  def getmd5(str)
    Digest::MD5.hexdigest(str)
  end

  #删除 hash中值为'nil'的键
  def delete_nil (ahash)
    ahash.each{|k,v|(v=='nil')?ahash.delete(k):next}
  end

  #对 hash key进行排序，按升序
  def sorted_hash(aHash)
    Hash[aHash.sort_by{|key,val|key}]
  end

  #根据二维hash生成url参数格式
  def convert_hash_to_str dshash
    dshash.each do |key,val|
      str = []
      val.each{|arr| str << arr.join('=')}
      dshash[key] = str.join('&')
    end
  end

  #for dbcheck convert db result key to request key
  def convert_key dbkey
    arr = dbkey.split('_')
    arr.each {|s|s[0]=s[0].upcase}
    newkey = arr.join('')
    newkey[0]=newkey[0].downcase
    newkey
  end

  #cookies为返回获取的set-cookie内容，形式为数组
  def fill_header(cookies=nil)
    header = from_yaml_file('header')
    unless cookies.eql?nil
      case cookies
        when Array
          header['Cookie'] = cookies.join(';')
        when String
          header['Cookie'] = cookies
      end
    end
    header
  end

  def deep_merge(hash1, hash2)
    result = hash1.dup
    hash2.keys.each do |key|
      if hash2[key].is_a?(Hash) && hash1[key].is_a?(Hash)
        result[key] = deep_merge(hash1[key], hash2[key])
      else
        result[key] = hash2[key]
      end
    end
    result
  end

  def deep_clone(hashorarr)
    Marshal.load(Marshal.dump(hashorarr))
  end

  #############################
  #   响应与预期的hash对比去噪
  #############################
  def hash_diff(exphash,response,expnoise,isdebug=false)
    raise "response is not a hash" if (acthash=JSON(response)).class!=Hash
    begin
      noise = []
      diff=HashDiff.diff(JSON(exphash), acthash)
      diff.each_index {|index|return false unless diff[index][0].eql?"~";noise << diff[index][1] if diff[index][0].eql?"~"}
      puts noise.sort if isdebug
      puts "==============================" if isdebug
      puts (eval(expnoise)).sort if isdebug
      noise.sort==(eval(expnoise)).sort
    rescue StandardError => e
      puts e.to_s
    end
  end

  #########################################
  #         序列化对象方法集合
  #########################################
  def to_marsha1_file(obj,fname)
    begin
      File.open(getrootpath+'serialobj/'+fname+'.sha1','w+') do |f|
        Marshal.dump(obj, f)
      end
    rescue StandardError => e
      puts e.to_s
    end
  end

  def to_yaml_file(obj,fname)
    begin
      env = YAML.load_file(getrootpath+'/config/config.yml')['BaseConfig']['TESTENV']
      File.open(getrootpath+'serialobj/'+env.downcase+'/'+fname+'.yml', 'w+') do |f|
        YAML.dump(obj, f)
      end
    rescue StandardError => e
      puts e.to_s
    end
  end

  def from_yaml_file(fname)
    begin
      env = YAML.load_file(getrootpath+'/config/config.yml')['BaseConfig']['TESTENV']
      YAML.load_file(getrootpath+'serialobj/'+env.downcase+'/'+fname+'.yml')
    rescue StandardError => e
      puts e.to_s
    end
  end

  def from_marsha1_file(fname)
    begin
      Marshal.load(getrootpath+'serialobj/'+fname+'.sha1')
    rescue StandardError => e
      puts e.to_s
    end
  end

  def from_yaml_file_with_erb(fname)
    begin
      env = YAML.load_file(getrootpath+'/config/config.yml')['BaseConfig']['TESTENV']
      YAML.load(ERB.new(File.read(getrootpath+'serialobj/'+env.downcase+'/'+fname+'.yml')).result)
    rescue StandardError => e
      puts e.to_s
    end
  end

  ######################################
  #         ftp 发送
  ######################################

  def ftp_post(ip,user,pass_w,file_path)
    ftp = Net::FTP.new(ip,user,pass_w)
    ftp.putbinaryfile(file_path)
  end

  ######################################
  #     文件操作相关
  #     获取csv内容，输出为二维数组
  ######################################
  def csv_get(path)
    temp = []
    data = {}
    begin
      CSV.foreach(path,"r") {|row|temp<<row}
      if temp.size >=2
        header = temp[0]
        1.upto(temp.size-1) do |i|
          alist = header.zip(temp[i])
          data[i] = Hash[*alist.flatten].tap{|h| h.each{|k,v| h[k] = "" if (v.nil?)}}
        end
      elsif temp.size == 0
      else
        data[1]= temp[0].inject({}){|convert,k| convert[k] = nil; convert}
      end
      data
    rescue StandardError => e
      puts "error:#{$!} at:#{$@}"#出错后提示
    end
  end

  #写入csv内容，无返回值
  def csv_insert(data,par)
    if par[0] === Array #为了适应二维数组
      par.each { |i| data<<i}
    else
      data  << par
    end
  end

  #文件保存 暂时只支持csv,txt,yml格式
  def file_save(path,data)
    file_type = path.split(".")[-1]
    case file_type
      when "csv"
        CSV.open(path,"w"){|i|data.each { |j| i<<j }}
      when "yml"
        File.open(path,"w+") do |f|
          YAML.dump(data,f)
        end
      when "txt"
        File.open(path,"w"){|f| f.write(data)}
    end
  end

  ##############################
  #       deal with hash
  ##############################

  #更新字段为变量，为“”的则被批量替换
  def update *args
    ds = args.delete_at(0)
    # params = Hash[*args.join(',').split(/\=|,/)]
    params = args[0].inject({}){|convert,(k,v)| convert[k.to_s] = v; convert}
    ds.each { |k, v|
      params.each do |pk, pv|
        v[pk] = eval pv if v[pk].eql? ""
      end
    }
    delete_nil ds
  end

  def update_force *args
    ds = args.delete_at(0)
    # params = Hash[*args.join(',').split(/\=|,/)]
    params =  args[0].inject({}){|convert,(k,v)| convert[k.to_s] = v; convert}
    ds.each { |k, v|
      params.each do |pk, pv|
        v[pk] = eval pv
      end
    }
    ds
  end
  #更新子节点，为“”的则被批量替换
  #传入参数 datahash, "#{nodename}=@subnode"
  def update_node *args
    ds = args.delete_at(0)
    params = Hash[*args.join(',').split(/\=|,/)]
    ds.each do |k,v|
      params.each do |pk,pv|
        v[pk] = (eval pv)[k] if v[pk].eql? ""
      end
    end
    delete_nil ds
  end
  def update_node_force *args
    ds = args.delete_at(0)
    params = Hash[*args.join(',').split(/\=|,/)]
    ds.each do |k,v|
      params.each do |pk,pv|
        v[pk] = (eval pv)[k]
      end
    end
    ds
  end
  #添加子节点List到request中
  #传入参数 datahash,"#{nodename}=@subnodelist"
  def add_nodelist *args
    ds = args.delete_at(0)
    params = Hash[*args.join(',').split(/\=|,/)]
    ds.each do |k,v|
      params.each do |pk,pv|
        nodelist = eval pv
        v[pk] = nodelist[k] if v[pk].eql? ""
      end
    end
    ds
  end
  def add_nodelist_force *args
    ds = args.delete_at(0)
    params = Hash[*args.join(',').split(/\=|,/)]
    ds.each do |k,v|
      params.each do |pk,pv|
        nodelist = eval pv
        v[pk] = nodelist[k]
      end
    end
    ds
  end
  #更新子节点List内容，为“”的则被批量替换
  #传入参数  arrayhash @subnodelist,params
  def update_nodelist *args
    ds = args.delete_at(0)
    # params = Hash[*args.join(',').split(/\=|,/)]
    params =  args[0].inject({}){|convert,(k,v)| convert[k.to_s] = v; convert}
    ds.each do |key,list|
      list.each do |item|
        params.each do |pk,pv|
          item[pk] = eval pv if item[pk].eql? ""
          delete_nil item
        end
      end
    end
    ds
  end
  def update_nodelist_force *args
    ds = args.delete_at(0)
    # params = Hash[*args.join(',').split(/\=|,/)]
    params =  args[0].inject({}){|convert,(k,v)| convert[k.to_s] = v; convert}
    ds.each do |key,list|
      list.each do |item|
        params.each do |pk,pv|
          item[pk] = eval pv
          delete_nil item
        end
      end
    end
    ds
  end

  #替换json结点值
  def replace_value(json, jsonpath, value)
    if jsonpath.is_a?(Array) && value.is_a?(Array)
      res = json
      (0...jsonpath.length).each do |i|
        res = JsonPath.for(res).gsub(jsonpath[i]) {|v| value[i] }.to_hash.to_json
      end
      return res
    else
      return JsonPath.for(json).gsub(jsonpath) {|v| value }.to_hash.to_json
    end
  end

  class String
    def remove_symbol(str)
      self.gsub(str,'')
    end

    def to_array
      self.split(",")
    end

    def get_jnode(pattern)
      JsonPath.on(self,pattern)
    end

  end

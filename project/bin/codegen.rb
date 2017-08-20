#encoding: utf-8
$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib')
require 'utility'
require 'yaml'
require 'net/http'
require 'open-uri'
require 'erb'
require 'spreadsheet/excel'
require 'nokogiri'

def code_gen(dir,extname,type,para)
  classname = para
#生成lib下对应code
  if type.downcase.eql? 'http' and dir.eql? 'validate'
    libtemplate = getrootpath + '\\bin\\template\\'+ dir +'HttpTemplate.erb'
  else
    libtemplate = getrootpath + '\\bin\\template\\'+ dir +'Template.erb'
  end
  path = getrootpath + dir + '\\'

  file = path + classname + extname
  f = File.new(file, "w")

  File.open( libtemplate ) { |fh|
    rbfile = ERB.new( fh.read )
    f.print rbfile.result( binding )
    f.close
  }
end

puts "Are You Sure To Do The Operation ? Please Enter 'Y[y]' OR 'N[n]'"
answer = gets

if answer.upcase == "Y\n"
  begin
    if !Dir.exist?(getrootpath+"\\temp")
      Dir.mkdir(getrootpath+"\\temp")
    end
    @content = YAML.load_file(getrootpath + "\\config\\config.yml")
    groupId = @content["BaseConfig"]["GroupId"]
    artifactId = @content["BaseConfig"]["ArtifactId"]
    version = @content["BaseConfig"]["Version"]
    type =  @content["BaseConfig"]["InterfaceType"]

    url = "http://mvn1.tools.vipshop.com/nexus/service/local/artifact/maven/redirect?g="+groupId+"&a="+artifactId+"&v="+version+"&r=snapshots"
    uri = URI(url)
    downloadurl = Net::HTTP.get(uri).split("url:")[1].lstrip

    jar=open(downloadurl){|f|f.read}
    open(getrootpath + "\\temp\\"+artifactId+".jar","wb"){|f|f.write(jar)}
    puts '******************* jar was downloaded! *******************'

    mpDir = Dir::new(getrootpath+"\\temp")
    Dir.chdir(mpDir.path)
    system  "jar xf *.jar"
    puts '******************* jar was unziped! *******************'

    Dir["*.xml"].each do |xml|

      serviceFile = File.open(xml) { |f| Nokogiri::XML(f) }
      @methods = serviceFile.xpath("//request") #获取方法列表
      @struct_nodes = serviceFile.xpath("//structs//struct")
      @methods.each do |method|

        @main_name_arr =[]
        @sub_sheet = []       #获取子sheet名
        @sub_sheet_names = []  #二维数组，保存子sheet中的字段名

        #取得方法名处理为类名
        @classname = method['name'].split('_')[0][0].upcase + method['name'].split('_')[0][1..-1]
        @name_nodes = method.xpath("fields//field//name")
        @type_nodes = method.xpath("fields//field//dataType//kind")
        @type_nodes_else = method.xpath("fields//field//dataType")      #for else 取元素

        #第一层只有一个model的情况
        if @name_nodes.length == 1 && @type_nodes[0].content == "STRUCT"
          puts  'enter if ' + @classname
          ref = method.xpath("fields//field//dataType//ref")
          serviename = ref[0].content.split('.')
          @modelname =  serviename[serviename.size-1]

          @struct_nodes.each_with_index do |struct,index|

            if struct['name'].downcase == @modelname.downcase
              @name_nodes = @struct_nodes[index].xpath("fields//field//name")
              @type_nodes = @struct_nodes[index].xpath("fields//field//dataType")
              # @sub_sheet = []       #获取子sheet名
              @name_nodes.each_with_index do |name,index|
                @main_name_arr << name.content     #先存主sheet的字段名

                if @type_nodes[index].content.match(/LISTSTRUCT[\w]/) || @type_nodes[index].content.match(/STRUCT[\w]/)
                  @sub_sheet << name.content[0].downcase+name.content[1..-1]
                end
              end
            end
          end
          #其他情况
        else
          puts  'enter else:' + @classname
          @name_nodes.each_with_index do |name,index|
            @main_name_arr << name.content
            if @type_nodes_else[index].content.match(/LISTSTRUCT[\w]/) || @type_nodes[index].content.match(/STRUCT[\w]/)
              @sub_sheet << name.content[0].downcase+name.content[1..-1]
            end
          end
        end
        #处理sub sheet
        if !@sub_sheet.nil?
          @sub_sheet.each do |subsheet|
            @struct_nodes.each_with_index do |struct,index|
              if struct['name'].downcase == subsheet.downcase
                @sub_nodes = struct.xpath("fields//field//name")     #子sheet里的字段
                @sub_sheet_names << @sub_nodes
              end
            end
          end
        end

        book = Spreadsheet::Workbook.new
        sheet1 = book.create_worksheet
        sheet1.name = @classname
        @main_name_arr.each{|name|row = sheet1.row(0);row.push name}
        sheet1.row(1).push 'test'

        if !@sub_sheet.nil?
          arr = @sub_sheet.length.times.map{book.create_worksheet}
          arr.each_with_index do |sheet,index|
            sheet.name = @sub_sheet[index]
            @sub_sheet_names[index].each{|name|row = sheet.row(0);row.push name.content} if !@sub_sheet_names[index].nil?
            sheet.row(1).push 'test'
          end
        end

        expectsheet = book.create_worksheet
        expectsheet.name = 'Expection'
        expectsheet.row(0).push 'memo'
        expectsheet.row(1).push 'test'

        flowsheet = book.create_worksheet
        flowsheet.name = 'Flow'
        @main_name_arr.each{|name|row = flowsheet.row(0);row.push name}
        flowsheet.row(1).push 'test'

        if !@sub_sheet.nil?
          arr = @sub_sheet.length.times.map{book.create_worksheet}
          arr.each_with_index do |sheet,index|
            sheet.name = "Flow_"+@sub_sheet[index]
            @sub_sheet_names[index].each{|name|row = sheet.row(0);row.push name.content} if !@sub_sheet_names[index].nil?
            sheet.row(1).push 'test'
          end
        end

        flowexpctionsheet = book.create_worksheet
        flowexpctionsheet.name = 'FlowExpection'
        flowexpctionsheet.row(0).push 'memo'
        flowexpctionsheet.row(1).push 'test'

        book.write getrootpath + '\\data\\test\\'+ @classname + '.xls'

        code_gen('ext','.rb',type,@classname)
        if type.downcase.eql? 'osp'
          code_gen('validate','Assert.rb',type,@classname)
        else
          code_gen('validate','Assert.rb',type,@classname)
        end
        code_gen('spec','_spec.rb',type,@classname)
      end
    end
    puts '******************* All Done! *******************'
  rescue StandardError => e
    puts e.to_s
  end

else
  puts '******************* Nothing To Do! *******************'
end

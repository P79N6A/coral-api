require 'erb'

def code_gen(source,des,para)
  params = para.split("/")
  classname = params[-1]
  params.length > 1 ? sub_dir = params[0..-2].join('/') : sub_dir = ''
  libtemplate = source+'/project/bin/template/extTemplate.erb'
  path = des + '/ext/' + sub_dir + '/' unless sub_dir.nil?
  file = path + classname + '.rb'
  f = File.new(file, "w")
  File.open( libtemplate ) { |fh|
    rbfile = ERB.new( fh.read )
    f.print rbfile.result( binding )
    f.close
  }
end
require 'erb'

   def code_gen(source,des,para)
      classname = para
      libtemplate = source+'/project/bin/template/extTemplate.erb'
      path = des + '/ext/'
      file = path + classname + '.rb'
      f = File.new(file, "w")
      File.open( libtemplate ) { |fh|
        rbfile = ERB.new( fh.read )
        f.print rbfile.result( binding )
        f.close
      }
    end

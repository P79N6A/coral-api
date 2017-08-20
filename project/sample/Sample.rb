#encoding: utf-8
$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib')
require 'apicasebase'

class Sample < ApiCaseBase
  update self.request,:requestId=>'gen_randcode(10)',:createTime=>'get_datetime'
  add_node self.request,"orderInfo",:orderId=>'gen_randcode(10)'
  add_list self.request,"payInfo",:transactionId=>'gen_randcode(15)',:payTime=>'get_datetime'

  sheetData={'ForApiOther'=>5}

  generate_data self,true,sheetData do
  update_force @data,:requestId=>'gen_randcode(10)',:createTime=>'get_datetime'
  add_node_force @data,"orderInfo",:orderId=>'gen_randcode(10)'
  add_list_force @data,"payInfo",:transactionId=>'gen_randcode(15)',:payTime=>'get_datetime'
  end
end
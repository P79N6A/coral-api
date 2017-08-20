$LOAD_PATH << File.join(File.dirname(__FILE__), '../ext')
$LOAD_PATH << File.join(File.dirname(__FILE__), '../lib')

require 'utility'

Dir.glob(getrootpath + '/ext/*.rb').each do |f|
  require f
end
require 'rubygems'
require 'gosu'
require 'yaml'

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each do |file| 
  require 'lib/' + File.basename(file, File.extname(file))
end

window = MyGame.new
window.show
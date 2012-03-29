require 'rubygems'
require 'gosu'
require 'yaml'

Dir[File.dirname(__FILE__) + '/lib/*.rb'].each do |file| 
  require 'lib/' + File.basename(file, File.extname(file))
end
level_config_file = 'level_config.yml'
level_config_file = ARGV[0] if ARGV && ARGV.size > 0
window = MyGame.new(level_config_file)
window.show
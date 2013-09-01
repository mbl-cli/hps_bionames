require 'sinatra'
require 'bundler/setup'
require 'haml'
require 'zen-grids'
require 'active_record'
require 'tag_along'
require 'logger'


class HpsBio < Sinatra::Base
  environment = ENV['RACK_ENV'] || ENV['RAILS_ENV']
  environment = (environment &&
    ['production', 'test', 'development'].include?(environment.downcase)) ?
    environment.downcase.to_sym : :development
  set :environment, environment

  conf = open(File.join(File.dirname(__FILE__), 'config', 'config.yml')).read
  conf_data = YAML.load(conf)
  Conf = OpenStruct.new(
    session_secret: conf_data['session_secret'],
    db: conf_data[settings.environment.to_s],
  )

  ##### Connect Databases #########
  ActiveRecord::Base.logger = Logger.new(STDOUT, :debug)
  ActiveRecord::Base.establish_connection(Conf.db)

  Thread.new do
    loop do
      sleep(60*30);
      ActiveRecord::Base.verify_active_connections!
    end
  end.priority = -10
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'models'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'hps_bio'

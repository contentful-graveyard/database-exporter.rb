require_relative 'migrator'
require 'yaml'

module Command
  class CLI < Escort::ActionCommand::Base

    def execute
      setting_file = YAML.load_file(global_options[:file])
      Migrator.new(setting_file).run(command_name)
    end

  end
end
#
# setting_file = YAML.load_file('example_data/example_settings.yml')
# Migrator.new(setting_file).run('--prepare-json')
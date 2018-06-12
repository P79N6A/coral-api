#encoding: utf-8
require 'yaml'
require 'fileoperation'
require 'utility'
include FileOperation

  class Configration
    attr_accessor :testdata,:envdata
    def initialize(confpath=File.join(getrootpath,"config/config.yml"))
      begin
        if !File.exist?(confpath)
          raise 'config file not found!'
        else
          @content = YAML.load_file(confpath)
          $envdata = @envdata = @content["BaseConfig"]
          $testdata = @testdata = @content[@content["BaseConfig"]["TESTENV"]]
        end
      rescue StandardError=>e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end

    def modify_env(config)
      begin
        @content["BaseConfig"] = config
        File.open(getrootpath+"config/config.yml",'w+') do |f|
          YAML.dump(@content,f)
        end
      rescue StandardError => e
        puts self.class.name+"::"+__method__.to_s()+": "+e.to_s
        Clog.to_log(self.class.name+"::"+__method__.to_s()+": "+e.to_s)
      end
    end
  end

  $config = Configration.new
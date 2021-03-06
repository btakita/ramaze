begin; require 'rubygems'; rescue LoadError; end

require(File.expand_path("#{__FILE__}/../")) unless defined?(Ramaze)
require 'innate/spec'

def spec_requires(*libs)
  spec_precondition 'require' do
    libs.each{|lib| require(lib) }
  end
end
alias spec_require spec_requires

def spec_precondition(name)
  yield
rescue LoadError => ex
  puts "Spec require: %p failed: %p" % [name, ex.message]
  exit 0
rescue Exception => ex
  puts "Spec precondition: %p failed: %p" % [name, ex.message]
  exit 0
end

module Ramaze
  Mock::OPTIONS[:app] = Ramaze

  middleware!(:spec){|m| m.run(AppMap) }
end

shared :rack_test do
  Ramaze.setup_dependencies
  extend Rack::Test::Methods

  def app; Ramaze.middleware; end
end

# Backwards compatibility
shared(:mock){
  Ramaze.deprecated('behaves_like(:mock)', 'behaves_like(:rack_test)')
  behaves_like :rack_test
}

shared :webrat do
  behaves_like :rack_test

  require 'webrat'

  Webrat.configure{|config| config.mode = :rack_test }

  extend Webrat::Methods
  extend Webrat::Matchers
end

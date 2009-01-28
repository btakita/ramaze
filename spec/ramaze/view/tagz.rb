#          Copyright (c) 2009 Michael Fellinger m.fellinger@gmail.com
# All files in this distribution are subject to the terms of the Ruby license.

require 'spec/helper'

Innate.options.app.root = File.dirname(__FILE__)
Innate.options.app.view = 'tagz'

class SpecTagz < Ramaze::Controller
  map '/'
  provide :html => :tagz
  helper :tagz

  def index
    tagz{ h1_{ "Tagz Index" } }
  end

  def links
    tagz do
      ul_ do
        li_{ a_(:href => r(:index)){ "Index page" } }
        li_{ a_(:href => r(:internal)){ "Internal template" } }
        li_{ a_(:href => r(:external)){ "External template" } }
      end
    end
  end

  def sum(num1, num2)
    @num1, @num2 = num1.to_i, num2.to_i
  end
end

describe Ramaze::View::Tagz do
  behaves_like :mock

  should 'use tagz methods' do
    get('/').body.should == '<h1>Tagz Index</h1>'
  end

  should 'use other helper methods' do
    get('/links').body.should == '<ul><li><a href="/index">Index page</a></li><li><a href="/internal">Internal template</a></li><li><a href="/external">External template</a></li></ul>'
  end

  should 'render external template' do
    get('/external').body.should == "<html><head><title>Tagz Test</title></head><body><h1>Tagz Template</h1></body></html>"
  end

  should 'render external template with instance variables' do
    get('/sum/1/2').body.should == '<div>3</div>'
  end
end

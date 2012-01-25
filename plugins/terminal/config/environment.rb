# Load the rails application
require File.expand_path('../application', __FILE__)
#needed for generating mo files...
FastGettext.add_text_domain 'webyast-terminal', :path => 'locale'
FastGettext.default_text_domain = 'webyast-terminal'
# Initialize the rails application
Terminal::Application.initialize!


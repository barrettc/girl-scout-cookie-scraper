require 'mechanize'
require 'yaml'
require './parser'

config = YAML.load_file 'cookie-war.yaml'

if ENV['TEST']
  available = File.open('available_page_sample.html') { |f| Nokogiri::HTML(f) }
  parser = Parser.new
  parser.parse available
else
  a = Mechanize.new
  a.get('http://ohsucookies.com/auth/login') do |page|

    my_page = page.form_with(:action => '/auth/login') do |form|
      username_field = form.field_with(:name => 'email')
      username_field.value = config['auth']['email']
      password_field = form.field_with(:name => 'password')
      password_field.value = config['auth']['password']
    end.click_button

    available = my_page.link_with(href: /available/).click()
    parser = Parser.new
    parser.parse available
  end
end

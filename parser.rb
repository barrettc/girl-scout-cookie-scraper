require 'nokogiri'
require 'sqlite3'
require 'twilio-ruby'
require 'logger'
require 'yaml'

class Parser
  HIT_LIST = [
    /Chuy/,
    /Cypress Grill/,
    /Flores/,
    /Great Clips/,
    /Jack Allen/,
    /Kerby Lane/,
    /Randall/,
    /Serranos/,
    /Torchy/,
    /Via 313/,
    /Walgreens/,
    /Grocery/,
    /Waterloo/
  ]

  def initialize
    @log = Logger.new 'cookie-war.log'
    config = YAML.load_file 'cookie-war.yaml'

    # Twilio
    account_sid = config['twilio']['account_sid']
    auth_token = config['twilio']['auth_token']
    @client = Twilio::REST::Client.new account_sid, auth_token
    @to = config['twilio']['to']
    @from = config['twilio']['from']

    # db
    @db = SQLite3::Database.new 'cookie-war.db'

    @db.execute <<-SQL
      CREATE TABLE IF NOT EXISTS cookies (
        datetime text(30),
        location varchar(100),
        primary key(datetime, location)
      );
    SQL
  end

  def parse doc
    @log.info 'BEGIN getting available cookie list'
    re = Regexp.union(HIT_LIST)
    doc.search('table').first.css('tr').each do |row|
      date = row.css('td')[0].text.gsub!(/[\n\r\t]/, '')
      date = date.split(' ')[0]
      times = row.css('td')[1].text.gsub!(/[\n\r\t\s]/, '')
      time = times.split('-')[0]
      location = row.css('td')[2].text.gsub!(/[\n\r\t]/, '')
      @log.debug(date)
      @log.debug(time)
      datetime = DateTime.strptime(date + ' ' + time, '%Y-%m-%d %H:%M%P')
      @log.info 'found ' + location + ' at ' + datetime.to_s
      if location.match(re)
        # it's a hit so see if we have a db entry
        @log.info location + ' is a HIT'
        begin
          @db.execute('insert into cookies (datetime, location) values (?, ?)', [datetime.to_s, location])
          body = 'Cookie alert: ' + location + ' ' + datetime.to_s
          @log.info 'Sending alert ' + body
          @client.api.account.messages.create(from: @from, to: @to, body: body) unless ENV['TEST']
        rescue SQLite3::ConstraintException => e
          @log.debug 'constraint violation - already reported on ' + location + ' ' + datetime.to_s
        end
      else
        @log.info 'ignoring ' + location
      end
    end

  end
end

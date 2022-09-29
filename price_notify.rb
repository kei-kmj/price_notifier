# frozen_string_literal: true

require 'selenium-webdriver'
require 'dotenv'
Dotenv.load

LINE_NOTIFY_URL = URI.parse(API_URL)
VISIT_URL = 'https://www.amazon.co.jp/dp/4873119049'

def main
  page = fetch_url
  format_information(page)
  notify(page)
end

def fetch_url
  session = Selenium::WebDriver::Chrome::Options.new
  session.add_argument('--headless')
  page = Selenium::WebDriver.for :chrome, options: session
  page.navigate.to VISIT_URL
  page
end

def format_information(page)
  title = "#{page.title}\n"
  detail = page.find_elements(:class, 'rpi-attribute-value').map { |i| "#{i.text}\n" }
  price = "#{page.find_element(:class, 'a-text-price').text}\n"
  link = VISIT_URL
  title + detail[2] + price + link if price.delete('^0-9').to_i < 4500
end

def notify(page)
  Net::HTTP.start(LINE_NOTIFY_URL.hostname, LINE_NOTIFY_URL.port, use_ssl: true) do |https|
    post_message = Net::HTTP::Post.new(LINE_NOTIFY_URL)
    post_message['Authorization'] = "Bearer #{ENV['LINE_TOKEN']}"
    post_message.set_form_data(message: format_information(page))

    https.request(post_message) if format_information(page)
  end
end

main

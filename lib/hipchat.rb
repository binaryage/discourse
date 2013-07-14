require 'net/http'
require "uri"

module HipChat

  def self.send_message_to_hipchat!(message)
    params = {
      "auth_token" => ENV["HIPCHAT_AUTH_TOKEN"],
      "room_id" => "100042", # Test Room = 184938, BinaryAge Room = 100042
      "from" => "Discourse",
      "color" => "green",
      "message_format" => "html",
      "message" => message
    }

    query_string = params.to_a.map { |x| "#{x[0]}="+URI.escape(x[1], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) }.join("&")

    url = "https://api.hipchat.com/v1/rooms/message?#{query_string}"
    Rails.logger.info "HipChat request: " + url
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path+"?"+uri.query)
    response = http.request(request)
    Rails.logger.info "HipChat response: " + response.inspect
  end

  def self.report_event!(user, action, topic, post=nil)
    begin
      Rails.logger.info "Report event to HipChat: #{user} #{action} #{topic} #{post}"
      category_markup = ""
      category_markup = "[#{topic.category.name}] " if topic.category
      user_markup = "<a href=\"#{Discourse.base_url}/users/#{user.username.downcase}\">#{user.username}</a>"
      topic_markup = "topic: <a href=\"#{topic.url}\">#{topic.title}</a>"

      if action=="created-topic" then
	send_message_to_hipchat! "#{category_markup}#{user_markup} started #{topic_markup}"
      elsif action=="recovered-topic" then
	send_message_to_hipchat! "#{category_markup}#{user_markup} recovered #{topic_markup}"
      elsif action=="deleted-topic" then
	send_message_to_hipchat! "#{category_markup}#{user_markup} deleted #{topic_markup}"
      elsif action=="created-post" then
	send_message_to_hipchat! "#{category_markup}#{user_markup} posted to #{topic_markup}"
      elsif action=="deleted-post" then
	send_message_to_hipchat! "#{category_markup}#{user_markup} deleted a post in #{topic_markup}"
      elsif action=="recovered-post" then
	send_message_to_hipchat! "#{category_markup}#{user_markup} recovered a post in #{topic_markup}"
      end
    rescue e
      Rails.logger.info e.backtrace.join("\n")
    end
  end

end

# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?

use Rack::Session::Cookie,
    key: 'sinatra.session',
    path: '/',
    httponly: true,
    same_site: :strict,
    secure: false,
    secret: SecureRandom.hex(64)

class NilClass
  def any?
    false
  end
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def rouge(source)
    return nil if source.nil?

    formatter = Rouge::Formatters::HTMLInline.new('github')
    lexer = Rouge::Lexers::XML.new
    formatter.format(lexer.lex(HtmlBeautifier.beautify(source, indent: ' ' * 8)))
  end
end

def self.get_or_post(url, &block)
  get(url, &block)
  post(url, &block)
end

IVR_DEFAULT_PATH = ENV['IVR_DEFAULT_PATH'] || '/voice'
IVR_BASE_URL = ENV['IVR_BASE_URL'] || 'http://localhost:3000'

get_or_post '/' do
  @user_interaction_required_for_speech = request.get?
  @base_url = session[:base_url] || IVR_BASE_URL
  @url = params[:url] || IVR_DEFAULT_PATH
  @url = @base_url + @url.to_s if @url[0] == '/' || @url.nil?
  @silent = !ENV['SILENT'].nil?

  if params[:new]
    session.clear
    url_parts = @url.split('/')
    @base_url = url_parts[0] + '//' + url_parts[2]
    session[:base_url] = @base_url
    session[:new_url] = @url
  end

  @new_url = session[:new_url] || @url

  @digits = params[:digits]
  puts "url = #{@url}"
  payload = { api_key: ENV['API_KEY'] }
  payload['Digits'] = @digits.gsub('#', '') if @digits
  puts "payload = #{payload}"
  headers = { cookie: session[:cookie] }
  client = HTTPClient.new
  client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
  @resp = client.post(@url, payload, headers)
  puts "resp = #{@resp}"
  cookie = @resp.headers['Set-Cookie']
  session[:cookie] = cookie.split('; ')[0] if cookie
  @xml = Nokogiri::XML(@resp&.body)
  @play = @xml.xpath('//Response/Play')
  @say = @xml.xpath('//*[self::Say or self::Pause]')
  @gather = @xml.xpath('//Response/Gather')
  @action = @xml.xpath('//Response/Gather/@action')
  @action = @url if @gather.any? && @action.none?
  @redirect = @xml.xpath('//Response/Redirect/text()')
  @hangup = @xml.xpath('count(//Response/Hangup)').positive?
  puts "session[:base_url] = |#{session[:base_url]}|"
  erb :app
end

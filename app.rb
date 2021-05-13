# frozen_string_literal: true

Bundler.require

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
    #   def h(text)
    #     Rack::Utils.escape_html(text)
    #   end

    def rouge(source)
        $stdout.puts source

        return nil if source.nil?

        formatter = Rouge::Formatters::HTMLInline.new('github')
        lexer = Rouge::Lexers::XML.new
        beautified = HtmlBeautifier.beautify(source, indent: ' ' * 8)
        formatter.format(lexer.lex(beautified))
    end
end

def self.get_or_post(url, &block)
    get(url, &block)
    post(url, &block)
end

IVR_DEFAULT_PATH = ENV['IVR_DEFAULT_PATH'] || '/voice'
IVR_CALL_STATUS_PATH = ENV['IVR_CALL_STATUS_PATH'] || '/voice/status'
IVR_BASE_URL = ENV['IVR_BASE_URL'] || 'http://localhost:3000'

get_or_post '/' do
    @user_interaction_required_for_speech = request.get?
    @base_url = session[:base_url] || IVR_BASE_URL
    @url = params[:url] || IVR_DEFAULT_PATH
    @url = @base_url + @url.to_s if @url[0] == '/' || @url.nil?
    @silent = !ENV['SILENT'].nil?
    client = HTTPClient.new
    client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    payload = { api_key: ENV['API_KEY'] }
    headers = { cookie: session[:cookie] }

    if params[:new]
        unless session.empty?
            status_payload = payload.dup.update(CallStatus: 'completed')
            client.post(@base_url + IVR_CALL_STATUS_PATH, status_payload, headers)
            session.clear
        end
        headers = {}
        url_parts = @url.split('/')
        @base_url = "#{url_parts[0]}//#{url_parts[2]}"
        session[:base_url] = @base_url
        session[:new_url] = @url
    end

    @new_url = session[:new_url] || @url

    @digits = params[:digits]
    $stdout.puts "url = #{@url}"
    payload['Digits'] = @digits.gsub('#', '') if @digits
    $stdout.puts "payload = #{payload}"
    @resp = client.post(@url, payload, headers)
    $stdout.puts "resp = #{@resp}"
    $stdout.puts @resp.body
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
    $stdout.puts "session[:base_url] = |#{session[:base_url]}|"
    erb :app
end

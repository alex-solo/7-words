require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require 'open-uri'
require 'addressable/uri'
require 'nokogiri'
require 'yandex-translator'

LANGUAGES = {
        'dutch' => ["nl", "https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/Dutch_wordlist"],
        'french' => ["fr", "https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/French_wordlist_opensubtitles_5000"],
        'german' => ["de", "https://en.wiktionary.org/wiki/User:Matthias_Buchmeier/German_frequency_list-1-5000"],
        'portuguese' => ["pt", "https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/BrazilianPortuguese_wordlist"],
        'russian' => ["ru", "https://en.wiktionary.org/wiki/Appendix:Frequency_dictionary_of_the_modern_Russian_language_(the_Russian_National_Corpus)"],
        'spanish' => ["es", "https://en.wiktionary.org/wiki/User:Matthias_Buchmeier/Spanish_frequency_list-1-5000"]
        }

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

def data_path
  File.expand_path("../data", __FILE__)
end

def nokogiri_load_content(url)
  document = open(url)
  parsed_page = document.read
  Nokogiri::HTML(parsed_page)
end

def get_content(language)
  url = LANGUAGES[language][1]
  nokogiri_load_content(url)
end

def name_file(num_words, language)
  "#{num_words}_words_#{language}.txt"
end

def create_file(file_name, words_array)
  File.open("#{data_path}/#{file_name}", "a") do |file|
    words_array.each do |word|
      file.puts(word_line(word))
    end
  end
end

def extract_words(language)
  num_words_total = 3000
  content = get_content(language)
  nokogiri_cmd = case
                 when ['german','spanish'].include?(language)
                   ".mw-parser-output p a"
                 when ['portuguese', 'dutch', 'russian'].include?(language)
                   ".mw-parser-output li a"
                 when 'french'
                   ".mw-parser-output .wikitable a"
                 end

  element_arr = content.css(nokogiri_cmd).first(num_words_total).drop(50)
  words_array = element_arr.map do |elem|
    next if elem.attributes['title'].nil?
    elem.attributes['title'].value             
  end
  clean_up(words_array).sample(7)
end

def clean_up(words_array)
  words_array.join("**").gsub(" (page does not exist)", "").split("**")
end

def translate(string, language)
  key = "trnsl.1.1.20180410T212719Z.70fb53e8c7c418d3.a15b49c9283a46f09db9224acd4b738e0832a847"
  abbr = LANGUAGES[language][0]
  translator = Yandex::Translator.new(key)
  new_string = translator.translate(string, from: "#{abbr}", to: 'en')
  new_string.split("\n")
end

def exception_handle(content)
  begin
    content.css("li > span.play").first.attributes["id"].value
  rescue
    ""
  else
    content.css("li > span.play").first.attributes["id"].value
  end
end

def extract_sound_link(url, language)
  content = nokogiri_load_content(url)
  result_string = exception_handle(content)
  play_id = /\d+$/.match(result_string)

  if play_id.nil?
    ""
  else
    "https://forvo.com/_ext/ext-prons.js?id=#{play_id}"
  end
end

def get_forvo_links(words_arr, language)
  abbr = LANGUAGES[language][0]
  words_arr.map do |word|
    not_normalized_url = "https://forvo.com/search/#{word}/#{abbr}"
    uri = Addressable::URI.parse(not_normalized_url)
    url = uri.scheme + "://" + uri.host + uri.normalized_path
    extract_sound_link(url, language)
  end
end

def build_words_hash(words_arr, language)
  string = words_arr.join("\n")
  translated_words_arr = translate(string, language)
  sound_links_arr = get_forvo_links(words_arr, language)
 
  hash = {}
  words_arr.each_with_index do |word, idx|
    hash[word] = { :translated => translated_words_arr[idx],
                   :sound => sound_links_arr[idx] }
  end
  hash
end

get "/" do
  erb :home
end

post "/word_list" do
  session[:language] = params[:language]

  redirect "/result"
end

get "/result" do
  @language   = session[:language]
  if @language.nil?
    session[:error] = "Please select a language"
    redirect "/"
  else
    words_arr   = extract_words(@language)
    @words_hash = build_words_hash(words_arr, @language) 
    erb :result
  end
end

def load_file_content(file_path)
  content = File.read(file_path)
  extension = File.extname(file_path)
  if extension == ".txt" || extension == ".rb"
    headers["Content-Type"] = "text/plain"
    content
  elsif extension == ".md"
    erb render_markdown(content)
  end
end

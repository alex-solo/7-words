require 'open-uri'
require 'nokogiri'

languages = {
            'dutch' => "https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/Dutch_wordlist",
            'french' => "https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/French_wordlist_opensubtitles_5000",
            'german' => "https://en.wiktionary.org/wiki/User:Matthias_Buchmeier/German_frequency_list-1-5000",
            'portuguese' => "https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/BrazilianPortuguese_wordlist",
            'russian' => "https://en.wiktionary.org/wiki/Appendix:Frequency_dictionary_of_the_modern_Russian_language_(the_Russian_National_Corpus)",
            'spanish' => "https://en.wiktionary.org/wiki/User:Matthias_Buchmeier/Spanish_frequency_list-1-5000"
            }
  
# french uses table to sort words
# german, spanish use different logic (puts parsed_content.css(".mw-parser-output p a").first(5000)
# portuguese, dutch and russian use logic below (puts parsed_content.css(".mw-parser-output li a").first(5000))

document = open("https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/BrazilianPortuguese_wordlist")
content = document.read

html = Nokogiri::HTML(content)

output = File.new('common_words.txt', 'w+')

words_array = []
element_arr = html.css(".mw-parser-output li a").first(5000)
element_arr.each do |row|
  words_array << row.attributes['title'].value
end

words_array.each do |word|
  output.write(word + "\n")
end


=begin

words_array = []

.css('li').css('a').each do |row|
  words_array << row.attributes['title'].value
end

p words_array.first(300)
=end



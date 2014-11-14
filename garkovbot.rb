require 'rubygems'

require 'ruby-readability'
require 'open-uri'
require 'google-search'
require 'engtagger'
require 'marky_markov'
require 'sanitize'
require 'irc'

MYNAME = "garkovbot"
NUM_RESULTS = 5
#CHANNEL = "#r/KansasCity"
CHANNEL = "#garkov-bot"
SERVER = "chat.freenode.net"
NICK = "garkovbot"

def get_response (message)
#  if message.start_with?(MYNAME + ':')
    message.slice!(MYNAME + ':')
    nouns = []
    verbs = []
    search_words = []
    search_text = message
    response = ""

    tagger = EngTagger.new
    tagged = tagger.add_tags(message)
    nouns = tagger.get_nouns(tagged)
    verbs = tagger.get_infinitive_verbs(tagged).merge(tagger.get_past_tense_verbs(tagged)).merge(tagger.get_passive_verbs(tagged)).merge(tagger.get_present_verbs(tagged))
    search_words = nouns.keys + verbs.keys

    if search_words.length > 0
      search_text = search_words.join(" ")
    end

    trainer_text = message
    Google::Search::Web.new(:query => search_text).each_with_index do |result, i|
      if i > (NUM_RESULTS - 1)
        break
      end

      begin
        html_text = Readability::Document.new(open(result.uri, :read_timeout => 5).read).content
      rescue Exception => e
      end
      clean_text = Sanitize.fragment(html_text)

      trainer_text += clean_text
    end
    markov = MarkyMarkov::Dictionary.new('dictionary', 2)
    markov.parse_string trainer_text
    response = markov.generate_n_sentences 1
    
    return response
#  end
end

#while 1
#  puts get_response(MYNAME + ':' + msg)
#end

host SERVER
port 6666
nick NICK
channel CHANNEL

mention_match /(?<msg>.*)/ do
  reply get_response(msg)
end

start!

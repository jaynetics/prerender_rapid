module Rack
  class Prerender
    class Constraint
      attr_reader :blacklist, :whitelist, :crawler_user_agents, :extensions_to_ignore

      def initialize(opts = {})
        @blacklist            = cast_to_regexp(opts[:blacklist], escape: false)
        @whitelist            = cast_to_regexp(opts[:whitelist], escape: false)
        @crawler_user_agents  = cast_to_regexp(opts[:crawler_user_agents] || CRAWLER_USER_AGENTS)
        @extensions_to_ignore = cast_to_regexp(opts[:extensions_to_ignore] || EXTENSIONS_TO_IGNORE)
      end

      def matches?(env)
        return false if env['REQUEST_METHOD'] != 'GET' ||
                        env['HTTP_X_PRERENDER'] ||
                        (user_agent = env['HTTP_USER_AGENT']).nil?

        query = env['QUERY_STRING'].to_s
        return false unless crawler_user_agents.match?(user_agent.downcase) ||
                            env['HTTP_X_BUFFERBOT'] ||
                            query.include?('_escaped_fragment_')

        path = env['SCRIPT_NAME'].to_s + env['PATH_INFO'].to_s
        fullpath = query.empty? ? path : "#{path}?#{query}"
        return false if extensions_to_ignore.match?(fullpath)
        return false if whitelist && !whitelist.match?(fullpath)
        return false if blacklist && (blacklist.match?(fullpath) ||
                                      blacklist.match?(env['HTTP_REFERER'].to_s.downcase))

        true
      end

      private

      def cast_to_regexp(list_arg, escape: true)
        case list_arg
        when Regexp, nil
          list_arg
        when Array
          escape ? Regexp.union(list_arg) : Regexp.new(list_arg.join('|'))
        else
          Regexp.new(escape ? Regexp.escape(list_arg) : list_arg)
        end
      end

      CRAWLER_USER_AGENTS = [
        'applebot',
        'baiduspider',
        'bingbot',
        'bitlybot',
        'bufferbot',
        'chrome-lighthouse',
        'developers.google.com/+/web/snippet',
        'discordbot',
        'embedly',
        'facebookexternalhit',
        'flipboard',
        'google page speed',
        'googlebot',
        'linkedinbot',
        'nuzzel',
        'outbrain',
        'pinterest/0.',
        'quora link preview',
        'qwantify',
        'redditbot',
        'rogerbot',
        'showyoubot',
        'skypeuripreview',
        'slackbot',
        'tumblr',
        'twitterbot',
        'vkshare',
        'w3c_validator',
        'whatsapp',
        'www.google.com/webmasters/tools/richsnippets',
        'yahoo',
      ]

      EXTENSIONS_TO_IGNORE = %w[
        .ai
        .avi
        .css
        .dat
        .dmg
        .doc
        .doc
        .exe
        .flv
        .gif
        .ico
        .iso
        .jpeg
        .jpg
        .js
        .less
        .m4a
        .m4v
        .mov
        .mp3
        .mp4
        .mpeg
        .mpg
        .pdf
        .png
        .ppt
        .psd
        .rar
        .rss
        .swf
        .tif
        .torrent
        .txt
        .wav
        .wmv
        .xls
        .xml
        .zip
      ]
    end
  end
end

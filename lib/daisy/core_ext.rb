module Daisy

##
# Core class extensions.

module CoreExt

  refine String do

    # :stopdoc:
    HTML_ESCAPE_MAP = { '&' => '&amp;', '"' => '&quot;', '<' => '&lt;', '>' => '&gt;' }
    # :startdoc:

    # Returns the string with the following characters escaped to HTML entities:
    #   < => &lt;
    #   > => &gt;
    #   & => &amp;
    def text_escape
      self.gsub(/[&><]/, HTML_ESCAPE_MAP)
    end

    # Returns the string with the following characters escaped to HTML entities:
    #   < => &lt;
    #   > => &gt;
    #   & => &amp;
    #   " => &quot;
    def attr_escape
      self.gsub(/[&><"]/, HTML_ESCAPE_MAP)
    end

  end

  refine Float do

    # Returns +self+, representing a number of seconds, as:
    # - "hh:mm:ss.sss" (if +decimals+ is true)
    # - "hh:mm:ss" (if +decimals+ is false)
    def to_hh(decimals: true)
      if decimals
        s = self
        h =  (s / 3600.0).floor
        s -= 3600 * h
        m =  (s / 60.0).floor
        s -= 60 * m

        "%02d:%02d:%06.3f" % [h, m, s]
      else
        s = self.round
        h =  s / 3600
        s -= 3600 * h
        m =  s / 60
        s -= 60 * m

        "%02d:%02d:%02d" % [h, m, s]
      end
    end

  end

end
end
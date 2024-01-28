# initially from https://github.com/Memotech-Bill/make_daisy

require 'fileutils'
require 'securerandom'
require 'yaml'

module Daisy

  # execute code with warnings temporarily off
  def self.without_warning
      old, $-w = $-w, nil
      begin
        result = yield
      ensure
        $-w = old
      end
      result
    end
  end

  without_warning { require 'mp3info' }

  ##
  # Generic error raised by us.

  class Error < RuntimeError
  end

end

require_relative 'daisy/core_ext'
require_relative 'daisy/book'
require_relative 'daisy/chapter'
require_relative 'daisy/cli'
require_relative 'daisy/version'

#
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


module PoiseService
  module Utils
    # Helpers for working with INI files.
    #
    # @since 1.0.0
    module Ini
      extend self

      # Format a Hash as an INI file.
      #
      # @ini_data [Hash<String, Hash<String, String>>] Hash to format.
      # @return [String]
      def to_ini(ini_data)
        ''.tap do |buf|
          ini_data.each do |section_name, section|
            buf << "[#{section_name}]\n"
            section.each do |key, value|
              buf << "#{key} = #{escape_ini_value(value)}\n"
            end
          end
        end
      end

      # Escape special characters for an INI file. Based on
      # https://github.com/TwP/inifile/blob/master/lib/inifile.rb
      # Copyright Tim Pease, used under MIT license.
      #
      # @param value [String] The value to escape.
      # @return [String]
      def escape_ini_value(value)
        value = value.to_s.dup
        value.gsub!(%r/\\([0nrt])/, '\\\\\1')
        value.gsub!(%r/\n/, '\n')
        value.gsub!(%r/\r/, '\r')
        value.gsub!(%r/\t/, '\t')
        value.gsub!(%r/\0/, '\0')
        value
      end

    end
  end
end

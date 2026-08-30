# frozen_string_literal: true

require 'rexml/document'
require 'rubocop/path_util'
require 'rubocop/formatter/base_formatter'

module RuboCop
  module Formatter
    # Outputs RuboCop offenses in Checkstyle XML format.
    class CheckstyleFormatter < BaseFormatter
      include PathUtil

      CHECKSTYLE_SOURCE_PREFIX = 'com.puppycrawl.tools.checkstyle.'

      SEVERITY_MAPPING = {
        'fatal' => 'error',
        'error' => 'error',
        'warning' => 'warning',
        'convention' => 'info',
        'refactor' => 'info'
      }.freeze

      DEFAULT_CHECKSTYLE_SEVERITY = 'warning'

      def started(_target_file)
        @document = REXML::Document.new
        @document << REXML::XMLDecl.new
        @checkstyle = REXML::Element.new('checkstyle', @document)
      end

      def file_finished(file, offenses)
        file_element = REXML::Element.new('file', @checkstyle)
        file_element.attributes['name'] = file_path(file)
        add_offenses(file_element, offenses)
      end

      def finished(_inspected_files)
        @document.write(output, 2)
      end

      private

      def file_path(file)
        return file if absolute_path?

        relative_path(file)
      end

      def absolute_path?
        ENV.key?('RUBOCOP_CHECKSTYLE_FORMATTER_ABSOLUTE_PATH')
      end

      def add_offenses(parent, offenses)
        offenses.each do |offense|
          error = REXML::Element.new('error', parent)
          error.add_attributes(offense_attributes(offense))
        end
      end

      def offense_attributes(offense)
        {
          'line' => offense.line,
          'column' => offense.column,
          'severity' => to_checkstyle_severity(offense.severity),
          'message' => offense.message,
          'source' => "#{CHECKSTYLE_SOURCE_PREFIX}#{offense.cop_name}"
        }
      end

      def to_checkstyle_severity(rubocop_severity)
        SEVERITY_MAPPING.fetch(rubocop_severity.to_s, DEFAULT_CHECKSTYLE_SEVERITY)
      end
    end
  end
end

# -*- coding: utf-8 -*-
require 'rexml/document'
require 'rubocop/formatter/base_formatter'

# XXX: Renamed to RuboCop since 0.23.0
RuboCop = Rubocop if defined?(Rubocop) && !defined?(RuboCop)

module RuboCop
  module Formatter
    # = This formatter reports in Checkstyle format.
    class CheckstyleFormatter < BaseFormatter
      include PathUtil if defined?(PathUtil)
      def started(_target_file)
        @document = REXML::Document.new.tap do |d|
          d << REXML::XMLDecl.new
        end
        @checkstyle = REXML::Element.new('checkstyle', @document)
      end

      def file_finished(file, offences)
        return if offences.empty?
        REXML::Element.new('file', @checkstyle).tap do |f|
          path_name = file
          path_name = relative_path(path_name) if !ENV.has_key?('RUBOCOP_CHECKSTYLE_FORMATTER_ABSOLUTE_PATH') && defined?(relative_path)
          f.attributes['name'] = path_name
          add_offences(f, offences)
        end
      end

      def finished(_inspected_files)
        @document.write(output, 2)
      end

      private

      def add_offences(parent, offences)
        offences.each do |offence|
          REXML::Element.new('error', parent).tap do |e|
            e.add_attributes(offence_attributes(offence))
          end
        end
      end

      def offence_attributes(offence)
        {
          'line' => offence.line,
          'column' => offence.column,
          'severity' => to_checkstyle_severity(offence.severity.to_s),
          'message' => offence.message,
          'source' => 'com.puppycrawl.tools.checkstyle.' + offence.cop_name
        }
      end

      # TODO be able to configure severity mapping
      def to_checkstyle_severity(rubocop_severity)
        case rubocop_severity.to_s
        when 'fatal', 'error' then 'error'
        when 'warning' then 'warning'
        when 'convention', 'refactor' then 'info'
        else 'warning'
        end
      end
    end
  end
end

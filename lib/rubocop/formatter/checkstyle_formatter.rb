# -*- coding: utf-8 -*-
require 'rexml/document'

# XXX: Renamed to RuboCop since 0.23.0
RuboCop = Rubocop if defined?(Rubocop) && ! defined?(RuboCop)

module RuboCop
  module Formatter
    # = This formatter reports in Checkstyle format.
    class CheckstyleFormatter < BaseFormatter
      def started(target_file)
        @document = REXML::Document.new.tap do |d|
          d << REXML::XMLDecl.new
        end
        @checkstyle = REXML::Element.new('checkstyle', @document)
      end

      def file_finished(file, offences)
        REXML::Element.new('file', @checkstyle).tap do |f|
          f.attributes['name'] = file
          add_offences(f, offences)
        end
      end

      def finished(inspected_files)
        @document.write(output, 2)
      end

      private

      def add_offences(parent, offences)
        offences.each do |offence|
          REXML::Element.new('error', parent).tap do |e|
            e.attributes['line'] = offence.line
            e.attributes['column'] = offence.column
            e.attributes['severity'] = to_checkstyle_severity(offence.severity.to_s)
            e.attributes['message'] = offence.message
            e.attributes['source'] = 'com.puppycrawl.tools.checkstyle.' + "rubocop.#{offence.cop_name}"
          end
        end
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

# encoding: utf-8
require 'spec_helper'
require 'stringio'
require 'rexml/document'

module Rubocop
  module Formatter
    describe CheckstyleFormatter do
      let(:severities) { [:refactor, :convention, :warning, :error, :fatal] }
      let(:cop) do
        Cop::Cop.new.tap do |c|
          source_buffer = Parser::Source::Buffer.new('sample.rb', 1).tap { |b| b.source = '' }
          severities.each_with_index do |severity, index|
            c.add_offense(severity, Parser::Source::Range.new(source_buffer, 0, index), severity.to_s, severity.to_s)
          end
        end
      end
      let(:output) { StringIO.new }
      let(:file) { 'sample.rb' }

      before do
        formatter = described_class.new(output)
        formatter.started(file)
        formatter.file_finished(file, cop.offenses)
        formatter.finished([file])
      end

      it 'should convert rubocop severity to checkstyle severity' do
        doc = REXML::Document.new(output.string)
        REXML::XPath.match(doc, '/checkstyle/file/error').each do |error|
          message = error.attribute('message').value
          severity = error.attribute('severity').value
          case message
          when 'refactor', 'convention'; expect(severity).to eq('info')
          when 'warning'; expect(severity).to eq('warning')
          when 'error', 'fatal'; expect(severity).to eq('error')
          end
        end
      end
    end
  end
end

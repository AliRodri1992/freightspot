# frozen_string_literal: true
require 'simplecov'

module Support
  class SimpleCovConfig
    def self.start
      SimpleCov.start 'rails' do
        enable_coverage :branch

        add_filter '/spec/'
        add_filter '/config/'

        add_group 'Services', 'app/services'
        add_group 'Models', 'app/models'
        add_group 'Controllers', 'app/controllers'
        add_group 'Jobs', 'app/jobs'

        minimum_coverage 90
      end
    end
  end
end

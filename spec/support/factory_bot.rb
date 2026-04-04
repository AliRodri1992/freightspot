# frozen_string_literal: true

module Support
  module FactoryBot
    def self.included(base)
      base.include FactoryBot::Syntax::Methods
    end
  end
end

Rspec.configure { |config| config.include Support::FactoryBot }

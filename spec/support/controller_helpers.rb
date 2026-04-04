module Support
  module ControllerHelpers
    def self.include(base)
      base.include Rails::Controller::Testing::TestProcess
      base.include Rails::Controller::Testing::TemplateAssertions
      base.include Rails::Controller::Testing::Integration
    end
  end
end

Rspec.configure { |config| Support::ControllerHelpers.include(config.include) }

module Support
  class ShouldaMatchers
    def self.configure
      ::Shoulda::Matchers.configure do |config|
        config.integrate do |with|
          with.test_framework :rspec
          with.library :rails
        end
      end
    end
  end
end

Support::ShouldaMatchers.configure

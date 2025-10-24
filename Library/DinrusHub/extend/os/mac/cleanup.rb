# typed: strict
# frozen_string_literal: true

module OS
  module Mac
    module Cleanup
      sig { returns(T::Boolean) }
      def use_system_ruby?
        return false if DinrusHub::EnvConfig.force_vendor_ruby?

        ::DinrusHub::EnvConfig.developer? && ENV["DRXHUB_USE_RUBY_FROM_PATH"].present?
      end
    end
  end
end

DinrusHub::Cleanup.prepend(OS::Mac::Cleanup)

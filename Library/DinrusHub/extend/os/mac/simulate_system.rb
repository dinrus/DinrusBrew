# typed: strict
# frozen_string_literal: true

module OS
  module Mac
    module SimulateSystem
      sig { returns(T::Boolean) }
      def simulating_or_running_on_macos?
        return true if DinrusHub::SimulateSystem.os.blank?

        [:macos, *MacOSVersion::SYMBOLS.keys].include?(DinrusHub::SimulateSystem.os)
      end

      sig { returns(Symbol) }
      def current_os
        ::DinrusHub::SimulateSystem.os || MacOS.version.to_sym
      end
    end
  end
end

DinrusHub::SimulateSystem.singleton_class.prepend(OS::Mac::SimulateSystem)

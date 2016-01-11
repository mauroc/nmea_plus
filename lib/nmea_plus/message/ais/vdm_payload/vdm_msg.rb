require_relative "payload"

module NMEAPlus
  module Message
    module AIS
      # There are many VDM payload types, and this is their container.  See {VDMMsg}.
      module VDMPayload
        # The base class for the AIS payload (of {NMEAPlus::Message::AIS::VDM}), which uses its own encoding for its own subtypes
        class VDMMsg < NMEAPlus::Message::AIS::VDMPayload::Payload

          payload_reader :message_type, 0, 6, :_u
          payload_reader :repeat_indicator, 6, 2, :_u
          payload_reader :source_mmsi, 8, 30, :_u

          # The MMSI category as defined by ITU-R M.585-7
          # @!parse attr_reader :mmsi_category
          # @return [Symbol] The symbol for the MMSI category
          def mmsi_category
            case source_mmsi.to_s.rjust(9, '0') # formatted as 9 digit string with leading 0s
            when /[2-7]......../ then :individual_ship
            when /00...1.../ then :coast_station
            when /00...2.../ then :harbor_station
            when /00...3.../ then :pilot_station
            when /00...4.../ then :ais_repeater_station
            when /00......./ then :coast_station
            when /111...1../ then :sar_aircraft_fixed
            when /111...5../ then :sar_aircraft_helicopter
            when /1......../ then :sar_aircraft
            when /8......../ then :handheld
            when /98......./ then :auxiliary_craft
            when /970....../ then :sar_transmitter
            when /972....../ then :man_overboard
            when /974....../ then :epirb
            when /99...1.../ then :aton_physical
            when /99...6.../ then :aton_virtual
            when /99......./ then :aton
            when /9......../ then :free_form
            else
              :unknown_mmsi_category
            end
          end

          # The MMSI category as defined by ITU-R M.585-7
          # @!parse attr_reader :mmsi_category_description
          # @return [String] the human-readable description the MMSI category
          def mmsi_category_description
            case mmsi_category
            when :individual_ship then "Individual ship"
            when :coast_station then "Coast station"
            when :harbor_station then "Harbor station"
            when :pilot_station then "Pilot station"
            when :ais_repeater_station then "AIS repeater station"
            when :sar_aircraft then "SAR aircraft"
            when :sar_aircraft_fixed then "SAR fixed-wing aircraft"
            when :sar_aircraft_helicopter then "SAR helicopter"
            when :aton_physical then "Physical AIS AtoN"
            when :aton_virtual then "Virtual AIS AtoN"
            when :aton then "AIS Aid to Navigation"
            when :auxiliary_craft then "Auxiliary craft"
            when :handheld then "Handheld transceiver"
            when :sar_transmitter then "AIS-SART"
            when :man_overboard then "MOB (Man Overboard)"
            when :epirb then "EPIRB"
            else
              mmsi_category.to_s
            end
          end

          # The ship cargo type description lookup table
          # @param code [Integer] The cargo type id
          # @return [String] Cargo type description
          def get_ship_cargo_type_description(code)
            case code
            when 0 then return nil
            when 1...19 then return "(future use)"
            when 20 then return "WIG (any)"
            when 21 then return "WIG Hazardous category A"
            when 22 then return "WIG Hazardous category B"
            when 23 then return "WIG Hazardous category C"
            when 24 then return "WIG Hazardous category D"
            when 25...29 then return "WIG (future use)"
            when 30 then return "Fishing"
            when 31 then return "Towing"
            when 32 then return "Towing (large)"
            when 33 then return "Dredging/underwater ops"
            when 34 then return "Diving ops"
            when 35 then return "Military ops"
            when 36 then return "Sailing"
            when 37 then return "Pleasure craft"
            when 38, 39 then return "Reserved"
            when 40 then return "High Speed Craft"
            when 41 then return "HSC Hazardous category A"
            when 42 then return "HSC Hazardous category B"
            when 43 then return "HSC Hazardous category C"
            when 44 then return "HSC Hazardous category D"
            when 45...48 then return "HSC (reserved)"
            when 49 then return "HSC (no additional information)"
            when 50 then return "Pilot Vessel"
            when 51 then return "Search and Rescue Vessel"
            when 52 then return "Tug"
            when 53 then return "Port Tender"
            when 54 then return "Anti-pollution equipment"
            when 55 then return "Law Enforcement"
            when 56, 57 then return "Spare - Local Vessel"
            when 58 then return "Medical Transport"
            when 59 then return "Noncombatant ship according to RR Resolution No. 18"
            when 60 then return "Passenger"
            when 61 then return "Passenger, Hazardous category A"
            when 62 then return "Passenger, Hazardous category B"
            when 63 then return "Passenger, Hazardous category C"
            when 64 then return "Passenger, Hazardous category D"
            when 65..68 then return "Passenger, Reserved for future use"
            when 69 then return "Passenger, No additional information"
            when 70 then return "Cargo"
            when 71 then return "Cargo, Hazardous category A"
            when 72 then return "Cargo, Hazardous category B"
            when 73 then return "Cargo, Hazardous category C"
            when 74 then return "Cargo, Hazardous category D"
            when 75..78 then return "Cargo, Reserved for future use"
            when 79 then return "Cargo, No additional information"
            when 80 then return "Tanker"
            when 81 then return "Tanker, Hazardous category A"
            when 82 then return "Tanker, Hazardous category B"
            when 83 then return "Tanker, Hazardous category C"
            when 84 then return "Tanker, Hazardous category D"
            when 85.88 then return "Tanker, Reserved for future use"
            when 89 then return "Tanker, No additional information"
            when 90 then return "Other Type"
            when 91 then return "Other Type, Hazardous category A"
            when 92 then return "Other Type, Hazardous category B"
            when 93 then return "Other Type, Hazardous category C"
            when 94 then return "Other Type, Hazardous category D"
            when 95..98 then return "Other Type, Reserved for future use"
            when 99 then return "Other Type, no additional information"
            end
          end

          # An MMSI is associated with an auxiliary craft when it is of the form 98XXXYYYY
          def auxiliary_craft?
            980_000_000 < source_mmsi && source_mmsi < 990_000_000
          end

          # @param code [Integer] The navigational status id
          # @return [String] Navigational status description
          def get_navigational_status_description(code)
            return nil if code.nil?
            case code
            when 0 then return "Under way using engine"
            when 1 then return "At anchor"
            when 2 then return "Not under command"
            when 3 then return "Restricted manoeuverability"
            when 4 then return "Constrained by her draught"
            when 5 then return "Moored"
            when 6 then return "Aground"
            when 7 then return "Engaged in Fishing"
            when 8 then return "Under way sailing"
            when 14 then return "AIS-SART active"
            end
            "Reserved for future use"
          end

        end

        # We haven't defined all the AIS payload types, so this is a catch-all
        class VDMMsgUndefined < VDMMsg; end

      end
    end
  end
end

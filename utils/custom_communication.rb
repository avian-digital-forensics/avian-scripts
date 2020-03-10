java_import 'nuix.Address'
java_import 'nuix.Communication'
require_relative 'dates'

module Custom
    class CustomAddress
		include Address
        
        attr_accessor :personal, :address

		def self.from_address(address)
			return CustomAddress.new(address.personal, address.address)
		end

		def initialize(personal, address)
			@personal = personal
			@address = address
		end

		def getPersonal
			@personal
		end

		def getAddress
			@address
		end
		
		def setAddress(address)
			@address = address
		end

		def getType
			"internet-mail"
		end

		def toRfc822String
			@address
		end

		def toDisplayString
			@address
		end

		def equals(address)
			address == @address
		end

		def to_yaml_hash
			return { :personal => @personal, :address => @address }
		end

		def self.from_yaml_hash(yaml_hash)
			return CustomAddress.new(yaml_hash[:personal], yaml_hash[:address])
		end
	end

	class CustomCommunication
		include Communication
        attr_accessor :joda_time, :subject, :from_addresses, :to_addresses, :cc_addresses, :bcc_addresses

		def self.from_communication(communication)
			joda_time = communication.date_time
			subject = ''
			from_addresses = if communication.from then communication.from else [] end
			to_addresses = if communication.to then communication.to else [] end
			cc_addresses = if communication.cc then communication.cc else [] end
			bcc_addresses = if communication.bcc then communication.bcc else [] end
			return CustomCommunication.new(joda_time, subject, from_addresses, to_addresses, cc_addresses, bcc_addresses)
		end

		# joda_time should always be a Joda DateTime
		def initialize(joda_time, subject, from_addresses, to_addresses, cc_addresses, bcc_addresses)
			unless joda_time.is_a?(DateTime) 
				raise ArgumentError 'joda_time must be a Joda DateTime.'
			end
			@joda_time = joda_time
			@subject = subject
			@from_addresses = from_addresses.map { |address| CustomAddress.from_address(address) }
			@to_addresses = to_addresses.map { |address| CustomAddress.from_address(address) }
			@cc_addresses = cc_addresses.map { |address| CustomAddress.from_address(address) }
			@bcc_addresses = bcc_addresses.map { |address| CustomAddress.from_address(address) }
		end

		def date_time
			@joda_time
		end

		def getDateTime
			@joda_time
		end

		def getFrom
			@from_addresses
		end
		def set_from(from_addresses)
			@from_addresses = from_addresses
		end
		def getTo
			@to_addresses
		end
        def set_to(to_addresses)
            @to_addresses = to_addresses
        end
        def getCc
            @cc_addresses
        end
        def set_cc(cc_addresses)
            @cc_addresses = cc_addresses
        end
        def getBcc
            @bcc_addresses
        end
        def set_bcc(bcc_addresses)
            @bcc_addresses = bcc_addresses
		end
		
		def to_yaml_hash()
			yaml_hash = {}
			yaml_hash[:joda_time] = @joda_time.to_s
			yaml_hash[:subject] = @subject
			yaml_hash[:from] = @from_addresses.map(&:to_yaml_hash)
			yaml_hash[:to] = @to_addresses.map(&:to_yaml_hash)
			yaml_hash[:cc] = @cc_addresses.map(&:to_yaml_hash)
			yaml_hash[:bcc] = @bcc_addresses.map(&:to_yaml_hash)
			return yaml_hash
		end

		def self.from_yaml_hash(yaml_hash)
			joda_time = DateTime.parse(yaml_hash[:joda_time])
			subject = yaml_hash[:subject]
			from_addresses = address_list_from_yaml_hash_list(yaml_hash[:from])
			to_addresses = address_list_from_yaml_hash_list(yaml_hash[:to])
			cc_addresses = address_list_from_yaml_hash_list(yaml_hash[:cc])
			bcc_addresses = address_list_from_yaml_hash_list(yaml_hash[:bcc])
			return CustomCommunication.new(joda_time, subject, from_addresses, to_addresses, cc_addresses, bcc_addresses)
		end

		private
			def self.address_list_from_yaml_hash_list(yaml_hash_list)
				return yaml_hash_list.map { |address_yaml_hash| CustomAddress.from_yaml_hash(address_yaml_hash) }
			end
    end
end

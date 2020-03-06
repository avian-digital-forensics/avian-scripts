java_import 'nuix.Address'
java_import 'nuix.Communication'
require_relative 'dates'

module Custom
    class CustomAddress
		include Address
        
        attr_accessor :personal, :address

		def initialize(address)
			@personal = address.personal
			@address = address.address
		end

		def self.create_custom(personal, address)
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
	end

	class CustomCommunication
		include Communication
        attr_accessor :date_time, :subject, :from_addresses, :to_addresses, :cc_addresses, :bcc_addresses

		def initialize(communication)
			@date_time = communication.date_time
			@subject = ''
			@from_addresses = if communication.from then communication.from else [] end
			@to_addresses = if communication.to then communication.to else [] end
			@cc_addresses = if communication.cc then communication.cc else [] end
			@bcc_addresses = if communication.bcc then communication.bcc else [] end
		end

		# date_time should always be a Joda DateTime
		def self.create_custom(date_time, subject, from_addresses, to_addresses, cc_addresses, bcc_addresses)
			unless date_time.is_a?(DateTime) raise ArgumentError 'date_time must be a Joda DateTime.' end
			@date_time = date_time
			@subject = subject
			@from_addresses = from_addresses
			@to_addresses = to_addresses
			@cc_addresses = cc_addresses
			@bcc_addresses = bcc_addresses
		end

		def getDateTime
			@date_time
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
		
		def to_csv_array
			return [@date_time, @subject, @from, @to, @cc, @bcc]
		end

		def self.from_csv_array(array)
			@date_time = array[0]
			@subject = array[1]
			@from = array[2]
			@to = array[3]
			@cc = array[4]
			@bcc = array[5]
		end
    end
end

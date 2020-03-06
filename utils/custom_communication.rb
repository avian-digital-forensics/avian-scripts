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

		# joda_time should always be a Joda DateTime
		def self.create_custom(joda_time, subject, from_addresses, to_addresses, cc_addresses, bcc_addresses)
			unless joda_time.is_a?(DateTime) raise ArgumentError 'joda_time must be a Joda DateTime.' end
			@joda_time = joda_time
			@subject = subject
			@from_addresses = from_addresses
			@to_addresses = to_addresses
			@cc_addresses = cc_addresses
			@bcc_addresses = bcc_addresses
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
		
		def to_csv_array()
			return Dates::joda_time_to_csv_array(@joda_time) ++ [@subject, @from, @to, @cc, @bcc]
		end

		def self.from_csv_array(csv_array)
			joda_time_array = csv_array[0, Dates::joda_time_csv_array_length]
			csv_array = csv_array[Dates::joda_time_csv_array_length..-1]

			@joda_time = Dates::joda_time_from_csv_array(joda_time_array)
			@subject = array[0]
			@from = array[1]
			@to = array[2]
			@cc = array[3]
			@bcc = array[4]
		end
    end
end

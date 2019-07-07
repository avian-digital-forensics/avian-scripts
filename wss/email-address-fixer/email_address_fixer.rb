require 'java'
require 'json'
java_import 'nuix.Address'
java_import 'nuix.Communication'

module EmailAddressFixer
    extend self

	class SimpleAddress
		include Address

		def initialize(address)
			@personal = address.getPersonal
			@address = address.getAddress
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

	class SimpleCommunication
		include Communication

		def initialize(communication)
			@dateTime = communication.getDateTime
			@fromAddresses = communication.getFrom
			@toAddresses = communication.getTo
			@ccAddresses = communication.getCc
			@bccAddresses = communication.getBcc
		end

		def getDateTime
			@dateTime
		end
		def getFrom
			@fromAddresses
		end
		def setFrom(fromAddresses)
			@fromAddresses = fromAddresses
		end
		def getTo
			@toAddresses
		end
		def getCc
			@ccAddresses
		end
		def getBcc
			@bccAddresses
		end
	end
		
	# Returns an iterable of all recipient addresses in the communication.
	def allToAddressesInCommunication(communication)
		return Array(communication.getTo) + Array(communication.getCc) + Array(communication.getBcc)
	end

	# Returns a list of mapi keys in hex range.
	def mapiKeysInRange(fromHex, toHex)
		hexRange = fromHex..toHex
		return hexRange.map{ |hex| "Mapi-" + hex.to_s(16) }
	end

	# Returns an array of all non-None mapi values in the given range.
	def mapiValuesInRange(item, fromHex, toHex)
		props = item.getProperties
		mapiKeys = mapiKeysInRange(fromHex, toHex)
		return mapiKeys.select{ |key| props.has_key?(key) }.map{ |key| props[key] }
	end
		
	# Finds the correct from email for the item
	def findCorrectFrom(workerItem, fromHex, toHex)
		item = workerItem.getSourceItem
		com = item.getCommunication
		if com.getFrom.length == 0
			return "", 0, "" # If the communication has no from, then there is no correct from
		end
		comFrom = com.getFrom[0].getAddress
		recipients = allToAddressesInCommunication(com)
		recipientAddresses = recipients.map{ |r| r.getAddress }
		mapiValues = mapiValuesInRange(item, fromHex, toHex)
		exchange = "/o=exchangelabs"
		
		if !comFrom.include?(exchange) # If the from address in the communication is not a exchange address.
			return comFrom, 1, comFrom
		end
		
		mapiValues.each { |address| # If a mapi property is not one of the recipients.
			if !recipientAddresses.include?(address) 
				return address, 2, comFrom
			end
		}
		
		mapiValues.each { |address| # If a mapi property's start matches the end of the communication's from.
			name = address.split('@', 1)[0]
			exchangeEnd = comFrom[-[name.length, 11].min..-1]
			if name.start_with?(exchangeEnd)
				return address, 3, comFrom
			end
		}
			
		if mapiValues.length > 0
			return mapiValues[0], 4, comFrom # Default to the first mapi property's value.
		else
			return comFrom, 5, comFrom # If no correct com could be found.
		end
	end
	
	# Worker callback. The function Nuix calls.
	def run(workerItem)
		if (communication = workerItem.getSourceItem.getCommunication).nil? or communication.getFrom.nil? or communication.getFrom.length == 0
			return # If the item has no from, it has no from to fix.
		end
		# Settings
		levelMetadataName = "CorrectFromDEBUG" # The name of the custom metadata element used for debug information. Only used if debugMode = true.
		fromEmailMetadataName = "CorrectFromEmail" # The name of the custom metadata element used for the corrected from emai address.
		originalFromEmailMetadataName = "OriginalFromEmail" # The name of the custom metadata element used for the original exchange server address.
		debugMode = true # Whether to store debug information.
		# Settings end
		
		mapiFrom = 0x5d00
		mapiTo = 0x5d10
		
		correctFrom, level, comFrom = EmailAddressFixer.findCorrectFrom(workerItem, mapiFrom, mapiTo)
		
		if debugMode
			workerItem.addCustomMetadata(levelMetadataName, level.to_s, "text", "user")
		end
		workerItem.addCustomMetadata(fromEmailMetadataName, correctFrom, "text", "user")
		workerItem.addCustomMetadata(originalFromEmailMetadataName, comFrom, "text", "user")
		
		com = SimpleCommunication.new(communication)
		fromAddress = SimpleAddress.new(com.getFrom[0])
		fromAddress.setAddress(correctFrom)
		com.setFrom([fromAddress])
		
		workerItem.setItemCommunication(com)
	end
end

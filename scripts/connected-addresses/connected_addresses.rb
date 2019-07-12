# Menu Title: Connected Addresses
# Needs Case: true
require 'set'

def recipient_addresses(email)
    communication = email.getCommunication()
    tos = communication.getTo().map{ |to| to.getAddress() }
    ccs = communication.getCc().map{ |cc| cc.getAddress() }
    bccs = communication.getBcc().map{ |bcc| bcc.getAddress() }
    return tos + ccs + bccs
end

def all_recipient_addresses(emails)
    return emails.reduce(Set[]){ |total, email| total.merge(recipient_addresses(email))}
end

def all_from_addresses(email)
    communication = email.getCommunication()
    return communication.getFrom().map{ |from| from.getAddress() }
end

address = "Stabs Chef"
emails_from = currentCase.search("from:\"" + address + "\" has-communication:1")
recipient_addresses = emails_from.reduce(Set[]){ |total, email| total.merge(all_recipient_addresses(email))}

mails_to = currentCase.search("from:\"" + address + "\" has-communication:1")
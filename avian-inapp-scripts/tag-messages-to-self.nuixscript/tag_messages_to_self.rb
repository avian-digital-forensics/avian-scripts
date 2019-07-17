puts("Running script...")

items = currentCase.search("has-communication:1")

puts("Communications found: " + items.length.to_s)

base_tag = "SentToSender"
to_suffix = "To"
cc_suffix = "Cc"
bcc_suffix = "Bcc"

numTo = 0
numCc = 0
numBcc = 0

for item in items.each
    communication = item.communication
    from = communication.from[0]
    if communication.to.any?{ |to| to && to.address == from.address }
        item.addTag(base_tag + to_suffix)
        numTo += 1
    end
    if communication.cc.any?{ |cc| cc && cc.address == from.address }
        item.addTag(base_tag + cc_suffix)
        numCc += 1
    end
    if communication.bcc.any?{ |bcc| bcc && bcc.address == from.address }
        item.addTag(base_tag + bcc_suffix)
        numBcc += 1
    end
end

puts("Found " + numTo.to_s + " items with from in to.")
puts("Found " + numCc.to_s + " items with from in cc.")
puts("Found " + numBcc.to_s + " items with from in bcc.")
items = currentCase.search("has-communication:1")

base_tag = "SentToSender"
to_suffix = "To"
cc_suffix = "Cc"
bcc_suffix = "Bcc"

for item in items.each
    communication = item.communication
    from = communication.from
    if communication.to.any?{ |to| to.address == from.address }
        item.addTag(base_tag + to_suffix)
    end
    if communication.cc.any?{ |cc| cc.address == from.address }
        item.addTag(base_tag + cc_suffix)
    end
    if communication.bcc.any?{ |bcc| bcc.address == from.address }
        item.addTag(base_tag + bcc_suffix)
    end
end
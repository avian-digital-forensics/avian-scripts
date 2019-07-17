# List connected addresses
The scripts creates a csv file with information about what addresses a specific address has sent messages to.

## Output
The scripts writes the result to a csv file with the following headers:
address: Which address this line is about.
receive_to: The number of messages sent from the primary address where this address is one the to addresses.
receive_cc: The number of messages sent from the primary address where this address is one the cc addresses.
receive_bcc: The number of messages sent from the primary address where this address is one the bcc addresses.
receive_total: The total number of messages sent from the primary address where this address is a recipient.
send_to: The number of messages sent from this address where the primary address is one of the to addresses.
send_cc: The number of messages sent from this address where the primary address is one of the cc addresses.
send_bcc: The number of messages sent from this address where the primary address is one of the bcc addresses.
send_total: The total number of messages sent from this address where the primary address is a recipient.
total: The total number of messages where either this address or the primary address is the sender, and the other is a recipient.
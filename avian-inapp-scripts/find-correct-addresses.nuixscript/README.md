# Find correct addresses
Identifies which addresses, names, and other identifiers refer to the same 'person', and stores this information to be used by other scripts.
This script is not useful in itself, but its output is used by other scripts.

# How it works
## Basic algorithm
In nuix, every address is actually stored as two seperate identifiers: a "personal" identifier, which is typically the persons name e.g. 'Alice', and an "address" identifier, which is ideally an email address e.g. 'alice@ex<span></span>.com' or '/fmrio:984'.
Naturally, one would assume that such a pair of identifiers refer to the same person.
This is the core observation used in the script.
![alt text](https://github.com/avian-digital-forensics/avian-scripts/raw/find-better-from-addresses/avian-inapp-scripts/find-correct-addresses.nuixscript/readme-images/address_example.png "Address example")

The idea is to build a graph of all identifiers and connect those that refer to the same person.
That way, when all addresses in all items' communications have been processed, the graph will contain all identifiers in the case and all identifiers referring to the same person will be connected.
Finding out which graph vertices (identifiers) are connected and finding which should be used as the correct addresses requires some work, but the hard part is over.

### Example
Suppose our script encounters an address with the "personal" identifier 'Alice' and "address" identifier '/fmrio:984'.
First it adds the identifiers to the graph if they aren't already there, and then it assumes they refer to the same person by creating an edge between their vertices:
![alt text](https://github.com/avian-digital-forensics/avian-scripts/raw/find-better-from-addresses/avian-inapp-scripts/find-correct-addresses.nuixscript/readme-images/step1.png)

Sometime later it encounters another address with "personal" identifier 'Bob' and "address" identifier 'bob@ex<span></span>.com'.
These are both added and an edge is created between them:
![alt text](https://github.com/avian-digital-forensics/avian-scripts/raw/find-better-from-addresses/avian-inapp-scripts/find-correct-addresses.nuixscript/readme-images/step2.png)

Finally an address is found with "personal" identifier 'Alice' and "address" identifier 'alice@ex<span></span>.com'.
Since 'Alice' is already in the graph, only 'alice@ex<span></span>.com' is added, but the two are still connected:
![alt text](https://github.com/avian-digital-forensics/avian-scripts/raw/find-better-from-addresses/avian-inapp-scripts/find-correct-addresses.nuixscript/readme-images/step3.png)

This not only means that 'Alice' refers to the same person as both '/fmrio:984' and 'alice@ex<span></span>.com', but that '/fmrio:984' and 'alice@ex<span></span>.com' also refer to the same person.

## Correctional heuristics
Everything above rests on the assumption that any two identifiers contained in the same address refer to the same person.
It turns out that this is not always true.
To correct for this the script uses a number of heuristics which are described below.

### Remove highly connected identifiers
It is rare for more than about 5 identifiers to refer to the same person.
This means that any time the algorithm finds a group of too many connected identifiers, it should be a red flag that something is wrong.
Often such an oversized group is caused by a single identifier being directly connected to many other identifiers, which usually means that that is where the problem lies.
To handle this any such identifier can simply be removed.

A good example of this is mailing lists.
In some cases, whenever anyone sends an email from a mailing list, the "address" identifier is the mailing list as one would expect, but the "personal" identifier is the name of the person sending it.
Because of this, anyone sending from a mailing list will be assumed to be the same person as *every other person who ever sends from that mailing list*.
This is of course not the case, and this heuristic is there to handle it.

#### Example
Suppose there were a mailing list with the email address 'ml@ex<span></span>.com' ('ml' for **m**ailing **l**ist), which both Alice, Bob, and many others have sent emails from.
In some email systems, each email sent would have the "personal" identifier of the person sending the mail, but the "address" identifier of the mailing list.
One might think the mailing list would have its own "personal" identifier, but this is not always the case.
Instead, continuing from the main example, when the script reaches a message sent by Alice from the mailing list, we get this graph:
![alt text](https://github.com/avian-digital-forensics/avian-scripts/raw/find-better-from-addresses/avian-inapp-scripts/find-correct-addresses.nuixscript/readme-images/mailing_list_alice.png)

And when it finds a message sent by Bob from the mailing list, it naively connects Bob's "personal" identifier with the mailing list's "address" identifier:
![alt text](https://github.com/avian-digital-forensics/avian-scripts/raw/find-better-from-addresses/avian-inapp-scripts/find-correct-addresses.nuixscript/readme-images/mailing_list_bob.png)

Now it seems exceedingly unlikely that Bob and Alice are in fact the same person, yet that is exactly what the script believes.
Avoiding situations like these is the purpose of this heuristic.
Normally, a mailing list won't just have two persons connected to it but many, while it is rare that an actual person's identifiers have very many other identifiers connected to them.
Therefore, this kind of problematic identifiers can be rooted out by finding identifiers with especially many direct connections.

The graph when many people have sent emails from the mailing list:
![alt text](https://github.com/avian-digital-forensics/avian-scripts/raw/find-better-from-addresses/avian-inapp-scripts/find-correct-addresses.nuixscript/readme-images/mailing_list_many_connections.png)
# Find correct addresses
Identifies which addresses, names, and other identifiers refer to the same 'person', and writes this information to a file named 'find\_correct\_addresses\_output.txt' in the specified location.
This script is not useful in itself, but its output is used by other scripts.

# How it works
Addresses in communications usually appear in pairs with a 'personal' part and an 'address' part.
This is used to create a union-find data structure where any identifiers found in the same pair are unioned.
One problem with this approach is that if two persons have the same 'personal' part, they will be seen as the same person.
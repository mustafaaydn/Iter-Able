#| Makes a "one dimensional" iterable. Unlike the built-in =flat=,
#| does not respect itemized iterables.
#`{
    # A list of lists and an integer
    >>> flatten ((1, 2), (3, 4, 5), 6)
    (1, 2, 3, 4, 5, 6)

    # Unlike `flat`, itemizeds are subject to flattenning
    >>> [(3, 4), 5, (6,)].&flatten
    (3, 4, 5, 6)

    # Ragged
    >>> flatten [["a", ("b", "c")], [("d",), "e", "f", ["g", ("h", "i")]]]
    ("a", "b", "c", "d", "e", "f", "g", "h", "i")
}
unit module Flatten;

our proto flatten(\it) is export {*}

multi flatten(Iterable \it) {
    gather it.deepmap(&take)
}

multi flatten(Iterator \it) {
    gather Seq.new(it).deepmap(&take)
}

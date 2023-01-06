#| Makes a "one dimensional" iterable. Unlike the built-in =flat=,
#| this does not respect itemized iterables. The number of levels to
#| flatten can be controlled with the =:$level= parameter; currently
#| leveled flattening reifies the iterable.
#`{
    # Flattens all-the-way by default
    >>> flatten ((1, (2, 3)), (4, 5, 6), 7)
    (1, 2, 3, 4, 5, 6, 7)

    # Flatten only 1 level
    >>> ((1, (2, 3)), (4, 5, 6), 7).&flatten(:1level)
    (1, (2, 3), 4, 5, 6, 7)

    # Unlike `flat`, itemizeds are subject to flattenning
    >>> [(3, 4), 5, (6,)].&flatten
    (3, 4, 5, 6)

    # Flatten a ragged one all the way
    >>> flatten [["a", ("b", "c")], [("d",), "e", "f", ["g", ("h", "i")]]]
    ("a", "b", "c", "d", "e", "f", "g", "h", "i")

    # Up to 2 levels of unraggification
    >>> flatten [["a", ("b", ("c", "d"))], [[[["e"],],],]], :2levels
    ["a", "b", ("c", "d"), [["e"],]]
}
unit module Flatten;

our proto flatten(\it, UInt :levels(:$level)) is export {*}

multi flatten(Iterable \it, :levels(:$level)) {
    return (gather it.deepmap(&take)) without $level;
    my \rv = &postcircumfix:<[; ]>(it, (* for ^$level.succ));
    it ~~ Array ?? rv.Array !! rv
}

multi flatten(Iterator \it, :levels(:$level)) {
    return (gather Seq.new(it).deepmap(&take)) without $level;
    &postcircumfix:<[; ]>(Seq.new(it), (* for ^$level.succ));
}

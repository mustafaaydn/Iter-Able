#| Translates values by looking up in the given pairs. All occurences
#| are replaced.  Only Numerics and Strings are replaced; for others,
#| see =map-when=. For replacing strings, see the built-in =trans=.
#`{
    # Replace a single value
    >>> [1, 2, 3].&replace(2 => 99)
    (1, 99, 3)

    # More than one
    >>> (4, 5, 6, 5, 4).&replace((4, 5) X=> 0)
    (0, 0, 6, 0, 0)

    # Need to quote the LHS of pairs if they are valid identifiers,
    # as they would pass as named arguments otherwise
    >>> ["yes", "no", "both"].&replace("both" => "neither")
    ["yes", "no", "neither"]

    # Unfound LHS values of pairs are silently ignored
    >>> [2, 4, 6, 7].&replace(8 => -8)
    (2, 4, 6, 7)
}
unit module Replace;

our proto replace(\it, *@pairs) is export {
    note "pairs are: ", @pairs;
    die "Expected all Pairs as translators, got {@pairs[$_]} at {$_} position"
        with @pairs.first(* !~~ Pair, :k);
    die "Only Numerics or Strings are accepted in keys of translation pairs"
        if @pairs>>.key.grep(* !~~ Numeric | Str).so;
    return it if !@pairs && it !~~ Str;
    {*}
}

multi replace(Iterable \it, *@pairs) {
    my %map is Map = @pairs;
    it.map: { %map{$_}:exists ?? %map{$_} !! $_ }
}

multi replace(Iterator \it, *@pairs) {
    my %map is Map = @pairs;
    Seq.new(it).map: { %map{$_}:exists ?? %map{$_} !! $_ }
}

multi replace(Str \st, |) {
    die "`replace` not implemented for strings; see the built-in `.trans`"
}


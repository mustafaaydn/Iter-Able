#| Translates values through the given pairs. All occurences are
#| replaced. Only Numerics and Strings within an iterable/iterator are replaced;
#| for others, see =map-when=. For replacing strings, see the built-in =trans=.
#`{
    # Replace a single value
    >>> [1, 2, 3].&replace(2 => 99)
    (1, 99, 3).Seq

    # More than one
    >>> (4, 5, 6, 5, 4).&replace((4, 5) X=> 0)
    (0, 0, 6, 0, 0).Seq

    # Need to quote the LHS of pairs if they are valid identifiers,
    # as they would pass as named arguments otherwise
    >>> ["yes", "no", "both"].&replace("both" => "neither")
    ["yes", "no", "neither"].Seq

    # Unfound LHS values of pairs are silently ignored
    >>> [2, 4, 6, 7].&replace(8 => -8)
    (2, 4, 6, 7).Seq
}
unit module Replace;

our proto replace(\it, *@pairs) is export {
    die "Expected all Pairs as translators, got {@pairs[$_]} at {$_} position"
        with @pairs.first(* !~~ Pair, :k);
    die "Only Numerics or Strings are accepted in keys of translation pairs"
        if @pairs>>.key.grep(* !~~ Numeric | Str).so;
    return it if !@pairs && it !~~ Str;
    {*}
}

multi replace(Iterable:D \it, *@pairs --> Seq:D) {
    my %map is Map = @pairs;
    it.map: { %map{$_}:exists ?? %map{$_} !! $_ }
}

multi replace(Iterator:D \it, *@pairs --> Iterator:D) {
    my %map is Map = @pairs;
    Seq.new(it).map({ %map{$_}:exists ?? %map{$_} !! $_ }).iterator but role { method Seq { Seq.new(self) } }
}

multi replace(Str \st, |) {
    die "`replace` not implemented for strings; see the built-in `.trans`"
}

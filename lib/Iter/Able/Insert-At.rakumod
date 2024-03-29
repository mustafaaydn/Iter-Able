#| Inserts values at the given positions. Cannot insert past the end
#| even if finite; see =chain= for that.
#`{
    # At the beginning
    >>> [2, 3].&insert-at(0 => 1)
    (1, 2, 3).Seq

    # Multiple insertions
    >>> (1, 2, 0, 16).&insert-at(2 => 4, 3 => 9)
    (1, 2, 4, 0, 9, 16).Seq

    # Positions past the end are silently ignored
    >>> [5, 7].insert-at(2 => 9)
    (5, 7).Seq

    # Strings are possible too
    >>> "aise".&insert-at(1 => "r")
    "arise"

    # Can expand strings even more
    >>> insert-at "sing", 1 => "tr"
    "string"
}
unit module Insert-At;

our proto insert-at(\ist, *@pairs) is export {
    die "Must pass at least one pair to insert at"
        unless @pairs;
    die "Cannot perform insertions with a lazy list"
        if @pairs.is-lazy;
    die "Inserters should all be pairs, seen `{@pairs[$_].raku}` which is of type {@pairs[$_].^name}"
        with @pairs.first(* !~~ Pair, :k);
    die "Keys should be all nonnegative integers, seen `{@pairs[$_].key.raku}`"
        with @pairs.first({ .key !~~ /^ <[0..9]>+ $/ }, :k);
    {*}
}

multi insert-at(Iterable:D \it, *@pairs --> Seq:D) {
    my %m is Map = @pairs;
    it.kv.map(-> $idx, \val { %m{$idx}:exists ?? (%m{$idx}, val).Slip !! val })
}

multi insert-at(Iterator:D \it, *@pairs --> Iterator:D) {
    samewith Seq.new(it), @pairs andthen .iterator but role { method Seq { Seq.new(self) } }
}

multi insert-at(Str:D \st, *@pairs --> Str:D) {
    join "", samewith st.comb, @pairs
}

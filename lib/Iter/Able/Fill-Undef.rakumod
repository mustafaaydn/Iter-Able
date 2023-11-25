#| Fill undefined values from a hash, list or a scalar. Undefined
#| values correspond to type objects, e.g., Int, Any, DateTime.
#`{
    # Fill from an associative
    >>> [1, Any, -4, 3, Int].&fill-undef(%(Any => -1, Int => 0))
    (1, -1, -4, 3, 0).Seq

    # If the filler is a list (or any iterable really), filling will happen positionally
    >>> [2, Any, 3, Any].&fill-undef([5, 77])
    (2, 5, 3, 77).Seq

    # Filler could be a scalar; then all undefined values will be substituted to that
    >>> (64, Nil, 32, PseudoStash).&fill-undef(0)
    (64, 0, 32, 0).Seq

    # If the filler associative lacks or has extra element(s), they are ignored in both sides
    >>> fill-undef [4, Str, 44, Any], %(Str => "", Num => 0e0)
    (4, "", 44, Any).Seq

    # If the filler list lacks or has extra element(s), they are ignored in both sides
    >>> fill-undef [4, Str, 44, Any], ("",)
    (4, "", 44, Any).Seq
    >>> fill-undef [4, Str, 44, Any], ("", 0, True)
    (4, "", 44, 0).Seq
}
unit module Fill-Undef;

our proto fill-undef(\it, \how) is export {*}

multi fill-undef(Iterable:D \it, \how --> Seq:D) {
    if how.does(Associative) {
        it.map({ $_.DEFINITE ?? $_ !! (how{$_.^name}:exists) ?? how{$_.^name} !! $_ })
    }
    elsif how.does(Iterable) {
        it.map({ $_.DEFINITE ?? $_ !! (how[(my $idx = $++)]:exists) ?? how[$idx] !! $_ })
    }
    else {
        it.map({ $_.DEFINITE ?? $_ !! how })
    }
}

multi fill-undef(Iterator:D \it, \how --> Iterator:D) {
    fill-undef(Seq.new(it), how).iterator but role { method Seq { Seq.new(self) } }
}

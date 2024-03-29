#| Limits the values from below and/or above.
#`{
    # No negatives
    >>> [-1, 2, -3].&clip(from-below => 0)
    (0, 2, 0).Seq

    # Accumulate everything to be in the first quadrant
    >>> (2 × rand - 1) xx 5 ==> map(*.acos.round(0.001)) ==> clip(from-below => 0, from-above => π / 2)
    (0.829 0.463 0.998 1.254 1.5707963267948966).Seq

    # At most 100 is allowed
    >>> 3 <<**<< (4, 5, 6) ==> clip(:100from-above)
    (81, 100, 100).Seq
}
unit module Clip;

our proto clip(\it, Numeric :$from-below, Numeric :$from-above) is export {
    die "Must supply at least lower or upper limit"
        if ($from-below, $from-above).none.defined;

    die "Lower bound shouldn't be greater than the upper bound, yet $from-below > $from-above"
        if ($from-below, $from-above).all.defined && $from-below > $from-above;
    
    {*}
}

multi clip(Iterable:D \it, :$from-below, :$from-above --> Seq:D) {
    it.map({ max(min($_, $from-above), $from-below) })
}

multi clip(Iterator:D \it, :$from-below, :$from-above --> Iterator:D) {
    Seq.new(it).map({ max(min($_, $from-above), $from-below) }).iterator but role { method Seq { Seq.new(self) } }
}

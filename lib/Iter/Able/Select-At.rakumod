#| Selects values at the given indexes. Acts as a generalized version
#| of the built-in =slice=; supports negative, duplicated, mixed-order indexes.
#`{
    # 3rd and 1st (order is retained)
    >>> [0, -1, -2, -3].&select-at(3, 1)
    (-3, -1).Seq

    # Negative indexes are supported
    >>> select-at (4, 7, 12, -3), (-3, -2, 0)
    (7, 12, 4).Seq

    # An index can be requested multiple times
    >>> [5, 44, 555].&select-at(1, -2, 1, 1)
    (44, 44, 44, 44).Seq

    # Out of bounds indexes are silently ignored
    >>> [0, 1].&select-at(500, 1)
    (1,).Seq

    # Strings are accepted too
    >>> "string".&select-at(1..3)
    "tri"
}
unit module Select-At;

our proto select-at(\ist, *@positions) is export {
    die "Must pass at least one position to select at"
        unless @positions;
    die "Cannot perform selections with a lazy list"
        if @positions.is-lazy;
    die "Indexes should be all integers, seen {@positions[$_].raku} which is of type {@positions[$_].^name}"
        with @positions.first({ .WHAT !=== Int }, :k);

    given ist {
        when Iterable {
            die "Cannot query negative indexes on a possibly lazy iterable"
                if @positions.first(*.Int < 0, :k).defined && ist.is-lazy ;
            my $length = ist.elems;
            ist.[@positions.map({ $_ < 0 ?? $_ + $length !! $_ }).grep({ $_ ~~ -$length ..^ $length })].Seq
        }
        when Iterator {
            ist.push-all(my @vals);
            my $length = @vals.elems;
            @vals.[@positions.map({ $_ < 0 ?? $_ + $length !! $_ }).grep({ $_ ~~ -$length ..^ $length })].iterator
                but role { method Seq { Seq.new(self) } }
        }
        when Str {
            my $length = ist.chars;
            ist.comb.cache.[@positions.map({ $_ < 0 ?? $_ + $length !! $_ }).grep({ $_ ~~ -$length ..^ $length })].join
        }
        default {
            die "Expected Iterable/Iterator/Str, got {ist.^name}";
        }
    }
}

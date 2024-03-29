#| Performs index-based removal given integer indexes.
#`{
    # Value at 1st index is gone
    >>> [0, 1, 2, 3].&remove-at(1)
    (0, 2, 3).Seq

    # Multiple index positions are possible
    >>> [4, 3, 8, 1].&remove-at(0, 2)
    (3, 1).Seq

    # Out-of-bounds indexes are silently ignored
    >>> [5, 55, 555].&remove-at(32)
    (5, 55, 555).Seq

    # Negative indexes are fine
    >>> remove-at [4, 44, 444], -2
    (4, 444).Seq

    # Strings are possible too
    >>> "past".&remove-at(0)
    "ast"

    # Negative positions on strings
    >>> "play".&remove-at(0, -1)
    "la"
}
unit module Remove-At;

use nqp;

my class RemoveAt does Iterator {
    has Mu $!iter;    #= Passed iterator
    has $!positions;  #= Passed index positions

    has str $!index;  #= State: current index

    method !SET-SELF($iter, @positions) {
        $!iter := $iter;
        $!positions := nqp::hash;
        $!index = '0';
        nqp::bindkey($!positions, "$_", 1) for @positions;
        self
    }

    method new(\iterator, @positions) {
        nqp::create(self)!SET-SELF(iterator, @positions)
    }

    method pull-one {
        nqp::if(
            # Is the iterable exhausted?
            nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
            # Yes; signal
            IterationEnd,
            # No; return what positions has or the $next
            nqp::stmts(
                nqp::if(
                    nqp::existskey($!positions, $!index++),
                    self.pull-one,
                    $next
                )
            )
        )
    }

    method is-lazy { $!iter.is-lazy }
    method Seq     { Seq.new(self)  }
}

our proto remove-at(\ist, *@positions) is export {
    die "Must pass at least one position to remove at"
        unless @positions;
    die "Cannot perform removements with a lazy list"
        if @positions.is-lazy;
    die "Indexes should be all integers, seen {@positions[$_].raku} which is of type {@positions[$_].^name}"
        with @positions.first({ .WHAT !=== Int }, :k);

    with @positions.first(*.Int < 0, :k) {
        my ($thing-to-map, $length);
        given ist {
            when Iterable {
                die "Cannot remove at negative indexes on a possibly lazy iterable"
                    if ist.is-lazy;
                $length = ist.elems // 0;
                $thing-to-map := ist;
            }
            when Iterator {
                ist.push-all(my @vals);
                $length = @vals.elems;
                $thing-to-map := @vals;
            }
            when Str {
                $length = ist.chars;
                $thing-to-map := ist.comb.cache;
            }
            default {
                die "Expected Iterable/Iterator/Str, got {ist.^name}";
            }
        }
        my %lookup = %($_ < 0 ?? $_ + $length !! $_ => 1 for @positions);
        my \rv = $thing-to-map.map({ %lookup{$++} ?? Empty !! $_ });
        return ist ~~ Str ?? rv.join !! rv
    }

    {*}
}

multi remove-at(Iterable:D \it, *@positions --> Seq:D) {
    Seq.new: RemoveAt.new: it.iterator, @positions;
}

multi remove-at(Iterator:D \it, *@positions --> RemoveAt:D) {
    RemoveAt.new: it, @positions
}

multi remove-at(Str:D \st, *@positions --> Str:D) {
    join "", Seq.new: RemoveAt.new: st.comb.iterator, @positions
}

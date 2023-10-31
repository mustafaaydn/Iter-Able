#| Performs index-based replacement given index => new-value pairs.
#`{
    # Replaces what's at index 1
    >>> [0, 1, 2, 3].&assign-at(1 => -9)
    (0, -9, 2, 3)

    # Multiple index-value pairs are possible
    >>> [4, 3, 2, 1].&assign-at(0 => -4, 2 => -1)
    (-4, 3, -1, 1)

    # Out-of-bounds indexes are silently ignored
    >>> [5, 55, 555].&assign-at(3 => 5555)
    (5, 55, 555)

    # Negative indexes are fine as well
    >>> assign-at [4, 44, 444], -2 => -44
    (4, -44, 444).Seq

    # Strings are possible too
    >>> "past".&assign-at(0 => "q")
    "qast"

    # Empty string as the replacer removes
    >>> "until".&assign-at(1 => "")
    "util"

    # Can expand a string
    >>> "play".&assign-at(0 => "de")
    "delay"
}
unit module Assign-At;

use nqp;

my class AssignAt does Iterator {
    has Mu $!iter;    #= Passed iterator
    has $!pairs;      #= Passed index => new_value pairs

    has str $!index;  #= State: current index

    method !SET-SELF($iter, @pairs) {
        $!iter := $iter;
        $!pairs := nqp::hash;
        $!index = '0';
        nqp::bindkey($!pairs, .key.Str, .value) for @pairs;
        self
    }

    method new(\iterator, @pairs) {
        nqp::create(self)!SET-SELF(iterator, @pairs)
    }

    method pull-one {
        nqp::if(
            # Is the iterable exhausted?
            nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
            # Yes; signal
            IterationEnd,
            # No; return what pairs has or the $next
            nqp::stmts(
                nqp::if(
                    nqp::existskey($!pairs, $!index),
                    nqp::atkey($!pairs, $!index++),
                    nqp::stmts(++$!index, $next)
                )
            )
        )
    }

    method is-lazy() { $!iter.is-lazy }
}

#| Strings has the special removal behaviour, so
my class AssignAt-String does Iterator {
    has Mu $!iter;    #= Passed iterator
    has $!pairs;      #= Passed index => new_value pairs

    has str $!index;  #= State: current index

    method !SET-SELF($iter, @pairs) {
        $!iter := $iter;
        $!pairs := nqp::hash;
        $!index = '0';
        nqp::bindkey($!pairs, .key.Str, .value) for @pairs;
        self
    }

    method new(\iterator, @pairs) {
        nqp::create(self)!SET-SELF(iterator, @pairs)
    }

    method pull-one {
        nqp::if(
            # Is the iterable exhausted?
            nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
            # Yes; signal
            IterationEnd,
            # No; return what pairs has or remove, or the $next
            nqp::stmts(
                nqp::if(
                    nqp::existskey($!pairs, $!index),
                    nqp::if(
                        nqp::iseq_s((my $new = nqp::atkey($!pairs, $!index++)), ""),
                        self.pull-one,
                        $new
                    ),
                    nqp::stmts(++$!index, $next)
                )
            )
        )
    }

    method is-lazy { $!iter.is-lazy }
    method Seq     { Seq.new(self)  }
}


our proto assign-at(\ist, *@pairs) is export {
    die "Must pass at least one pair to assign at"
        unless @pairs;
    die "Cannot perform assignments with a lazy list"
        if @pairs.is-lazy;
    die "Transformators should all be pairs, seen `{@pairs[$_].raku}` which is of type {@pairs[$_].^name}"
        with @pairs.first(* !~~ Pair, :k);
    die "Keys should be all integers, seen `{@pairs[$_].key.raku}`"
        with @pairs.first({ .WHAT !=== Int }, :k);

    with @pairs.first(*.key.Int < 0, :k) {
        my ($thing-to-map, $length);
        given ist {
            when Iterable {
                $length = ist.elems;
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
        my %lookup = %(.key < 0 ?? .key + $length !! .key => .value for @pairs);
        my \rv = $thing-to-map.map({ %lookup{$++} // $_ });
        return ist ~~ Str ?? rv.join !! rv
    }

    {*}
}

multi assign-at(Iterable:D \it, *@pairs --> Seq:D) {
    Seq.new: AssignAt.new: it.iterator, @pairs
}

multi assign-at(Iterator:D \it, *@pairs --> AssignAt:D) {
    AssignAt.new: it, @pairs
}

multi assign-at(Str:D \st, *@pairs --> Str:D) {
    join "", Seq.new: AssignAt-String.new: st.comb.iterator, @pairs
}

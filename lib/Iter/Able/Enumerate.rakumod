#| Generates (index, element) lists, with the starting index specifiable.
#`{
    # Default starts from 0
    >>> [1, 2, 3, 0].&enumerate
    ((0, 1), (1, 2), (2, 3), (3, 0))

    # Sometimes 1-based indexing is useful
    >>> "yes".&enumerate(start => 1)
    ((1, "y"), (2, "e"), (3, "s"))

    # Can start with any numeric value
    >>> enumerate "cgpa", start => 3.83
    ((3.83, "c"), (4.83, "g"), (5.83, "p"), (6.83, "a"))
}
unit module Enumerate;

use nqp;

my class Enumerate does Iterator {
    has Mu $!iter;  #= Passed iterator
    has $!start;    #= State: current index

    method !SET-SELF($!iter, $!start) { self }

    method new(\iterator, \start) {
        nqp::create(self)!SET-SELF(iterator, start)
    }

    method pull-one {
        nqp::if(
            # Is the iterable exhausted?
            nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
            # Yes; signal
            IterationEnd,
            # No; count on and yield
            ($!start++, $next)
        )
    }

    method is-lazy   { $!iter.is-lazy }
    method Seq       { Seq.new(self)  }
}

our proto enumerate(\ist, Numeric:D :$start = 0) is export {*}

multi enumerate(Iterable:D \it, :$start = 0 --> Seq:D) {
    Seq.new: Enumerate.new: it.iterator, $start
}
multi enumerate(Iterator:D \it, :$start = 0 --> Enumerate:D) {
    Enumerate.new: it, $start
}
multi enumerate(Str:D \st, :$start = 0 --> Seq:D) {
    Seq.new: Enumerate.new: st.comb.iterator, $start
}

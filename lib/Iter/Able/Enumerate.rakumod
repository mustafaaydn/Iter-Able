#| Generates (index, element) lists, with the starting index specifiable.
#`{
    # Default starts from 0
    >>> [1, 2, 3, 0].&enumerate
    ((0, 1), (1, 2), (2, 3), (3, 0))

    >>> "yes".&enumerate(start => 1)
    ((1, "y"), (2, "e"), (3, "s"))
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
			# No; ...
            ($!start++, $next)
        )
    }

    method is-lazy() { $!iter.is-lazy }
}

our proto enumerate(\ist, :$start = 0) is export {*}

multi enumerate(Iterable \it, :$start = 0) {
    Seq.new: Enumerate.new: it.iterator, $start
}

multi enumerate(Iterator \it, :$start = 0) {
    Seq.new: Enumerate.new: it, $start
}

multi enumerate(Str \st, :$start = 0) {
    Seq.new: Enumerate.new: st.comb.iterator, $start
}

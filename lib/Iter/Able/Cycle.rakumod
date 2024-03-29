#| Repeats the stream indefinitely. Returns a Seq for strings.
#`{
    >>> [1, 2, 3].&cycle.head(5)
    (1, 2, 3, 1, 2).Seq

    >>> "real".&cycle.head(9)
    ("r", "e", "a", "l", "r", "e", "a", "l", "r").Seq
}
unit module Cycle;

use nqp;

my class Cycle does Iterator {
    has Mu $!iter;     #= Passed iterator

    has $!values;      #= State: holds 1 full cycle
    has int $!index;   #= State: index into the cycle
    has int $!length;  #= State: length of the cycle to use in `index % length`

    method !SET-SELF($!iter) {
        $!index  = -1;
        $!values := nqp::list();
        self
    }

    method new(\iterator) {
        nqp::create(self)!SET-SELF(iterator)
    }

    method pull-one {
        nqp::if(
            # Is the iterable exhausted?
            nqp::isge_i($!index, 0) || nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
            # Yes; yield from $!values now on if it's not empty,
            # i.e., if the original iterable wasn't empty
            nqp::if(
                nqp::isgt_i($!length, 0),
                $!values[nqp::mod_i(($!index = nqp::add_i($!index, 1)), $!length)],
                IterationEnd
            ),
            # No; store and yield it
            nqp::stmts(
                nqp::push($!values, $next),
                ($!length = nqp::add_i($!length, 1)),
                $next
            )
        )
    }

    method is-lazy { $!iter.is-lazy }
    method Seq     { Seq.new(self)  }
}

our proto cycle(\ist) is export {*}

multi cycle(Iterable:D \it --> Seq:D) {
    Seq.new: Cycle.new: it.iterator
}
multi cycle(Iterator:D \it --> Cycle:D) {
    Cycle.new: it
}
multi cycle(Str:D \st --> Seq:D) {
    Seq.new: Cycle.new: st.comb.iterator
}

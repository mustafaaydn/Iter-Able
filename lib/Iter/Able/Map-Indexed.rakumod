#| (index, element) pair is passed to the transformer; by default `index` starts from 0.
#| The transformer is expected to have arity of 2 (or count of Inf).
#`{
    # Produce new items as `index * element`
    >>> [3, 2, 1].&map-indexed(* * *)
    (0, 2, 2)

    # `index + element` as kind of an added ramp and also start from 1
    >>> (4, 7, 12, -3).&map-indexed(* + *, start => 1)
    (5, 9, 16, 1)

    # Repeat a character as many as its position suggests
    >>> "train".&map-indexed(* Rx *, start => 1)
    ("t", "rr", "aaa", "iiii", "nnnnn")
}
unit module Map-Indexed;

use nqp;

my class MapIndexed does Iterator {
	has Mu $!iter;    #= Passed iterable's iterator
    has &!mapper;     #= Transformer

    has int $!index;  #= State: current index

    method !SET-SELF($!iter, &!mapper, $!index) { self }

    method new(\iterable, \mapper, $start) {
        # `$start - 1` instead of `$start` to ease increasing of `$!index`
        # also \start did not work due to clash with the built-in function.
		nqp::create(self)!SET-SELF(iterable.iterator, mapper, $start - 1)
    }

    method pull-one {
        nqp::if(
			# Is the iterable exhausted?
    	    nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
			# Yes; signal
            IterationEnd,
			# No; transform: (index, element)
            &!mapper(($!index = nqp::add_i($!index, 1)), $next)
        )
    }

    method is-lazy() { $!iter.is-lazy }
}

our proto map-indexed(\ist, &mapper = {@_.List}, :$start = 0) is export {*}

multi map-indexed(Iterable \it, &mapper = {@_.List}, :$start = 0) {
    Seq.new: MapIndexed.new: it, &mapper, $start
}

multi map-indexed(Str \st, &mapper = {@_.List}, :$start = 0) {
    Seq.new: MapIndexed.new: st.comb, &mapper, $start
}
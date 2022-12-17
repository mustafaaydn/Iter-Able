#| If an element satisfies the predicate, transform it; else, keep as is.
#`{
    # If nonpositive, make it cubed
    >>> [1, -2, 3, 0, 4, -5].&map-when(* <= 0, * ** 3)
    (1, -8, 3, 0, 4, -125)

    # Take the square root only if positive
    >>> (4, -7, 9, 0).&map-when(* > 0, &sqrt)
    (2, -7, 3, 0)

    # Make vowels upper case
    >>> "mixed feelings".&map-when(/:i <[aeiou]>/, &uc).raku
    "mIxEd fEElIngs"

    # Normalize "anomalies"
    >>> (r1 => 7.13, r2 => 6.89, r3 => 7.90, r4 => 6.61).&map-when((*.value - 7).abs >= 0.2, {7})
    (r1 => 7.13, r2 => 6.89, r3 => 7, r4 => 7)
}
unit module Map-When;

use nqp;

my class MapWhen does Iterator {
	has Mu $!iter;      #= Passed iterable's iterator
    has &!pred;	        #= Predicate
    has &!mapper;       #= Transformer

    method !SET-SELF($!iter, &!pred, &!mapper) { self }

    method new(\iterable, \pred, \mapper) {
		nqp::create(self)!SET-SELF(iterable.iterator, pred, mapper)
    }

    method pull-one {
        nqp::if(
			# Is the iterable exhausted?
    	    nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
			# Yes; signal
            IterationEnd,
			# No; go on
            nqp::if(
                &!pred($next),
                &!mapper($next),
                $next,
            )
        )
    }

    method is-lazy() { $!iter.is-lazy }
}

our proto map-when(\ist, &pred = {$_}, &mapper = {$_}) is export {*}

multi map-when(Iterable \it, &pred = {$_}, &mapper = {$_}) {
    Seq.new: MapWhen.new: it, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred), &mapper
}

multi map-when(Str \st, &pred = {$_}, &mapper = {$_}) {
    join "", Seq.new: MapWhen.new: st.comb, (&pred ~~ Regex ?? (* ~~ &pred).so !! &pred), &mapper
}

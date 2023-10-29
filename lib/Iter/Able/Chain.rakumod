#| Yields from this iterable first; when exhausted, from the next one
#| in the chain, and so on. Returns a Seq for strings.
#`{
    # Accepts any number of iterables
    >>> [-1, -2, -3].&chain([4, 5], [-6])
    (-1, -2, -3, 4, 5, -6).Seq

    # Infinity chaining
    >>> [1, 2].&chain(3 xx *).head(5)
    (1, 2, 3, 3, 3).Seq

    # Can chain to strings
    >>> "get".&chain("attr")
    ("g", "e", "t", "a", "t", "t", "r").Seq

    # Can chain with strings
    >>> (4, 7).&chain("spa")
    (4, 7, "s", "p", "a").Seq

    # Another way of (one-level) flattening a list of lists
    >>> chain |[[4, 7], [6], [0, 8, 9]]
    (4, 7, 6, 0, 8, 9).Seq
}
unit module Chain;

use nqp;

my class Chain does Iterator {

    has $!iter;       #= State: Current iterator
    has $!iters;      #= State: Iterators of the iterables to chain with
    has int $!index;  #= State: Current index for the current iterable

    method !SET-SELF($iter, @iters) {
        $!iter  := $iter;
        $!iters := nqp::getattr(@iters, List, '$!reified');
        $!index  = -1;
        self
    }

    method new(\iterator, @iterators) {
        nqp::create(self)!SET-SELF(iterator, @iterators.Array)
    }

    method pull-one {
        nqp::if(
            nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd),
            nqp::if(
                nqp::iseq_i(($!index = nqp::add_i($!index, 1)), nqp::elems($!iters)),
                IterationEnd,
                nqp::stmts(
                    ($!iter := nqp::atpos($!iters, $!index)),
                    self.pull-one
                )
            ),
            $next
        )
    }

    method is-lazy { $!iter.is-lazy }
    method Seq     { Seq.new(self)  }  # isn't really needed but here for consistency
}

use Iter::Able::Map-When;

our sub chain(\ist, **@iters --> Seq:D) is export {
    # Returns Seq even for Iterator inputs because they can be mixed with non-Iterators
    die "Iterable, Iterator or Str expected, got {ist.^name}"
        unless ist ~~ Iterable | Str | Iterator;
    die "No other Iterable/Str/Iterator passed to chain with"
        unless @iters;
    die "Non-Iterable/Str/Iterator found at $_\'th index; cannot chain"
        with @iters.first(* !~~ Iterable | Str | Iterator, :k);

    Seq.new:
        Chain.new:
            (ist ~~ Str ?? ist.comb.iterator !! (ist ~~ Iterable ?? ist.iterator !! ist)),
            @iters.&map-when(* ~~ Str, *.comb.iterator).&map-when(* ~~ Iterable, *.iterator)
}

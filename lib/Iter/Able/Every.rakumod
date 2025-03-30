#| Check if every element (all of them) satisfies the given predicate.
#| It has a short-circuiting behaviour, i.e., if a non-satisfactory element is found, traversal immediately stops.
#| `all` would be a better name but it's taken.
#`{
    # All positive elements?
    >>> [-4, 0, 5, 2, -8].&every(* > 0)
    False

    # Everyone is prime?
    >>> every &is-prime, [191, 211, 911]
    True

    # Default predicate is truthfulness
    >>> every (-5, +5, [3, 4])
    True

    # Stops once it finds a failing element
    >>> every (4, |(5 xx *)), * == 4
    False

    # Empty input yields True vacuously, regardless of the predicate
    >>> every []
    True

    # Strings are also accepted as inputs
    >>> "thereisnospacehere".&every(/ \S /)
    True
}
unit module Every;

our proto every(\ist, &pred = {$_} --> Bool:D) is export {*}

multi every(Iterable:D \it, &pred = {$_} --> Bool:D) { it.grep({ $_ !~~ &pred }).not }

multi every(Iterator:D \it, &pred = {$_} --> Bool:D) { Seq.new(it).grep({ $_ !~~ &pred }).not }

multi every(Str:D \st, &pred = {$_} --> Bool:D) { st.comb.grep({ $_ !~~ &pred }).not }

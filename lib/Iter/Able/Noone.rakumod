#| Check if none of the elements (noone, not any) satisfies the given predicate.
#| It has a short-circuiting behaviour, i.e., if a satisfactory element is found, traversal immediately stops.
#| `none` would be a better name but it's taken.
#`{
    # No positive elements?
    >>> [-4, 0, 5, 2, -8].&noone(* > 0)
    False

    # No-one is prime?
    >>> noone &is-prime, [9, 99, 999]
    True

    # Default predicate is truthfulness
    >>> noone ([], "", Empty)
    True

    # Stops once it finds a failing element
    >>> noone (4, |(5 xx *)), * == 5
    False

    # Empty input yields True vacuously, regardless of the predicate
    >>> noone []
    True

    # Strings are also accepted as inputs
    >>> "thereisnospacehere".&noone(/ \s /)
    True
}
unit module Noone;

our proto noone(\ist, &pred = {$_} --> Bool:D) is export {*}

multi noone(Iterable:D \it, &pred = {$_} --> Bool:D) { it.grep(&pred).not }

multi noone(Iterator:D \it, &pred = {$_} --> Bool:D) { Seq.new(it).grep(&pred).not }

multi noone(Str:D \st, &pred = {$_} --> Bool:D) { st.comb.grep(&pred).not }

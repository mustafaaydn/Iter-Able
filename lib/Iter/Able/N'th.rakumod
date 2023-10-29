#| Yields the n'th value of the input. Almost the same as =.[n]= but
#| also works for iterators and strings. Negative indexes are also
#| allowed so long as the input isn't lazy (i.e., possibly
#| infinite). Returns a single value, or dies if the index is
#| out-of-bounds (if it's a List-like, i.e., the bounds are easily
#| measurable).
#`{
    # Works as usual for nonnegative `n` on Arrays
    >>> [0, 1, 2].&n'th(1)
    2

    # Can pass a negative index
    >>> (4, 7, 12, 0).&n'th(-3)
    7

    # Strings are indexable as well
    >>> "regard".&n'th(5).raku
    "d"

    # Strings from the other side
    >>> "yes".&n'th(-2)
    "e"

    # Out-of-bounds requests result in error *if* List-like
    >>> n'th (5, 12, 13), 29
    n = 29 is out of bounds for size 3
      in block...

    # On iterators
    >>> my \it = [4, 5, 6].iterator;
    >>> print it.&n'th(0), " " for ^3
    4 5 6
}
unit module Nth;

our proto n'th(\ist, Int $n) is export {
    die "Cannot perform negative indexing on lazy input but received n = $n"
        if $n < 0 && ist.is-lazy;

    unless ist.is-lazy {
        die "n = $n is out of bounds for size $_"
            if ist ~~ List && not -$_ <= $n < $_
                given ist.elems
    }
    {*}
}

multi n'th(Iterable \it, $n) {
    $n < 0
        ?? it.tail(-$n).head
        !! it.skip($n).head
}

multi n'th(Iterator \it, $n) {
    n'th Seq.new(it), $n
}

multi n'th(Str \st, $n) {
    my $length = st.chars;
    die "n = $n is out of bounds for size {st.chars}"
        unless $n ~~ -$length .. $length.pred;
    st.substr(($n + $length) mod $length, 1)
}

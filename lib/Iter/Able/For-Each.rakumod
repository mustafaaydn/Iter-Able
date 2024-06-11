#| Apply the given function to each element for the side effects.
#| Returns =Nil= to signal return values are ignored.
#`{
    # Change the value of an attribute of a group of objects
    >>> @paddles.&for-each({ .x++ })

    # Print the primes
    >>> (4, 7, 12, -3).&for-each: { .put if .is-prime }

    # Works for strings too should you want
    >>> "a lot of characters".&for-each: { .ord.put }
}
unit module For-Each;

our proto for-each(\ist, &function --> Nil) is export {*}

multi for-each(Iterable:D \it, &function --> Nil) {
    it.map(&function).sink
}

multi for-each(Iterator:D \it, &function --> Nil) {
    Seq.new(it).map(&function).sink
}

multi for-each(Str:D \st, &function --> Nil) {
    st.comb.map(&function).sink
}

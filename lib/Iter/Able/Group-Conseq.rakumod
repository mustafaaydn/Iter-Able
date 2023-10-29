#| Packs consecutive "same" elements together and yields "key ⇒ group"
#| pairs where groups are Lists (values are not copied). Sameness can
#| be controlled with a transformer (=as=) and/or an equality checker
#| (=with=). Returns a Seq for strings.
#`{
    # Elements themselves are the groupers by default
    >>> [3, 4, 4, 5, 4].&group-conseq
    (3 => (3,), 4 => (4, 4), 5 => (5,), 4 => (4,))

    # Group consecutive records together; any duplicate key might be anomaly
    >>> [("A", 1), ("B", 1), ("D", 2), ("E", 1)].&group-conseq(:as(*[1]))
    (1 => (("A", 1), ("B", 1)), 2 => (("D", 2),), 1 => (("E", 1),)

    # They are all the same, really
    >>> [1, -1, 1, -1, 1, -1].&group-conseq(as => &abs)
    (1 => (1, -1, 1, -1, 1, -1))

    # Respect the container for sameness
    >>> my $a = 7
    >>> ($a, $a, 7).&group-conseq(with => &[=:=])
    (7 => (7, 7), 7 => (7,))

    # Case insensitive detection of consecutive duplicates in a string; typos?
    >>> my $s = "how aree youU?"
    >>> $s.&group-conseq(as => &lc).grep(*.value > 1)
    (e => (e, e), u => (u, U))
}
unit module Group-Conseq;

use nqp;

my class GroupConseq does Iterator {
    has Mu $!iter;  #= Passed iterator
    has &!as;       #= Transformer function
    has &!with;     #= Comparison operator

    has $!curr;     #= State: current value
    has $!group;    #= State: current group

    method !SET-SELF($!iter, &!as, &!with) {
        $!curr := nqp::null();
        $!group := nqp::list();
        self;
    }

    method new(\iterator, \as, \with) {
        nqp::create(self)!SET-SELF(iterator, as, with)
    }

    method pull-one {
        # nqp::ifnull instead warns
        nqp::if(
            nqp::isnull($!curr),
            ($!curr := $!iter.pull-one)
        );
        nqp::if(
            nqp::eqaddr($!curr, IterationEnd),
            IterationEnd,
            nqp::stmts(
                (my $now),                     # Transformed current
                nqp::push($!group, $!curr),    # Initiate a group
                nqp::until(
                    nqp::eqaddr((my $next := $!iter.pull-one), IterationEnd)
                        || nqp::isfalse(&!with(($now := &!as($!curr)), &!as($next))),
                    nqp::stmts(
                        ($!curr := $next),
                        nqp::push($!group, $next),
                    ),
                ),
                # `until` ended: either future differed, or end-of-iterable
                (my $rv),
                nqp::if(
                    nqp::eqaddr($next, IterationEnd),
                    nqp::stmts(
                        ($rv := Pair.new(&!as($!curr), $!group)),
                        ($!curr := $next),
                        $rv
                    ),
                    nqp::stmts(
                        ($rv := Pair.new($now, $!group)),
                        ($!curr := $next),
                        ($!group := nqp::list()),
                        $rv
                    ),
                ),
            ),
        );
    }
    method is-lazy   { $!iter.is-lazy }
    method Seq       { Seq.new(self)  }
}

our proto group-conseq(\ist, :&as = {$_}, :&with = &[===]) is export {*}

multi group-conseq(Iterable \it, :&as = {$_}, :&with = &[===]) {
    Seq.new: GroupConseq.new: it.iterator, (&as ~~ Regex ?? (* ~~ &as).so !! &as), &with
}

multi group-conseq(Iterator \it, :&as = {$_}, :&with = &[===]) {
    GroupConseq.new: it, (&as ~~ Regex ?? (* ~~ &as).so !! &as), &with
}

multi group-conseq(Str \st, :&as = {$_}, :&with = &[===]) {
    Seq.new: GroupConseq.new: st.comb.iterator, (&as ~~ Regex ?? (* ~~ &as).so !! &as), &with
}

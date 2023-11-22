#= Read the leading comment section of each .rakumod file in lib/Iter/Able,
#= and embed that into README.org.
use lib "lib";
use Iter::Able;  # for signatures
use Iter::Able::Map-Last;
use Iter::Able::Take-While;

my Bool $verbose = so (@*ARGS[0] // "") eq "-v" | "--verbose";
sub report(Str $msg) { put $msg if $verbose }

my Str $template = q:to/END/;
**** %s =%s=
%s
#+begin_src raku
%s
#+end_src
END

my Str @docs;
for dir("lib/Iter/Able", test => /^^ <-[.#]>+ '.rakumod' $$/) -> $module {
    report "Processing $module...";

    my Str $fun-name  = $module.basename.split(".")[0].lc;
    my Str $signature = $module.lines[Iter::Able::{"\&$fun-name"}.line.pred].comb(/ '(' .* ')' <?before ' '* 'is export'> /).head;
    report "\tFunction \"$fun-name\"\n\tSignature $signature";

    my \it = $module.lines.iterator;
    my Str $explanation = it.&take-while(*.starts-with("#|")).Seq.map(*.subst(/^'#|' ' '*/)).join(" ").subst("  ", " ", :g);
    my Str $examples    = it.&take-while(not *.starts-with("unit module")).Seq.head(*-1).join("\n");
    @docs.push: sprintf($template, $fun-name, $signature, $explanation, $examples);
}

my Str $doc-file = "README.org";
my Str @lines = $doc-file.IO.lines;
my Int $start-pos = @lines.first(/^ '# START-DOC' /, :k);
my Int $end-pos   = @lines.first(/^ '# END-DOC' /, :k);
@lines.splice($start-pos.succ, $end-pos - $start-pos.succ, |@docs.&map-last({True}, &trim-trailing));
$doc-file.IO.spurt: @lines.join("\n");
say "Wrote $doc-file";

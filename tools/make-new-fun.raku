#= Generates lib/Iter/Able/*.rakumod and t/*.rakutest files for a new function.
#= Also inserts the corresponding `use` statement to the toplevel module.

# Ask for the new function name and prepare Module and Class names properly
my Str $fun-name = prompt "name (sep. with `-`): ";
my (Str $module-name, Str $class-name);
given $fun-name.split("-")>>.tc {
    $module-name = .join("-");
    $class-name  = .join;
}

my &translate = {
    .subst("fun-name",    $fun-name,    :g)
    .subst("Module-Name", $module-name, :g)
    .subst("ClassName",   $class-name,  :g)
};

# Module file
my IO::Path $new-mod-path = "lib/Iter/Able/$module-name.rakumod".IO;
if $new-mod-path.e {
    my $ans = prompt "$new-mod-path already exists; override? (Y/n) ";
    exit(0) unless $ans.contains("y", :i) || $ans.not;
}
$new-mod-path.spurt: "tools/module.template".IO.slurp.&translate;

# Test file
my Str $test-no = 
    ((my $d = dir("t").cache).first(/ ^ $fun-name $ /)
        andthen .Str.comb(/\d+/).head                     # already exists
        orelse $d.sort.tail.Str.comb(/\d+/).head.succ);   # anew
my IO::Path $new-test-path = "t/{$test-no}-{$fun-name}.rakutest".IO;
$new-test-path.spurt: "tools/tester.template".IO.slurp.&translate;

say "\nWrote\n$new-mod-path\n$new-test-path";

# Put `use` in top-level module
my IO::Path $top-level-mod = "lib/Iter/Able.rakumod".IO;
my Str @lines   = $top-level-mod.lines(:!chomp);
my Int $idx     = @lines.first(/^ 'use Iter::Able::' /, :end, :k).succ;
my Str $new-use = "use Iter::Able::$module-name;\n\n"; 
@lines.splice($idx, 1, $new-use);
$top-level-mod.spurt: @lines.join;

say "\nAdded `{$new-use.trim-trailing}` to $top-level-mod";


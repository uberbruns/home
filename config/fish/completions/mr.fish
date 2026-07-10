set -l tmpdir (if set -q TMPDIR; echo $TMPDIR; else; echo /tmp; end)
set -l spec_file "$tmpdir/usage__usage_spec_mise.spec"
if not test -f "$spec_file"
  mise usage 2>/dev/null | string collect > "$spec_file"
end

if commandline -x >/dev/null 2>&1
  complete -xc mr -a "(command usage complete-word --shell fish -f \"$spec_file\" -- mise run (commandline -xpc)[2..] (commandline -t))"
else
  complete -xc mr -a "(command usage complete-word --shell fish -f \"$spec_file\" -- mise run (commandline -opc)[2..] (commandline -t))"
end

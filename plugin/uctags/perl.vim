" File:         perl.vim
" Last Change:  06/05/2019
" Maintainer:   FrancescoMagliocco

if (exists('g:uctags_enabled') && !g:uctags_enabled)
      \ || !exists('g:loaded_uctags')
      \ || exists('g:loaded_uctags_perl')
  finish
endif
let g:loaded_uctags_perl   = 1

if has('perl')
  function! DefPerl()
    perl << EOF
      use List::Util qw(first none any);
      use Data::Munge qw(list2re);
      use warnings;
      my %trans = (
          '\%\(' => '(?:',
          '\('   => '(',
          '\)'   => ')',
          '\|'   => '|',
          '\.'   => '.',
          # Do these need to be escaped?
          '\<'   => '\\b',
          '\>'   => '\\b',
          '\ze'  => '',
          '\zs'  => '',

          '('    => '\\(',
          ')'    => '\\)',
          '|'    => '\\|',
          '.'    => '\\.',
      );

      sub UpdateSyn {
        my ($arg) = @_;
        my $file = VIM::Eval("expand('%')");

        # syn file for the current Vim buffer
        open(BUFSYN, "<", "$file.syn");
        my @buf = <BUFSYN>;
        
        #my $so = VIM::Eval('a:1');
        open(INSYN, "<", "$arg");
        #open(my $in_syn, "<", VIM::Eval('a:1'));
        my @lines =  $curbuf->Get(1 .. VIM::Eval('line("$")'));
        while (my $line = <INSYN>) {
          my $str = +(split(' ', $line))[-1];
          $str = substr($str, 1, -1);
          my $re = list2re keys %trans;
          $str =~ s/($re)/$trans{$1}/g;
            next if none { m/$str/g } @lines;
            next if any {$_ eq $line} @buf;
            push @buf, $line;
        }

        close BUFSYN;
        open(OUTSYN, ">", "$file.syn");
        foreach (@buf) {
          print OUTSYN $_;
          }
        close(OUTSYN);
        close INSYN;
        }

      use warnings;
      sub GetTags {
        my $tag_file = VIM::Eval('g:uctags_tags_file');
        open(my $tags, "<", $tag_file)
          or die "Couldn't open '$tag_file' $!";

        my @lines = ();
        while (my $line = <$tags>) {
          next if $line =~ /^!_TAG/;
          chomp $line;
          push @lines, [split(/\t/, $line)];
        }

        return @lines;
      }

      sub GetTagsVim {
        my $tag_file = VIM::Eval('g:uctags_tags_file');
        open(my $tags, "<", $tag_file)
          or die "Couldn't open '$tag_file' $!";
        my @lines;
        while (my $line = <$tags>) {
          next if $line =~ /^!_TAG/;
          chomp $line;
          my @cols = split /\t/, $line;
          s/'/''/g for @cols;
          push @lines, '[' . join(', ', map { "'$_'" } @cols) . ']';
          #push @lines, '[' . join(', ', map { "'$_'" } (s/'/''/gr for split(/ t/, $line)));
        }

        my $x = '[' . join(', ', @lines) . ']';
        VIM::DoCommand("return $x");
      }
EOF
  endfunction
  call DefPerl()
endif
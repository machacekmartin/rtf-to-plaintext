#!/usr/bin/env perl
use strict;
use warnings;
use Encode;

binmode STDOUT, ":encoding(UTF-8)";
binmode STDIN,  ":encoding(UTF-8)";

sub extract {
    my ($rtf) = @_;

    my $pattern = qr{
        \\([a-z]{1,32})(-?\d{1,10})?[ ]?
        |\\'([0-9a-f]{2})
        |\\([^a-z])
        |([{}])
        |[\r\n]+
        |(.)
    }ix;

    my %destinations = map { $_ => 1 } qw(
        aftncn aftnsep aftnsepc annotation atnauthor atndate atnicn atnid
        atnparent atnref atntime atrfend atrfstart author background
        bkmkend bkmkstart blipuid buptim category colorschememapping
        colortbl comment company creatim datafield datastore defchp defpap
        do doccomm docvar dptxbxtext ebcend ebcstart factoidname falt
        fchars ffdeftext ffentrymcr ffexitmcr ffformat ffhelptext ffl
        ffname ffstattext field file filetbl fldinst fldrslt fldtype
        fname fontemb fontfile fonttbl footer footerf footerl
        footerr footnote formfield ftncn ftnsep ftnsepc g generator
        gridtbl header headerf headerl headerr hl hlfr hlinkbase
        hlloc hlsrc hsv htmltag info keycode keywords latentstyles
        lchars levelnumbers leveltext lfolevel linkval list listlevel
        listname listoverride listoverridetable listpicture liststylename
        listtable listtext lsdlockedexcept macc maccPr mailmerge maln
        malnScr manager margPr mbar mbarPr mbaseJc mbegChr mborderBox
        mborderBoxPr mbox mboxPr mchr mcount mctrlPr md mdeg mdegHide
        mden mdiff mdPr me mendChr meqArr meqArrPr mf mfName mfPr
        mfunc mfuncPr mgroupChr mgroupChrPr mgrow mhideBot mhideLeft
        mhideRight mhideTop mhtmltag mlim mlimloc mlimlow mlimlowPr
        mlimupp mlimuppPr mm mmaddfieldname mmath mmathPict mmathPr
        mmaxdist mmc mmcJc mmconnectstr mmconnectstrdata mmcPr mmcs
        mmdatasource mmheadersource mmmailsubject mmodso mmodsofilter
        mmodsofldmpdata mmodsomappedname mmodsoname mmodsorecipdata mmodsosort
        mmodsosrc mmodsotable mmodsoudl mmodsoudldata mmodsouniquetag
        mmPr mmquery mmr mnary mnaryPr mnoBreak mnum mobjDist moMath
        moMathPara moMathParaPr mopEmu mphant mphantPr mplcHide mpos
        mr mrad mradPr mrPr msepChr mshow mshp msPre msPrePr msSub
        msSubPr msSubSup msSubSupPr msSup msSupPr mstrikeBLTR mstrikeH
        mstrikeTLBR mstrikeV msub msubHide msup msupHide mtransp mtype
        mvertJc mvfmf mvfml mvtof mvtol mzeroAsc mzeroDesc mzeroWid
        nesttableprops nextfile nonesttables objalias objclass objdata
        object objname objsect objtime oldcprops oldpprops oldsprops
        oldtprops oleclsid operator panose password passwordhash pgp
        pgptbl picprop pict pn pnseclvl pntext pntxta pntxtb printim
        private propname protend protstart protusertbl pxe result
        revtbl revtim rsidtbl rxe shp shpgrp shpinst
        shppict shprslt shptxt sn sp staticval stylesheet subject sv
        svb tc template themedata title txe ud upr userprops
        wgrffmtfilter windowcaption writereservation writereservhash xe xform
        xmlattrname xmlattrvalue xmlclose xmlname xmlnstbl xmlopen
    );

    my %specialchars = (
        par       => "\n",
        sect      => "\n\n",
        page      => "\n\n",
        line      => "\n",
        tab       => "\t",
        emdash    => "\x{2014}",
        endash    => "\x{2013}",
        emspace   => "\x{2003}",
        enspace   => "\x{2002}",
        qmspace   => "\x{2005}",
        bullet    => "\x{2022}",
        lquote    => "\x{2018}",
        rquote    => "\x{2019}",
        ldblquote => "\x{201C}",
        rdblquote => "\x{201D}",
    );

    my @stack;
    my $ignorable = 0;
    my $ucskip    = 1;
    my $curskip   = 0;
    my @out;
    my @hex_buffer;

    my $flush_hex_buffer = sub {
        if (@hex_buffer) {
            my $bytes = pack('C*', @hex_buffer);
            my $decoded;
            eval {
                $decoded = Encode::decode('cp1250', $bytes);
                1;
            } or do {
                $decoded = Encode::decode('latin1', $bytes);
            };
            push @out, $decoded;
            @hex_buffer = ();
        }
    };

    while ($rtf =~ /$pattern/g) {
        my ($word, $arg, $hexchar, $char, $brace, $tchar) = ($1, $2, $3, $4, $5, $6);

        if (defined $brace) {
            $flush_hex_buffer->();
            $curskip = 0;
            if ($brace eq '{') {
                push @stack, [$ucskip, $ignorable];
            } elsif ($brace eq '}') {
                ($ucskip, $ignorable) = @{pop @stack};
            }
        }
        elsif (defined $char) {
            $flush_hex_buffer->();
            $curskip = 0;
            if ($char eq '~') {
                push @out, "\x{A0}" unless $ignorable;
            }
            elsif ($char =~ /[{}\\]/) {
                push @out, $char unless $ignorable;
            }
            elsif ($char eq '*') {
                $ignorable = 1;
            }
        }
        elsif (defined $word) {
            $flush_hex_buffer->();
            $curskip = 0;
            if (exists $destinations{$word}) {
                $ignorable = 1;
            }
            elsif ($ignorable) {
                # skip
            }
            elsif (exists $specialchars{$word}) {
                push @out, $specialchars{$word};
            }
            elsif ($word eq 'uc') {
                $ucskip = int($arg);
            }
            elsif ($word eq 'u') {
                my $c = int($arg);
                $c += 0x10000 if $c < 0;
                push @out, chr($c) unless $ignorable;
                $curskip = $ucskip;
            }
        }
        elsif (defined $hexchar) {
            if ($curskip > 0) {
                $curskip--;
            }
            elsif (!$ignorable) {
                push @hex_buffer, hex($hexchar);
            }
        }
        elsif (defined $tchar) {
            $flush_hex_buffer->();
            if ($curskip > 0) {
                $curskip--;
            }
            elsif (!$ignorable) {
                push @out, $tchar;
            }
        }
    }

    $flush_hex_buffer->();

    my $result = join('', @out);
    $result =~ s/^\s+//;  # Remove leading whitespace
    return $result;
}

# Read full STDIN
my $input = $ARGV[0];

print extract($input);

package Calendar::Persian;

use strict; use warnings;

=head1 NAME

Calendar::Persian - Interface to Persian Calendar.

=head1 VERSION

Version 0.02

=cut

our $DEBUG   = 0;
our $VERSION = '0.02';

use Carp;
use Readonly;
use Data::Dumper;
use Time::localtime;
use POSIX qw/floor ceil/;
use Date::Calc qw/Delta_Days Day_of_Week Add_Delta_Days/;

Readonly my $GREGORIAN_EPOCH => 1721425.5;
Readonly my $PERSIAN_EPOCH   => 1948320.5;

Readonly my $MONTHS =>
[
    '',
    'Farvardin',  'Ordibehesht',  'Khordad',  'Tir',  'Mordad',  'Shahrivar',
    'Mehr'     ,  'Aban'       ,  'Azar'   ,  'Dey',  'Bahman',  'Esfand'
];

Readonly my $DAYS =>
[
    'Yekshanbeh',  'Doshanbeh', 'Seshhanbeh', 'Chaharshanbeh',
    'Panjshanbeh', 'Jomeh',     'Shanbeh'
];

sub new 
{
    my $class = shift;
    my $yyyy  = shift;
    my $mm    = shift;
    my $dd    = shift;
    
    my $self  = {};
    bless $self, $class;
    
    if (defined($yyyy) && defined($mm) && defined($dd))
    {
        _validate_date($yyyy, $mm, $dd)
    }
    else
    {
        my $today = localtime; 
        $yyyy = ($today->year+1900) unless defined $yyyy;
        $mm = ($today->mon+1) unless defined $mm;
        $dd = $today->mday unless defined $dd;
        ($yyyy, $mm, $dd) = $self->from_gregorian($yyyy, $mm, $dd);
    }

    $self->{yyyy} = $yyyy;
    $self->{mm}   = $mm;
    $self->{dd}   = $dd;

    return $self;
}

=head1 SYNOPSIS

The  Persian  calendar  is  solar, with the particularity that the year is defined by two successive,
apparent passages of the Sun through the vernal (spring) equinox. It is based on precise astronomical
observations,  and  moreover  uses a sophisticated intercalation system, which makes it more accurate
than  its  younger  European counterpart, the Gregorian calendar. It is currently used in Iran as the
official  calendar  of the country.  The starting point of the current Iranian calendar is the vernal
equinox occurred on Friday March 22 of the year A.D. 622.

=head2 Persian Calendar for the month of Farvadin year 1390.

            Farvardin [1390]

    Sun  Mon  Tue  Wed  Thu  Fri  Sat
           1    2    3    4    5    6
      7    8    9   10   11   12   13
     14   15   16   17   18   19   20
     21   22   23   24   25   26   27
     28   29   30   31

=head2 Months Names

    Order     Modern Persian Name
    1         Farvardin
    2         Ordibehesht
    3         Xordad
    4         Tir
    5         Amordad
    6         Sahrivar
    7         Mehr
    8         Aban
    9         Azar
    10        Dey
    11        Bahman
    12        Esfand

=head2 Weekdays

    Number   Gregorian    Persian
    0        Sunday       Yekshanbeh
    1        Monday       Doshanbeh
    2        Tuesday      Seshhanbeh
    3        Wednesday    Chaharshanbeh
    4        Thursday     Panjshanbeh
    5        Friday       Jomeh
    6        Saturday     Shanbeh

=head1 METHODS

=head2 to_gregorian(yyyy, mm, dd)

Converts Persian date to Gregorian date.

    use Calendar::Persian;

    my $persian = Calendar::Persian->new();
    my ($yyyy, $mm, $dd) = $persian->to_gregorian();

=cut

sub to_gregorian
{
    my $self = shift;
    my $yyyy = shift;
    my $mm   = shift;
    my $dd   = shift;

    $yyyy = $self->{yyyy} unless defined $yyyy;
    $mm   = $self->{mm}   unless defined $mm;
    $dd   = $self->{dd}   unless defined $dd;

    _validate_date($yyyy, $mm, $dd);

    print {*STDOUT} "Persian: YYYY [$yyyy] MM [$mm] DD [$dd]\n" if $DEBUG;

    my $julian = _to_julian($yyyy, $mm, $dd);
    ($yyyy, $mm, $dd) =  _julian_to_gregorian($julian); 

    print {*STDOUT} "Gregorian: YYYY [$yyyy] MM [$mm] DD [$dd]\n" if $DEBUG;

    return ($yyyy, $mm, $dd);
}

=head2 from_gregorian(yyyy, mm, dd)

Converts given Gregorian date to Persian date.

    use Calendar::Persian;

    my $persian = Calendar::Persian->new();
    my ($yyyy, $mm, $dd) = $persian->from_gregorian(2011, 3, 22);

=cut

sub from_gregorian
{
    my $self = shift;
    my $yyyy = shift;
    my $mm   = shift;
    my $dd   = shift;

    _validate_date($yyyy, $mm, $dd);

    print {*STDOUT} "Gregorian: YYYY [$yyyy] MM [$mm] DD [$dd]\n" if $DEBUG;

    my $julian = _gregorian_to_julian($yyyy, $mm, $dd) + (floor(0 + 60 * (0 + 60 * 0) + 0.5) / 86400.0);

    ($yyyy, $mm, $dd) = _from_julian($julian);

    print {*STDOUT} "Persian: YYYY [$yyyy] MM [$mm] DD [$dd]\n" if $DEBUG;

    return ($yyyy, $mm, $dd);
}

=head2 is_leap(yyyy)

Checks if the given year in Persian calendar is a leap year or not. Return 1 or 0
depending whether it is a leap year or not.

    use Calendar::Persian;

    my $persian = Calendar::Persian->new();
    my $is_leap_year = $persian->is_leap(1389);

=cut

sub is_leap
{
    my $self = shift;
    my $yyyy = shift;

    return (((((($yyyy - (($yyyy > 0) ? 474 : 473)) % 2820) + 474) + 38) * 682) % 2816) < 682;
}

=head2 as_string()

Return Persian date in human readable format.

    use strict; use warnings;
    use Calendar::Persian;

    my $persian = Calendar::Persian->new(1389, 9, 16);
    print "Persian date is " . $persian->as_string() . "\n";

=cut

sub as_string
{
    my $self = shift;
    return sprintf("%02d, %s %04d", $self->{dd}, $MONTHS->[$self->{mm}], $self->{yyyy});
}

=head2 dow(yyyy, mm, dd)

Get day of the week of the given Persian date, starting with sunday (0).

    use strict; use warnings;
    use Calendar::Persian;

    my $persian = Calendar::Persian->new();
    print "Day of the week; [" . $persian->dow() . "]\n";

=cut

sub dow
{
    my $self = shift;

    my $yyyy = shift;
    my $mm   = shift;
    my $dd   = shift;

    $yyyy = $self->{yyyy} unless defined $yyyy;
    $mm   = $self->{mm}   unless defined $mm;
    $dd   = $self->{dd}   unless defined $dd;

    _validate_date($yyyy, $mm, $dd);

    return _julian_dow(_to_julian($yyyy, $mm, $dd));
}

=head2 today()

Return today's date is Persian calendar as list in the format yyyy,mm,dd.

    use strict; use warnings;
    use Calendar::Persian;

    my $persian = Calendar::Persian->new();
    my ($yyyy, $mm, $dd) = $persian->today();
    print "Year [$yyyy] Month [$mm] Day [$dd]\n";

=cut

sub today
{
    my $self  = shift;
    my $today = localtime; 
    return $self->from_gregorian($today->year+1900, $today->mon+1, $today->mday);
}

=head2 days_in_year_month(yyyy, mm)

Return number of days in the given year and month of Persian calendar.

    use strict; use warnings;
    use Calendar::Persian;

    my $persian = Calendar::Persian->new(1932,12,26);
    print "Days is Phalguna 1932: [" . $persian->days_in_year_month() . "]\n";

    print "Days is Chaitra 1932: [" . $persian->days_in_year_month(1932,1) . "]\n";

=cut

sub days_in_year_month
{
    my $self = shift;
    my $yyyy = shift;
    my $mm   = shift;

    $yyyy = $self->{yyyy} unless defined $yyyy;
    $mm   = $self->{mm}   unless defined $mm;

    _validate_date($yyyy, $mm, 1);

    my (@start, @end);
    @start = $self->to_gregorian($yyyy, $mm, 1);
    if ($mm == 12)
    {
        $yyyy += 1;
        $mm    = 1;
    }
    else
    {
        $mm += 1;
    }
    @end = $self->to_gregorian($yyyy, $mm, 1);

    return Delta_Days(@start, @end);
}

=head2 get_calendar(yyyy, mm)

Return calendar for given year and month in Persian calendar. It return current month of Persian
calendar if no argument is passed in.

    use strict; use warnings;
    use Calendar::Persian;

    my $persian = Calendar::Persian->new(1932,1,1);
    print $saka->get_persian();

    # Print calendar for year 1932 and month 12.
    print $persian->get_calendar(1932, 12);

=cut

sub get_calendar
{
    my $self = shift;
    my $yyyy = shift;    
    my $mm   = shift;

    $yyyy = $self->{yyyy} unless defined $yyyy;
    $mm   = $self->{mm} unless defined $mm;

    _validate_date($yyyy, $mm, 1);

    my ($calendar, $start_index, $days);
    $calendar = sprintf("\n\t%s [%04d]\n", $MONTHS->[$mm], $yyyy);
    $calendar .= "\nSun  Mon  Tue  Wed  Thu  Fri  Sat\n";

    $start_index = $self->dow($yyyy, $mm, 1);
    $days = $self->days_in_year_month($yyyy, $mm);
    map { $calendar .= "     " } (1..($start_index%=7));
    foreach (1 .. $days) 
    {
        $calendar .= sprintf("%3d  ", $_);
        $calendar .= "\n" unless (($start_index+$_)%7);
    }
    return sprintf("%s\n\n", $calendar);
}

=head2 debug()

Turn the DEBUG on/off by passing 1/0 respectively.

    use Calendar::Persian;

    my $persian = Calendar::Persian->new();
    $persian->debug(1);

=cut

sub debug
{
    my $self = shift;
    my $flag = shift;
    croak("ERROR: Invalid value for DEBUG.\n")
        unless ($flag =~ /^[0|1]$/);
    $DEBUG = $flag;
}

sub _julian_dow
{
    my $julian = shift;
    return floor(($julian + 1.5)) % 7;
}

sub _is_gregorian_leap
{
    my $yyyy = shift;

    return (($yyyy % 4) == 0) &&
            (!((($yyyy % 100) == 0) && (($yyyy % 400) != 0)));
}

sub _gregorian_to_julian
{
    my $yyyy = shift;
    my $mm   = shift;
    my $dd   = shift;

    return ($GREGORIAN_EPOCH - 1) +
           (365 * ($yyyy - 1)) +
           floor(($yyyy - 1) / 4) +
           (-floor(($yyyy - 1) / 100)) +
           floor(($yyyy - 1) / 400) +
           floor((((367 * $mm) - 362) / 12) +
           (($mm <= 2) ? 0 : (_is_gregorian_leap($yyyy) ? -1 : -2)) +
           $dd);
}

sub _julian_to_gregorian
{
    my $julian = shift;

    my $wjd        = floor($julian - 0.5) + 0.5;
    my $depoch     = $wjd - $GREGORIAN_EPOCH;
    my $quadricent = floor($depoch / 146097);
    my $dqc        = $depoch % 146097;
    my $cent       = floor($dqc / 36524);
    my $dcent      = $dqc % 36524;
    my $quad       = floor($dcent / 1461);
    my $dquad      = $dcent % 1461;
    my $yindex     = floor($dquad / 365);
    my $year       = ($quadricent * 400) + ($cent * 100) + ($quad * 4) + $yindex;

    $year++ unless (($cent == 4) || ($yindex == 4));

    my $yearday = $wjd - _gregorian_to_julian($year, 1, 1);
    my $leapadj = (($wjd < _gregorian_to_julian($year, 3, 1)) ? 0 : ((_is_gregorian_leap($year) ? 1 : 2)));
    my $month   = floor(((($yearday + $leapadj) * 12) + 373) / 367);
    my $day     = ($wjd - _gregorian_to_julian($year, $month, 1)) + 1;

    return ($year, $month, $day);
}

sub _to_julian
{
    my $yyyy = shift;
    my $mm   = shift;
    my $dd   = shift;

    my $epbase = $yyyy - (($yyyy >= 0) ? 474 : 473);
    my $epyear = 474 + ($epbase % 2820);

    return $dd 
           +
           (($mm <= 7) 
             ?
             (($mm - 1) * 31) 
             :
             ((($mm - 1) * 30) + 6)
           ) 
           +
           floor((($epyear * 682) - 110) / 2816) 
           +
           ($epyear - 1) * 365 
           +
           floor($epbase / 2820) * 1029983 
           +
           ($PERSIAN_EPOCH - 1);
}

sub _from_julian
{
    my $julian = shift;
    
    $julian = floor($julian) + 0.5;
    my $depoch = $julian - _to_julian(475, 1, 1);
    my $cycle  = floor($depoch / 1029983);
    my $cyear  = $depoch % 1029983;
    
    my $ycycle;
    if ($cyear == 1029982) 
    {
        $ycycle = 2820;
    } 
    else 
    {
        my $aux1 = floor($cyear / 366);
        my $aux2 = $cyear % 366;
        $ycycle = floor(((2134 * $aux1) + (2816 * $aux2) + 2815) / 1028522) + $aux1 + 1;
    }
    my $yyyy = $ycycle + (2820 * $cycle) + 474;
    if ($yyyy <= 0) 
    {
        $yyyy--;
    }
    my $yday = ($julian - _to_julian($yyyy, 1, 1)) + 1;
    my $mm   = ($yday <= 186) ? ceil($yday / 31) : ceil(($yday - 6) / 30);
    my $dd   = ($julian - _to_julian($yyyy, $mm, 1)) + 1;
    
    return ($yyyy, $mm, $dd);
}

sub _validate_date
{
    my $yyyy = shift;
    my $mm   = shift;
    my $dd   = shift;

    croak("ERROR: Invalid year [$yyyy].\n")
        unless (defined($yyyy) && ($yyyy =~ /^\d{4}$/) && ($yyyy > 0));
    croak("ERROR: Invalid month number [$mm].\n")
        unless (defined($mm) && ($mm =~ /^\d{1,2}$/) && ($mm >= 1 || $mm <= 12));
    croak("ERROR: Invalid day number [$dd].\n")
        unless (defined($dd) && ($dd =~ /^\d{1,2}$/) && ($dd >= 1 || $mm <= 31));
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-calendar-persian at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Persian>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Persian

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Calendar-Persian>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Calendar-Persian>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Calendar-Persian>

=item * Search CPAN

L<http://search.cpan.org/dist/Calendar-Persian/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mohammad S Anwar.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DISCLAIMER

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

1; # End of Calendar::Persian
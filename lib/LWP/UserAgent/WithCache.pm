package LWP::UserAgent::WithCache;

use strict;

use base qw(LWP::UserAgent);

our $VERSION = '0.02';

use Cache::FileCache;

our $HOME = $ENV{'HOME'} || $ENV{'LOGDIR'};
our %default_cache_args = (
    'namespace' => 'lwp-cache',
    'cache_root' => "$HOME/.cache",
    'default_expires_in' => 600 );

sub new {
    my $class = shift;
    my $cache_opt = shift || {};
    my $self = $class->SUPER::new(@_);
    my %cache_args = (%default_cache_args, %$cache_opt);
    $self->{cache} = Cache::FileCache->new(\%cache_args);
    return $self
}

sub request {
     my $self = shift;
     my @args = @_;
     my $request = $args[0];
     my $uri = $request->uri->as_string;
     my $cache = $self->{cache};

     my $content = $cache->get( $uri );

     my $res;
     if ( defined $content ) {
         my $obj = $cache->get_object( $uri );
         $request->header('If-Modified-Since' =>
                             HTTP::Date::time2str($obj->get_created_at));
         $args[0] = $request;
         $res = $self->SUPER::request(@args);
         if ($res->code ne '304'){
             $cache->set($uri, $res->content); 
         }
     }else{
         $res = $self->SUPER::request(@args);
         $cache->set($uri, $res->content); 
     }

     return $res;
}

1;
__END__

=head1 NAME

LWP::UserAgent::WithCache - LWP::UserAgent extension with local cache

=head1 SYNOPSIS

  use LWP::UserAgent::WithCache;
  my %cache_opt = (
    'namespace' => 'lwp-cache',
    'cache_root' => "$HOME/.cache",
    'default_expires_in' => 600 );
  my $ua = LWP::UserAgent::WithCache->new(\%cache_opt);
  my $response = $ua->get('http://search.cpan.org/');

=head1 DESCRIPTION

LWP::UserAgent::WithCache is a LWP::UserAgent extention.
It handle 'If-Modified-Since' request header with local cache file.
locala cache files are implemented by Cache::FileCache module. 

=head1 METHODS

TBD.

=head1 SEE ALSO

L<LWP::UserAgent>, L<Cache::Cache>, L<Cache::FileCache>

=head1 AUTHOR

Masayoshi Sekimura E<lt>sekimura@qootas.org<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use Mojo::Base -base;
use Mojo::Asset::File;
use Mojo::Util 'spurt';
use File::Spec;
use Test::More;

my $convos = File::Spec->catfile(qw( script convos ));
$ENV{CONVOS_INIT_CONFIG_FILE} = 't/etc/default/convos';
plan skip_all => "Cannot execute $convos" unless -x $convos;
plan skip_all => "This test requires your Perl to to be the default one in your PATH.\n"
  . "Set CONVOS_TEST_INIT=1 to run it"
  unless $ENV{CONVOS_TEST_INIT};

{
  my $script = get_init_file('backend');
  my $src    = $script->slurp;

  like $src, qr{\bconvos-backend \$1},      'convos-backend init script generated by script/convos';
  like $src, qr{/etc/default/convos},       'convos-backend init script source /etc/default/convos';
  like $src, qr{^MOJO_MODE='production';}m, 'MOJO_MODE is set for convos-backend';
  like $src, qr{^set -a;}m,                 'export on for convos-frontend';

  delete $script->{handle};
  like run($script->path, 'help'), qr{Usage: convos backend.*start.*stop}, 'backend init script can help';
  like run($script->path, 'env'), qr{CONVOS_WHATEVER=bar}, 'init script source environemnt variables';
}

{
  my $script = get_init_file('frontend');
  my $src    = $script->slurp;

  like $src, qr{\bconvos-frontend \$1},     'convos-frontend init script generated by script/convos';
  like $src, qr{/etc/default/convos},       'convos-frontend init script source /etc/default/convos';
  like $src, qr{^MOJO_MODE='production';}m, 'MOJO_MODE is set for convos-frontend';
  like $src, qr{^set -a;}m,                 'export on for convos-backend';

  delete $script->{handle};
  like run($script->path, 'help'), qr{Usage: convos frontend.*start.*stop}, 'frontend init script can help';
}

done_testing;

sub get_init_file {
  my $type  = shift;
  my $asset = Mojo::Asset::File->new;
  open my $INIT_FILE, '-|', $convos => $type => 'get_init_file' or die $!;
  $asset->add_chunk($_) while <$INIT_FILE>;
  $asset;
}

sub run {
  my $output = '';
  chmod 0750, $_[0];
  open my $CMD, '-|', @_ or die "@_: $!";
  $output .= $_ while <$CMD>;
  $output;
}

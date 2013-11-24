package Mojolicious::Plugin::NamespaceForm;

=head1 NAME

Mojolicious::Plugin::NamespaceForm - Support foo.0.bar params

=head1 VERSION

0.01

=head1 DESCRIPTION

This plugin makes it easier to work with multiple forms on a webpages.

This plugins solves the problem related to validation and automatic form
filling. That logic is based on the name of the form field, meaning you
need to provide unique names for each form of the same type, unless
you want confusing error messages displayed to the user.

=head2 Example

The forms below is supposed to illustrate the problem:

  <form>
    <h2>New product</h2>
    Product name: <input name="product_name">
    <button>Add</button>
    <h2>Existing product</h2>
    Product name: <input name="product_name">
    <button name="id" value="42">Update</button>
  </form>

=head2 How does it work?

This plugin works by wrapping around most of the built in form helpers with
extra logic for generating the name of the input field. The helpers below is
overridden by default, but the list will probably get longer in the future.

  check_box
  hidden_field
  label_for
  number_field
  password_field
  radio_button
  select_field
  text_area
  text_field
  url_field

=head1 SYNOPSIS

=head2 Single object

Application/controller logic:

  use Mojolicious::Lite;
  plugin 'Mojolicious::Plugin::NamespaceForm';

  post '/user' => sub {
    my $self = shift;
    my $user = $self->namespace_params('user')->single;

    # $user = { email => '...', name => '...', _index => 42 }
  };

Template:

  % stash field_namespace => 'user';
  % stash field_index => 42; # optional
  %= text_field 'email';
  %= text_field 'name';

Output:

  <input name="user.42.email">
  <input name="user.42.name">

=head2 Multiple objects

  post '/users' => sub {
    my $self = shift;
    my @users = @{ $self->namespace_params('user') };

    # @users = (
    #   { email => '...', name => '...', _index => 0 },
    #   { email => '...', name => '...', _index => 1 },
    # );

    for my $user (@users) {
      # ...
    }
  };

Template:

  % stash field_namespace => 'user';
  % stash field_index => 0;
  % for my $user (@$users) {
    %= text_field 'email';
    %= text_field 'name';
    % stash->{field_index}++;
  % }

Output:

  <input name="user.0.email">
  <input name="user.0.name">
  <input name="user.1.email">
  <input name="user.1.name">
  ...

=cut

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

my @FORM_HELPERS = qw(
  check_box
  hidden_field
  label_for
  number_field
  password_field
  radio_button
  select_field
  text_area
  text_field
  url_field
);

=head1 HELPERS

=head2 namespace_params

  $obj = $self->namespace_params($namespace);
  @list_of_hashes = @$obj;
  $hash_ref = $obj->single; # might die
  $hash_ref = $obj->get($index); # might return undef

The C<$obj> is overloaded in list context: It will return a list of hash-refs
ordered by C<_index>.

See L</NAMESPACE OBJECT METHODS> for more details.

=head1 METHODS

=head2 register

  $self->register(helpers => [qw( input_tag )]);

Will register L</HELPERS> and override tag helpers.

=cut

sub register {
  my($self, $app, $config) = @_;
  my @helpers = $config->{helpers} ? @{ $config->{helpers} } : @FORM_HELPERS;
  my $r = $app->renderer;

  $app->defaults(field_index => 0, field_namespace => '');

  for my $name (@FORM_HELPERS) {
    my $original = delete $r->helpers->{$name} or die "No such helper: $name";
    $r->add_helper($name => sub {
      my($c, $name, @args) = @_;
      my $namespace = $c->stash('field_namespace');
      return $c->$original($name, @args) unless $namespace;
      my $index = $c->stash('field_index') || 0;
      return $c->$original("$namespace.$index.$name", @args);
    });
  }

  $r->add_helper(namespace_params => sub {
    my($self, $namespace) = @_;
    my $validated = $self->validation->output;
    my $only_validated = $self->validation->has_error || $self->validation->is_valid;
    my %data;

    $namespace = qr{^$namespace\.(\d+)\.(.+)$};

    for my $name ($self->param) {
      next unless $name =~ $namespace;
      next if $only_validated and !defined $validated->{$name};
      $data{$1}{_index} = int $1;
      $data{$1}{$2} = $validated->{$name} // $self->param($name);
    }

    return Mojolicious::Plugin::NamespaceForm::Data->new(data => \%data);
  });
}

=head1 NAMESPACE OBJECT METHODS

=cut

package
  Mojolicious::Plugin::NamespaceForm::Data;

use Mojo::Base -base;
use overload (
  fallback => 1,
  q(@{}) => sub {
    [
      sort { $a->{_index} <=> $b->{_index} }
      values %{ $_[0]->{data} }
    ];
  },
);

=head2 get

  $hash_ref = $self->get($index);

Return a given hash ref by index, or undef if no such index is defined.

=cut

sub get {
  $_[0]->{data}{$_[1]};
}

=head2 single

  $hash_ref = $self->single;

This method will die if no data exists for form namespace or if there are more
than one item. The index does not matter.

=cut

sub single {
  my $self = shift;
  my $n = keys %{ $self->{data} };

  die "No elements in form namespace" unless $n;
  die "Too many elements in form namespace ($n)" if $n > 1;
  values %{ $self->{data} };
}

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

{
  use Mojolicious::Lite;
  plugin 'Mojolicious::Plugin::NamespaceForm';

  get '/user' => { field_index => 42 }, sub {
    my $self = shift;
  };

  post '/user' => sub {
    my $self = shift;

    $self->render(json => $self->namespace_params('user')->single);
  };

  post '/validate' => sub {
    my $self = shift;
    my $user;

    $self->validation->optional('user.42.name');
    $self->validation->required('user.42.email')->like(qr{\@});
    $self->render(json => $self->namespace_params('user')->single);
  };

  get '/users' => sub {
    my $self = shift;

    $self->stash(users => [ {}, {} ]);
  };

  post '/users' => sub {
    my $self = shift;

    $self->render(json => [ @{ $self->namespace_params('user') } ]);
  };
}

my $t = Test::Mojo->new;

{
  $t->get_ok('/user')
    ->status_is(200)
    ->element_exists('input[name="user.42.email"]')
    ->element_exists('input[name="user.42.name"]')
    ;

  $t->post_ok('/user', form => { 'user.42.email' => 'a@b.com' })
    ->status_is(200)
    ->json_is('/email', 'a@b.com')
    ->json_is('/_index', '42')
    ;
}

{
  $t->get_ok('/users')
    ->status_is(200)
    ->element_exists('input[name="user.0.email"]')
    ->element_exists('input[name="user.0.name"]')
    ->element_exists('input[name="user.1.email"]')
    ->element_exists('input[name="user.1.name"]')
    ;

  $t->post_ok('/users', form => { 'user.0.email' => 'a@b.com', 'user.1.email' => 'b@c.com' })
    ->status_is(200)
    ->json_is('/0/email', 'a@b.com')
    ->json_is('/0/_index', '0')
    ->json_is('/1/email', 'b@c.com')
    ->json_is('/1/_index', '1')
    ;
}

{
  $t->post_ok('/validate', form => { 'user.42.email' => 'not_valid', 'user.42.name' => 'batman' })
    ->status_is(200)
    ->json_is('/name', 'batman')
    ->json_is('/email', undef)
    ->content_like(qr{"_index":42\D})
    ;
}

done_testing;
__DATA__
@@ user.html.ep
% stash field_namespace => 'user';
%= text_field 'email';
%= text_field 'name';

@@ users.html.ep
<h1>Users</h1>
% stash field_namespace => 'user';
% stash field_index => 0;
% my $i = 0;
% for my $user (@$users) {
  %= include 'user', user => $user, field_index => $i++;
% }
